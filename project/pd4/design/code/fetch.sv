/*
 * Module: fetch
 *
 * Description: Fetch stage
 *
 * -------- REPLACE THIS FILE WITH THE FETCH MODULE DEVELOPED IN PD1 -----------
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
    parameter int DWIDTH=32,
    parameter int AWIDTH=32,
    parameter int BASEADDR=32'h01000000
    )(
	// inputs
	input logic clk,
	input logic rst,
    input logic br_taken_i,  
    input logic [AWIDTH-1:0] target_addr_i, 
    //additional input for instruction input:
    // memory interface
    input logic [DWIDTH-1:0] instr_from_mem_i,
	// outputs	
	output logic [AWIDTH - 1:0] pc_o,
    output logic [DWIDTH - 1:0] insn_o
);

logic [AWIDTH-1:0] pc_reg;
    /*
     * Process definitions to be filled by
     * student below...
     */
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_reg <= BASEADDR;
        end
        else begin
            if (br_taken_i)
            pc_reg <= target_addr_i;   // branch or jump taken
        else
            pc_reg <= pc_reg + 32'd4;  // normal sequential fetch
    end
end

assign pc_o = pc_reg;
assign insn_o = instr_from_mem_i; 

endmodule : fetch