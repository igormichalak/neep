package neep

Op :: enum u8 {
	ACALL,
	ADD,
	ADDC,
	AJMP,
	ANL,
	CJNE,
	CLR,
	CPL,
	DA,
	DEC,
	DIV,
	DJNZ,
	INC,
	JB,
	JBC,
	JC,
	JMP,
	JNB,
	JNC,
	JNZ,
	JZ,
	LCALL,
	LJMP,
	MOV,
	MOVC,
	MOVX,
	MUL,
	NOP,
	ORL,
	POP,
	PUSH,
	RET,
	RETI,
	RL,
	RLC,
	RR,
	RRC,
	SETB,
	SJMP,
	SUBB,
	SWAP,
	XCH,
	XCHD,
	XRL,
}

Operand_Type :: enum u8 {
	NONE,                   // no operand and no value
	ACC,                    // no value (A)
	REG,                    // 3-bit value (Rn)
	AB,                     // no value (AB)
	CARRY_BIT,              // no value (C)
	BIT_ADDR,               // 8-bit address (const)
	INV_BIT_ADDR,           // 8-bit address (/const)
	IMM,	                // 8-bit immediate (#const)
	IMM_LONG,               // 16-bit immediate (#const)
	DPTR,                   // no value (DPTR)
	DIRECT_ADDR,            // 8-bit address (const)
	INDIRECT_REG,           // 1-bit value (@Ri)
	INDIRECT_DPTR,          // no value (@DPTR)
	INDIRECT_ACC_PLUS_DPTR, // no value (@A + DPTR)
	INDIRECT_ACC_PLUS_PC,   // no value (@A + PC)
	ADDR_11,                // 11-bit address (const)
	ADDR_16,                // 16-bit address (const)
	OFFSET,                 // 8-bit signed offset (const)
}

Operand :: struct {
	type: Operand_Type,
	value: i32,
}

Instruction :: struct {
	byte_address: u16,
	bytes: u8,
	op: Op,
	using _: struct #raw_union {
		destination: Operand,
		a: Operand,
	},
	using _: struct #raw_union {
		source: Operand,
		b: Operand,
	},
	transfer: Operand,
}

Operand_Fetch :: enum u8 {
	NONE,      // no fetch
	BYTE_1,    // byte_1
	BYTE_2,    // byte_2
	TWO_BYTES, // (byte_1 << 8) | byte_2
	ADDR_11,   // ((byte_0 & 0xE0) << 3) | byte_1
}

Opcode_Entry_Operand :: struct {
	type: Operand_Type,
	value: i32,
	fetch: Operand_Fetch,
}

Opcode_Entry :: struct {
	bytes: u8,
	op: Op,
	a, b, transfer: Opcode_Entry_Operand,
}

opcode_entry :: #force_inline proc(bytes: u8, op: Op, a, b, transfer: Opcode_Entry_Operand) -> Opcode_Entry {
	return {bytes, op, a, b, transfer}
}

// Some opcodes contain 3 high bits for 11-bit addresses.
opcode_constant :: #force_inline proc(opcode: u8) -> i32 {
	return i32(u16(opcode & 0xE0) << 3)
}

