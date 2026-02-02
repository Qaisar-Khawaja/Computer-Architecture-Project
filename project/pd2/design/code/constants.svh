/*
 * Good practice to define constants and refer to them in the
 * design files. An example of some constants are provided to you
 * as a starting point
 *
 */
`ifndef CONSTANTS_SVH_
`define CONSTANTS_SVH_

parameter logic [31:0] ZERO = 32'd0;

/*
 * Define constants as required...
 */
`define Opcode_RType 7'b0110011
`define Opcode_IType 7'b0010011
`define Opcode_IType_Load 7'b0000011
`define Opcode_SType 7'b0100011
`define Opcode_BType 7'b1100011
`define Opcode_JType_Jump_And_Link 7'b1101111
`define Opcode_IType_Jump_And_LinkReg 7'b1100111
`define Opcode_UType_Load_Upper_Imm 7'b0110111
`define Opcode_UType_Add_Upper_Imm 7'b0010111
`define Opcode_IType_ecall_ebreak 7'b1110011
`endif
