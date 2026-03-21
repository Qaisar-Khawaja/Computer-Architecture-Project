// // /*
// //  * Module: pd5
// //  *
// //  * Description: Top level module that will contain sub-module instantiations.
// //  *
// //  * Inputs:
// //  * 1) clk
// //  * 2) reset signal
// //  */
// // /*
// //  * Module: pd5
// //  * Description: Top level 5-stage RISC-V Pipeline with Forwarding and Stalling.
// //  */
// // `include "constants.svh"

// // module pd5 #(
// //     parameter int AWIDTH = 32,
// //     parameter int DWIDTH = 32,
// //     parameter logic [31:0] BASEADDR = 32'h01000000
// // )(
// //     input logic clk,
// //     input logic reset
// // );

// //     // --- GLOBAL CONTROL SIGNALS ---
// //     logic stall;
// //     logic brtaken;
// //     logic [AWIDTH-1:0] br_target;

// //     // =========================================================================
// //     // 1. FETCH STAGE (IF)
// //     // =========================================================================
// //     logic [AWIDTH-1:0] if_pc;
// //     logic [DWIDTH-1:0] if_insn;

// //     fetch #(DWIDTH, AWIDTH, BASEADDR) u_fetch (
// //         .clk             (clk),
// //         .rst             (reset),
// //         .brtaken_i       (brtaken),
// //         .stall_i         (stall),
// //         .branch_target_i (br_target),
// //         .pc_o            (if_pc)
// //         //.insn_o          (if_insn)
// //     );

// //     // --- IF/ID PIPELINE REGISTER ---
// //     logic [AWIDTH-1:0] id_pc;
// //     logic [DWIDTH-1:0] id_insn;

// //     always_ff @(posedge clk) begin
// //         if (reset || brtaken) begin
// //             id_pc   <= '0;
// //             id_insn <= 32'h00000013; // NOP
// //         end else if (!stall) begin
// //             id_pc   <= if_pc;
// //             id_insn <= if_insn; 
// //         end
// //     end

// //     // =========================================================================
// //     // 2. DECODE STAGE (ID)
// //     // =========================================================================
// //     logic [4:0] id_rs1_addr, id_rs2_addr, id_rd_addr;
// //     logic [DWIDTH-1:0] id_imm, id_rs1_data, id_rs2_data;
    
// //     logic id_regwren_ctrl, id_memren_ctrl, id_memwren_ctrl, id_regwren;
// //     logic [3:0] id_alusel;
// //     logic id_rs1sel, id_rs2sel, id_memren, id_memwren;
// //     logic [1:0] id_wbsel;

// //     control u_control (
// //         .insn_i    (id_insn),
// //         .opcode_i  (id_insn[6:0]),
// //         .funct7_i  (id_insn[31:25]),
// //         .funct3_i  (id_insn[14:12]),
// //         .regwren_o (id_regwren_ctrl),
// //         .memren_o  (id_memren_ctrl),
// //         .memwren_o (id_memwren_ctrl),
// //         .alusel_o  (id_alusel),
// //         .rs1sel_o  (id_rs1sel),
// //         .rs2sel_o  (id_rs2sel),
// //         .wbsel_o   (id_wbsel)
// //     );

// //     decode u_decode (
// //         .insn_i         (id_insn),
// //         .pc_i           (id_pc),
// //         .rd_ex_i        (ex_rd_addr),   
// //         .memren_ex_i    (ex_memren),    
// //         .brtaken_i      (brtaken),
// //         .regwren_ctrl_i (id_regwren_ctrl),
// //         .memren_ctrl_i  (id_memren_ctrl),
// //         .memwren_ctrl_i (id_memwren_ctrl),
// //         .stall_o        (stall),
// //         .regwren_o      (id_regwren),
// //         .memren_o       (id_memren),
// //         .memwren_o      (id_memwren),
// //         .rs1_o          (id_rs1_addr),
// //         .rs2_o          (id_rs2_addr),
// //         .rd_o           (id_rd_addr)
// //     );

// //     igen u_igen (
// //         .opcode_i (id_insn[6:0]),
// //         .insn_i   (id_insn),
// //         .imm_o    (id_imm)
// //     );

// //     register_file u_regfile (
// //         .clk       (clk),
// //         .rst       (reset),
// //         .rs1_i     (id_rs1_addr),
// //         .rs2_i     (id_rs2_addr),
// //         .rd_i      (wb_rd),   
// //         .datawb_i  (wb_data),   
// //         .regwren_i (wb_regwren),   
// //         .rs1data_o (id_rs1_data),
// //         .rs2data_o (id_rs2_data)
// //     );

// //     // --- ID/EX PIPELINE REGISTER ---
// //     logic [AWIDTH-1:0] ex_pc;
// //     logic [DWIDTH-1:0] ex_rs1_data, ex_rs2_data, ex_imm;
// //     logic [3:0] ex_alusel;
// //     logic [6:0] ex_opcode;   // Added for ALU branching
// //     logic [2:0] ex_funct3;   // Added for ALU branching
// //     logic ex_rs1sel, ex_rs2sel, ex_regwren, ex_memren, ex_memwren;
// //     logic [4:0] ex_rd_addr, ex_rs1_addr, ex_rs2_addr;
// //     logic [1:0] ex_wbsel;

