/*
 * Module: pd2
 *
 * Description: Top level module that will contain sub-module instantiations.
 * Fixed to resolve multi-driven net errors on instruction signals.
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

    // Signals to connect between dmemory and fetch
    logic [AWIDTH-1:0] FETCH_PC_O;
    logic [DWIDTH-1:0] FETCH_INSN_O;
    logic [AWIDTH-1:0] MEM_ADDR_I;
    logic [DWIDTH-1:0] MEM_DATA_O;

    // Decode signals
    logic [AWIDTH-1:0]  assign_d_pc, assign_f_pc;
    logic [DWIDTH-1:0]  assign_d_insn_o, assign_f_insn;
    logic [6:0]         assign_d_opcode;
    logic [4:0]         assign_d_rd, assign_d_rs1, assign_d_rs2, assign_d_shamt;
    logic [6:0]         assign_d_funct7;
    logic [2:0]         assign_d_funct3;
    logic [DWIDTH-1:0]  assign_d_imm;
    logic [DWIDTH-1:0]  assign_i_imm;

    // Control signals
    logic pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
    logic [1:0] wbsel;
    logic [3:0] alusel;

    /////////////////////////////////
    //   INSTANTIATING MODULES     //
    /////////////////////////////////

    // Connections needed for connection between fetch and memory
    // Also assigning probes to their respective wires
    assign FETCH_INSN_O = MEM_DATA_O;
    assign MEM_ADDR_I   = FETCH_PC_O;
    assign assign_f_pc = FETCH_PC_O;
    assign assign_f_insn = FETCH_INSN_O;

    // 1. FETCH MODULE
    fetch #(AWIDTH, DWIDTH) fetch_inst (
        .clk    (clk),
        .rst    (reset),
        .pc_o   (FETCH_PC_O),
        .insn_o (FETCH_INSN_O)
    );

    // 2. INSTRUCTION MEMORY
    memory #(AWIDTH, DWIDTH) imem (
        .clk        (clk),
        .rst        (reset),
        .addr_i     (MEM_ADDR_I),
        .data_i     ('0),
        .read_en_i  (1'b1),
        .write_en_i (1'b0),
        .data_o     (MEM_DATA_O)
    );

    // 3. DECODE MODULE
    decode #(DWIDTH, AWIDTH) decode_inst (
        .clk      (clk),
        .rst      (reset),
        .insn_i   (FETCH_INSN_O),
        .pc_i     (FETCH_PC_O),
        .pc_o     (assign_d_pc),
        .insn_o   (assign_d_insn_o),
        .opcode_o (assign_d_opcode),
        .rd_o     (assign_d_rd),
        .rs1_o    (assign_d_rs1),
        .rs2_o    (assign_d_rs2),
        .funct7_o (assign_d_funct7),
        .funct3_o (assign_d_funct3),
        .shamt_o  (assign_d_shamt),
        .imm_o    (assign_d_imm)
    );

    // 4. CONTROL MODULE
    control #(DWIDTH) control_inst (
        .insn_i    (assign_d_insn_o),
        .opcode_i  (assign_d_opcode),
        .funct7_i  (assign_d_funct7),
        .funct3_i  (assign_d_funct3),
        .pcsel_o   (pcsel),
        .immsel_o  (immsel),
        .regwren_o (regwren),
        .rs1sel_o  (rs1sel),
        .rs2sel_o  (rs2sel),
        .memren_o  (memren),
        .memwren_o (memwren),
        .wbsel_o   (wbsel),
        .alusel_o  (alusel)
    );

    // 5. IMMEDIATE GENERATOR
    igen #(DWIDTH) igen_inst (
        .opcode_i (assign_d_opcode),
        .insn_i   (assign_d_insn_o),
        .imm_o    (assign_i_imm)
    );

endmodule : pd2


