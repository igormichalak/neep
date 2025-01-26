package neep

import "core:fmt"
import "core:strings"

hex_string_u8 :: #force_inline proc(buf: ^strings.Builder, n: u8, uppercase := false) {
	fmt.sbprintf(buf, "%02X" if uppercase else "%02x", n)
}

hex_string_u16 :: #force_inline proc(buf: ^strings.Builder, n: u16, uppercase := false) {
	fmt.sbprintf(buf, "%04X" if uppercase else "%04x", n)
}

hex_string :: proc{hex_string_u8, hex_string_u16}

decode_instruction :: proc(data: [3]u8) -> (string, int) {
	return "", 1
}

disassemble_bin :: proc(data: []u8) -> string {
	sb := strings.builder_make(256)
	position: int = 0
	imem := [3]u8{0, 0, 0}

	for position < len(data) {
		copy_n := min(len(data) - position, 3)
		for i := copy_n; i < 3; i += 1 {
			imem[i] = 0;
		}
		copy(imem[:], data[position:position+copy_n])
		// decode_instruction(imem)
		position += 1
	}

	return strings.to_string(sb)
}