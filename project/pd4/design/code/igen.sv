/*
 * Module: igen
 *
 * Description: Immediate value generator
 * -------- REPLACE THIS FILE WITH THE IGEN MODULE DEVELOPED IN PD2 -----------
 */
`include "constants.svh"

module igen #(
    parameter int DWIDTH = 32
)(
    input  logic [6:0]        opcode_i,
    input  logic [DWIDTH-1:0] insn_i,
    output logic [31:0]       imm_o
);

    logic [11:0] store_holder;
    logic [12:0] branch_holder;
    logic [20:0] jump_holder;

    always_comb begin
        unique case (opcode_i)
            `Opcode_IType,
            `Opcode_IType_Jump_And_LinkReg,
            `Opcode_IType_Load: begin
                if (insn_i[31])
                    imm_o = {20'hFFFFF, insn_i[31:20]};
                else
                    imm_o = {20'h00000, insn_i[31:20]};
            end

            `Opcode_UType_Add_Upper_Imm,
            `Opcode_UType_Load_Upper_Imm: begin
                imm_o = {insn_i[31:12], 12'h000};
            end

            `Opcode_SType: begin
                store_holder = {insn_i[31:25], insn_i[11:7]};
                if (insn_i[31])
                    imm_o = {20'hFFFFF, store_holder};
                else
                    imm_o = {20'h00000, store_holder};
            end

            `Opcode_BType: begin
                branch_holder = {insn_i[31], insn_i[7], insn_i[30:25], insn_i[11:8], 1'b0};
                if (insn_i[31])
                    imm_o = {19'h7FFFF, branch_holder};
                else
                    imm_o = {19'h00000, branch_holder};
            end

            `Opcode_JType_Jump_And_Link: begin
                jump_holder = {insn_i[31], insn_i[19:12], insn_i[20], insn_i[30:21], 1'b0};
                if (insn_i[31])
                    imm_o = {11'h7FF, jump_holder};
                else
                    imm_o = {11'h000, jump_holder};
            end

            default: imm_o = 32'h00000000;
        endcase
    end

endmodule
