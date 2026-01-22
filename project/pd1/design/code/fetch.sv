/*
 * Module: fetch
 *
 * Description: Fetch stage
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
    parameter int DWIDTH = 32,
    parameter int AWIDTH = 32,
    parameter int BASEADDR = 32'h01000000
)(
	// inputs
	input logic clk,
	input logic rst,
    //additional input for instruction input
    input logic [DWIDTH-1:0] inst_i,
	// outputs	
	output logic [AWIDTH - 1:0] pc_o,
    output logic [DWIDTH - 1:0] insn_o
);
    /*
     * Process definitions to be filled by
     * student below...
     */
    always_ff @(posedge clk) begin
        if (rst) begin
            pc_o <= BASEADDR;
        end
        else begin
            pc_o <= pc_o +4;

        end
    end
    assign insn_o = inst_i;

endmodule : fetch
				
