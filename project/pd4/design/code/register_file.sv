/*
 * Module: register_file
 *
 * Description: Register file 
 *
 * -------- REPLACE THIS FILE WITH THE RF MODULE DEVELOPED IN PD4 -----------
 *
 */
module register_file #(
     parameter int DWIDTH=32
 )(
     // inputs
     input logic clk,
     input logic rst,
     input logic [4:0] rs1_i,
     input logic [4:0] rs2_i,
     input logic [4:0] rd_i,
     input logic [DWIDTH-1:0] datawb_i,
     input logic regwren_i,
     // outputs
     output logic [DWIDTH-1:0] rs1data_o,
     output logic [DWIDTH-1:0] rs2data_o
 );

    /*
     * Process definitions to be filled by
     * student below...
     */
    logic [DWIDTH-1:0] regs [31:0];
    integer i;

    // Sequential write
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 0;

            regs[2] <= 32'h01100000; // stack pointer
        end
        else begin
            if (regwren_i && rd_i != 0)
                regs[rd_i] <= datawb_i;
        end
    end

    // Combinational read
    //Changed to match teh redudancy issue pointed by TA
    assign rs1data_o = regs[rs1_i];
    assign rs2data_o = regs[rs2_i];

endmodule : register_file