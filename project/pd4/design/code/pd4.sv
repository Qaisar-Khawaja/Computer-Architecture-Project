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

module pd4 #(
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
    logic [AWIDTH-1:0] assign_d_pc;
    logic [6:0]        assign_d_opcode;
    logic [4:0]        assign_d_rd, assign_d_rs1, assign_d_rs2, d_shamt;
    logic [6:0]        assign_d_funct7;
    logic [2:0]        assign_d_funct3;
    logic [DWIDTH-1:0] assign_d_imm, assign_i_imm;
    logic [DWIDTH-1:0] assign_d_insn;
    logic pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
    logic [1:0] wbsel;
    logic [3:0] alusel;
    logic [DWIDTH-1:0] assign_wb_data;
logic [31:0] data_out;
    logic assign_r_write_enable;
    logic [4:0] assign_r_write_destination;
    logic [DWIDTH-1:0] assign_r_write_data;
    logic [4:0] assign_r_read_rs1;
    logic [4:0] assign_r_read_rs2;
    logic [DWIDTH-1:0] assign_r_read_rs1_data;
    logic [DWIDTH-1:0] assign_r_read_rs2_data;

    logic assign_e_br_taken, breq, brlt, is_branch_taken;
    logic [AWIDTH-1:0] assign_e_pc;
    logic [DWIDTH-1:0] assign_e_alu_res;
    logic [DWIDTH-1:0] alu_operand_a, alu_operand_b;

    logic [AWIDTH-1:0] assign_m_pc, assign_wb_next_pc, assign_f_pc;
    logic [AWIDTH-1:0] assign_m_address;
    logic [DWIDTH-1:0] assign_m_size_encoded;
    logic [DWIDTH-1:0] assign_m_data;
