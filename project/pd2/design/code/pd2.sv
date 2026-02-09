/*
 * Module: pd2
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd2 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32
)(
    input logic clk,
    input logic reset
);

    // Fetch and Signals
    logic [AWIDTH-1:0] assign_pc;
    logic [DWIDTH-1:0] assign_insn;

    fetch #(AWIDTH, DWIDTH) fetch_inst (
        .clk(clk),
        .rst(reset),
        .pc_o(assign_pc),
        .insn_o(assign_insn)
    );

    memory #(AWIDTH, DWIDTH) imem (
        .clk(clk),
        .rst(reset),
        .addr_i(assign_pc),
        .data_i(32'b0),
        .read_en_i(1'b1),
        .write_en_i(1'b0),
        .data_o(assign_insn)
    );

    // Decode Signals
    logic [AWIDTH-1:0] assign_d_pc;
    logic [6:0]        assign_d_opcode;
    logic [4:0]        assign_d_rd, assign_d_rs1, assign_d_rs2, d_shamt;
    logic [6:0]        assign_d_funct7;
    logic [2:0]        assign_d_funct3;
    logic [DWIDTH-1:0] assign_d_imm;
    logic [DWIDTH-1:0] d_insn;

    decode #(DWIDTH, AWIDTH) decode_inst (
        .clk(clk),
        .rst(reset),
        .insn_i(assign_insn),
        .pc_i(assign_pc),
        .pc_o(assign_d_pc),
        .insn_o(d_insn),
        .opcode_o(assign_d_opcode),
        .rd_o(assign_d_rd),
        .rs1_o(assign_d_rs1),
        .rs2_o(assign_d_rs2),
        .funct7_o(assign_d_funct7),
        .funct3_o(assign_d_funct3),
        .shamt_o(d_shamt),
        .imm_o(assign_d_imm)
    );

    // Control Signals
    logic pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
    logic [1:0] wbsel;
    logic [3:0] alusel;

    control #(DWIDTH) control_inst (
        .insn_i(d_insn),
        .opcode_i(assign_d_opcode),
        .funct7_i(assign_d_funct7),
        .funct3_i(assign_d_funct3),
        .pcsel_o(pcsel),
        .immsel_o(immsel),
        .regwren_o(regwren),
        .rs1sel_o(rs1sel),
        .rs2sel_o(rs2sel),
        .memren_o(memren),
        .memwren_o(memwren),
        .wbsel_o(wbsel),
        .alusel_o(alusel)
    );

    // Immediate Generator
    igen #(DWIDTH) igen_inst (
        .opcode_i(assign_d_opcode),
        .insn_i(d_insn),
        .imm_o(assign_d_imm)
    );


endmodule : pd2
