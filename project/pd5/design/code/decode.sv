/*
 * Module: decode
 *
 * Description: Decode stage
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD2 -----------
 */
`include "constants.svh"

module decode #(
    parameter int DWIDTH = 32,
    parameter int AWIDTH = 32
)(
    input logic [DWIDTH - 1:0]  insn_i,
    input logic [AWIDTH - 1:0]  pc_i,

    // --- PIPELINE HAZARD INPUTS ---
    input logic [4:0]           rd_ex_i,      
    input logic                 memren_ex_i,  
    input logic                 brtaken_i,    

    // --- INPUTS FROM YOUR CONTROL MODULE ---
    input logic                 regwren_ctrl_i,
    input logic                 memren_ctrl_i,
    input logic                 memwren_ctrl_i,

    // --- OUTPUTS (With Hazard Overrides) ---
    output logic                stall_o,      
    output logic                regwren_o,    
    output logic                memren_o,     
    output logic                memwren_o,    
    
    // --- DATA PASS-THROUGH ---
    output logic [AWIDTH-1:0]   pc_o,
    output logic [4:0]          rd_o,
    output logic [4:0]          rs1_o,
    output logic [4:0]          rs2_o,
    output logic [6:0]          opcode_o,
    output logic [2:0]          funct3_o,
    output logic [6:0]          funct7_o
);

    // 1. Structural Parsing
    assign pc_o     = pc_i;
    assign opcode_o = insn_i[6:0];
    assign rd_o     = insn_i[11:7];
    assign funct3_o = insn_i[14:12];
    assign rs1_o    = insn_i[19:15];
    assign rs2_o    = insn_i[24:20];
    assign funct7_o = insn_i[31:25];

    // 2. Hazard & Control Logic
    always_comb begin
        // Start with the signals from your Control Module
        regwren_o = regwren_ctrl_i;
        memren_o  = memren_ctrl_i;
        memwren_o = memwren_ctrl_i;
        stall_o   = 1'b0;

        // --- LOAD-USE STALL ---
        if (memren_ex_i && (rd_ex_i != 0) && ((rd_ex_i == rs1_o) || (rd_ex_i == rs2_o))) begin
            stall_o   = 1'b1;
            regwren_o = 1'b0; // Kill the write
            memwren_o = 1'b0; // Kill the store
        end

        // --- BRANCH SQUASH ---
        if (brtaken_i) begin
            regwren_o = 1'b0;
            memwren_o = 1'b0;
            memren_o  = 1'b0;
        end
    end

endmodule