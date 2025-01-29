package neep

import "core:strings"

Disassembly_Line :: struct {
	byte_address: u16,
	raw: []u8,
	instruction: Instruction,
}

disassembly_line_to_string :: proc(sb: ^strings.Builder, line: ^Disassembly_Line) {
	hex_string(sb, line.byte_address)
	strings.write_string(sb, ": ")
	for i := 0; i < 3; i += 1 {
		strings.write_string(sb, " ")
		if i < len(line.raw) {
			hex_string(sb, line.raw[i], uppercase=true)
		} else {
			strings.write_string(sb, "  ")
		}
	}
	strings.write_string(sb, "         ")
	instruction_to_string(sb, &line.instruction)
	strings.write_rune(sb, '\n')
}

disassemble_bin :: proc(data: []u8) -> string {
	sb := strings.builder_make(256)
	address: u32
	max_address := u32(len(data))

	lines := make([dynamic]Disassembly_Line, 0, 32)
	defer delete(lines)

	for address < max_address {
		rem_bytes := max_address - address
		instruction, ok := decode_instruction(data[address:], rem_bytes)
		if !ok {
			panic("Malformed instruction stream!")
		}
		next_address := address + u32(instruction.bytes)
		append(&lines, Disassembly_Line{
			byte_address=u16(address),
			raw=data[address:next_address],
			instruction=instruction,
		})
		address = next_address
	}

	for &line in lines {
		disassembly_line_to_string(&sb, &line)
	}

	return strings.to_string(sb)
}
