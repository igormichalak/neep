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

fetch_operand :: proc(data: []u8, blueprint: Opcode_Entry_Operand) -> (operand: Operand) {
	operand.type = blueprint.type
	switch blueprint.fetch {
	case .NONE:
		operand.value = blueprint.value
	case .BYTE_1:
		signed := blueprint.type == .OFFSET
		operand.value = signed ? i32((^i8)(&data[1])^) : i32(data[1])
	case .BYTE_2:
		signed := blueprint.type == .OFFSET
		operand.value = signed ? i32((^i8)(&data[2])^) : i32(data[2])
	case .TWO_BYTES:
		operand.value = i32(u16(data[1]) << 8 | u16(data[2]))
	case .ADDR_11:
		operand.value = blueprint.value + i32(data[1])
	}
	return
}

decode_instruction :: proc(data: []u8, position, rem: u32) -> (Instruction, bool) {
	opcode_entry := OPCODE_TABLE[data[0]]
	if rem < u32(opcode_entry.bytes) {
		return {}, false
	}
	return Instruction{
		u16(position),
		opcode_entry.bytes,
		opcode_entry.op,
		{a=fetch_operand(data, opcode_entry.a)},
		{b=fetch_operand(data, opcode_entry.b)},
		fetch_operand(data, opcode_entry.transfer),
	}, true
}

disassemble_bin :: proc(data: []u8) -> string {
	sb := strings.builder_make(256)
	position: u32

	instructions := make([dynamic]Instruction, 0, 32)
	defer delete(instructions)

	for position < u32(len(data)) {
		rem := u32(len(data)) - position
		inst, ok := decode_instruction(data[position:], position, rem)
		if !ok {
			panic("Malformed instruction stream!")
		}
		append(&instructions, inst)
		position += u32(inst.bytes)
	}

	for inst in instructions {
		fmt.sbprint(&sb, inst.op, "")
		if inst.destination.type != .NONE {
			fmt.sbprint(&sb, inst.destination.type, "")
		}
		if inst.source.type != .NONE {
			fmt.sbprint(&sb, inst.source.type, "")
		}
		if inst.transfer.type != .NONE {
			fmt.sbprint(&sb, inst.transfer.type)
		}
		fmt.sbprintln(&sb)
	}

	return strings.to_string(sb)
}
