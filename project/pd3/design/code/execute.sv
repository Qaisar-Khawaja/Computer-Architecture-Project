/*
 * Module: alu
 *
 * Description: ALU implementation for execute stage.
 *
 * Inputs:
 * 1) 32-bit PC pc_i
 * 2) 32-bit rs1 data rs1_i
 * 3) 32-bit rs2 data rs2_i
 * 4) 3-bit funct3 funct3_i
 * 5) 7-bit funct7 funct7_i
 *
 * Outputs:
 * 1) 32-bit result of ALU res_o
 * 2) 1-bit branch taken signal brtaken_o
 */

module alu #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32
)(
    input logic [AWIDTH-1:0] pc_i,
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
    input logic [2:0] funct3_i,
    input logic [6:0] funct7_i,
    output logic [DWIDTH-1:0] res_o,
    output logic brtaken_o
);

    /*
     * Process definitions to be filled by
     * student below...
     */
    logic signed [DWIDTH-1:0] srs1, srs2;
    assign srs1 = rs1_i;
    assign srs2 = rs2_i;

    always_comb begin
        res_o = 0;
        brtaken_o = 0;

        // -------------------------
        // ALU Operations
        // -------------------------
        unique case (funct3_i)

            // ADD / SUB / ADDI
            3'b000: begin
                if (funct7_i == 7'b0100000)
                    res_o = rs1_i - rs2_i;   // SUB
                else
                    res_o = rs1_i + rs2_i;   // ADD / ADDI
            end

            // SLL / SLLI
            3'b001: res_o = rs1_i << rs2_i[4:0];

            // SLT / SLTI
            3'b010: res_o = (srs1 < srs2);

            // SLTU / SLTIU
            3'b011: res_o = (rs1_i < rs2_i);

            // XOR / XORI
            3'b100: res_o = rs1_i ^ rs2_i;

            // SRL / SRA / SRLI / SRAI
            3'b101: begin
                if (funct7_i == 7'b0100000)
                    res_o = srs1 >>> rs2_i[4:0]; // SRA
                else
                    res_o = rs1_i >> rs2_i[4:0]; // SRL
            end

            // OR / ORI
            3'b110: res_o = rs1_i | rs2_i;

            // AND / ANDI
            3'b111: res_o = rs1_i & rs2_i;

        endcase

        // -------------------------
        // Branch decision logic
        // -------------------------
        case (funct3_i)
            3'b000: brtaken_o = (rs1_i == rs2_i);               // BEQ
            3'b001: brtaken_o = (rs1_i != rs2_i);               // BNE
            3'b100: brtaken_o = (srs1 < srs2);                  // BLT
            3'b101: brtaken_o = !(srs1 < srs2);                 // BGE
            3'b110: brtaken_o = (rs1_i < rs2_i);                // BLTU
            3'b111: brtaken_o = !(rs1_i < rs2_i);               // BGEU
            default: brtaken_o = 0;
        endcase
    end

endmodule : alu