// //     always_ff @(posedge clk) begin
// //         if (reset || brtaken || stall) begin
// //             ex_regwren <= 1'b0;
// //             ex_memwren <= 1'b0;
// //             ex_memren  <= 1'b0;
// //             ex_opcode  <= 7'h0;
// //             ex_funct3  <= 3'h0;
// //         end else begin
// //             ex_pc       <= id_pc;
// //             ex_imm      <= id_imm;
// //             ex_alusel   <= id_alusel;
// //             ex_opcode   <= id_insn[6:0];
// //             ex_funct3   <= id_insn[14:12];
// //             ex_rs1sel   <= id_rs1sel;
// //             ex_rs2sel   <= id_rs2sel;
// //             ex_rd_addr  <= id_rd_addr;
// //             ex_rs1_addr <= id_rs1_addr;
// //             ex_rs2_addr <= id_rs2_addr;
// //             ex_regwren  <= id_regwren;
// //             ex_memren   <= id_memren;
// //             ex_memwren  <= id_memwren;
// //             ex_wbsel    <= id_wbsel;
// //             ex_rs1_data <= id_rs1_data; 
// //             ex_rs2_data <= id_rs2_data; 
// //         end
// //     end

// //     // =========================================================================
// //     // 3. EXECUTE STAGE (EX)
// //     // =========================================================================
// //     logic [DWIDTH-1:0] fwd_a_data, fwd_b_data, alu_op1, alu_op2, alu_res;

// //     // --- FORWARDING UNIT ---
// //     always_comb begin
// //         // Forward rs1
// //         if (mem_regwren && (mem_rd != 0) && (mem_rd == ex_rs1_addr))
// //             fwd_a_data = mem_alu_res;
// //         else if (wb_regwren && (wb_rd != 0) && (wb_rd == ex_rs1_addr))
// //             fwd_a_data = wb_data;
// //         else
// //             fwd_a_data = ex_rs1_data;

// //         // Forward rs2
// //         if (mem_regwren && (mem_rd != 0) && (mem_rd == ex_rs2_addr))
// //             fwd_b_data = mem_alu_res;
// //         else if (wb_regwren && (wb_rd != 0) && (wb_rd == ex_rs2_addr))
// //             fwd_b_data = wb_data;
// //         else
// //             fwd_b_data = ex_rs2_data;
// //     end

// //     // Operand Selection
// //     assign alu_op1 = (ex_rs1sel == `OP1_PC)  ? ex_pc  : fwd_a_data;
// //     assign alu_op2 = (ex_rs2sel == `OP2_IMM) ? ex_imm : fwd_b_data;

// //     alu #(DWIDTH, AWIDTH) u_alu (
// //         .opcode_i  (ex_opcode),
// //         .funct3_i  (ex_funct3),
// //         .rs1_i     (alu_op1),
// //         .rs2_i     (alu_op2),
// //         .alusel_i  (ex_alusel),
// //         .res_o     (alu_res),
// //         .brtaken_o (brtaken)
// //     );

// //     assign br_target = ex_pc + ex_imm;

// //     // --- EX/MEM PIPELINE REGISTER ---
// //     logic [DWIDTH-1:0] mem_alu_res, mem_rs2_data;
// //     logic [AWIDTH-1:0] mem_pc; // Added to support JAL Return Addresses
// //     logic [4:0]        mem_rd;
// //     logic              mem_regwren, mem_memren, mem_memwren;
// //     logic [1:0]        mem_wbsel;

// //     always_ff @(posedge clk) begin
// //         if (reset) begin
// //             mem_regwren <= 0; mem_memren <= 0; mem_memwren <= 0;
// //         end else begin
// //             mem_pc       <= ex_pc;
// //             mem_alu_res  <= alu_res;
// //             mem_rs2_data <= fwd_b_data; 
// //             mem_rd       <= ex_rd_addr;
// //             mem_regwren  <= ex_regwren;
// //             mem_memren   <= ex_memren;
// //             mem_memwren  <= ex_memwren;
// //             mem_wbsel    <= ex_wbsel;
// //         end
// //     end

// //     // =========================================================================
// //     // 4. MEMORY STAGE (MEM)
// //     // =========================================================================
// //     logic [DWIDTH-1:0] data_from_mem;

// //     memory u_mem (
// //         .clk         (clk),
// //         .rst         (reset),
// //         .addr_i      (mem_alu_res),
// //         .data_i      (mem_rs2_data),
// //         .read_en_i   (mem_memren),
// //         .write_en_i  (mem_memwren),
// //         .size_i      (2'b10), 
// //         .sign_en_i   (1'b1),
// //         .data_o      (data_from_mem),
// //         .insn_addr_i (if_pc),
// //         .insn_o      (if_insn)
// //     );

// //     // --- MEM/WB PIPELINE REGISTER ---
// //     logic [DWIDTH-1:0] wb_alu_res, wb_mem_data;
// //     logic [AWIDTH-1:0] wb_pc;
// //     logic [4:0]        wb_rd;
// //     logic              wb_regwren;
// //     logic [1:0]        wb_wbsel;

// //     always_ff @(posedge clk) begin
// //         if (reset) wb_regwren <= 0;
// //         else begin
// //             wb_pc       <= mem_pc;
// //             wb_alu_res  <= mem_alu_res;
// //             wb_mem_data <= data_from_mem;
// //             wb_rd       <= mem_rd;
// //             wb_regwren  <= mem_regwren;
// //             wb_wbsel    <= mem_wbsel;
// //         end
// //     end

// //     // =========================================================================
// //     // 5. WRITEBACK STAGE (WB)
// //     // =========================================================================
// //     logic [DWIDTH-1:0] wb_data;

// //     writeback u_wb (
// //         .pc_i             (wb_pc), 
// //         .alu_res_i        (wb_alu_res),
// //         .memory_data_i    (wb_mem_data),
// //         .brtaken_i        (1'b0), 
// //         .wbsel_i          (wb_wbsel),
// //         .writeback_data_o (wb_data)
// //     );

