`include "constants.svh"

module alu #(
    parameter int DWIDTH = 32,
    parameter int AWIDTH = 32
)(
    input logic [AWIDTH-1:0]    pc_i,
    input logic [DWIDTH-1:0]    rs1_i,
    input logic [DWIDTH-1:0]    rs2_i,
    input logic [2:0]           funct3_i,
    input logic [6:0]           funct7_i,
    input logic [3:0]           alusel_i,
    output logic [DWIDTH-1:0]   res_o,
    output logic                brtaken_o
);
    /*
     * Arithmetic Logic Unit.
     * Computes results based on the alusel_i control signal.
     * Only the last 5 bits of the shift value are used.
     */
    always_comb begin: ALU
        case(alusel_i)
            `ADD: res_o = rs1_i + rs2_i;
            `SUB: res_o = rs1_i - rs2_i;
            `AND: res_o = rs1_i & rs2_i;
            `OR:  res_o = rs1_i | rs2_i;
            `XOR: res_o = rs1_i ^ rs2_i;
            `SLL: res_o = rs1_i << rs2_i[4:0];
            `SRL: res_o = rs1_i >> rs2_i[4:0];
            `SRA: res_o = $signed(rs1_i) >>> rs2_i[4:0];
            `SLT:  res_o = ($signed(rs1_i) < $signed(rs2_i)) ? 1 : 0;
            `SLTU: res_o = ($unsigned(rs1_i) < $unsigned(rs2_i)) ? 1:0;
            `LUI: res_o = rs2_i;
            default: res_o = 'd0;
        endcase
    end

    assign brtaken_o = 1'b0;

endmodule : alu