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
    parameter int DWIDTH = 32
)(
    input  logic clk,
    input  logic reset
);

    // =========================================================
    // Fetch stage probes
    // =========================================================
    logic [AWIDTH-1:0] assign_f_pc;
    logic [DWIDTH-1:0] assign_f_insn;

    // =========================================================
    // Decode stage probes
    // =========================================================
    logic [AWIDTH-1:0] assign_d_pc;
    logic [DWIDTH-1:0] assign_d_insn;
    logic [6:0]        assign_d_opcode;
    logic [4:0]        assign_d_rd, assign_d_rs1, assign_d_rs2, assign_d_shamt;
    logic [6:0]        assign_d_funct7;
    logic [2:0]        assign_d_funct3;
    logic [DWIDTH-1:0] assign_d_imm;

    // Immediate generator output
    logic [DWIDTH-1:0] igen_imm;

    // =========================================================
    // Register file probes / signals
    // =========================================================
    logic              assign_r_write_enable;
    logic [4:0]        assign_r_write_destination;
    logic [DWIDTH-1:0] assign_r_write_data;

    logic [4:0]        assign_r_read_rs1;
    logic [4:0]        assign_r_read_rs2;
    logic [DWIDTH-1:0] assign_r_read_rs1_data;
    logic [DWIDTH-1:0] assign_r_read_rs2_data;

    // =========================================================
    // Control signals
    // =========================================================
    logic              pcsel;
    logic              immsel;
    logic              regwren;
    logic              rs1sel;
    logic              rs2sel;
    logic              memren;
    logic              memwren;
    logic [1:0]        wbsel;
    logic [3:0]        alusel;

    // =========================================================
    // Execute stage probes / signals
    // =========================================================
    logic [AWIDTH-1:0] assign_e_pc;
    logic [DWIDTH-1:0] assign_e_alu_res;
    logic              assign_e_br_taken;

    logic [DWIDTH-1:0] op1;
    logic [DWIDTH-1:0] op2;

    // Branch compare outputs
    logic breq, brlt, brltu;

    // =========================================================
    // Memory stage probes / signals
    // =========================================================
    logic [AWIDTH-1:0] assign_m_pc;
    logic [AWIDTH-1:0] assign_m_address;
    logic [1:0]        assign_m_size_encoded;
    logic [DWIDTH-1:0] assign_m_data;

    logic [DWIDTH-1:0] mem_read_data;
    logic              mem_sign_en;

    // =========================================================
    // Writeback stage probes / signals
    // =========================================================
    logic [DWIDTH-1:0] alu_res_for_pc;
    logic [AWIDTH-1:0] assign_w_pc;
    logic              assign_w_write_enable;
    logic [4:0]        assign_w_write_destination;
    logic [DWIDTH-1:0] assign_w_data;

    logic [AWIDTH-1:0] branch_target_if;
    logic br_or_jump_taken;
    assign br_or_jump_taken = assign_e_br_taken | pcsel;
    assign branch_target_if = assign_e_alu_res;

    // =========================================================
    // Fetch: PC register
    // =========================================================
    fetch #(DWIDTH, AWIDTH) u_fetch (
        .clk       (clk),
        .rst       (reset),
        .brtaken_i  (br_or_jump_taken),
        .branch_target_i(branch_target_if),
        .pc_o      (assign_f_pc),
        .insn_o    ()
    );

    // =========================================================
    // Memory stage
    // =========================================================
    logic [1:0] actual_mem_size;

    assign assign_m_pc           = assign_e_pc;
    assign assign_m_address      = assign_e_alu_res;
    assign assign_m_size_encoded = assign_d_funct3[1:0];

    assign actual_mem_size = (memren | memwren) ? assign_d_funct3[1:0] : 2'b10;

    assign mem_sign_en = (assign_d_opcode == `Opcode_IType_Load) ? ~assign_d_funct3[2] : 1'b0;

    // Testbench expects M_DATA to always show memory read output
    assign assign_m_data = mem_read_data;

    // =========================================================
    // Unified Memory
    // =========================================================
    memory #(AWIDTH, DWIDTH) u_mem (
        .clk         (clk),
        .rst         (reset),

        // Data port
        .addr_i      (assign_m_address),
        .data_i      (assign_r_read_rs2_data),
        .read_en_i   (1'b1),              // ALWAYS READ (fix)
        .write_en_i  (memwren),
        .size_i      (actual_mem_size),
        .sign_en_i   (mem_sign_en),
        .data_o      (mem_read_data),

        // Instruction port
        .insn_addr_i (assign_f_pc),
        .insn_o      (assign_f_insn)
    );

    // =========================================================
    // Decode stage
    // =========================================================
    decode #(DWIDTH, AWIDTH) u_decode (
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
        .shamt_o  (assign_d_shamt),
        .imm_o    ()
    );

    igen #(DWIDTH) u_igen (
        .opcode_i (assign_d_opcode),
        .insn_i   (assign_d_insn),
        .imm_o    (igen_imm)
    );

    assign assign_d_imm = igen_imm;

    // =========================================================
    // Control
    // =========================================================
    control #(DWIDTH) u_control (
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

    // =========================================================
    // Register File
    // =========================================================
    assign assign_r_read_rs1          = assign_d_rs1;
    assign assign_r_read_rs2          = assign_d_rs2;
    assign assign_r_write_enable      = assign_w_write_enable;
    assign assign_r_write_destination = assign_w_write_destination;
    assign assign_r_write_data        = assign_w_data;

    register_file #(DWIDTH) u_rf (
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

    // =========================================================
    // Branch comparator
    // =========================================================
    branch_control #(DWIDTH) u_branch_control (
        .opcode_i (assign_d_opcode),
        .funct3_i (assign_d_funct3),
        .rs1_i    (assign_r_read_rs1_data),
        .rs2_i    (assign_r_read_rs2_data),
        .breq_o   (breq),
        .brlt_o   (brlt),
        .brltu_o  (brltu)
    );

    always_comb begin
        assign_e_br_taken = 1'b0;

        if (assign_d_opcode == `Opcode_BType) begin
            unique case (assign_d_funct3)
                3'b000: assign_e_br_taken = breq;
                3'b001: assign_e_br_taken = ~breq;
                3'b100: assign_e_br_taken = brlt;
                3'b101: assign_e_br_taken = ~brlt;
                3'b110: assign_e_br_taken = brltu;
                3'b111: assign_e_br_taken = ~brltu;
                default: assign_e_br_taken = 1'b0;
            endcase
        end
    end

    // =========================================================
    // Execute stage
    // =========================================================
    assign assign_e_pc = assign_d_pc;

    assign op1 = (rs1sel == `OP1_PC)  ? assign_e_pc   : assign_r_read_rs1_data;
    assign op2 = (rs2sel == `OP2_IMM) ? assign_d_imm  : assign_r_read_rs2_data;

    alu #(DWIDTH, AWIDTH) u_alu (
        .pc_i      (assign_e_pc),
        .rs1_i     (op1),
        .rs2_i     (op2),
        .funct3_i  (assign_d_funct3),
        .funct7_i  (assign_d_funct7),
        .alusel_i  (alusel),
        .res_o     (assign_e_alu_res),
        .brtaken_o ()
    );

    // =========================================================
    // Writeback stage
    // =========================================================
    always_comb begin
        alu_res_for_pc = assign_e_alu_res;
        if (assign_d_opcode == `Opcode_IType_Jump_And_LinkReg) begin
            alu_res_for_pc = {assign_e_alu_res[DWIDTH-1:1], 1'b0};
        end
    end

    assign assign_w_pc                = assign_e_pc;
    assign assign_w_write_enable      = regwren;
    assign assign_w_write_destination = assign_d_rd;

    writeback #(DWIDTH, AWIDTH) u_wb (
        .pc_i             (assign_e_pc),
        .alu_res_i        (alu_res_for_pc),
        .memory_data_i    (mem_read_data),
        .wbsel_i          (wbsel),
        //.brtaken_i        (assign_e_br_taken | pcsel),
        .writeback_data_o (assign_w_data)
        //.next_pc_o        (next_pc)
    );


endmodule : pd4
