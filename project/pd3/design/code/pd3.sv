/*
 * Module: pd3
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd3 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32)(
    input logic clk,
    input logic reset
);

 /*
  * Instantiate other submodules and
  * probes. To be filled by student...
  *
  */
  // PC + instruction
    logic [AWIDTH-1:0] pc;
    logic [DWIDTH-1:0] insn;

    // Decode outputs
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [6:0] funct7;
    logic [2:0] funct3;
    logic [DWIDTH-1:0] imm;

    // Register file outputs
    logic [DWIDTH-1:0] rs1_data, rs2_data;

    // ALU outputs
    logic [DWIDTH-1:0] alu_result;
    logic br_taken;
    logic [DWIDTH-1:0] mem_data;

    // Control signals
    logic regwren;
    logic memren, memwren;
    logic [1:0] wbsel;
    logic pcsel;
    logic [3:0] alusel;

fetch assign_fetch (
    .clk(clk),
    .rst(reset),
    .pc_o(pc)
);


decode assign_decode (
    .clk(clk),
    .rst(reset),
    .insn_i(mem_data),
    .pc_i(pc),

    .pc_o(),
    .insn_o(),
    .opcode_o(opcode),
    .rd_o(rd),
    .rs1_o(rs1),
    .rs2_o(rs2),
    .funct7_o(funct7),
    .funct3_o(funct3),
    .shamt_o(),
    .imm_o(imm)
);

control assign_control (
    .insn_i(mem_data),
    .opcode_i(opcode),
    .funct7_i(funct7),
    .funct3_i(funct3),

    .pcsel_o(pcsel),
    .immsel_o(),
    .regwren_o(regwren),
    .rs1sel_o(),
    .rs2sel_o(),
    .memren_o(memren),
    .memwren_o(memwren),
    .wbsel_o(wbsel),
    .alusel_o(alusel)
);


register_file assign_regfile (
    .clk(clk),
    .rst(reset),
    .rs1_i(rs1),
    .rs2_i(rs2),
    .rd_i(rd),
    .datawb_i(alu_result),   // simplified for now
    .regwren_i(regwren),

    .rs1data_o(rs1_data),
    .rs2data_o(rs2_data)
);


alu assign_alu (
    .pc_i(pc),
    .rs1_i(rs1_data),
    .rs2_i(rs2_data),
    .funct3_i(funct3),
    .funct7_i(funct7),

    .res_o(alu_result),
    .brtaken_o(br_taken)
);

memory assign_memory (
    .clk(clk),
    .rst(reset),
    .addr_i(pc),          // instruction fetch address
    .data_i(rs2_data),
    .read_en_i(1'b1),     // always reading instruction
    .write_en_i(memwren),
    .data_o(mem_data)
);






endmodule : pd3