// //     // --- TERMINATION LOGIC ---
// //     always @(posedge clk) begin
// //         if (id_insn == 32'h00000073) begin
// //             $display("--- EBREAK Detected at PC %h ---", id_pc);
// //             $finish; 
// //         end
// //     end



// //         // =========================================================================
// //     // MONITOR SIGNALS FOR TESTBENCH
// //     // =========================================================================

// //     // --- Declared logic types for all monitor signals ---
// //     logic [AWIDTH-1:0]  assign_f_pc;
// //     logic [DWIDTH-1:0]  assign_f_insn;

// //     logic [AWIDTH-1:0]  assign_d_pc;
// //     logic [6:0]         assign_d_opcode;
// //     logic [4:0]         assign_d_rd;
// //     logic [4:0]         assign_d_rs1;
// //     logic [4:0]         assign_d_rs2;
// //     logic [2:0]         assign_d_funct3;
// //     logic [6:0]         assign_d_funct7;
// //     logic [DWIDTH-1:0]  assign_d_imm;
// //     logic [4:0]         assign_d_shamt;       // shamt is bits [24:20]

// //     // R (register file) stage monitor signals
// //     logic              assign_r_write_enable;
// //     logic [4:0]        assign_r_write_destination;
// //     logic [DWIDTH-1:0] assign_r_write_data;
// //     logic [4:0]        assign_r_read_rs1;     // was missing declaration
// //     logic [4:0]        assign_r_read_rs2;     // was missing declaration
// //     logic [DWIDTH-1:0] assign_r_read_rs1_data;
// //     logic [DWIDTH-1:0] assign_r_read_rs2_data;

// //     logic [AWIDTH-1:0]  assign_e_pc;
// //     logic [DWIDTH-1:0]  assign_e_alu_res;
// //     logic               assign_e_br_taken;

// //     logic [AWIDTH-1:0]  assign_m_pc;
// //     logic [AWIDTH-1:0]  assign_m_address;     // was missing declaration
// //     logic [1:0]         assign_m_size_encoded; // was missing declaration
// //     logic [DWIDTH-1:0]  assign_m_data;

// //     logic [AWIDTH-1:0]  assign_w_pc;
// //     logic               assign_w_write_enable;
// //     logic [4:0]         assign_w_write_destination;
// //     logic [DWIDTH-1:0]  assign_w_data;

// //     // --- F stage ---
// //     assign assign_f_pc   = if_pc;
// //     assign assign_f_insn = if_insn;

// //     // --- D stage ---
// //     assign assign_d_pc     = id_pc;
// //     assign assign_d_opcode = id_insn[6:0];
// //     assign assign_d_rd     = id_rd_addr;
// //     assign assign_d_rs1    = id_rs1_addr;
// //     assign assign_d_rs2    = id_rs2_addr;
// //     assign assign_d_funct3 = id_insn[14:12];
// //     assign assign_d_funct7 = id_insn[31:25];
// //     assign assign_d_imm    = id_imm;
// //     assign assign_d_shamt  = id_insn[24:20];  // shamt lives in rs2 field

// //     // --- R (register file) stage ---
// //     // Read side: what addresses and data are being read this cycle (from ID stage)
// //     assign assign_r_read_rs1      = id_rs1_addr;
// //     assign assign_r_read_rs2      = id_rs2_addr;
// //     assign assign_r_read_rs1_data = id_rs1_data;
// //     assign assign_r_read_rs2_data = id_rs2_data;
// //     // Write side: what is being written this cycle (from WB stage)
// //     assign assign_r_write_enable      = wb_regwren;
// //     assign assign_r_write_destination = wb_rd;
// //     assign assign_r_write_data        = wb_data;

// //     // --- E stage ---
// //     assign assign_e_pc       = ex_pc;
// //     assign assign_e_alu_res  = alu_res_internal;
// //     assign assign_e_br_taken = brtaken;

// //     // --- M stage ---
// //     assign assign_m_pc           = mem_pc;
// //     assign assign_m_address      = mem_alu_res;
// //     assign assign_m_size_encoded = (mem_memren || mem_memwren) ? 2'b10 : 2'b00;
// //     assign assign_m_data         = mem_rs2_data;

// //     // --- W stage ---
// //     assign assign_w_pc                = wb_pc;
// //     assign assign_w_write_enable      = wb_regwren;
// //     assign assign_w_write_destination = wb_rd;
// //     assign assign_w_data              = wb_data;


// // endmodule : pd5
















// `include "constants.svh"

// module pd5 #(
//     parameter int AWIDTH = 32,
//     parameter int DWIDTH = 32,
//     parameter logic [31:0] BASEADDR = 32'h01000000
// )(
//     input logic clk,
//     input logic reset
// );

//     // --- GLOBAL CONTROL SIGNALS ---
//     logic stall;
//     logic brtaken;
//     logic [AWIDTH-1:0] br_target;

//     // --- PIPELINE SIGNAL DECLARATIONS ---
//     // IF Signals
//     logic [AWIDTH-1:0] if_pc;
//     logic [DWIDTH-1:0] if_insn;

//     // ID Signals
//     logic [AWIDTH-1:0] id_pc;
//     logic [DWIDTH-1:0] id_insn;
//     logic [4:0]        id_rs1_addr, id_rs2_addr, id_rd_addr;
//     logic [DWIDTH-1:0] id_imm, id_rs1_data, id_rs2_data;
//     logic              id_regwren_ctrl, id_memren_ctrl, id_memwren_ctrl, id_regwren;
//     logic [3:0]        id_alusel;
//     logic              id_rs1sel, id_rs2sel, id_memren, id_memwren;
//     logic [1:0]        id_wbsel;
    
