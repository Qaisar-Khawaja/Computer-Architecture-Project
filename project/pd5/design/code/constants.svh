`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_

// -----------------------------
// Opcode encodings
// -----------------------------
`define Opcode_RType                        7'b0110011
`define Opcode_IType                        7'b0010011
`define Opcode_IType_Load                   7'b0000011
`define Opcode_SType                        7'b0100011
`define Opcode_BType                        7'b1100011
`define Opcode_JType_Jump_And_Link          7'b1101111
`define Opcode_IType_Jump_And_LinkReg       7'b1100111
`define Opcode_UType_Load_Upper_Imm         7'b0110111
`define Opcode_UType_Add_Upper_Imm          7'b0010111

// -----------------------------
// PC / operand selection
// -----------------------------
`define PC_NEXTLINE 1'b0
`define PC_JUMP     1'b1

`define OP1_RS1     1'b0
`define OP1_PC      1'b1

`define OP2_RS2     1'b0
`define OP2_IMM     1'b1

// -----------------------------
// Writeback selection
// -----------------------------
`define WB_ALU      2'b00
`define WB_MEM      2'b01
`define WB_PC4      2'b10

// -----------------------------
// ALU selection
// -----------------------------
`define ADD         4'b0000
`define SUB         4'b0001
`define AND         4'b0010
`define OR          4'b0011
`define XOR         4'b0100
`define SLL         4'b0101
`define SRL         4'b0110
`define SRA         4'b0111
`define SLT         4'b1000
`define SLTU        4'b1001
`define LUI         4'b1010

// Canonical RV32I NOP = addi x0, x0, 0
`define NOP         32'h00000013

`endif
