/*
 * Module: writeback
 *
 * Description: Write-back control stage implementation
 *
 * Inputs:
 * 1) PC pc_i
 * 2) result from alu alu_res_i
 * 3) data from memory memory_data_i
 * 4) data to select for write-back wbsel_i
 * 5) branch taken signal brtaken_i
 *
 * Outputs:
 * 1) DWIDTH wide write back data write_data_o
 * 2) AWIDTH wide next computed PC next_pc_o
 */

`include "constants.svh"

 module writeback #(
     parameter int DWIDTH = 32,
     parameter int AWIDTH = 32
 )(
     input logic [AWIDTH-1:0]   pc_i,
     input logic [DWIDTH-1:0]   alu_res_i,
     input logic [DWIDTH-1:0]   memory_data_i,
     input logic [1:0]          wbsel_i,
     output logic [DWIDTH-1:0]  writeback_data_o
 );

    /*
     * Writeback Logic
     * Selects between the ALU result, memory data, or the return 
     * address (PC + 4) to be written back to the register file
     */
    always_comb begin
        case(wbsel_i)
            `WB_ALU: begin
                writeback_data_o = alu_res_i;
            end
            `WB_MEM: begin
                writeback_data_o = memory_data_i;
            end
            `WB_PC4: begin
                writeback_data_o = pc_i + 4;
            end
            default: begin
                writeback_data_o = alu_res_i;
            end
        endcase


    end
 endmodule: writeback
