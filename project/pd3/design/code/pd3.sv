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
    parameter int DWIDTH = 32
)(
    input  logic clk,
    input  logic reset
);

    // -------------------------
    // Fetch & Instruction Memory
    // -------------------------

    logic [AWIDTH-1:0] assign_f_pc;
    logic [DWIDTH-1:0] assign_f_insn;

    fetch #(AWIDTH, DWIDTH) fetch_inst (
        .clk    (clk),
        .rst    (reset),
        .pc_o   (assign_f_pc),
        .insn_o (assign_f_insn)
    );

    memory #(AWIDTH, DWIDTH) imem (
        .clk        (clk),
        .rst        (reset),
        .addr_i     (assign_f_pc),
        .data_i     (32'b0),
        .read_en_i  (1'b1),
        .write_en_i (1'b0),
        .data_o     (assign_f_insn)
    );

    // -------------------------
    // Decode
    // -------------------------

    logic [AWIDTH-1:0] assign_d_pc;
    logic [6:0]        assign_d_opcode;
    logic [4:0]        assign_d_rd, assign_d_rs1, assign_d_rs2, d_shamt;
    logic [6:0]        assign_d_funct7;
    logic [2:0]        assign_d_funct3;
    logic [DWIDTH-1:0] assign_d_imm, assign_i_imm;
    logic [DWIDTH-1:0] assign_d_insn;

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
    // Immediate Generator
    // -------------------------

    igen #(DWIDTH) igen_inst (
        .opcode_i (assign_d_opcode),
        .insn_i   (assign_d_insn),
        .imm_o    (assign_i_imm)
    );

    // -------------------------
    // Control
    // -------------------------
    logic pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
    logic [1:0] wbsel;
    logic [3:0] alusel;

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
    logic assign_r_write_enable;
    logic [4:0] assign_r_write_destination;
    logic [DWIDTH-1:0] assign_r_write_data;
    logic [4:0] assign_r_read_rs1;
    logic [4:0] assign_r_read_rs2;
    logic [DWIDTH-1:0] assign_r_read_rs1_data;
    logic [DWIDTH-1:0] assign_r_read_rs2_data;

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
    assign assign_r_write_data        = 1'b0;

    // -------------------------
    // Branching
    // -------------------------

    logic assign_e_br_taken, breq, brlt, is_branch_taken;
    logic [AWIDTH-1:0] assign_e_pc;
    logic [DWIDTH-1:0] assign_e_alu_res;
    logic [DWIDTH-1:0] alu_operand_a, alu_operand_b;

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
        .brtaken_o (assign_e_br_taken)
    );

    // ALU rs1 and rs2 input muxes
    assign alu_operand_a = (rs1sel) ? assign_e_pc  : assign_r_read_rs1_data;
    assign alu_operand_b = (immsel) ? assign_i_imm : assign_r_read_rs2_data;

endmodule : pd3