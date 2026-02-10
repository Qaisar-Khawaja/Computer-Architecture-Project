/*
 * Module: decode
 *
 * Description: Decode stage
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) insn_iruction ins_i
 * 4) program counter pc_i
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide insn_iruction output insn_o
 * 3) 5-bit wide destination register ID rd_o
 * 4) 5-bit wide source 1 register ID rs1_o
 * 5) 5-bit wide source 2 register ID rs2_o
 * 6) 7-bit wide funct7 funct7_o
 * 7) 3-bit wide funct3 funct3_o
 * 8) 32-bit wide immediate imm_o
 * 9) 5-bit wide shift amount shamt_o
 * 10) 7-bit width opcode_o
 */


`include "constants.svh"

module decode #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
    // inputs
    input logic clk,
    input logic rst,
    input logic [DWIDTH - 1:0] insn_i,
    input logic [DWIDTH - 1:0] pc_i,

    // outputs
    output logic [AWIDTH-1:0] pc_o,
    output logic [DWIDTH-1:0] insn_o,
    output logic [6:0] opcode_o,
    output logic [4:0] rd_o,
    output logic [4:0] rs1_o,
    output logic [4:0] rs2_o,
    output logic [6:0] funct7_o,
    output logic [2:0] funct3_o,
    output logic [4:0] shamt_o,
    output logic [DWIDTH-1:0] imm_o
);

    // Assigning registers
    logic [2:0] funct3_r;
    logic [4:0] rs1_r, rs2_r, shamt_r, rd_r;
    logic [6:0] opcode_w, funct7_r;
    logic [DWIDTH-1:0] imm_r;

    // Assigning opcode for case statement
    assign opcode_w = insn_i[6:0];

    always_comb begin : Decode
        rd_r       = '0;
        rs1_r      = '0;
        rs2_r      = '0;
        funct3_r   = '0;
        funct7_r   = '0;
        imm_r      = '0;
        shamt_r    = '0;

        case(opcode_w)
            // R-Type
            `Opcode_RType: begin
                rd_r     = insn_i[11:7];
                funct3_r = insn_i[14:12];
                rs1_r    = insn_i[19:15];
                rs2_r    = insn_i[24:20];
                funct7_r = insn_i[31:25];
            end

            // I-Type Instructions (ALU: ADDI, SLTI, SLLI, etc.)
            `Opcode_IType: begin
                rd_r     = insn_i[11:7];
                funct3_r = insn_i[14:12];
                rs1_r    = insn_i[19:15];
                rs2_r    = 'd0; // I-types don't use rs2

                case(funct3_r)
                    // ADDI, SLTI, SLTIU, XORI, ORI, ANDI
                    3'h0, 3'h2, 3'h3, 3'h4, 3'h6, 3'h7: begin
                        imm_r    = {{DWIDTH-12{insn_i[31]}}, insn_i[31:20]};
                        shamt_r  = 'd0;
                        funct7_r = 'd0;
                    end

                    // SLLI, SRLI, SRAI
                    3'h1, 3'h5: begin
                        if(insn_i[31:25] == 7'h0 || insn_i[31:25] == 7'h20) begin
                            shamt_r  = insn_i[24:20];
                            imm_r    = {{DWIDTH-12{1'b0}}, insn_i[31:20]};
                            funct7_r = insn_i[31:25];
                        end
                        else begin
                            shamt_r  = 'd0;
                            imm_r    = 'd0;
                            funct7_r = 'd0;
                        end
                    end

                    default: begin
                        imm_r   = 'd0;
                        shamt_r = 'd0;
                    end
                endcase
            end

            // I-Type Load Instructions
            `Opcode_IType_Load: begin
                rd_r     = insn_i[11:7];
                funct3_r = insn_i[14:12];
                rs1_r    = insn_i[19:15];
                rs2_r    = 'd0;
                funct7_r = 'd0;
                shamt_r  = 'd0;
                imm_r    = {{DWIDTH-12{insn_i[31]}}, insn_i[31:20]};
            end

            // Jump and Link Register (JALR)
            `Opcode_IType_Jump_And_LinkReg: begin
                rd_r     = insn_i[11:7];
                funct3_r = insn_i[14:12];
                rs1_r    = insn_i[19:15];
                rs2_r    = 'd0;
                funct7_r = 'd0;
                shamt_r  = 'd0;
                imm_r    = {{DWIDTH-12{insn_i[31]}}, insn_i[31:20]};
            end

            // S-Type
            `Opcode_SType: begin
                funct3_r = insn_i[14:12];
                rs1_r    = insn_i[19:15];
                rs2_r    = insn_i[24:20];
                imm_r    = {{20{insn_i[31]}}, insn_i[31:25], insn_i[11:7]};
            end

            // B-Type
            `Opcode_BType: begin
                funct3_r = insn_i[14:12];
                rs1_r    = insn_i[19:15];
                rs2_r    = insn_i[24:20];
                imm_r    = {{19{insn_i[31]}}, insn_i[31], insn_i[7], insn_i[30:25], insn_i[11:8], 1'b0};
            end

            // U-Type
            `Opcode_UType_Load_Upper_Imm , `Opcode_UType_Add_Upper_Imm: begin
                rd_r     = insn_i[11:7];
                imm_r    = {insn_i[31:12], 12'h000};
            end

            // J-Type
            `Opcode_JType_Jump_And_Link: begin
                rd_r     = insn_i[11:7];
                imm_r    = {{DWIDTH-21{insn_i[31]}}, insn_i[31], insn_i[19:12], insn_i[20], insn_i[30:21], 1'b0};
            end

            default: begin
                rd_r     = '0;
                rs1_r    = '0;
                rs2_r    = '0;
                funct3_r = '0;
                funct7_r = '0;
                imm_r    = '0;
                shamt_r  = '0;
            end
        endcase
    end

    assign pc_o     = pc_i;
    assign insn_o   = insn_i;
    assign opcode_o = opcode_w;
    assign rd_o     = rd_r;
    assign rs1_o    = rs1_r;
    assign rs2_o    = rs2_r;
    assign funct3_o = funct3_r;
    assign funct7_o = funct7_r;
    assign shamt_o  = shamt_r;
    assign imm_o    = imm_r;

endmodule : decode