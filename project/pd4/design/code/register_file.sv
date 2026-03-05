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

    // Sequential write
    // Sequential write
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        integer i;
        for (i = 0; i < 32; i = i + 1)
            regs[i] <= '0;             // set all regs to 0
        regs[2] <= 32'h01100000;       // stack pointer
    end else begin
        if (regwren_i && rd_i != 0)
            regs[rd_i] <= datawb_i;
    end
end

    // Combinational read
    assign rs1data_o = (rs1_i == 0) ? 0 : regs[rs1_i];
    assign rs2data_o = (rs2_i == 0) ? 0 : regs[rs2_i];

endmodule : register_file