// program termination logic
reg is_program = 0;
always_ff @(posedge clk) begin
    if (data_out == 32'h00000073) $finish;  // directly terminate if see ecall
    if (data_out == 32'h00008067) is_program = 1;  // if see ret instruction, it is simple program test
    // [TODO] Change register_file_0.registers[2] to the appropriate x2 register based on your module instantiations...
    if (is_program && (reg_file_inst.regs[2] == 32'h01000000 + `MEM_DEPTH)) $finish;
end

    // -------------------------
    // Fetch & Instruction Memory
    // -------------------------

assign assign_m_pc = (pcsel) ? assign_wb_next_pc : assign_f_pc;
logic [DWIDTH-1 : 0] assign_f_insn;
    logic [DWIDTH-1:0] assign_m_read_data;

fetch #(AWIDTH, DWIDTH) fetch_inst (
        .clk       (clk),
        .rst       (reset),
        .pc_o      (assign_f_pc),
        .insn_o    ()    
    );

// -------------------------
    //  Memory
    // -------------------------
// -------------------------
    //  Memory
    // -------------------------


// -------------------------
    // Data Memory (Actual)
    // -------------------------

// -------------------------
    // Instruction Memory
    // -------------------------
// -------------------------
    // Unified Memory (Instruction & Data)
    // -------------------------
memory #(AWIDTH, DWIDTH) main_mem (
    .clk           (clk),
    .rst           (reset),
    
    // --- Port A: Data Memory (L/S) ---
    .addr_i        (assign_e_alu_res),       // FIX: Use ALU result for data address
    .data_i        (assign_r_read_rs2_data), // Store data from rs2
    .read_en_i     (memren),
    .write_en_i    (memwren),
    .size_i        (assign_d_funct3[1:0]),   // funct3 determines byte/hw/word [cite: 21, 23]
    .sign_en_i     (!assign_d_funct3[2]),    // LBU/LHU vs LB/LH [cite: 17, 19]
    .data_o        (assign_m_read_data),

    // --- Port B: Instruction Fetch ---
    .insn_addr_i   (assign_f_pc),            // Use PC for fetching instructions 
    .insn_o        (assign_f_insn)           // Feeds to Decode stage
);


assign assign_m_address      = assign_e_alu_res;
    assign assign_m_data         = assign_r_read_rs2_data;
    assign assign_m_size_encoded = {29'b0, assign_d_funct3}; // Assuming size is tracked by funct3
    //assign assign_d_imm = assign_i_imm;

    // -------------------------
    // Immediate Generator
    // -------------------------

    igen #(DWIDTH) igen_inst (
        .opcode_i (assign_d_opcode),
        .insn_i   (assign_d_insn),
        .imm_o    (assign_i_imm)
    );

    // -------------------------
    // Decode
    // -------------------------
    decode #(DWIDTH, AWIDTH) decode_inst (
        .clk      (clk),
        .rst      (reset),
        .insn_i   (assign_f_insn),
        .pc_i     (assign_f_pc),
        .pc_o     (assign_d_pc),
        .insn_o   (assign_d_insn),
        .opcode_o (assign_d_opcode),
        .rd_o     (assign_d_rd),
        .rs1_o    (assign_d_rs1),
        .rs2_o    (assign_d_rs2),
        .funct7_o (assign_d_funct7),
        .funct3_o (assign_d_funct3),
        .shamt_o  (d_shamt),
        .imm_o    (assign_d_imm)
    );

    assign assign_d_imm = assign_i_imm;

    // -------------------------
    // Control
    // -------------------------

    control #(DWIDTH) control_inst (
        .insn_i    (assign_d_insn),
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

    // -------------------------
    // Register File
    // -------------------------

    register_file #(DWIDTH) reg_file_inst (
        .clk       (clk),
        .rst       (reset),
        .rs1_i     (assign_r_read_rs1),
        .rs2_i     (assign_r_read_rs2),
        .rd_i      (assign_r_write_destination),
        .datawb_i  (assign_r_write_data),
        .regwren_i (assign_r_write_enable),
        .rs1data_o (assign_r_read_rs1_data),
        .rs2data_o (assign_r_read_rs2_data)
    );

    assign assign_r_read_rs1          = assign_d_rs1;
    assign assign_r_read_rs2          = assign_d_rs2;
    assign assign_r_write_enable      = regwren;
    assign assign_r_write_destination = assign_d_rd;
    assign assign_r_write_data        = assign_wb_data; //wriet back

    // -------------------------
    // Branching
    // -------------------------

    branch_control #(DWIDTH) branch_ctrl_inst (
        .opcode_i (assign_d_opcode),
        .funct3_i (assign_d_funct3),
        .rs1_i    (assign_r_read_rs1_data),
        .rs2_i    (assign_r_read_rs2_data),
        .breq_o   (breq),
        .brlt_o   (brlt)
    );

    assign assign_e_pc = assign_d_pc;

    // logic to evaluate whether branch was taken or not
    always_comb begin
        is_branch_taken = 1'b0;
        // evaluating opcode and funct3 together
        case ({assign_d_opcode, assign_d_funct3})
            {7'b110_0011, 3'b000}: is_branch_taken = breq;   // BEQ
            {7'b110_0011, 3'b001}: is_branch_taken = ~breq;  // BNE
            {7'b110_0011, 3'b100},                           // BLT
            {7'b110_0011, 3'b110}: is_branch_taken = brlt;   // BLTU
            {7'b110_0011, 3'b101},                           // BGE
            {7'b110_0011, 3'b111}: is_branch_taken = ~brlt;  // BGEU
            default:               is_branch_taken = 1'b0;
        endcase
    end

    assign assign_e_br_taken = is_branch_taken;

    // -------------------------
    // Execution
    // -------------------------

    alu #(DWIDTH, AWIDTH) alu_inst (
        .pc_i      (assign_e_pc),
        .rs1_i     (alu_operand_a),
        .rs2_i     (alu_operand_b),
        .alusel_i  (alusel),
        .funct3_i  (assign_d_funct3),
        .funct7_i  (assign_d_funct7),
        .res_o     (assign_e_alu_res),
        .brtaken_o ()
    );

    // ALU rs1 and rs2 input muxes
    assign alu_operand_a = (rs1sel) ? assign_e_pc  : assign_r_read_rs1_data;
    assign alu_operand_b = (immsel) ? assign_i_imm : assign_r_read_rs2_data;

// -------------------------
    // Writeback Stage
    // -------------------------
// Instantiate the writeback module
    writeback #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH)
    ) wb_inst (
        .pc_i             (assign_e_pc),
        .alu_res_i        (assign_e_alu_res),
        .memory_data_i    (assign_m_read_data),
        .wbsel_i          (wbsel),
        .brtaken_i        (assign_e_br_taken),
        .writeback_data_o (assign_wb_data),
        .next_pc_o        (assign_wb_next_pc) 
    );

    // Map the probes to the writeback signals
    assign assign_w_pc          = assign_e_pc;
    assign assign_w_enable      = regwren;
    assign assign_w_destination = assign_d_rd;
    assign assign_w_data        = assign_wb_data;
endmodule : pd4