//     // Unused wires to satisfy module ports
//     logic              id_pcsel, id_immsel;
//     logic [AWIDTH-1:0] id_pc_out;
//     logic [6:0]        id_opcode_out, id_funct7_out;
//     logic [2:0]        id_funct3_out;

//     // EX Signals
//     logic [AWIDTH-1:0] ex_pc;
//     logic [DWIDTH-1:0] ex_rs1_data, ex_rs2_data, ex_imm;
//     logic [3:0]        ex_alusel;
//     logic [6:0]        ex_opcode;
//     logic [2:0]        ex_funct3;
//     logic              ex_rs1sel, ex_rs2sel, ex_regwren, ex_memren, ex_memwren;
//     logic [4:0]        ex_rd_addr, ex_rs1_addr, ex_rs2_addr;
//     logic [1:0]        ex_wbsel;

//     // MEM Signals
//     logic [DWIDTH-1:0] mem_alu_res, mem_rs2_data;
//     logic [AWIDTH-1:0] mem_pc;
//     logic [4:0]        mem_rd;
//     logic              mem_regwren, mem_memren, mem_memwren;
//     logic [1:0]        mem_wbsel;

//     // WB Signals
//     logic [DWIDTH-1:0] wb_alu_res, wb_mem_data, wb_data;
//     logic [AWIDTH-1:0] wb_pc;
//     logic [4:0]        wb_rd;
//     logic              wb_regwren;
//     logic [1:0]        wb_wbsel;

//     // =========================================================================
//     // 1. FETCH STAGE (IF)
//     // =========================================================================
//     fetch #(DWIDTH, AWIDTH, BASEADDR) u_fetch (
//         .clk             (clk),
//         .rst             (reset),
//         .brtaken_i       (brtaken),
//         .stall_i         (stall),
//         .branch_target_i (br_target),
//         .pc_o            (if_pc),
//         .insn_o          (if_insn) 
//     );

//     // IF/ID Register
//     // IF/ID Register
//     always_ff @(posedge clk) begin
//         if (reset) begin
//             id_pc   <= 0; // Reset to the start address
//             id_insn <= 0; // Reset to a NOP (ADDI x0, x0, 0)
//         end else if (brtaken) begin
//             id_pc   <= '0;
//             id_insn <= 32'h00000013; // Flush on branch
//         end else if (!stall) begin
//             id_pc   <= if_pc;
//             id_insn <= if_insn; 
//         end
//     end

//     // =========================================================================
//     // 2. DECODE STAGE (ID)
//     // =========================================================================
//     control u_control (
//         .insn_i    (id_insn),
//         .opcode_i  (id_insn[6:0]),
//         .funct7_i  (id_insn[31:25]),
//         .funct3_i  (id_insn[14:12]),
//         .pcsel_o   (id_pcsel),
//         .immsel_o  (id_immsel),
//         .regwren_o (id_regwren_ctrl),
//         .memren_o  (id_memren_ctrl),
//         .memwren_o (id_memwren_ctrl),
//         .alusel_o  (id_alusel),
//         .rs1sel_o  (id_rs1sel),
//         .rs2sel_o  (id_rs2sel),
//         .wbsel_o   (id_wbsel)
//     );

//     decode u_decode (
//         .insn_i         (id_insn),
//         .pc_i           (id_pc),
//         .rd_ex_i        (ex_rd_addr),   
//         .memren_ex_i    (ex_memren),    
//         .brtaken_i      (brtaken),
//         .regwren_ctrl_i (id_regwren_ctrl),
//         .memren_ctrl_i  (id_memren_ctrl),
//         .memwren_ctrl_i (id_memwren_ctrl),
//         .stall_o        (stall),
//         .regwren_o      (id_regwren),
//         .memren_o       (id_memren),
//         .memwren_o      (id_memwren),
//         .pc_o           (id_pc_out),
//         .rd_o           (id_rd_addr),
//         .rs1_o          (id_rs1_addr),
//         .rs2_o          (id_rs2_addr),
//         .opcode_o       (id_opcode_out),
//         .funct3_o       (id_funct3_out),
//         .funct7_o       (id_funct7_out)
//     );

//     igen u_igen (
//         .opcode_i (id_insn[6:0]),
//         .insn_i   (id_insn),
//         .imm_o    (id_imm)
//     );

//     register_file u_regfile (
//         .clk       (clk),
//         .rst       (reset),
//         .rs1_i     (id_rs1_addr),
//         .rs2_i     (id_rs2_addr),
//         .rd_i      (wb_rd),   
//         .datawb_i  (wb_data),   
//         .regwren_i (wb_regwren),   
//         .rs1data_o (id_rs1_data),
//         .rs2data_o (id_rs2_data)
//     );

//     // ID/EX Register
//     always_ff @(posedge clk) begin
//         if (reset) begin
//             ex_pc <= '0; ex_imm <= '0; ex_alusel <= '0; ex_opcode <= '0;
//             ex_funct3 <= '0; ex_rs1sel <= '0; ex_rs2sel <= '0; ex_rd_addr <= '0;
//             ex_rs1_addr <= '0; ex_rs2_addr <= '0; ex_regwren <= '0;
//             ex_memren <= '0; ex_memwren <= '0; ex_wbsel <= '0;
//             ex_rs1_data <= '0; ex_rs2_data <= '0;
//         end else if (brtaken || stall) begin
//             ex_regwren <= 1'b0;
//             ex_memwren <= 1'b0;
//             ex_memren  <= 1'b0;
//         end else begin
//             ex_pc       <= id_pc;
//             ex_imm      <= id_imm;
//             ex_alusel   <= id_alusel;
//             ex_opcode   <= id_insn[6:0];
//             ex_funct3   <= id_insn[14:12];
//             ex_rs1sel   <= id_rs1sel;
//             ex_rs2sel   <= id_rs2sel;
//             ex_rd_addr  <= id_rd_addr;
//             ex_rs1_addr <= id_rs1_addr;
//             ex_rs2_addr <= id_rs2_addr;
//             ex_regwren  <= id_regwren;
//             ex_memren   <= id_memren;
//             ex_memwren  <= id_memwren;
//             ex_wbsel    <= id_wbsel;
//             ex_rs1_data <= id_rs1_data; 
//             ex_rs2_data <= id_rs2_data; 
//         end
//     end