OPCODE_TABLE := [256]Opcode_Entry {
	0x00 = opcode_entry(1, .NOP, {}, {}, {}),
	0x01 = opcode_entry(2, .AJMP, {}, {}, {.ADDR_11, opcode_constant(0x01), .ADDR_11}),
	0x02 = opcode_entry(3, .LJMP, {}, {}, {.ADDR_16, 0, .TWO_BYTES}),
	0x03 = opcode_entry(1, .RR, {.ACC, 0, .NONE}, {}, {}),
	0x04 = opcode_entry(1, .INC, {.ACC, 0, .NONE}, {}, {}),
	0x05 = opcode_entry(2, .INC, {.DIRECT_ADDR, 0, .BYTE_1}, {}, {}),
	0x06 = opcode_entry(1, .INC, {.INDIRECT_REG, 0, .NONE}, {}, {}),
	0x07 = opcode_entry(1, .INC, {.INDIRECT_REG, 1, .NONE}, {}, {}),
	0x08 = opcode_entry(1, .INC, {.REG, 0, .NONE}, {}, {}),
	0x09 = opcode_entry(1, .INC, {.REG, 1, .NONE}, {}, {}),
	0x0A = opcode_entry(1, .INC, {.REG, 2, .NONE}, {}, {}),
	0x0B = opcode_entry(1, .INC, {.REG, 3, .NONE}, {}, {}),
	0x0C = opcode_entry(1, .INC, {.REG, 4, .NONE}, {}, {}),
	0x0D = opcode_entry(1, .INC, {.REG, 5, .NONE}, {}, {}),
	0x0E = opcode_entry(1, .INC, {.REG, 6, .NONE}, {}, {}),
	0x0F = opcode_entry(1, .INC, {.REG, 7, .NONE}, {}, {}),
	0x10 = opcode_entry(3, .JBC, {.BIT_ADDR, 0, .BYTE_1}, {}, {.OFFSET, 0, .BYTE_2}),
	0x11 = opcode_entry(2, .ACALL, {}, {}, {.ADDR_11, opcode_constant(0x11), .ADDR_11}),
	0x12 = opcode_entry(3, .LCALL, {}, {}, {.ADDR_16, 0, .TWO_BYTES}),
	0x13 = opcode_entry(1, .RRC, {.ACC, 0, .NONE}, {}, {}),
	0x14 = opcode_entry(1, .DEC, {.ACC, 0, .NONE}, {}, {}),
	0x15 = opcode_entry(2, .DEC, {.DIRECT_ADDR, 0, .BYTE_1}, {}, {}),
	0x16 = opcode_entry(1, .DEC, {.INDIRECT_REG, 0, .NONE}, {}, {}),
	0x17 = opcode_entry(1, .DEC, {.INDIRECT_REG, 1, .NONE}, {}, {}),
	0x18 = opcode_entry(1, .DEC, {.REG, 0, .NONE}, {}, {}),
	0x19 = opcode_entry(1, .DEC, {.REG, 1, .NONE}, {}, {}),
	0x1A = opcode_entry(1, .DEC, {.REG, 2, .NONE}, {}, {}),
	0x1B = opcode_entry(1, .DEC, {.REG, 3, .NONE}, {}, {}),
	0x1C = opcode_entry(1, .DEC, {.REG, 4, .NONE}, {}, {}),
	0x1D = opcode_entry(1, .DEC, {.REG, 5, .NONE}, {}, {}),
	0x1E = opcode_entry(1, .DEC, {.REG, 6, .NONE}, {}, {}),
	0x1F = opcode_entry(1, .DEC, {.REG, 7, .NONE}, {}, {}),
	0x20 = opcode_entry(3, .JB, {.BIT_ADDR, 0, .BYTE_1}, {}, {.OFFSET, 0, .BYTE_2}),
	0x21 = opcode_entry(2, .AJMP, {}, {}, {.ADDR_11, opcode_constant(0x21), .ADDR_11}),
	0x22 = opcode_entry(1, .RET, {}, {}, {}),
	0x23 = opcode_entry(1, .RL, {.ACC, 0, .NONE}, {}, {}),
	0x24 = opcode_entry(2, .ADD, {.ACC, 0, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x25 = opcode_entry(2, .ADD, {.ACC, 0, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0x26 = opcode_entry(1, .ADD, {.ACC, 0, .NONE}, {.INDIRECT_REG, 0, .NONE}, {}),
	0x27 = opcode_entry(1, .ADD, {.ACC, 0, .NONE}, {.INDIRECT_REG, 1, .NONE}, {}),
	0x28 = opcode_entry(1, .ADD, {.ACC, 0, .NONE}, {.REG, 0, .NONE}, {}),
	0x29 = opcode_entry(1, .ADD, {.ACC, 0, .NONE}, {.REG, 1, .NONE}, {}),
	0x2A = opcode_entry(1, .ADD, {.ACC, 0, .NONE}, {.REG, 2, .NONE}, {}),
	0x2B = opcode_entry(1, .ADD, {.ACC, 0, .NONE}, {.REG, 3, .NONE}, {}),
	0x2C = opcode_entry(1, .ADD, {.ACC, 0, .NONE}, {.REG, 4, .NONE}, {}),
	0x2D = opcode_entry(1, .ADD, {.ACC, 0, .NONE}, {.REG, 5, .NONE}, {}),
	0x2E = opcode_entry(1, .ADD, {.ACC, 0, .NONE}, {.REG, 6, .NONE}, {}),
	0x2F = opcode_entry(1, .ADD, {.ACC, 0, .NONE}, {.REG, 7, .NONE}, {}),
	0x30 = opcode_entry(3, .JNB, {.BIT_ADDR, 0, .BYTE_1}, {}, {.OFFSET, 0, .BYTE_2}),
	0x31 = opcode_entry(2, .ACALL, {}, {}, {.ADDR_11, opcode_constant(0x31), .ADDR_11}),
	0x32 = opcode_entry(1, .RETI, {}, {}, {}),
	0x33 = opcode_entry(1, .RLC, {.ACC, 0, .NONE}, {}, {}),
	0x34 = opcode_entry(2, .ADDC, {.ACC, 0, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x35 = opcode_entry(2, .ADDC, {.ACC, 0, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0x36 = opcode_entry(1, .ADDC, {.ACC, 0, .NONE}, {.INDIRECT_REG, 0, .NONE}, {}),
	0x37 = opcode_entry(1, .ADDC, {.ACC, 0, .NONE}, {.INDIRECT_REG, 1, .NONE}, {}),
	0x38 = opcode_entry(1, .ADDC, {.ACC, 0, .NONE}, {.REG, 0, .NONE}, {}),
	0x39 = opcode_entry(1, .ADDC, {.ACC, 0, .NONE}, {.REG, 1, .NONE}, {}),
	0x3A = opcode_entry(1, .ADDC, {.ACC, 0, .NONE}, {.REG, 2, .NONE}, {}),
	0x3B = opcode_entry(1, .ADDC, {.ACC, 0, .NONE}, {.REG, 3, .NONE}, {}),
	0x3C = opcode_entry(1, .ADDC, {.ACC, 0, .NONE}, {.REG, 4, .NONE}, {}),
	0x3D = opcode_entry(1, .ADDC, {.ACC, 0, .NONE}, {.REG, 5, .NONE}, {}),
	0x3E = opcode_entry(1, .ADDC, {.ACC, 0, .NONE}, {.REG, 6, .NONE}, {}),
	0x3F = opcode_entry(1, .ADDC, {.ACC, 0, .NONE}, {.REG, 7, .NONE}, {}),
	0x40 = opcode_entry(2, .JC, {}, {}, {.OFFSET, 0, .BYTE_1}),
	0x41 = opcode_entry(2, .AJMP, {}, {}, {.ADDR_11, opcode_constant(0x41), .ADDR_11}),
	0x42 = opcode_entry(2, .ORL, {.DIRECT_ADDR, 0, .BYTE_1}, {.ACC, 0, .NONE}, {}),
	0x43 = opcode_entry(3, .ORL, {.DIRECT_ADDR, 0, .BYTE_1}, {.IMM, 0, .BYTE_2}, {}),
	0x44 = opcode_entry(2, .ORL, {.ACC, 0, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x45 = opcode_entry(2, .ORL, {.ACC, 0, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0x46 = opcode_entry(1, .ORL, {.ACC, 0, .NONE}, {.INDIRECT_REG, 0, .NONE}, {}),
	0x47 = opcode_entry(1, .ORL, {.ACC, 0, .NONE}, {.INDIRECT_REG, 1, .NONE}, {}),
	0x48 = opcode_entry(1, .ORL, {.ACC, 0, .NONE}, {.REG, 0, .NONE}, {}),
	0x49 = opcode_entry(1, .ORL, {.ACC, 0, .NONE}, {.REG, 1, .NONE}, {}),
	0x4A = opcode_entry(1, .ORL, {.ACC, 0, .NONE}, {.REG, 2, .NONE}, {}),
	0x4B = opcode_entry(1, .ORL, {.ACC, 0, .NONE}, {.REG, 3, .NONE}, {}),
	0x4C = opcode_entry(1, .ORL, {.ACC, 0, .NONE}, {.REG, 4, .NONE}, {}),
	0x4D = opcode_entry(1, .ORL, {.ACC, 0, .NONE}, {.REG, 5, .NONE}, {}),
	0x4E = opcode_entry(1, .ORL, {.ACC, 0, .NONE}, {.REG, 6, .NONE}, {}),
	0x4F = opcode_entry(1, .ORL, {.ACC, 0, .NONE}, {.REG, 7, .NONE}, {}),
	0x50 = opcode_entry(2, .JNC, {}, {}, {.OFFSET, 0, .BYTE_1}),
	0x51 = opcode_entry(2, .ACALL, {}, {}, {.ADDR_11, opcode_constant(0x51), .ADDR_11}),
	0x52 = opcode_entry(2, .ANL, {.DIRECT_ADDR, 0, .BYTE_1}, {.ACC, 0, .NONE}, {}),
	0x53 = opcode_entry(3, .ANL, {.DIRECT_ADDR, 0, .BYTE_1}, {.IMM, 0, .BYTE_2}, {}),
	0x54 = opcode_entry(2, .ANL, {.ACC, 0, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x55 = opcode_entry(2, .ANL, {.ACC, 0, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0x56 = opcode_entry(1, .ANL, {.ACC, 0, .NONE}, {.INDIRECT_REG, 0, .NONE}, {}),
	0x57 = opcode_entry(1, .ANL, {.ACC, 0, .NONE}, {.INDIRECT_REG, 1, .NONE}, {}),
	0x58 = opcode_entry(1, .ANL, {.ACC, 0, .NONE}, {.REG, 0, .NONE}, {}),
	0x59 = opcode_entry(1, .ANL, {.ACC, 0, .NONE}, {.REG, 1, .NONE}, {}),
	0x5A = opcode_entry(1, .ANL, {.ACC, 0, .NONE}, {.REG, 2, .NONE}, {}),
	0x5B = opcode_entry(1, .ANL, {.ACC, 0, .NONE}, {.REG, 3, .NONE}, {}),
	0x5C = opcode_entry(1, .ANL, {.ACC, 0, .NONE}, {.REG, 4, .NONE}, {}),
	0x5D = opcode_entry(1, .ANL, {.ACC, 0, .NONE}, {.REG, 5, .NONE}, {}),
	0x5E = opcode_entry(1, .ANL, {.ACC, 0, .NONE}, {.REG, 6, .NONE}, {}),
	0x5F = opcode_entry(1, .ANL, {.ACC, 0, .NONE}, {.REG, 7, .NONE}, {}),
	0x60 = opcode_entry(2, .JZ, {}, {}, {.OFFSET, 0, .BYTE_1}),
	0x61 = opcode_entry(2, .AJMP, {}, {}, {.ADDR_11, opcode_constant(0x61), .ADDR_11}),
	0x62 = opcode_entry(2, .XRL, {.DIRECT_ADDR, 0, .BYTE_1}, {.ACC, 0, .NONE}, {}),
	0x63 = opcode_entry(3, .XRL, {.DIRECT_ADDR, 0, .BYTE_1}, {.IMM, 0, .BYTE_2}, {}),
	0x64 = opcode_entry(2, .XRL, {.ACC, 0, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x65 = opcode_entry(2, .XRL, {.ACC, 0, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0x66 = opcode_entry(1, .XRL, {.ACC, 0, .NONE}, {.INDIRECT_REG, 0, .NONE}, {}),
	0x67 = opcode_entry(1, .XRL, {.ACC, 0, .NONE}, {.INDIRECT_REG, 1, .NONE}, {}),
	0x68 = opcode_entry(1, .XRL, {.ACC, 0, .NONE}, {.REG, 0, .NONE}, {}),
	0x69 = opcode_entry(1, .XRL, {.ACC, 0, .NONE}, {.REG, 1, .NONE}, {}),
	0x6A = opcode_entry(1, .XRL, {.ACC, 0, .NONE}, {.REG, 2, .NONE}, {}),
	0x6B = opcode_entry(1, .XRL, {.ACC, 0, .NONE}, {.REG, 3, .NONE}, {}),
	0x6C = opcode_entry(1, .XRL, {.ACC, 0, .NONE}, {.REG, 4, .NONE}, {}),
	0x6D = opcode_entry(1, .XRL, {.ACC, 0, .NONE}, {.REG, 5, .NONE}, {}),
	0x6E = opcode_entry(1, .XRL, {.ACC, 0, .NONE}, {.REG, 6, .NONE}, {}),
	0x6F = opcode_entry(1, .XRL, {.ACC, 0, .NONE}, {.REG, 7, .NONE}, {}),
	0x70 = opcode_entry(2, .JNZ, {}, {}, {.OFFSET, 0, .BYTE_1}),
	0x71 = opcode_entry(2, .ACALL, {}, {}, {.ADDR_11, opcode_constant(0x71), .ADDR_11}),
	0x72 = opcode_entry(2, .ORL, {.CARRY_BIT, 0, .NONE}, {.BIT_ADDR, 0, .BYTE_1}, {}),
	0x73 = opcode_entry(1, .JMP, {}, {}, {.INDIRECT_ACC_PLUS_DPTR, 0, .NONE}),
	0x74 = opcode_entry(2, .MOV, {.ACC, 0, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x75 = opcode_entry(3, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.IMM, 0, .BYTE_2}, {}),
	0x76 = opcode_entry(2, .MOV, {.INDIRECT_REG, 0, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x77 = opcode_entry(2, .MOV, {.INDIRECT_REG, 1, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x78 = opcode_entry(2, .MOV, {.REG, 0, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x79 = opcode_entry(2, .MOV, {.REG, 1, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x7A = opcode_entry(2, .MOV, {.REG, 2, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x7B = opcode_entry(2, .MOV, {.REG, 3, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x7C = opcode_entry(2, .MOV, {.REG, 4, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x7D = opcode_entry(2, .MOV, {.REG, 5, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x7E = opcode_entry(2, .MOV, {.REG, 6, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x7F = opcode_entry(2, .MOV, {.REG, 7, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x80 = opcode_entry(2, .SJMP, {}, {}, {.OFFSET, 0, .BYTE_1}),
	0x81 = opcode_entry(2, .AJMP, {}, {}, {.ADDR_11, opcode_constant(0x81), .ADDR_11}),
	0x82 = opcode_entry(2, .ANL, {.CARRY_BIT, 0, .NONE}, {.BIT_ADDR, 0, .BYTE_1}, {}),
	0x83 = opcode_entry(1, .MOVC, {.ACC, 0, .NONE}, {.INDIRECT_ACC_PLUS_PC, 0, .NONE}, {}),
	0x84 = opcode_entry(1, .DIV, {.AB, 0, .NONE}, {}, {}),
	0x85 = opcode_entry(3, .MOV, {.DIRECT_ADDR, 0, .BYTE_2}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0x86 = opcode_entry(2, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.INDIRECT_REG, 0, .NONE}, {}),
	0x87 = opcode_entry(2, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.INDIRECT_REG, 1, .NONE}, {}),
	0x88 = opcode_entry(2, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.REG, 0, .NONE}, {}),
	0x89 = opcode_entry(2, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.REG, 1, .NONE}, {}),
	0x8A = opcode_entry(2, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.REG, 2, .NONE}, {}),
	0x8B = opcode_entry(2, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.REG, 3, .NONE}, {}),
	0x8C = opcode_entry(2, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.REG, 4, .NONE}, {}),
	0x8D = opcode_entry(2, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.REG, 5, .NONE}, {}),
	0x8E = opcode_entry(2, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.REG, 6, .NONE}, {}),
	0x8F = opcode_entry(2, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.REG, 7, .NONE}, {}),
	0x90 = opcode_entry(3, .MOV, {.DPTR, 0, .NONE}, {.IMM_LONG, 0, .TWO_BYTES}, {}),
	0x91 = opcode_entry(2, .ACALL, {}, {}, {.ADDR_11, opcode_constant(0x91), .ADDR_11}),
	0x92 = opcode_entry(2, .MOV, {.BIT_ADDR, 0, .BYTE_1}, {.CARRY_BIT, 0, .NONE}, {}),
	0x93 = opcode_entry(1, .MOVC, {.ACC, 0, .NONE}, {.INDIRECT_ACC_PLUS_DPTR, 0, .NONE}, {}),
	0x94 = opcode_entry(2, .SUBB, {.ACC, 0, .NONE}, {.IMM, 0, .BYTE_1}, {}),
	0x95 = opcode_entry(2, .SUBB, {.ACC, 0, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0x96 = opcode_entry(1, .SUBB, {.ACC, 0, .NONE}, {.INDIRECT_REG, 0, .NONE}, {}),
	0x97 = opcode_entry(1, .SUBB, {.ACC, 0, .NONE}, {.INDIRECT_REG, 1, .NONE}, {}),
	0x98 = opcode_entry(1, .SUBB, {.ACC, 0, .NONE}, {.REG, 0, .NONE}, {}),
	0x99 = opcode_entry(1, .SUBB, {.ACC, 0, .NONE}, {.REG, 1, .NONE}, {}),
	0x9A = opcode_entry(1, .SUBB, {.ACC, 0, .NONE}, {.REG, 2, .NONE}, {}),
	0x9B = opcode_entry(1, .SUBB, {.ACC, 0, .NONE}, {.REG, 3, .NONE}, {}),
	0x9C = opcode_entry(1, .SUBB, {.ACC, 0, .NONE}, {.REG, 4, .NONE}, {}),
	0x9D = opcode_entry(1, .SUBB, {.ACC, 0, .NONE}, {.REG, 5, .NONE}, {}),
	0x9E = opcode_entry(1, .SUBB, {.ACC, 0, .NONE}, {.REG, 6, .NONE}, {}),
	0x9F = opcode_entry(1, .SUBB, {.ACC, 0, .NONE}, {.REG, 7, .NONE}, {}),
	0xA0 = opcode_entry(2, .ORL, {.CARRY_BIT, 0, .NONE}, {.INV_BIT_ADDR, 0, .BYTE_1}, {}),
	0xA1 = opcode_entry(2, .AJMP, {}, {}, {.ADDR_11, opcode_constant(0xA1), .ADDR_11}),
	0xA2 = opcode_entry(2, .MOV, {.CARRY_BIT, 0, .NONE}, {.BIT_ADDR, 0, .BYTE_1}, {}),
	0xA3 = opcode_entry(1, .INC, {.DPTR, 0, .NONE}, {}, {}),
	0xA4 = opcode_entry(1, .MUL, {.AB, 0, .NONE}, {}, {}),
	0xA5 = opcode_entry(0, .NOP, {}, {}, {}),
	0xA6 = opcode_entry(2, .MOV, {.INDIRECT_REG, 0, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xA7 = opcode_entry(2, .MOV, {.INDIRECT_REG, 1, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xA8 = opcode_entry(2, .MOV, {.REG, 0, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xA9 = opcode_entry(2, .MOV, {.REG, 1, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xAA = opcode_entry(2, .MOV, {.REG, 2, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xAB = opcode_entry(2, .MOV, {.REG, 3, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xAC = opcode_entry(2, .MOV, {.REG, 4, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xAD = opcode_entry(2, .MOV, {.REG, 5, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xAE = opcode_entry(2, .MOV, {.REG, 6, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xAF = opcode_entry(2, .MOV, {.REG, 7, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xB0 = opcode_entry(2, .ANL, {.CARRY_BIT, 0, .NONE}, {.INV_BIT_ADDR, 0, .BYTE_1}, {}),
	0xB1 = opcode_entry(2, .ACALL, {}, {}, {.ADDR_11, opcode_constant(0xB1), .ADDR_11}),
	0xB2 = opcode_entry(2, .CPL, {.BIT_ADDR, 0, .BYTE_1}, {}, {}),
	0xB3 = opcode_entry(1, .CPL, {.CARRY_BIT, 0, .NONE}, {}, {}),
	0xB4 = opcode_entry(3, .CJNE, {.ACC, 0, .NONE}, {.IMM, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xB5 = opcode_entry(3, .CJNE, {.ACC, 0, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xB6 = opcode_entry(3, .CJNE, {.INDIRECT_REG, 0, .NONE}, {.IMM, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xB7 = opcode_entry(3, .CJNE, {.INDIRECT_REG, 1, .NONE}, {.IMM, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xB8 = opcode_entry(3, .CJNE, {.REG, 0, .NONE}, {.IMM, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xB9 = opcode_entry(3, .CJNE, {.REG, 1, .NONE}, {.IMM, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xBA = opcode_entry(3, .CJNE, {.REG, 2, .NONE}, {.IMM, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xBB = opcode_entry(3, .CJNE, {.REG, 3, .NONE}, {.IMM, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xBC = opcode_entry(3, .CJNE, {.REG, 4, .NONE}, {.IMM, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xBD = opcode_entry(3, .CJNE, {.REG, 5, .NONE}, {.IMM, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xBE = opcode_entry(3, .CJNE, {.REG, 6, .NONE}, {.IMM, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xBF = opcode_entry(3, .CJNE, {.REG, 7, .NONE}, {.IMM, 0, .BYTE_1}, {.OFFSET, 0, .BYTE_2}),
	0xC0 = opcode_entry(2, .PUSH, {.DIRECT_ADDR, 0, .BYTE_1}, {}, {}),
	0xC1 = opcode_entry(2, .AJMP, {}, {}, {.ADDR_11, opcode_constant(0xC1), .ADDR_11}),
	0xC2 = opcode_entry(2, .CLR, {.BIT_ADDR, 0, .BYTE_1}, {}, {}),
	0xC3 = opcode_entry(1, .CLR, {.CARRY_BIT, 0, .NONE}, {}, {}),
	0xC4 = opcode_entry(1, .SWAP, {.ACC, 0, .NONE}, {}, {}),
	0xC5 = opcode_entry(2, .XCH, {.ACC, 0, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xC6 = opcode_entry(1, .XCH, {.ACC, 0, .NONE}, {.INDIRECT_REG, 0, .NONE}, {}),
	0xC7 = opcode_entry(1, .XCH, {.ACC, 0, .NONE}, {.INDIRECT_REG, 1, .NONE}, {}),
	0xC8 = opcode_entry(1, .XCH, {.ACC, 0, .NONE}, {.REG, 0, .NONE}, {}),
	0xC9 = opcode_entry(1, .XCH, {.ACC, 0, .NONE}, {.REG, 1, .NONE}, {}),
	0xCA = opcode_entry(1, .XCH, {.ACC, 0, .NONE}, {.REG, 2, .NONE}, {}),
	0xCB = opcode_entry(1, .XCH, {.ACC, 0, .NONE}, {.REG, 3, .NONE}, {}),
	0xCC = opcode_entry(1, .XCH, {.ACC, 0, .NONE}, {.REG, 4, .NONE}, {}),
	0xCD = opcode_entry(1, .XCH, {.ACC, 0, .NONE}, {.REG, 5, .NONE}, {}),
	0xCE = opcode_entry(1, .XCH, {.ACC, 0, .NONE}, {.REG, 6, .NONE}, {}),
	0xCF = opcode_entry(1, .XCH, {.ACC, 0, .NONE}, {.REG, 7, .NONE}, {}),
	0xD0 = opcode_entry(2, .POP, {.DIRECT_ADDR, 0, .BYTE_1}, {}, {}),
	0xD1 = opcode_entry(2, .ACALL, {}, {}, {.ADDR_11, opcode_constant(0xD1), .ADDR_11}),
	0xD2 = opcode_entry(2, .SETB, {.BIT_ADDR, 0, .BYTE_1}, {}, {}),
	0xD3 = opcode_entry(1, .SETB, {.CARRY_BIT, 0, .NONE}, {}, {}),
	0xD4 = opcode_entry(1, .DA, {.ACC, 0, .NONE}, {}, {}),
	0xD5 = opcode_entry(3, .DJNZ, {.DIRECT_ADDR, 0, .BYTE_1}, {}, {.OFFSET, 0, .BYTE_2}),
	0xD6 = opcode_entry(1, .XCHD, {.ACC, 0, .NONE}, {.INDIRECT_REG, 0, .NONE}, {}),
	0xD7 = opcode_entry(1, .XCHD, {.ACC, 0, .NONE}, {.INDIRECT_REG, 1, .NONE}, {}),
	0xD8 = opcode_entry(2, .DJNZ, {.REG, 0, .NONE}, {}, {.OFFSET, 0, .BYTE_1}),
	0xD9 = opcode_entry(2, .DJNZ, {.REG, 1, .NONE}, {}, {.OFFSET, 0, .BYTE_1}),
	0xDA = opcode_entry(2, .DJNZ, {.REG, 2, .NONE}, {}, {.OFFSET, 0, .BYTE_1}),
	0xDB = opcode_entry(2, .DJNZ, {.REG, 3, .NONE}, {}, {.OFFSET, 0, .BYTE_1}),
	0xDC = opcode_entry(2, .DJNZ, {.REG, 4, .NONE}, {}, {.OFFSET, 0, .BYTE_1}),
	0xDD = opcode_entry(2, .DJNZ, {.REG, 5, .NONE}, {}, {.OFFSET, 0, .BYTE_1}),
	0xDE = opcode_entry(2, .DJNZ, {.REG, 6, .NONE}, {}, {.OFFSET, 0, .BYTE_1}),
	0xDF = opcode_entry(2, .DJNZ, {.REG, 7, .NONE}, {}, {.OFFSET, 0, .BYTE_1}),
	0xE0 = opcode_entry(1, .MOVX, {.ACC, 0, .NONE}, {.INDIRECT_DPTR, 0, .NONE}, {}),
	0xE1 = opcode_entry(2, .AJMP, {}, {}, {.ADDR_11, opcode_constant(0xE1), .ADDR_11}),
	0xE2 = opcode_entry(1, .MOVX, {.ACC, 0, .NONE}, {.INDIRECT_REG, 0, .NONE}, {}),
	0xE3 = opcode_entry(1, .MOVX, {.ACC, 0, .NONE}, {.INDIRECT_REG, 1, .NONE}, {}),
	0xE4 = opcode_entry(1, .CLR, {.ACC, 0, .NONE}, {}, {}),
	0xE5 = opcode_entry(2, .MOV, {.ACC, 0, .NONE}, {.DIRECT_ADDR, 0, .BYTE_1}, {}),
	0xE6 = opcode_entry(1, .MOV, {.ACC, 0, .NONE}, {.INDIRECT_REG, 0, .NONE}, {}),
	0xE7 = opcode_entry(1, .MOV, {.ACC, 0, .NONE}, {.INDIRECT_REG, 1, .NONE}, {}),
	0xE8 = opcode_entry(1, .MOV, {.ACC, 0, .NONE}, {.REG, 0, .NONE}, {}),
	0xE9 = opcode_entry(1, .MOV, {.ACC, 0, .NONE}, {.REG, 1, .NONE}, {}),
	0xEA = opcode_entry(1, .MOV, {.ACC, 0, .NONE}, {.REG, 2, .NONE}, {}),
	0xEB = opcode_entry(1, .MOV, {.ACC, 0, .NONE}, {.REG, 3, .NONE}, {}),
	0xEC = opcode_entry(1, .MOV, {.ACC, 0, .NONE}, {.REG, 4, .NONE}, {}),
	0xED = opcode_entry(1, .MOV, {.ACC, 0, .NONE}, {.REG, 5, .NONE}, {}),
	0xEE = opcode_entry(1, .MOV, {.ACC, 0, .NONE}, {.REG, 6, .NONE}, {}),
	0xEF = opcode_entry(1, .MOV, {.ACC, 0, .NONE}, {.REG, 7, .NONE}, {}),
	0xF0 = opcode_entry(1, .MOVX, {.INDIRECT_DPTR, 0, .NONE}, {.ACC, 0, .NONE}, {}),
	0xF1 = opcode_entry(2, .ACALL, {}, {}, {.ADDR_11, opcode_constant(0xF1), .ADDR_11}),
	0xF2 = opcode_entry(1, .MOVX, {.INDIRECT_REG, 0, .NONE}, {.ACC, 0, .NONE}, {}),
	0xF3 = opcode_entry(1, .MOVX, {.INDIRECT_REG, 1, .NONE}, {.ACC, 0, .NONE}, {}),
	0xF4 = opcode_entry(1, .CPL, {.ACC, 0, .NONE}, {}, {}),
	0xF5 = opcode_entry(2, .MOV, {.DIRECT_ADDR, 0, .BYTE_1}, {.ACC, 0, .NONE}, {}),
	0xF6 = opcode_entry(1, .MOV, {.INDIRECT_REG, 0, .NONE}, {.ACC, 0, .NONE}, {}),
	0xF7 = opcode_entry(1, .MOV, {.INDIRECT_REG, 1, .NONE}, {.ACC, 0, .NONE}, {}),
	0xF8 = opcode_entry(1, .MOV, {.REG, 0, .NONE}, {.ACC, 0, .NONE}, {}),
	0xF9 = opcode_entry(1, .MOV, {.REG, 1, .NONE}, {.ACC, 0, .NONE}, {}),
	0xFA = opcode_entry(1, .MOV, {.REG, 2, .NONE}, {.ACC, 0, .NONE}, {}),
	0xFB = opcode_entry(1, .MOV, {.REG, 3, .NONE}, {.ACC, 0, .NONE}, {}),
	0xFC = opcode_entry(1, .MOV, {.REG, 4, .NONE}, {.ACC, 0, .NONE}, {}),
	0xFD = opcode_entry(1, .MOV, {.REG, 5, .NONE}, {.ACC, 0, .NONE}, {}),
	0xFE = opcode_entry(1, .MOV, {.REG, 6, .NONE}, {.ACC, 0, .NONE}, {}),
	0xFF = opcode_entry(1, .MOV, {.REG, 7, .NONE}, {.ACC, 0, .NONE}, {}),
}
