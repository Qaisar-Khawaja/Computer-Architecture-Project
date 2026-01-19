/*
 * Module: pd1
 *
 * Description: Top level module that will contain sub-module instantiations.
 *
 * Inputs:
 * 1) clk
 * 2) reset signal
 */

module pd1 #(
    parameter int AWIDTH = 32,
    parameter int DWIDTH = 32)(
    input logic clk,
    input logic reset
);

 /*
  * Instantiate other submodules and
  * probes. To be filled by student...
  *
  */
//Fetch File
logic [DWIDTH-1:0] assign_fetch_inst_i;
logic [AWIDTH - 1:0] assign_fetch_pc_o;
logic [DWIDTH - 1:0] assign_fetch_insn_o;

fetch assign_fetch(
    .insn_o(assign_fetch_insn_o),
    .inst_i(assign_fetch_inst_i),
    .pc_o(assign_fetch_pc_o),
    .clk(clk),
    .rst(reset)
);


//Mmeory File

logic [AWIDTH-1:0] assign_memory_addr_i;
logic [DWIDTH-1:0] assign_memory_data_i;
logic assign_memory_read_en_i;
logic assign_memory_write_en_i;
logic [DWIDTH-1:0] assign_memory_data_o;

memory assign_memory(
    .clk(clk),
    .rst(reset),
    .addr_i(assign_memory_addr_i),
    .data_i(assign_memory_data_i),
    .read_en_i(assign_memory_read_en_i),
    .write_en_i(assign_memory_write_en_i),
    .data_o(assign_memory_data_o)
);


endmodule : pd1