//     // =========================================================================
//     // 3. EXECUTE STAGE (EX)
//     // =========================================================================
//     logic [DWIDTH-1:0] fwd_a_data, fwd_b_data, alu_op1, alu_op2, alu_res_internal;

//     always_comb begin
//         if (mem_regwren && (mem_rd != 0) && (mem_rd == ex_rs1_addr))
//             fwd_a_data = mem_alu_res;
//         else if (wb_regwren && (wb_rd != 0) && (wb_rd == ex_rs1_addr))
//             fwd_a_data = wb_data;
//         else
//             fwd_a_data = ex_rs1_data;

//         if (mem_regwren && (mem_rd != 0) && (mem_rd == ex_rs2_addr))
//             fwd_b_data = mem_alu_res;
//         else if (wb_regwren && (wb_rd != 0) && (wb_rd == ex_rs2_addr))
//             fwd_b_data = wb_data;
//         else
//             fwd_b_data = ex_rs2_data;
//     end

//     assign alu_op1 = (ex_rs1sel == `OP1_PC)  ? ex_pc  : fwd_a_data;
//     assign alu_op2 = (ex_rs2sel == `OP2_IMM) ? ex_imm : fwd_b_data;

//     alu #(DWIDTH, AWIDTH) u_alu (
//         .opcode_i  (ex_opcode),
//         .funct3_i  (ex_funct3),
//         .rs1_i     (alu_op1),
//         .rs2_i     (alu_op2),
//         .alusel_i  (ex_alusel),
//         .res_o     (alu_res_internal),
//         .brtaken_o (brtaken)
//     );

//     assign br_target = ex_pc + ex_imm;

//     // EX/MEM Register
//     always_ff @(posedge clk) begin
//         if (reset) begin
//             mem_pc <= '0; mem_alu_res <= '0; mem_rs2_data <= '0;
//             mem_rd <= '0; mem_regwren <= '0; mem_memren <= '0;
//             mem_memwren <= '0; mem_wbsel <= '0;
//         end else begin
//             mem_pc       <= ex_pc;
//             mem_alu_res  <= alu_res_internal;
//             mem_rs2_data <= fwd_b_data; 
//             mem_rd       <= ex_rd_addr;
//             mem_regwren  <= ex_regwren;
//             mem_memren   <= ex_memren;
//             mem_memwren  <= ex_memwren;
//             mem_wbsel    <= ex_wbsel;
//         end
//     end

//     // =========================================================================
//     // 4. MEMORY STAGE (MEM)
//     // =========================================================================
//     logic [DWIDTH-1:0] data_from_mem;

//     memory u_mem (
//         .clk         (clk),
//         .rst         (reset),
//         .addr_i      (mem_alu_res),
//         .data_i      (mem_rs2_data),
//         .read_en_i   (mem_memren),
//         .write_en_i  (mem_memwren),
//         .size_i      (2'b10), 
//         .sign_en_i   (1'b1),
//         .data_o      (data_from_mem),
//         .insn_addr_i (if_pc),
//         .insn_o      (if_insn)
//     );

//     // MEM/WB Register
//     always_ff @(posedge clk) begin
//         if (reset) begin
//             wb_pc <= '0; wb_alu_res <= '0; wb_mem_data <= '0;
//             wb_rd <= '0; wb_regwren <= '0; wb_wbsel <= '0;
//         end else begin
//             wb_pc       <= mem_pc;
//             wb_alu_res  <= mem_alu_res;
//             wb_mem_data <= data_from_mem;
//             wb_rd       <= mem_rd;
//             wb_regwren  <= mem_regwren;
//             wb_wbsel    <= mem_wbsel;
//         end
//     end

//     // =========================================================================
//     // 5. WRITEBACK STAGE (WB)
//     // =========================================================================
//     writeback u_wb (
//         .pc_i             (wb_pc), 
//         .alu_res_i        (wb_alu_res),
//         .memory_data_i    (wb_mem_data),
//         .brtaken_i        (1'b0), 
//         .wbsel_i          (wb_wbsel),
//         .writeback_data_o (wb_data)
//     );
// // --- MONITOR SIGNALS FOR TESTBENCH ---
//     // Declaring the logic types for the monitor signals
//     logic [AWIDTH-1:0] assign_f_pc, assign_d_pc, assign_e_pc, assign_m_pc, assign_w_pc;
//     logic [DWIDTH-1:0] assign_f_insn, assign_d_imm, assign_r_read_rs1_data, assign_r_read_rs2_data, assign_e_alu_res, assign_m_data, assign_w_data;
//     logic [6:0]        assign_d_opcode, assign_d_funct7;
//     logic [4:0]        assign_d_rd, assign_d_rs1, assign_d_rs2, assign_w_write_destination;
//     logic [2:0]        assign_d_funct3;
//     logic              assign_e_br_taken, assign_w_write_enable;
//     logic [4:0] assign_r_read_rs1, assign_r_read_rs2;
//     logic [AWIDTH-1:0] assign_m_address;
//     logic [1:0]        assign_m_size_encoded;
//     logic [4:0]        assign_r_write_destination;  // different from assign_w_write_destination
//     logic              assign_r_write_enable;
//     logic [DWIDTH-1:0] assign_r_write_data;
//     logic [4:0]        assign_d_shamt;

