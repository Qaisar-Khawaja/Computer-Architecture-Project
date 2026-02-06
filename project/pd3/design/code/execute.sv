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
`include "constants.svh"
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
    logic [4:0] shamt;
    assign shamt = rs2_i[4:0];

    assign opa = (op1_sel_i == `OP1_PC)  ? pc_i       : rs1_data_i;
    assign opb = (op2_sel_i == `OP2_IMM) ? imm_i

    always_comb begin
    res_o = 32'b0;
        case (funct3_i)
            3'b000: begin // ADD or SUB
                if (funct7_i[5]) res_o = rs1_i - rs2_i; // `SUB
                else             res_o = rs1_i + rs2_i; // `ADD
            end
            3'b001: res_o = rs1_i << shamt;               // `SLL
            3'b010: res_o = ($signed(rs1_i) < $signed(rs2_i)) ? 32'b1 : 32'b0; // `SLT
            3'b011: res_o = (rs1_i < rs2_i) ? 32'b1 : 32'b0; // `SLTU
            3'b100: res_o = rs1_i ^ rs2_i;               // `XOR
            3'b101: begin // SRL or SRA
                if (funct7_i[5]) res_o = $signed(rs1_i) >>> shamt; // `SRA
                else             res_o = rs1_i >> shamt;           // `SRL
            end
            3'b110: res_o = rs1_i | rs2_i;               // `OR
            3'b111: res_o = rs1_i & rs2_i;               // `AND
            default: res_o = 32'b0;
        endcase
        
    end

endmodule : alu
