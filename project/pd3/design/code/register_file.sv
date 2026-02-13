/*
 * Module: register_file
 *
 * Description: Branch control logic. Only sets the branch control bits based on the
 * branch instruction
 *
 * Inputs:
 * 1) clk
 * 2) reset signal rst
 * 3) 5-bit rs1 address rs1_i
 * 4) 5-bit rs2 address rs2_i
 * 5) 5-bit rd address rd_i
 * 6) DWIDTH-wide data writeback datawb_i
 * 7) register write enable regwren_i
 * Outputs:
 * 1) 32-bit rs1 data rs1data_o
 * 2) 32-bit rs2 data rs2data_o
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
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            regs[0] <= 0;
            regs[2] <= 32'h7FFFFFFC; // stack pointer
        end else begin
            if (regwren_i && rd_i != 0)
                regs[rd_i] <= datawb_i;
        end
    end

    // Combinational read
    assign rs1data_o = (rs1_i == 0) ? 0 : regs[rs1_i];
    assign rs2data_o = (rs2_i == 0) ? 0 : regs[rs2_i];

endmodule : register_file