//     // The assignments
//     assign assign_f_pc = if_pc;
//     assign assign_f_insn = if_insn;
//     assign assign_d_pc = id_pc;
//     assign assign_d_opcode = id_insn[6:0];
//     assign assign_d_rd = id_rd_addr;
//     assign assign_d_rs1 = id_rs1_addr;
//     assign assign_d_rs2 = id_rs2_addr;
//     assign assign_d_funct3 = id_insn[14:12];
//     assign assign_d_funct7 = id_insn[31:25];
//     assign assign_d_imm = id_imm;
    
//     // The ones previously missing
//     assign assign_r_read_rs1 = id_rs1_addr;
//     assign assign_r_read_rs2 = id_rs2_addr;
//     assign assign_r_read_rs1_data = id_rs1_data;
//     assign assign_r_read_rs2_data = id_rs2_data;
    
//     assign assign_e_pc = ex_pc;
//     assign assign_e_alu_res = alu_res_internal;
//     assign assign_e_br_taken = brtaken;
    
//     assign assign_m_pc = mem_pc;
//     assign assign_m_address = mem_alu_res;
//     assign assign_m_data = mem_rs2_data;
//     assign assign_m_size_encoded = 2'b10;
    
//     assign assign_w_pc = wb_pc;
//     assign assign_w_write_enable = wb_regwren;
//     assign assign_w_write_destination = wb_rd;
//     assign assign_w_data = wb_data;

// endmodule


























