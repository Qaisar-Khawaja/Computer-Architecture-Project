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
`include "probes.svh"

module pd4 #(
    parameter int AWIDTH    = 32,
    parameter int DWIDTH    = 32,
    parameter int MEM_DEPTH = 1024,
    parameter logic [31:0] BASE_ADDR = 32'h01000000
)(
    input  logic clk,
    input  logic reset    // active-low
);

    // ===================== FETCH =====================
    logic [AWIDTH-1:0] f_pc;
    logic [DWIDTH-1:0] f_insn;
    logic [DWIDTH-1:0] f_insn_fetch;

    logic [AWIDTH-1:0] target_addr;  // from writeback
    logic e_br_taken;                 // declare only once

    fetch #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .BASEADDR(BASE_ADDR)
    ) fetch_0 (
        .clk(clk),
        .rst_n(reset),
        .br_taken_i(e_br_taken),
        .target_addr_i(target_addr),
        .instr_from_mem_i(f_insn),
        .pc_o(f_pc),
        .insn_o(f_insn_fetch)
    );

    // ===================== PIPE F→D =====================
    logic [AWIDTH-1:0] fd_pc;
    logic [DWIDTH-1:0] fd_insn;

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            fd_pc   <= '0;
            fd_insn <= '0;
        end else begin
            fd_pc   <= f_pc;
            fd_insn <= f_insn_fetch;
        end
    end

    // ===================== DECODE =====================
    logic [AWIDTH-1:0] d_pc;
    logic [DWIDTH-1:0] d_insn;
    logic [6:0]        d_opcode;
    logic [4:0]        d_rd, d_rs1, d_rs2;
    logic [6:0]        d_funct7;
    logic [2:0]        d_funct3;
    logic [DWIDTH-1:0] d_imm;

    decode decode_0 (
        .clk     (clk),
        .rst     (~reset),
        .insn_i  (fd_insn),
        .pc_i    (fd_pc),
        .pc_o    (d_pc),
        .insn_o  (d_insn),
        .opcode_o(d_opcode),
        .rd_o    (d_rd),
        .rs1_o   (d_rs1),
        .rs2_o   (d_rs2),
        .funct7_o(d_funct7),
        .funct3_o(d_funct3),
        .shamt_o (),
        .imm_o   ()
    );

    igen igen_0 (
        .opcode_i(d_opcode),
        .insn_i  (d_insn),
        .imm_o   (d_imm)
    );

    control control_0 (
        .insn_i    (d_insn),
        .opcode_i  (d_opcode),
        .funct7_i  (d_funct7),
        .funct3_i  (d_funct3),
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

    // ===================== REGISTER FILE READ =====================
    logic [DWIDTH-1:0] r_rs1_data, r_rs2_data;

    // ===================== BRANCH CONTROL =====================
    logic breq, brlt;

    branch_control bc_0 (
        .opcode_i(d_opcode),
        .funct3_i(d_funct3),
        .rs1_i(r_rs1_data),
        .rs2_i(r_rs2_data),
        .breq_o(breq),
        .brlt_o(brlt)
    );

    assign e_br_taken =
        (d_opcode == `Opcode_BType) &&
        (
            (d_funct3 == 3'b000 && breq) ||
            (d_funct3 == 3'b001 && !breq) ||
            (d_funct3 == 3'b100 && brlt) ||
            (d_funct3 == 3'b101 && !brlt) ||
            (d_funct3 == 3'b110 && brlt) ||
            (d_funct3 == 3'b111 && !brlt)
        );

    // ===================== PIPE D→E =====================
    logic [AWIDTH-1:0] de_pc;
    logic [DWIDTH-1:0] de_rs1_data, de_rs2_data, de_imm;
    logic [4:0]        de_rd;
    logic [6:0]        de_funct7;
    logic [2:0]        de_funct3;
    logic              de_rs1sel, de_rs2sel;
    logic [3:0]        de_alusel;
    logic [1:0]        de_wbsel;
    logic              de_regwren;
    logic              de_memren, de_memwren;

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            de_pc       <= '0;
            de_rs1_data <= '0;
            de_rs2_data <= '0;
            de_imm      <= '0;
            de_rd       <= '0;
            de_funct7   <= '0;
            de_funct3   <= '0;
            de_rs1sel   <= 0;
            de_rs2sel   <= 0;
            de_alusel   <= 0;
            de_wbsel    <= 0;
            de_regwren  <= 0;
            de_memren   <= 0;
            de_memwren  <= 0;
        end else begin
            de_pc       <= d_pc;
            de_rs1_data <= r_rs1_data;
            de_rs2_data <= r_rs2_data;
            de_imm      <= d_imm;
            de_rd       <= d_rd;
            de_funct7   <= d_funct7;
            de_funct3   <= d_funct3;
            de_rs1sel   <= rs1sel;
            de_rs2sel   <= rs2sel;
            de_alusel   <= alusel;
            de_wbsel    <= wbsel;
            de_regwren  <= regwren;
            de_memren   <= memren;
            de_memwren  <= memwren;
        end
    end

    // ===================== EXECUTE =====================
    logic [DWIDTH-1:0] e_alu_res;
    logic [DWIDTH-1:0] alu_op1, alu_op2;

    assign alu_op1 = (de_rs1sel) ? de_pc : de_rs1_data;
    assign alu_op2 = (de_rs2sel) ? de_imm : de_rs2_data;

    alu alu_0 (
        .pc_i(de_pc),
        .rs1_i(alu_op1),
        .rs2_i(alu_op2),
        .funct3_i(de_funct3),
        .funct7_i(de_funct7),
        .alusel_i(de_alusel),
        .res_o(e_alu_res),
        .brtaken_o()
    );

    // ===================== PIPE E→M =====================
    logic [AWIDTH-1:0] em_pc;
    logic [DWIDTH-1:0] em_alu_res, em_rs2_data;
    logic [4:0]        em_rd;
    logic [1:0]        em_wbsel;
    logic [2:0]        em_funct3;
    logic              em_regwren, em_memren, em_memwren;

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            em_pc       <= '0;
            em_alu_res  <= '0;
            em_rs2_data <= '0;
            em_rd       <= '0;
            em_wbsel    <= 0;
            em_funct3   <= 0;
            em_regwren  <= 0;
            em_memren   <= 0;
            em_memwren  <= 0;
        end else begin
            em_pc       <= de_pc;
            em_alu_res  <= e_alu_res;
            em_rs2_data <= de_rs2_data;
            em_rd       <= de_rd;
            em_wbsel    <= de_wbsel;
            em_funct3   <= de_funct3;
            em_regwren  <= de_regwren;
            em_memren   <= de_memren;
            em_memwren  <= de_memwren;
        end
    end

    // ===================== MEMORY =====================
    logic [DWIDTH-1:0] m_data_read;

    memory #(
        .DWIDTH(DWIDTH),
        .AWIDTH(AWIDTH),
        .BASE_ADDR(BASE_ADDR)
    ) mem_0 (
        .clk         (clk),
        .rst_n       (reset),
        .instr_addr_i(f_pc),
        .instr_data_o(f_insn),
        .data_addr_i (em_alu_res),
        .data_i      (em_rs2_data),
        .read_en_i   (em_memren),
        .write_en_i  (em_memwren),
        .funct3_i    (em_funct3),
        .data_o      (m_data_read)
    );

    // ===================== PIPE M→W =====================
    logic [AWIDTH-1:0] wb_pc;
    logic [DWIDTH-1:0] wb_alu_res, wb_mem_data, wb_data;
    logic [4:0]        wb_rd_w;
    logic [1:0]        wb_wbsel_w;
    logic              wb_regwren_w;

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            wb_pc        <= '0;
            wb_alu_res   <= '0;
            wb_mem_data  <= '0;
            wb_rd_w      <= '0;
            wb_wbsel_w   <= 0;
            wb_regwren_w <= 0;
        end else begin
            wb_pc        <= em_pc;
            wb_alu_res   <= em_alu_res;
            wb_mem_data  <= m_data_read;
            wb_rd_w      <= em_rd;
            wb_wbsel_w   <= em_wbsel;
            wb_regwren_w <= em_regwren;
        end
    end

    // ===================== REGISTER FILE WRITEBACK =====================
    register_file rf_0 (
        .clk        (clk),
        .rst        (~reset),
        .rs1_i      (d_rs1),
        .rs2_i      (d_rs2),
        .rd_i       (wb_rd_w),
        .datawb_i   (wb_data),
        .regwren_i  (wb_regwren_w),
        .rs1data_o  (r_rs1_data),
        .rs2data_o  (r_rs2_data)
    );

// ===================== DEBUG SIGNALS =====================
logic [AWIDTH-1:0] assign_f_pc;
logic [DWIDTH-1:0] assign_f_insn;
logic [AWIDTH-1:0] assign_d_pc;
logic [6:0]        assign_d_opcode;
logic [4:0]        assign_d_rd, assign_d_rs1, assign_d_rs2;
logic [2:0]        assign_d_funct3;
logic [6:0]        assign_d_funct7;
logic [DWIDTH-1:0] assign_d_imm;
logic [DWIDTH-1:0] assign_r_read_rs1, assign_r_read_rs2;
logic [DWIDTH-1:0] assign_r_read_rs1_data, assign_r_read_rs2_data;
logic [AWIDTH-1:0] assign_e_pc;
logic [DWIDTH-1:0] assign_e_alu_res;
logic              assign_e_br_taken;
logic [AWIDTH-1:0] assign_m_pc;
logic [DWIDTH-1:0] assign_m_address;
logic [2:0]        assign_m_size_encoded;
logic [DWIDTH-1:0] assign_m_data;
logic [AWIDTH-1:0] assign_w_pc;
logic              assign_w_enable;
logic [4:0]        assign_w_destination;
logic [DWIDTH-1:0] assign_w_data;
    // ===================== WRITEBACK =====================
    writeback wb_0 (
        .pc_i            (wb_pc),
        .alu_res_i       (wb_alu_res),
        .memory_data_i   (wb_mem_data),
        .wbsel_i         (wb_wbsel_w),
        .brtaken_i       (e_br_taken),
        .writeback_data_o(wb_data),
        .next_pc_o       (target_addr)
    );
// ===================== DEBUG SIGNALS ASSIGN =====================
assign assign_f_pc           = f_pc;
assign assign_f_insn         = f_insn_fetch;
assign assign_d_pc           = d_pc;
assign assign_d_opcode       = d_opcode;
assign assign_d_rd           = d_rd;
assign assign_d_rs1          = d_rs1;
assign assign_d_rs2          = d_rs2;
assign assign_d_funct3       = d_funct3;
assign assign_d_funct7       = d_funct7;
assign assign_d_imm          = d_imm;
assign assign_r_read_rs1     = d_rs1;
assign assign_r_read_rs2     = d_rs2;
assign assign_r_read_rs1_data= r_rs1_data;
assign assign_r_read_rs2_data= r_rs2_data;
assign assign_e_pc           = de_pc;
assign assign_e_alu_res      = e_alu_res;
assign assign_e_br_taken     = e_br_taken;
assign assign_m_pc           = em_pc;
assign assign_m_address      = em_alu_res;
assign assign_m_size_encoded = em_funct3;
assign assign_m_data         = em_rs2_data;
assign assign_w_pc           = wb_pc;
assign assign_w_enable       = wb_regwren_w;
assign assign_w_destination  = wb_rd_w;
assign assign_w_data         = wb_data;
endmodule