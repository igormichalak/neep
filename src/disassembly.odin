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

disassembly_line_to_string :: proc(
	sb: ^strings.Builder,
	line: ^Disassembly_Line,
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
		instruction_to_string(sb, &line.instruction, jump_operand)
		delete(jump_operand)
	} else {
		instruction_to_string(sb, &line.instruction)
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
	for &line in lines {
		disassembly_line_to_string(&sb, &line, label_digits, reference_map)
	}

	return strings.to_string(sb)
}