`include "constants.svh"

module pd5 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32,
    parameter logic [31:0] BASEADDR = 32'h01000000
)(
    input logic clk,
    input logic reset
);

    // --- GLOBAL CONTROL SIGNALS ---
    logic stall;
    logic brtaken;
    logic [AWIDTH-1:0] br_target;

    // --- PIPELINE SIGNAL DECLARATIONS ---
    // IF Signals
    logic [AWIDTH-1:0] if_pc;
    logic [DWIDTH-1:0] if_insn;

    // ID Signals
    logic [AWIDTH-1:0] id_pc;
    logic [DWIDTH-1:0] id_insn;
    logic [4:0]        id_rs1_addr, id_rs2_addr, id_rd_addr;
    logic [DWIDTH-1:0] id_imm, id_rs1_data, id_rs2_data;
    logic              id_regwren_ctrl, id_memren_ctrl, id_memwren_ctrl, id_regwren;
    logic [3:0]        id_alusel;
    logic              id_rs1sel, id_rs2sel, id_memren, id_memwren;
    logic [1:0]        id_wbsel;

    // Unused wires to satisfy module ports
    logic              id_pcsel, id_immsel;
    logic [AWIDTH-1:0] id_pc_out;
    logic [6:0]        id_opcode_out, id_funct7_out;
    logic [2:0]        id_funct3_out;

    // EX Signals
    logic [AWIDTH-1:0] ex_pc;
    logic [DWIDTH-1:0] ex_rs1_data, ex_rs2_data, ex_imm;
    logic [3:0]        ex_alusel;
    logic [6:0]        ex_opcode;
    logic [2:0]        ex_funct3;
    logic              ex_rs1sel, ex_rs2sel, ex_regwren, ex_memren, ex_memwren;
    logic [4:0]        ex_rd_addr, ex_rs1_addr, ex_rs2_addr;
    logic [1:0]        ex_wbsel;

    // MEM Signals
    logic [DWIDTH-1:0] mem_alu_res, mem_rs2_data;
    logic [AWIDTH-1:0] mem_pc;
    logic [4:0]        mem_rd;
    logic              mem_regwren, mem_memren, mem_memwren;
    logic [1:0]        mem_wbsel;

    // WB Signals
    logic [DWIDTH-1:0] wb_alu_res, wb_mem_data, wb_data;
    logic [AWIDTH-1:0] wb_pc;
    logic [4:0]        wb_rd;
    logic              wb_regwren;
    logic [1:0]        wb_wbsel;

    // =========================================================================
    // 1. FETCH STAGE (IF)
    // =========================================================================
    fetch #(DWIDTH, AWIDTH, BASEADDR) u_fetch (
        .clk             (clk),
        .rst             (reset),
        .brtaken_i       (brtaken),
        .stall_i         (stall),
        .branch_target_i (br_target),
        .pc_o            (if_pc),
        .insn_o          (if_insn)
    );

    // IF/ID Register
    always_ff @(posedge clk) begin
        if (reset) begin
            id_pc   <= '0;
            id_insn <= '0;
        end else if (brtaken) begin
            id_pc   <= '0;
            id_insn <= '0; // Flush on branch
        end else if (!stall) begin
            id_pc   <= if_pc;
            id_insn <= if_insn;
        end
    end

    // =========================================================================
    // 2. DECODE STAGE (ID)
    // =========================================================================
    control u_control (
        .insn_i    (id_insn),
        .opcode_i  (id_insn[6:0]),
        .funct7_i  (id_insn[31:25]),
        .funct3_i  (id_insn[14:12]),
        .pcsel_o   (id_pcsel),
        .immsel_o  (id_immsel),
        .regwren_o (id_regwren_ctrl),
        .memren_o  (id_memren_ctrl),
        .memwren_o (id_memwren_ctrl),
        .alusel_o  (id_alusel),
        .rs1sel_o  (id_rs1sel),
        .rs2sel_o  (id_rs2sel),
        .wbsel_o   (id_wbsel)
    );

    decode u_decode (
        .insn_i         (id_insn),
        .pc_i           (id_pc),
        .rd_ex_i        (ex_rd_addr),
        .memren_ex_i    (ex_memren),
        .brtaken_i      (brtaken),
        .regwren_ctrl_i (id_regwren_ctrl),
        .memren_ctrl_i  (id_memren_ctrl),
        .memwren_ctrl_i (id_memwren_ctrl),
        .stall_o        (stall),
        .regwren_o      (id_regwren),
        .memren_o       (id_memren),
        .memwren_o      (id_memwren),
        .pc_o           (id_pc_out),
        .rd_o           (id_rd_addr),
        .rs1_o          (id_rs1_addr),
        .rs2_o          (id_rs2_addr),
        .opcode_o       (id_opcode_out),
        .funct3_o       (id_funct3_out),
        .funct7_o       (id_funct7_out)
    );

    igen u_igen (
        .opcode_i (id_insn[6:0]),
        .insn_i   (id_insn),
        .imm_o    (id_imm)
    );

    register_file u_regfile (
        .clk       (clk),
        .rst       (reset),
        .rs1_i     (id_rs1_addr),
        .rs2_i     (id_rs2_addr),
        .rd_i      (wb_rd),
        .datawb_i  (wb_data),
        .regwren_i (wb_regwren),
        .rs1data_o (id_rs1_data),
        .rs2data_o (id_rs2_data)
    );

    // ID/EX Register
    always_ff @(posedge clk) begin
        if (reset) begin
            ex_pc       <= '0;
            ex_imm      <= '0;
            ex_alusel   <= '0;
            ex_opcode   <= '0;
            ex_funct3   <= '0;
            ex_rs1sel   <= '0;
            ex_rs2sel   <= '0;
            ex_rd_addr  <= '0;
            ex_rs1_addr <= '0;
            ex_rs2_addr <= '0;
            ex_regwren  <= '0;
            ex_memren   <= '0;
            ex_memwren  <= '0;
            ex_wbsel    <= '0;
            ex_rs1_data <= '0;
            ex_rs2_data <= '0;
        end else if (brtaken || stall) begin
        ex_regwren  <= 1'b0;
        ex_memwren  <= 1'b0;
        ex_memren   <= 1'b0;
        ex_opcode   <= '0;
        ex_rd_addr  <= '0;
        ex_rs1_addr <= '0;    // ADD THIS
        ex_rs2_addr <= '0;    // ADD THIS
        ex_wbsel    <= '0;
        end else begin
            ex_pc       <= id_pc;
            ex_imm      <= id_imm;
            ex_alusel   <= id_alusel;
            ex_opcode   <= id_insn[6:0];
            ex_funct3   <= id_insn[14:12];
            ex_rs1sel   <= id_rs1sel;
            ex_rs2sel   <= id_rs2sel;
            ex_rd_addr  <= id_rd_addr;
            ex_rs1_addr <= id_rs1_addr;
            ex_rs2_addr <= id_rs2_addr;
            ex_regwren  <= id_regwren;
            ex_memren   <= id_memren;
            ex_memwren  <= id_memwren;
            ex_wbsel    <= id_wbsel;
            ex_rs1_data <= id_rs1_data;
            ex_rs2_data <= id_rs2_data;
        end
    end

    // =========================================================================
    // 3. EXECUTE STAGE (EX)
    // =========================================================================
    logic [DWIDTH-1:0] fwd_a_data, fwd_b_data, alu_op1, alu_op2, alu_res_internal;
    logic [DWIDTH-1:0] data_from_mem;
    logic [DWIDTH-1:0] mem_fwd_data;

    assign mem_fwd_data = (mem_wbsel == 2'b01) ? data_from_mem : mem_alu_res;
    always_comb begin
        if (mem_regwren && (mem_rd != 0) && (mem_rd == ex_rs1_addr))
            fwd_a_data = mem_fwd_data;
        else if (wb_regwren && (wb_rd != 0) && (wb_rd == ex_rs1_addr))
            fwd_a_data = wb_data;
        else
            fwd_a_data = ex_rs1_data;

        if (mem_regwren && (mem_rd != 0) && (mem_rd == ex_rs2_addr))
            fwd_b_data = mem_fwd_data;
        else if (wb_regwren && (wb_rd != 0) && (wb_rd == ex_rs2_addr))
            fwd_b_data = wb_data;
        else
            fwd_b_data = ex_rs2_data;
    end

    assign alu_op1 = (ex_rs1sel == `OP1_PC)  ? ex_pc  : fwd_a_data;
    assign alu_op2 = (ex_rs2sel == `OP2_IMM) ? ex_imm : fwd_b_data;

    alu #(DWIDTH, AWIDTH) u_alu (
        .opcode_i  (ex_opcode),
        .funct3_i  (ex_funct3),
        .rs1_i     (alu_op1),
        .rs2_i     (alu_op2),
        .alusel_i  (ex_alusel),
        .res_o     (alu_res_internal),
        .brtaken_o (brtaken)
    );

    assign br_target = ex_pc + ex_imm;

    // EX/MEM Register
    always_ff @(posedge clk) begin
        if (reset) begin
            mem_pc      <= '0;
            mem_alu_res <= '0;
            mem_rs2_data <= '0;
            mem_rd      <= '0;
            mem_regwren <= '0;
            mem_memren  <= '0;
            mem_memwren <= '0;
            mem_wbsel   <= '0;
        end else begin
            mem_pc       <= ex_pc;
            mem_alu_res  <= alu_res_internal;
            mem_rs2_data <= fwd_b_data;
            mem_rd       <= ex_rd_addr;
            mem_regwren  <= ex_regwren;
            mem_memren   <= ex_memren;
            mem_memwren  <= ex_memwren;
            mem_wbsel    <= ex_wbsel;
        end
    end

    // =========================================================================
    // 4. MEMORY STAGE (MEM)
    // =========================================================================
    

    memory u_mem (
        .clk         (clk),
        .rst         (reset),
        .addr_i      (mem_alu_res),
        .data_i      (mem_rs2_data),
        .read_en_i   (mem_memren),
        .write_en_i  (mem_memwren),
        .size_i      (2'b10),
        .sign_en_i   (1'b1),
        .data_o      (data_from_mem),
        .insn_addr_i (if_pc),
        .insn_o      (if_insn)
    );

    // MEM/WB Register
    always_ff @(posedge clk) begin
        if (reset) begin
            wb_pc       <= '0;
            wb_alu_res  <= '0;
            wb_mem_data <= '0;
            wb_rd       <= '0;
            wb_regwren  <= '0;
            wb_wbsel    <= '0;
        end else begin
            wb_pc       <= mem_pc;
            wb_alu_res  <= mem_alu_res;
            wb_mem_data <= data_from_mem;
            wb_rd       <= mem_rd;
            wb_regwren  <= mem_regwren;
            wb_wbsel    <= mem_wbsel;
        end
    end

    // =========================================================================
    // 5. WRITEBACK STAGE (WB)
    // =========================================================================
    writeback u_wb (
        .pc_i             (wb_pc),
        .alu_res_i        (wb_alu_res),
        .memory_data_i    (wb_mem_data),
        .brtaken_i        (1'b0),
        .wbsel_i          (wb_wbsel),
        .writeback_data_o (wb_data)
    );

    // =========================================================================
    // MONITOR SIGNALS FOR TESTBENCH
    // =========================================================================

    // --- Declared logic types for all monitor signals ---
    logic [AWIDTH-1:0]  assign_f_pc;
    logic [DWIDTH-1:0]  assign_f_insn;

    logic [AWIDTH-1:0]  assign_d_pc;
    logic [6:0]         assign_d_opcode;
    logic [4:0]         assign_d_rd;
    logic [4:0]         assign_d_rs1;
    logic [4:0]         assign_d_rs2;
    logic [2:0]         assign_d_funct3;
    logic [6:0]         assign_d_funct7;
    logic [DWIDTH-1:0]  assign_d_imm;
    logic [4:0]         assign_d_shamt;       // shamt is bits [24:20]

    // R (register file) stage monitor signals
    logic              assign_r_write_enable;
    logic [4:0]        assign_r_write_destination;
    logic [DWIDTH-1:0] assign_r_write_data;
    logic [4:0]        assign_r_read_rs1;     // was missing declaration
    logic [4:0]        assign_r_read_rs2;     // was missing declaration
    logic [DWIDTH-1:0] assign_r_read_rs1_data;
    logic [DWIDTH-1:0] assign_r_read_rs2_data;

    logic [AWIDTH-1:0]  assign_e_pc;
    logic [DWIDTH-1:0]  assign_e_alu_res;
    logic               assign_e_br_taken;

    logic [AWIDTH-1:0]  assign_m_pc;
    logic [AWIDTH-1:0]  assign_m_address;     // was missing declaration
    logic [1:0]         assign_m_size_encoded; // was missing declaration
    logic [DWIDTH-1:0]  assign_m_data;

    logic [AWIDTH-1:0]  assign_w_pc;
    logic               assign_w_write_enable;
    logic [4:0]         assign_w_write_destination;
    logic [DWIDTH-1:0]  assign_w_data;

    // --- F stage ---
    assign assign_f_pc   = if_pc;
    assign assign_f_insn = if_insn;

    // --- D stage ---
    assign assign_d_pc     = id_pc;
    assign assign_d_opcode = id_insn[6:0];
    assign assign_d_rd     = id_rd_addr;
    assign assign_d_rs1    = id_rs1_addr;
    assign assign_d_rs2    = id_rs2_addr;
    assign assign_d_funct3 = id_insn[14:12];
    assign assign_d_funct7 = id_insn[31:25];
    assign assign_d_imm    = id_imm;
    assign assign_d_shamt  = id_insn[24:20];  // shamt lives in rs2 field

    // --- R (register file) stage ---
    // Read side: what addresses and data are being read this cycle (from ID stage)
    assign assign_r_read_rs1      = id_rs1_addr;
    assign assign_r_read_rs2      = id_rs2_addr;
    assign assign_r_read_rs1_data = id_rs1_data;
    assign assign_r_read_rs2_data = id_rs2_data;
    // Write side: what is being written this cycle (from WB stage)
    assign assign_r_write_enable      = wb_regwren;
    assign assign_r_write_destination = wb_rd;
    assign assign_r_write_data        = wb_data;

    // --- E stage ---
    assign assign_e_pc       = ex_pc;
    assign assign_e_alu_res  = alu_res_internal;
    assign assign_e_br_taken = brtaken;

    // --- M stage ---
    assign assign_m_pc           = mem_pc;
    assign assign_m_address      = mem_alu_res;
    assign assign_m_size_encoded = (mem_memren || mem_memwren) ? 2'b10 : 2'b00;
    assign assign_m_data         = mem_rs2_data;

    // --- W stage ---
    assign assign_w_pc                = wb_pc;
    assign assign_w_write_enable      = wb_regwren;
    assign assign_w_write_destination = wb_rd;
    assign assign_w_data              = wb_data;

endmodule