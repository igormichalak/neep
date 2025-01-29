package neep

fetch_operand :: proc(data: []u8, specifier: ^Operand_Specifier) -> Operand {
	operand := Operand{
		type=specifier.type,
		value=specifier.constant,
	}
	signed := specifier.type == .OFFSET

	switch specifier.fetch {
	case .NONE:
	case .BYTE_1:
		operand.value = i32((^i8)(&data[1])^) if signed else i32(data[1])
	case .BYTE_2:
		operand.value = i32((^i8)(&data[2])^) if signed else i32(data[2])
	case .TWO_BYTES:
		operand.value = i32(u16(data[1]) << 8 | u16(data[2]))
	case .ADDR_11:
		operand.value += i32(data[1])
	}

	return operand
}

decode_instruction :: proc(data: []u8, max_bytes: u32) -> (Instruction, bool) {
	specifier := &OPCODE_TABLE[data[0]]
	if specifier.op == .ILLEGAL {
		return {}, false
	}
	if max_bytes < u32(specifier.bytes) {
		return {}, false
	}
	return Instruction{
		specifier.bytes,
		specifier.op,
		{a=fetch_operand(data, &specifier.a)},
		{b=fetch_operand(data, &specifier.b)},
		fetch_operand(data, &specifier.jump),
	}, true
}
