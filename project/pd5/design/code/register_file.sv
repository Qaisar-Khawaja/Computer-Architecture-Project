/*
 * Module: register_file
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD4 -----------
 *
 */
module register_file #(
     parameter int DWIDTH=32
 )(
     // inputs
     input logic                clk,
     input logic                rst,
     input logic [4:0]          rs1_i,
     input logic [4:0]          rs2_i,
     input logic [4:0]          rd_i,
     input logic [DWIDTH-1:0]   datawb_i,
     input logic                regwren_i,
     
     // outputs
     output logic [DWIDTH-1:0] rs1data_o,
     output logic [DWIDTH-1:0] rs2data_o
 );

     /*
     * Register File (32 entries).
     * Entry x0 is hardwired to zero.
     * Entry x2 is initialized to the stack pointer.
     */
    logic [DWIDTH-1:0] regs [31:0];
    
    integer i;

    // Sequential write
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= (i == 2) ? 32'h01100000 : 0;
            end
        end
        else if (regwren_i && rd_i != 0) begin
            regs[rd_i] <= datawb_i;
        end
    end

    // Combinational read with same-cycle WB bypass.
    // This lets decode observe the value being written in WB on the same cycle.
    assign rs1data_o = (rs1_i == 5'b0) ? '0 : regs[rs1_i];
    assign rs2data_o = (rs2_i == 5'b0) ? '0 : regs[rs2_i];

endmodule : register_file