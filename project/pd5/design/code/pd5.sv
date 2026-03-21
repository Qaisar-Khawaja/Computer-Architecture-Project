/*
 * Module: pd5
 *
 * Description:
 * 5-stage pipelined RV32I top level built from the PD4 single-cycle modules.
 *
 * Stages:
 *   IF  -> fetch PC + instruction memory read
 *   ID  -> decode + control + register read + immediate generation
 *   EX  -> ALU + branch/jump decision
 *   MEM -> data memory access
 *   WB  -> register writeback mux
 *
 * Notes for this version:
 * - The pipeline registers are implemented.
 * - Basic control-flow redirect/flush is included so branch/jump wiring has a
 *   clean home in the EX stage.
 * - Data forwarding and load-use stalls are NOT implemented yet.
 * - Comments mark where hazard detection / forwarding logic should be added.
 */
`include "constants.svh"

module pd5 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32,
    parameter logic [31:0] BASEADDR = 32'h01000000
)(
    input logic clk,
    input logic reset
);

    // =====================================================================
    // Probe-style signals kept with the same naming convention as PD4
    // =====================================================================
    logic [AWIDTH-1:0] assign_f_pc;
    logic [DWIDTH-1:0] assign_f_insn;

    logic [AWIDTH-1:0] assign_d_pc;
    logic [DWIDTH-1:0] assign_d_insn;
    logic [6:0]        assign_d_opcode;
    logic [4:0]        assign_d_rd, assign_d_rs1, assign_d_rs2, assign_d_shamt;
    logic [6:0]        assign_d_funct7;
    logic [2:0]        assign_d_funct3;
    logic [DWIDTH-1:0] assign_d_imm;

    logic              assign_r_write_enable;
    logic [4:0]        assign_r_write_destination;
    logic [DWIDTH-1:0] assign_r_write_data;
    logic [4:0]        assign_r_read_rs1;
    logic [4:0]        assign_r_read_rs2;
    logic [DWIDTH-1:0] assign_r_read_rs1_data;
    logic [DWIDTH-1:0] assign_r_read_rs2_data;

    logic [AWIDTH-1:0] assign_e_pc;
    logic [DWIDTH-1:0] assign_e_alu_res;
    logic              assign_e_br_taken;

    logic [AWIDTH-1:0] assign_m_pc;
    logic [AWIDTH-1:0] assign_m_address;
    logic [1:0]        assign_m_size_encoded;
    logic [DWIDTH-1:0] assign_m_data;

    logic [AWIDTH-1:0] assign_w_pc;
    logic              assign_w_write_enable;
    logic [4:0]        assign_w_write_destination;
    logic [DWIDTH-1:0] assign_w_data;

    logic              mem_wb_valid;
    logic [AWIDTH-1:0] mem_wb_pc;
    logic [4:0]        mem_wb_rd;
    logic [DWIDTH-1:0] mem_wb_alu_res;
    logic [DWIDTH-1:0] mem_wb_mem_data;
    logic              mem_wb_regwren;
    logic [1:0]        mem_wb_wbsel;


    // =====================================================================
    // IF stage
    // =====================================================================
    logic [AWIDTH-1:0] if_pc;
    logic [DWIDTH-1:0] if_insn;

    logic              ex_redirect_taken;
    logic [AWIDTH-1:0] ex_redirect_target;

    // NOTE: stall support will need a PC hold/enable in fetch.
    // For now, the fetch stage always advances unless EX redirects control flow.
    fetch #(
        .DWIDTH   (DWIDTH),
        .AWIDTH   (AWIDTH),
        .BASEADDR (BASEADDR)
    ) u_fetch (
        .clk             (clk),
        .rst             (reset),
        .brtaken_i       (ex_redirect_taken),
        .branch_target_i (ex_redirect_target),
        .pc_o            (if_pc),
        .insn_o          (),
        .stall_i         (stall)
    );

    // Unified memory instance: instruction port + data port
    logic [DWIDTH-1:0] mem_read_data;
    logic [1:0]        mem_size;
    logic              mem_sign_en;

    // EX/MEM declarations are placed here so they are declared before use in the
    // memory instance below.
    logic              ex_mem_valid;
    logic [AWIDTH-1:0] ex_mem_pc;
    logic [6:0]        ex_mem_opcode;
    logic [4:0]        ex_mem_rd;
    logic [2:0]        ex_mem_funct3;
    logic [DWIDTH-1:0] ex_mem_alu_res;
    logic [DWIDTH-1:0] ex_mem_rs2_data;
    logic              ex_mem_regwren;
    logic              ex_mem_memren;
    logic              ex_mem_memwren;
    logic [1:0]        ex_mem_wbsel;

    memory #(
        .AWIDTH    (AWIDTH),
        .DWIDTH    (DWIDTH),
        .BASE_ADDR (BASEADDR)
    ) u_mem (
        .clk         (clk),
        .rst         (reset),
        .addr_i      (assign_m_address),
        .data_i      (assign_m_data),
        .read_en_i   (ex_mem_memren),
        .write_en_i  (ex_mem_memwren),
        .size_i      (mem_size),
        .sign_en_i   (mem_sign_en),
        .data_o      (mem_read_data),
        .insn_addr_i (if_pc),
        .insn_o      (if_insn)
    );

    assign assign_f_pc   = if_pc;
    assign assign_f_insn = if_insn;

    // =====================================================================
    // IF/ID pipeline register
    // =====================================================================
    logic              if_id_valid;
    logic [AWIDTH-1:0] if_id_pc;
    logic [DWIDTH-1:0] if_id_insn;

    // =====================================================================
    // ID stage
    // =====================================================================
    logic [AWIDTH-1:0] id_pc;
    logic [DWIDTH-1:0] id_insn;
    logic [6:0]        id_opcode;
    logic [4:0]        id_rd, id_rs1, id_rs2, id_shamt;
    logic [6:0]        id_funct7;
    logic [2:0]        id_funct3;
    logic [DWIDTH-1:0] id_imm;

    logic              id_pcsel;
    logic              id_immsel;
    logic              id_regwren;
    logic              id_rs1sel;
    logic              id_rs2sel;
    logic              id_memren;
    logic              id_memwren;
    logic [1:0]        id_wbsel;
    logic [3:0]        id_alusel;

    decode #(
        .DWIDTH (DWIDTH),
        .AWIDTH (AWIDTH)
    ) u_decode (
        .clk      (clk),
        .rst      (reset),
        .insn_i   (if_id_insn),
        .pc_i     (if_id_pc),
        .pc_o     (id_pc),
        .insn_o   (id_insn),
        .opcode_o (id_opcode),
        .rd_o     (id_rd),
        .rs1_o    (id_rs1),
        .rs2_o    (id_rs2),
        .funct7_o (id_funct7),
        .funct3_o (id_funct3),
        .shamt_o  (id_shamt),
        .imm_o    ()
    );

    igen #(
        .DWIDTH (DWIDTH)
    ) u_igen (
        .opcode_i (id_opcode),
        .insn_i   (id_insn),
        .imm_o    (id_imm)
    );

    control #(
        .DWIDTH (DWIDTH)
    ) u_control (
        .insn_i    (id_insn),
        .opcode_i  (id_opcode),
        .funct7_i  (id_funct7),
        .funct3_i  (id_funct3),
        .pcsel_o   (id_pcsel),
        .immsel_o  (id_immsel),
        .regwren_o (id_regwren),
        .rs1sel_o  (id_rs1sel),
        .rs2sel_o  (id_rs2sel),
        .memren_o  (id_memren),
        .memwren_o (id_memwren),
        .wbsel_o   (id_wbsel),
        .alusel_o  (id_alusel)
    );

    assign assign_d_pc     = id_pc;
    assign assign_d_insn   = id_insn;
    assign assign_d_opcode = id_opcode;
    assign assign_d_rd     = id_rd;
    assign assign_d_rs1    = id_rs1;
    assign assign_d_rs2    = id_rs2;
    assign assign_d_shamt  = id_shamt;
    assign assign_d_funct7 = id_funct7;
    assign assign_d_funct3 = id_funct3;
    assign assign_d_imm    = id_imm;

    // Register file read in ID, write in WB
    assign assign_r_read_rs1          = id_rs1;
    assign assign_r_read_rs2          = id_rs2;
    assign assign_r_write_enable      = assign_w_write_enable;
    assign assign_r_write_destination = assign_w_write_destination;
    assign assign_r_write_data        = assign_w_data;

    register_file #(
        .DWIDTH (DWIDTH)
    ) u_rf (
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

    // =====================================================================
    // ID/EX pipeline register
    // =====================================================================
    logic              id_ex_valid;
    logic [AWIDTH-1:0] id_ex_pc;
    logic [DWIDTH-1:0] id_ex_insn;
    logic [6:0]        id_ex_opcode;
    logic [4:0]        id_ex_rd, id_ex_rs1, id_ex_rs2;
    logic [6:0]        id_ex_funct7;
    logic [2:0]        id_ex_funct3;
    logic [DWIDTH-1:0] id_ex_imm;
    logic [DWIDTH-1:0] id_ex_rs1_data;
    logic [DWIDTH-1:0] id_ex_rs2_data;
    logic              id_ex_pcsel;
    logic              id_ex_immsel;
    logic              id_ex_regwren;
    logic              id_ex_rs1sel;
    logic              id_ex_rs2sel;
    logic              id_ex_memren;
    logic              id_ex_memwren;
    logic [1:0]        id_ex_wbsel;
    logic [3:0]        id_ex_alusel;

    // =====================================================================
    // EX stage
    // =====================================================================
    logic [DWIDTH-1:0] ex_op1;
    logic [DWIDTH-1:0] ex_op2;
    logic [DWIDTH-1:0] ex_alu_res_raw;
    logic [AWIDTH-1:0] ex_alu_res_for_pc;
    logic              ex_breq, ex_brlt, ex_brltu;
    logic [DWIDTH-1:0] ex_rs1_fwd;
    logic [DWIDTH-1:0] ex_rs2_fwd;

    always_comb begin
        ex_rs1_fwd = id_ex_rs1_data;
        ex_rs2_fwd = id_ex_rs2_data;

        // EX/MEM -> EX forwarding for ALU-producing instructions only.
        // Loads cannot forward from EX/MEM because ex_mem_alu_res is just the address.
        if (ex_mem_valid && ex_mem_regwren && (ex_mem_rd != 5'd0) &&
            !ex_mem_memren && (ex_mem_rd == id_ex_rs1)) begin
            ex_rs1_fwd = ex_mem_alu_res;
        end
        else if (mem_wb_valid && mem_wb_regwren && (mem_wb_rd != 5'd0) &&
                 (mem_wb_rd == id_ex_rs1)) begin
            ex_rs1_fwd = assign_w_data;
        end

        if (ex_mem_valid && ex_mem_regwren && (ex_mem_rd != 5'd0) &&
            !ex_mem_memren && (ex_mem_rd == id_ex_rs2)) begin
            ex_rs2_fwd = ex_mem_alu_res;
        end
        else if (mem_wb_valid && mem_wb_regwren && (mem_wb_rd != 5'd0) &&
                 (mem_wb_rd == id_ex_rs2)) begin
            ex_rs2_fwd = assign_w_data;
        end
    end

    assign ex_op1 = (id_ex_rs1sel == `OP1_PC)  ? id_ex_pc  : ex_rs1_fwd;
    assign ex_op2 = (id_ex_rs2sel == `OP2_IMM) ? id_ex_imm : ex_rs2_fwd;

    alu #(
        .DWIDTH (DWIDTH),
        .AWIDTH (AWIDTH)
    ) u_alu (
        .pc_i      (id_ex_pc),
        .rs1_i     (ex_op1),
        .rs2_i     (ex_op2),
        .funct3_i  (id_ex_funct3),
        .funct7_i  (id_ex_funct7),
        .alusel_i  (id_ex_alusel),
        .res_o     (ex_alu_res_raw),
        .brtaken_o ()
    );

    branch_control #(
        .DWIDTH (DWIDTH)
    ) u_branch_control (
        .opcode_i (id_ex_opcode),
        .funct3_i (id_ex_funct3),
        .rs1_i    (ex_rs1_fwd),
        .rs2_i    (ex_rs2_fwd),
        .breq_o   (ex_breq),
        .brlt_o   (ex_brlt),
        .brltu_o  (ex_brltu)
    );

    // JALR requires bit[0] of the target to be cleared.
    assign ex_alu_res_for_pc = (id_ex_opcode == `Opcode_IType_Jump_And_LinkReg)
                             ? {ex_alu_res_raw[AWIDTH-1:1], 1'b0}
                             : ex_alu_res_raw;

    always_comb begin
        ex_redirect_taken  = 1'b0;
        ex_redirect_target = ex_alu_res_for_pc;

        // Control-flow decision point lives in EX.
        // Younger instructions in IF/ID and ID/EX are flushed when this is true.
        if (id_ex_valid) begin
            unique case (id_ex_opcode)
                `Opcode_JType_Jump_And_Link,
                `Opcode_IType_Jump_And_LinkReg: begin
                    ex_redirect_taken  = 1'b1;
                    ex_redirect_target = ex_alu_res_for_pc;
                end

                `Opcode_BType: begin
                    unique case (id_ex_funct3)
                        3'b000: ex_redirect_taken = ex_breq;
                        3'b001: ex_redirect_taken = ~ex_breq;
                        3'b100: ex_redirect_taken = ex_brlt;
                        3'b101: ex_redirect_taken = ~ex_brlt;
                        3'b110: ex_redirect_taken = ex_brltu;
                        3'b111: ex_redirect_taken = ~ex_brltu;
                        default: ex_redirect_taken = 1'b0;
                    endcase
                    ex_redirect_target = id_ex_pc + id_ex_imm;
                end

                default: begin
                    ex_redirect_taken  = 1'b0;
                    ex_redirect_target = ex_alu_res_for_pc;
                end
            endcase
        end
    end

    assign assign_e_pc       = id_ex_pc;
    assign assign_e_alu_res  = ex_alu_res_raw;
    assign assign_e_br_taken = ex_redirect_taken;

    // =====================================================================
    // MEM stage
    // =====================================================================
    assign assign_m_pc           = ex_mem_pc;
    assign assign_m_address      = ex_mem_alu_res;
    assign assign_m_size_encoded = ex_mem_funct3[1:0];
    assign assign_m_data         = ex_mem_rs2_data;

    assign mem_size    = (ex_mem_memren || ex_mem_memwren) ? ex_mem_funct3[1:0] : 2'b10;
    assign mem_sign_en = (ex_mem_opcode == `Opcode_IType_Load) ? ~ex_mem_funct3[2] : 1'b0;

    // =====================================================================
    // MEM/WB pipeline register
    // =====================================================================

    // =====================================================================
    // WB stage
    // =====================================================================
    writeback #(
        .DWIDTH (DWIDTH),
        .AWIDTH (AWIDTH)
    ) u_wb (
        .pc_i             (mem_wb_pc),
        .alu_res_i        (mem_wb_alu_res),
        .memory_data_i    (mem_wb_mem_data),
        .wbsel_i          (mem_wb_wbsel),
        .writeback_data_o (assign_w_data)
    );

    assign assign_w_pc                = mem_wb_pc;
    assign assign_w_write_enable      = mem_wb_valid && mem_wb_regwren;
    assign assign_w_write_destination = mem_wb_rd;

    logic id_uses_rs1, id_uses_rs2;

    always_comb begin
        id_uses_rs1 = 1'b0;
        id_uses_rs2 = 1'b0;

        unique case (id_opcode)
            `Opcode_RType: begin
                id_uses_rs1 = 1'b1;
                id_uses_rs2 = 1'b1;
            end

            `Opcode_IType,
            `Opcode_IType_Load,
            `Opcode_IType_Jump_And_LinkReg: begin
                id_uses_rs1 = 1'b1;
                id_uses_rs2 = 1'b0;
            end

            `Opcode_SType,
            `Opcode_BType: begin
                id_uses_rs1 = 1'b1;
                id_uses_rs2 = 1'b1;
            end

            // LUI, AUIPC, JAL do not read rs1/rs2 from the register file
            `Opcode_UType_Load_Upper_Imm,
            `Opcode_UType_Add_Upper_Imm,
            `Opcode_JType_Jump_And_Link: begin
                id_uses_rs1 = 1'b0;
                id_uses_rs2 = 1'b0;
            end

            default: begin
                id_uses_rs1 = 1'b0;
                id_uses_rs2 = 1'b0;
            end
        endcase
    end

    assign stall =
        id_ex_valid &&
        id_ex_memren &&
        (id_ex_rd != 5'd0) &&
        (
            (id_uses_rs1 && (id_ex_rd == id_rs1)) ||
            (id_uses_rs2 && (id_ex_rd == id_rs2))
        );
   // =====================================================================
   // Pipeline register updates
   // =====================================================================

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            if_id_valid <= 1'b0;
            if_id_pc    <= '0;
            if_id_insn  <= `NOP;

            id_ex_valid    <= 1'b0;
            id_ex_pc       <= '0;
            id_ex_insn     <= `NOP;
            id_ex_opcode   <= '0;
            id_ex_rd       <= '0;
            id_ex_rs1      <= '0;
            id_ex_rs2      <= '0;
            id_ex_funct7   <= '0;
            id_ex_funct3   <= '0;
            id_ex_imm      <= '0;
            id_ex_rs1_data <= '0;
            id_ex_rs2_data <= '0;
            id_ex_pcsel    <= `PC_NEXTLINE;
            id_ex_immsel   <= 1'b0;
            id_ex_regwren  <= 1'b0;
            id_ex_rs1sel   <= `OP1_RS1;
            id_ex_rs2sel   <= `OP2_RS2;
            id_ex_memren   <= 1'b0;
            id_ex_memwren  <= 1'b0;
            id_ex_wbsel    <= `WB_ALU;
            id_ex_alusel   <= `ADD;

            ex_mem_valid    <= 1'b0;
            ex_mem_pc       <= '0;
            ex_mem_opcode   <= '0;
            ex_mem_rd       <= '0;
            ex_mem_funct3   <= '0;
            ex_mem_alu_res  <= '0;
            ex_mem_rs2_data <= '0;
            ex_mem_regwren  <= 1'b0;
            ex_mem_memren   <= 1'b0;
            ex_mem_memwren  <= 1'b0;
            ex_mem_wbsel    <= `WB_ALU;

            mem_wb_valid    <= 1'b0;
            mem_wb_pc       <= '0;
            mem_wb_rd       <= '0;
            mem_wb_alu_res  <= '0;
            mem_wb_mem_data <= '0;
            mem_wb_regwren  <= 1'b0;
            mem_wb_wbsel    <= `WB_ALU;
        end
        else begin
            // ---------------------------
            // Back half always advances
            // ---------------------------
            mem_wb_valid    <= ex_mem_valid;
            mem_wb_pc       <= ex_mem_pc;
            mem_wb_rd       <= ex_mem_rd;
            mem_wb_alu_res  <= ex_mem_alu_res;
            mem_wb_mem_data <= mem_read_data;
            mem_wb_regwren  <= ex_mem_regwren;
            mem_wb_wbsel    <= ex_mem_wbsel;

            ex_mem_valid    <= id_ex_valid;
            ex_mem_pc       <= id_ex_pc;
            ex_mem_opcode   <= id_ex_opcode;
            ex_mem_rd       <= id_ex_rd;
            ex_mem_funct3   <= id_ex_funct3;
            ex_mem_alu_res  <= ex_alu_res_raw;
            ex_mem_rs2_data <= ex_rs2_fwd;
            ex_mem_regwren  <= id_ex_regwren;
            ex_mem_memren   <= id_ex_memren;
            ex_mem_memwren  <= id_ex_memwren;
            ex_mem_wbsel    <= id_ex_wbsel;

            // ---------------------------
            // Front half control
            // priority: flush > stall > normal
            // ---------------------------
            if (ex_redirect_taken) begin
                if_id_valid <= 1'b0;
                if_id_pc    <= '0;
                if_id_insn  <= `NOP;

                id_ex_valid    <= 1'b0;
                id_ex_pc       <= '0;
                id_ex_insn     <= `NOP;
                id_ex_opcode   <= '0;
                id_ex_rd       <= '0;
                id_ex_rs1      <= '0;
                id_ex_rs2      <= '0;
                id_ex_funct7   <= '0;
                id_ex_funct3   <= '0;
                id_ex_imm      <= '0;
                id_ex_rs1_data <= '0;
                id_ex_rs2_data <= '0;
                id_ex_pcsel    <= `PC_NEXTLINE;
                id_ex_immsel   <= 1'b0;
                id_ex_regwren  <= 1'b0;
                id_ex_rs1sel   <= `OP1_RS1;
                id_ex_rs2sel   <= `OP2_RS2;
                id_ex_memren   <= 1'b0;
                id_ex_memwren  <= 1'b0;
                id_ex_wbsel    <= `WB_ALU;
                id_ex_alusel   <= `ADD;
            end
            else if (stall) begin
                // Hold IF/ID
                if_id_valid <= if_id_valid;
                if_id_pc    <= if_id_pc;
                if_id_insn  <= if_id_insn;

                // Bubble ID/EX
                id_ex_valid    <= 1'b0;
                id_ex_pc       <= '0;
                id_ex_insn     <= `NOP;
                id_ex_opcode   <= '0;
                id_ex_rd       <= '0;
                id_ex_rs1      <= '0;
                id_ex_rs2      <= '0;
                id_ex_funct7   <= '0;
                id_ex_funct3   <= '0;
                id_ex_imm      <= '0;
                id_ex_rs1_data <= '0;
                id_ex_rs2_data <= '0;
                id_ex_pcsel    <= `PC_NEXTLINE;
                id_ex_immsel   <= 1'b0;
                id_ex_regwren  <= 1'b0;
                id_ex_rs1sel   <= `OP1_RS1;
                id_ex_rs2sel   <= `OP2_RS2;
                id_ex_memren   <= 1'b0;
                id_ex_memwren  <= 1'b0;
                id_ex_wbsel    <= `WB_ALU;
                id_ex_alusel   <= `ADD;
            end
            else begin
                // Normal advance
                if_id_valid <= 1'b1;
                if_id_pc    <= if_pc;
                if_id_insn  <= if_insn;

                id_ex_valid    <= if_id_valid;
                id_ex_pc       <= id_pc;
                id_ex_insn     <= id_insn;
                id_ex_opcode   <= id_opcode;
                id_ex_rd       <= id_rd;
                id_ex_rs1      <= id_rs1;
                id_ex_rs2      <= id_rs2;
                id_ex_funct7   <= id_funct7;
                id_ex_funct3   <= id_funct3;
                id_ex_imm      <= id_imm;
                id_ex_rs1_data <= assign_r_read_rs1_data;
                id_ex_rs2_data <= assign_r_read_rs2_data;
                id_ex_pcsel    <= id_pcsel;
                id_ex_immsel   <= id_immsel;
                id_ex_regwren  <= id_regwren;
                id_ex_rs1sel   <= id_rs1sel;
                id_ex_rs2sel   <= id_rs2sel;
                id_ex_memren   <= id_memren;
                id_ex_memwren  <= id_memwren;
                id_ex_wbsel    <= id_wbsel;
                id_ex_alusel   <= id_alusel;
            end
        end
    end

endmodule : pd5
