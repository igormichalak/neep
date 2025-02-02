package neep

import "core:fmt"
import "core:strings"

hex_string_u8 :: #force_inline proc(sb: ^strings.Builder, n: u8, uppercase := false) {
	fmt.sbprintf(sb, "%02X" if uppercase else "%02x", n)
}

hex_string_u16 :: #force_inline proc(sb: ^strings.Builder, n: u16, uppercase := false) {
	fmt.sbprintf(sb, "%04X" if uppercase else "%04x", n)
}

hex_string :: proc{hex_string_u8, hex_string_u16}

operand_to_string :: proc(sb: ^strings.Builder, operand: ^Operand) {
	switch operand.type {
	case .ACC:
		strings.write_string(sb, "A")
	case .REG:
		fmt.sbprintf(sb, "R%d", operand.value)
	case .AB:
		strings.write_string(sb, "AB")
	case .CARRY_BIT:
		strings.write_string(sb, "C")
	case .BIT_ADDR:
		symbol := symbol_from_address(u16(operand.value), .IRAM_BIT)
		if symbol == "" {
			fmt.sbprintf(sb, "0x%02X", operand.value)
		} else {
			fmt.sbprintf(sb, "%s.%d", symbol, operand.value & 0b111)
		}
	case .INV_BIT_ADDR:
		fmt.sbprintf(sb, "/0x%02X", operand.value)
	case .IMM, .IMM_LONG:
		fmt.sbprintf(sb, "#0x%02X", operand.value)
		if operand.value != 0x00 && operand.value != 0xFF && operand.value != 0xFFFF {
			fmt.sbprintf(sb, " ; %d", operand.value)
		}
	case .DPTR:
		strings.write_string(sb, "DPTR")
	case .DIRECT_ADDR:
		symbol := symbol_from_address(u16(operand.value), .IRAM)
		if symbol == "" {
			fmt.sbprintf(sb, "0x%02X", operand.value)
		} else {
			strings.write_string(sb, symbol)
		}
	case .INDIRECT_REG:
		fmt.sbprintf(sb, "@R%d", operand.value)
	case .INDIRECT_DPTR:
		strings.write_string(sb, "@DPTR")
	case .INDIRECT_ACC_PLUS_DPTR:
		strings.write_string(sb, "@A + DPTR")
	case .INDIRECT_ACC_PLUS_PC:
		strings.write_string(sb, "@A + PC")
	case .ADDR_11, .ADDR_16:
		fmt.sbprintf(sb, "0x%04x", operand.value)
	case .OFFSET:
		fmt.sbprintf(sb, "%d", operand.value)
	case .NONE:
	}
}

Character_Case :: enum u8 {
	UPPERCASE,
	LOWERCASE,
}

write_cased_string :: proc(sb: ^strings.Builder, s: string, cc: Character_Case) {
	for r in s {
		switch {
		case cc == .UPPERCASE && 'a' <= r && r <= 'z':
			strings.write_rune(sb, r - 32)
		case cc == .LOWERCASE && 'A' <= r && r <= 'Z':
			strings.write_rune(sb, r + 32)
		case:
			strings.write_rune(sb, r)
		}
	}
}

instruction_to_string :: proc(sb: ^strings.Builder, instruction: ^Instruction) {
	mnemonic := Op_Mnemonics[instruction.op]
	write_cased_string(sb, mnemonic, .LOWERCASE)

	for pad := 6 - len(mnemonic); pad > 0; pad -= 1 {
		strings.write_rune(sb, ' ')
	}
	strings.write_rune(sb, ' ')

	hasOperandA := false
	hasOperandB := false

	if instruction.a.type != .NONE {
		operand_to_string(sb, &instruction.a)
		hasOperandA = true
	}
	if instruction.b.type != .NONE {
		if hasOperandA {
			strings.write_string(sb, ", ")
		}
		operand_to_string(sb, &instruction.b)
		hasOperandB = true
	}
	if instruction.jump.type != .NONE {
		if hasOperandA || hasOperandB {
			strings.write_string(sb, ", ")
		}
		operand_to_string(sb, &instruction.jump)
	}
}
