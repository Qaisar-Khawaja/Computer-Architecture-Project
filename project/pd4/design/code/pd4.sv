/*
 * Module: pd4
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */
/*
 * Module: pd4
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */
`include "constants.svh"
`define MEM_DEPTH 1024  // or whatever your memory depth is
module pd4 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32
)(
    input logic clk,
    input logic reset
);

    // -----------------------------
    // Wires between pipeline stages
    // -----------------------------
    logic [AWIDTH-1:0] pc_fetch;
    logic [DWIDTH-1:0] instr_fetch;

    // Decode outputs
    logic [6:0] opcode;
    logic [4:0] rd, rs1, rs2;
    logic [6:0] funct7;
    logic [2:0] funct3;
    logic [DWIDTH-1:0] imm;

    // Register file
    logic [DWIDTH-1:0] rs1_data, rs2_data;

    // ALU
    logic [DWIDTH-1:0] alu_result;
    logic br_taken;

    // Control signals
    logic pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
    logic [1:0] wbsel;
    logic [3:0] alusel;

    // Memory and writeback
    logic [DWIDTH-1:0] mem_data;
    logic [DWIDTH-1:0] wb_data;
    logic [AWIDTH-1:0] target_addr;

    // -----------------------------
    // Instruction Fetch
    // -----------------------------
    fetch fetch_0 (
        .clk(clk),
        .rst(reset),
        .br_taken_i(br_taken),
        .target_addr_i(target_addr),
        .instr_from_mem_i(mem_data), // memory instruction port
        .pc_o(pc_fetch),
        .insn_o(instr_fetch)
    );

    // -----------------------------
    // Decode
    // -----------------------------
    decode decode_0 (
        .clk(clk),
        .rst(reset),
        .insn_i(instr_fetch),
        .pc_i(pc_fetch),
        .pc_o(), // not needed
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

    // -----------------------------
    // Control
    // -----------------------------
    control control_0 (
        .insn_i(instr_fetch),
        .opcode_i(opcode),
        .funct7_i(funct7),
        .funct3_i(funct3),
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

    // -----------------------------
    // Register File
    // -----------------------------
    register_file rf_0 (
        .clk(clk),
        .rst(reset),
        .rs1_i(rs1),
        .rs2_i(rs2),
        .rd_i(rd),
        .datawb_i(wb_data),
        .regwren_i(regwren),
        .rs1data_o(rs1_data),
        .rs2data_o(rs2_data)
    );

    // -----------------------------
    // ALU
    // -----------------------------
    alu alu_0 (
        .pc_i(pc_fetch),
        .rs1_i(rs1_data),
        .rs2_i(immsel ? imm : rs2_data),
        .funct3_i(funct3),
        .funct7_i(funct7),
        .alusel_i(alusel),
        .res_o(alu_result),
        .brtaken_o(br_taken)
    );

    // -----------------------------
    // Memory (single dual-purpose memory)
    // -----------------------------
    memory mem_0 (
        .clk(clk),
        .rst(reset),
        // Instruction port
        .instr_addr_i(pc_fetch),
        .instr_data_o(mem_data),
        // Data port
        .data_addr_i(alu_result),
        .data_i(rs2_data),
        .read_en_i(memren),
        .write_en_i(memwren),
        .funct3_i(funct3),
        .data_o(mem_data)
    );

    // -----------------------------
    // Writeback
    // -----------------------------
    writeback wb_0 (
        .pc_i(pc_fetch),
        .alu_res_i(alu_result),
        .memory_data_i(mem_data),
        .wbsel_i(wbsel),
        .brtaken_i(br_taken),
        .writeback_data_o(wb_data),
        .next_pc_o(target_addr)
    );

    // -----------------------------
    //Program termination logic
    //-----------------------------
    always_ff @(posedge clk) begin
        if (wb_data == 32'h00000073) $finish;  // ecall
        if (wb_data == 32'h00008067) is_program <= 1;  // ret instruction
        if (is_program && (rf_0.regs[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
end

endmodule : pd4