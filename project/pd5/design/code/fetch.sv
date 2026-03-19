/*
 * Module: fetch
 *
 * Description: Fetch stage
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD1 -----------
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 *
 * Outputs:
 * 1) AWIDTH wide program counter pc_o
 * 2) DWIDTH wide instruction output insn_o
 */
module fetch #(
    parameter int DWIDTH    = 32,
    parameter int AWIDTH    = 32,
    parameter int BASEADDR  = 32'h01000000
    )(
    
    // inputs
    input  logic                clk,
    input  logic                rst,
    input  logic                brtaken_i,
    input  logic                stall_i,
    input logic [AWIDTH-1:0]    branch_target_i,
    
    // outputs
    output logic [AWIDTH-1:0] pc_o,
    output logic [DWIDTH-1:0] insn_o
);

    logic [AWIDTH-1:0] pc_reg;
    logic [AWIDTH-1:0] pc_plus4;
    logic [AWIDTH-1:0] next_pc;

    assign pc_plus4 = pc_reg + 4;
    
    // Select the next PC based on branch control
    assign next_pc =brtaken_i ? branch_target_i : pc_plus4;

    always_ff @(posedge clk) begin
        if (rst) begin
            pc_reg <= BASEADDR;
        end
        //Update PC if no stall occurs
        else if (!stall_i) begin
            pc_reg <= next_pc;
        end
    end

    assign pc_o   = pc_reg;

    /* Instruction output is kept for port compatibility
     * The actual instruction is driven by the memory module Port B
     */

    //assign insn_o = '0;


endmodule : fetch