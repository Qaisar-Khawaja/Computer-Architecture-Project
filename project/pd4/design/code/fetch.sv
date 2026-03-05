/*
 * Module: fetch
 *
 * Description: Fetch stage
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) next_pc_i — next PC from the write-back stage (branch/jump target or PC+4)
 *
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide instruction output insn_o (unused; driven by memory Port B)
 */
module fetch #(
    parameter int DWIDTH=32,
    parameter int AWIDTH=32,
    parameter int BASEADDR=32'h01000000
    )(
    // inputs
    input  logic clk,
    input  logic rst,
    // Next PC feedback from write-back stage
    input  logic [AWIDTH-1:0] next_pc_i,
    // outputs
    output logic [AWIDTH-1:0] pc_o,
    output logic [DWIDTH-1:0] insn_o    // kept for port compatibility
);

    logic [AWIDTH-1:0] pc_reg;

    always_ff @(posedge clk) begin
        if (rst)
            pc_reg <= BASEADDR;
        else
            pc_reg <= next_pc_i;
    end

    assign pc_o   = pc_reg;
    assign insn_o = '0;   // actual instruction driven by memory module Port B

endmodule : fetch