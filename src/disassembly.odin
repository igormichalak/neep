package neep

import "core:fmt"
import "core:strings"

Disassembly_Line :: struct {
	byte_address: u16,
	raw: []u8,
	instruction: Instruction,
	label_num: int,
	jumps_to: u16,
}

Disassembly_Context :: struct {
	sfr_page: int,
}

write_label_string :: proc(sb: ^strings.Builder, num, num_width: int, $colon: bool) {
	when colon {
		fmt.sbprintf(sb, ANSI_SEQ_LABEL + ".L_%0*[1][0]d" + ANSI_SEQ_RESET + ":", num, num_width)
	} else {
		fmt.sbprintf(sb, ANSI_SEQ_LABEL + ".L_%0*[1][0]d" + ANSI_SEQ_RESET, num, num_width)
	}
}

label_string :: proc(num, num_width: int, $colon: bool) -> string {
	when colon {
		return fmt.aprintf(ANSI_SEQ_LABEL + ".L_%0*[1][0]d" + ANSI_SEQ_RESET + ":", num, num_width)
	} else {
		return fmt.aprintf(ANSI_SEQ_LABEL + ".L_%0*[1][0]d" + ANSI_SEQ_RESET, num, num_width)
	}
}

get_sfr_page :: proc(instruction: ^Instruction, prev_sfr_page: int) -> int {
	if instruction.op               == .MOV &&
	   instruction.source.type      == .IMM &&
	   instruction.destination.type == .DIRECT_ADDR {
		address, ok := get_sfr_page_reg_address()
		return int(instruction.source.value) if ok && instruction.destination.value == i32(address) else prev_sfr_page
	} else {
		return prev_sfr_page
	}
}

new_disassembly_context :: #force_inline proc() -> Disassembly_Context {
	return Disassembly_Context{sfr_page=UNKNOWN_SFR_PAGE}
}

update_disassembly_context_pre :: proc(disasm_ctx: ^Disassembly_Context, line: ^Disassembly_Line) {
	if line.label_num >= 0 {
		disasm_ctx.sfr_page = UNKNOWN_SFR_PAGE
	}
}

update_disassembly_context_post :: proc(disasm_ctx: ^Disassembly_Context, line: ^Disassembly_Line) {
	if is_branch_op(line.instruction.op) {
		disasm_ctx.sfr_page = UNKNOWN_SFR_PAGE
	} else {
		disasm_ctx.sfr_page = get_sfr_page(&line.instruction, disasm_ctx.sfr_page)
	}
}

disassembly_line_to_string :: proc(
	sb: ^strings.Builder,
	line: ^Disassembly_Line,
	disasm_ctx: ^Disassembly_Context,
	label_digits: int,
	reference_map: map[u16]int,
) {
	hex_string(sb, line.byte_address)
	strings.write_string(sb, ": ")

	for i := 0; i < 3; i += 1 {
		write_space(sb, 1)
		if i < len(line.raw) {
			hex_string(sb, line.raw[i], uppercase=true)
		} else {
			write_space(sb, 2)
		}
	}

	if line.label_num >= 0 {
		write_space(sb, 3)
		write_label_string(sb, line.label_num, label_digits, colon=true)
		write_space(sb, 2)
	} else {
		write_space(sb, 9 + label_digits)
	}

	if jump_label_num, ok := reference_map[line.jumps_to]; ok && jump_label_num >= 0 {
		jump_operand := label_string(jump_label_num, label_digits, colon=false)
		instruction_to_string(sb, &line.instruction, disasm_ctx, jump_operand)
		delete(jump_operand)
	} else {
		instruction_to_string(sb, &line.instruction, disasm_ctx)
	}

	strings.write_rune(sb, '\n')
}

disassemble_bin :: proc(data: []u8) -> string {
	sb := strings.builder_make(256)
	address: u32
	max_address := u32(len(data))

	lines := make([dynamic]Disassembly_Line, 0, 32)
	defer delete(lines)

	reference_map := make(map[u16]int)

	for address < max_address {
		rem_bytes := max_address - address
		instruction, ok := decode_instruction(data[address:], rem_bytes)
		if !ok {
			panic("malformed instruction stream")
		}
		next_address := address + u32(instruction.bytes)

		jumps_to: u16

		#partial switch instruction.jump.type {
		case .ADDR_11, .ADDR_16:
			jumps_to = u16(instruction.jump.value)
			reference_map[jumps_to] = -1
		case .OFFSET:
			jump_address := i32(address) +
			                i32(instruction.bytes) +
			                instruction.jump.value
			if 0 <= jump_address && jump_address <= i32(max(u16)) {
				jumps_to = u16(jump_address)
				reference_map[jumps_to] = -1
			}
		}

		append(&lines, Disassembly_Line{
			byte_address=u16(address),
			raw=data[address:next_address],
			instruction=instruction,
			label_num=-1,
			jumps_to=jumps_to,
		})
		address = next_address
	}

	label_counter := -1
	for &line in lines {
		if line.byte_address in reference_map {
			label_counter += 1
			reference_map[line.byte_address] = label_counter
			line.label_num = label_counter
		}
	}
	label_digits := count_digits(label_counter)

	disasm_ctx := new_disassembly_context()
	for &line in lines {
		update_disassembly_context_pre(&disasm_ctx, &line)
		disassembly_line_to_string(&sb, &line, &disasm_ctx, label_digits, reference_map)
		update_disassembly_context_post(&disasm_ctx, &line)
	}

	return strings.to_string(sb)
}
