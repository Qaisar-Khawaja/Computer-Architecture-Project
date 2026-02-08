/*
 * Module: control
 *
 * Description: This module sets the control bits (control path) based on the decoded
 * instruction. Note that this is part of the decode stage but housed in a separate
 * module for better readability, debug and design purposes.
 *
 * Inputs:
 * 1) DWIDTH instruction ins_i
 * 2) 7-bit opcode opcode_i
 * 3) 7-bit funct7 funct7_i
 * 4) 3-bit funct3 funct3_i
 *
 * Outputs:
 * 1) 1-bit PC select pcsel_o
 * 2) 1-bit Immediate select immsel_o
 * 3) 1-bit register write en regwren_o
 * 4) 1-bit rs1 select rs1sel_o
 * 5) 1-bit rs2 select rs2sel_o
 * 6) k-bit ALU select alusel_o
 * 7) 1-bit memory read en memren_o
 * 8) 1-bit memory write en memwren_o
 * 9) 2-bit writeback sel wbsel_o
 */

`include "constants.svh"

module control #(
	parameter int DWIDTH=32
)(
	// inputs
    input logic [DWIDTH-1:0] insn_i,
    input logic [6:0] opcode_i,
    input logic [6:0] funct7_i,
    input logic [2:0] funct3_i,

    // outputs
    output logic pcsel_o,
    output logic immsel_o,
    output logic regwren_o,
    output logic rs1sel_o,
    output logic rs2sel_o,
    output logic memren_o,
    output logic memwren_o,
    output logic [1:0] wbsel_o,
    output logic [3:0] alusel_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */
    always_comb begin
        pcsel_o = `PC_NEXTLINE;
        immsel_o = 1'b0;
        regwren_o = 1'b0;
        rs1sel_o = `OP1_RS1;
        rs2sel_o = `OP2_RS2;
        memren_o = 1'b0;
        memwren_o = 1'b0;
        wbsel_o =  `WB_ALU;
        alusel_o = `ADD;
        
        
        case (opcode_i)
            `Opcode_RType: begin
                regwren_o = 1'b1;
                rs1sel_o = `OP1_RS1;
                rs2sel_o = `OP2_RS2;
                immsel_o = 1'b0;
                wbsel_o =  `WB_ALU;
                case (funct3_i)
                    3'h0: alusel_o = (funct7_i == 7'h20) ? `SUB : `ADD;
                    3'h4: alusel_o = `XOR;
                    3'h6: alusel_o = `OR;
                    3'h7: alusel_o = `AND;
                    3'h1: alusel_o = `SLL;
                    3'h5: alusel_o = (funct7_i == 7'h20) ? `SRA : `SRL;
                    3'h2: alusel_o = `SLT;
                    3'h3: alusel_o = `SLTU;
                endcase
                default:  alusel_o = ADD;
            end
            
            
            `Opcode_IType: begin
                regwren_o = 1'b1;
                rs2sel_o  = `OP2_IMM;
                immsel_o  = 1'b1;
                rs1sel_o = `OP1_RS1;
                wbsel_o =  `WB_ALU;
                case (funct3_i)
                    3'h0: alusel_o = `ADD;
                    3'h4: alusel_o = `XOR;
                    3'h6: alusel_o = `OR;
                    3'h7: alusel_o = `AND;
                    3'h1: alusel_o = `SLL;
                    3'h5: alusel_o = (funct7_i == 7'h20) ? `SRA : `SRL;
                    3'h2: alusel_o = `SLT;
                    3'h3: alusel_o = `SLTU;
                endcase
                default:  alusel_o = ADD;
            end

            `Opcode_IType_Load: begin
                regwren_o = 1'b1;
                rs1sel_o = `OP1_RS1;
                rs2sel_o  = `OP2_IMM;
                immsel_o  = 1'b1;
                memren_o  = 1'b1;
                wbsel_o   = `WB_MEM;
                alusel_o  = `ADD;
            end

            `Opcode_SType: begin
                regwren_o = 1'b0;
                rs1sel_o = `OP1_RS1;
                rs2sel_o  = `OP2_IMM;
                immsel_o  = 1'b1;
                memren_o  = 1'b1;
                wbsel_o   = `WB_ALU;
                alusel_o  = `ADD;
            end

            `Opcode_BType: begin
                regwren_o = 1'b0;
                rs1sel_o = `OP1_RS1;
                rs2sel_o  = `OP2_RS2;
                immsel_o  = 1'b1;
                pcsel_o  = 1'b0;
                wbsel_o   = `WB_ALU;
                alusel_o  = `SUB;

            end


            `Opcode_UType_Load_Upper_Imm: begin
                regwren_o = 1'b1;
                rs2sel_o  = `OP1_PC;
                rs2sel_o  = `OP2_IMM;
                immsel_o  = 1'b1;
                wbsel_o   = `WB_ALU;
                alusel_o  = `LUI; 
            end

            `Opcode_UType_Add_Upper_Imm: begin
                regwren_o = 1'b1;
                rs1sel_o  = `OP1_PC;
                rs2sel_o  = `OP2_IMM;
                immsel_o  = 1'b1;
                wbsel_o   = `WB_ALU;
                alusel_o  = `AUIPC;
            end

            `Opcode_JType_Jump_And_Link: begin
                regwren_o = 1'b1;
                rs1sel_o  = `OP1_PC;
                rs2sel_o  = `OP2_IMM;
                immsel_o  = 1'b1;
                pcsel_o   = `PC_JUMP;
                wbsel_o   = `WB_PC4;
                alusel_o  = `ADD;
            end

            `Opcode_IType_Jump_And_LinkReg: begin
                regwren_o = 1'b1;
                rs1sel_o  = `OP1_PC;
                rs2sel_o  = `OP2_IMM;
                pcsel_o   = `PC_JUMP;
                immsel_o  = 1'b1;
                alusel_o  = `ADD;
                wbsel_o   = `WB_PC4;
            end //

            default: ; 
        endcase
    end
endmodule


