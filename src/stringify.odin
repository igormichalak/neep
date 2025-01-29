package neep

import "core:strings"

operand_to_string :: proc(sb: ^strings.Builder, operand: ^Operand) {
}

instruction_to_string :: proc(sb: ^strings.Builder, instruction: ^Instruction) {
	strings.write_string(sb, Op_Mnemonics[instruction.op])
}
