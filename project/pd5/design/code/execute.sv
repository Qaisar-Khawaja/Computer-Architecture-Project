`include "constants.svh"

module alu #(
    parameter int DWIDTH = 32,
    parameter int AWIDTH = 32
)(
    input logic [6:0]           opcode_i, // Added to identify Branch vs Jump
    input logic [2:0]           funct3_i,
    input logic [DWIDTH-1:0]    rs1_i,    // Forwarded RS1 or PC
    input logic [DWIDTH-1:0]    rs2_i,    // Forwarded RS2 or IMM
    input logic [3:0]           alusel_i,
    output logic [DWIDTH-1:0]   res_o,
    output logic                brtaken_o
);

    // 1. Arithmetic & Logic Operations
    always_comb begin : ALU_Operations
        case(alusel_i)
            `ADD:  res_o = rs1_i + rs2_i;
            `SUB:  res_o = rs1_i - rs2_i;
            `AND:  res_o = rs1_i & rs2_i;
            `OR:   res_o = rs1_i | rs2_i;
            `XOR:  res_o = rs1_i ^ rs2_i;
            `SLL:  res_o = rs1_i << rs2_i[4:0];
            `SRL:  res_o = rs1_i >> rs2_i[4:0];
            `SRA:  res_o = $signed(rs1_i) >>> rs2_i[4:0];
            `SLT:  res_o = ($signed(rs1_i) < $signed(rs2_i)) ? 32'd1 : 32'd0;
            `SLTU: res_o = (rs1_i < rs2_i) ? 32'd1 : 32'd0;
            `LUI:  res_o = rs2_i;
            default: res_o = 32'd0;
        endcase
    end

    // 2. Branch Decision Logic
    always_comb begin : Branch_Logic
        brtaken_o = 1'b0; // Default: No branch
        
        case (opcode_i)
            // Jumps are always taken
            `Opcode_JType_Jump_And_Link, 
            `Opcode_IType_Jump_And_LinkReg: begin
                brtaken_o = 1'b1;
            end

            // Conditional Branches
            `Opcode_BType: begin
                case (funct3_i)
                    3'b000: brtaken_o = (rs1_i == rs2_i);                         // BEQ
                    3'b001: brtaken_o = (rs1_i != rs2_i);                         // BNE
                    3'b100: brtaken_o = ($signed(rs1_i) < $signed(rs2_i));        // BLT
                    3'b101: brtaken_o = ($signed(rs1_i) >= $signed(rs2_i));       // BGE
                    3'b110: brtaken_o = (rs1_i < rs2_i);                          // BLTU
                    3'b111: brtaken_o = (rs1_i >= rs2_i);                         // BGEU
                    default: brtaken_o = 1'b0;
                endcase
            end
            
            default: brtaken_o = 1'b0;
        endcase
    end

endmodule : alu