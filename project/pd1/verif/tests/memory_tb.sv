`timescale 1ns/1ps

module memory_tb ();

localparam int AWIDTH = 32;
localparam int DWIDTH = 32;
localparam logic [31:0] BASE_ADDR = 32'h01000000;
localparam int CLK_PERIOD = 20;

logic clk;
logic rst;
logic [AWIDTH-1:0] addr_i;
logic [DWIDTH-1:0] data_i, data_o, expected_write_data, expected_read_data;
logic read_en_i;
logic write_en_i;


memory #(
  // parameters
  .AWIDTH   (32),
  .DWIDTH   (32),
  .BASE_ADDR (32'h01000000)
) dut (
  // inputs
  .clk                  (clk),
  .rst                  (rst),
  .addr_i               (addr_i),
  .data_i               (data_i), //32 bits
  .read_en_i            (read_en_i),
  .write_en_i           (write_en_i),
  // outputs
  .data_o               (data_o)
);

initial begin
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// try using test_patterns at the end of this file
integer offset = 0;
logic [DWIDTH-1:0] actual_read_data; 
wire  [DWIDTH-1:0] actual_write_data; 

assign actual_write_data = {
    dut.main_memory[offset + 3], 
    dut.main_memory[offset + 2], 
    dut.main_memory[offset + 1], 
    dut.main_memory[offset]
};

assign expected_read_data = {
    dut.main_memory[offset + 3], 
    dut.main_memory[offset + 2], 
    dut.main_memory[offset + 1], 
    dut.main_memory[offset]
};

initial begin
    read_en_i = 0;
    write_en_i = 0;
    expected_write_data = 0;
    rst = 1;
    #(CLK_PERIOD * 2);

    // TEST CASE 1
    offset = 4;
    expected_write_data = 32'hDEADBEEF;
    write(offset, expected_write_data); //offset 4 so will begin writing at 32'h01000004
    #1;
    if (actual_write_data == expected_write_data) begin
        $display("TEST 1 - Simple Write 1: PASS (EXPECTED: %h | ACTUAL: %h)", expected_write_data, actual_write_data); 
    end
    else begin
        $display("TEST 1 - Simple Write 1: FAIL (EXPECTED: %h | ACTUAL: %h)", expected_write_data, actual_write_data); 
    end

    // TEST CASE 2
    offset = 32;
    expected_write_data = 32'hCAFEBABE;
    write(offset, expected_write_data); //offset 4 so will begin writing at 32'h01000004
    #1;
    if (actual_write_data == expected_write_data) begin
        $display("TEST 2 - Simple Write 1: PASS (EXPECTED: %h | ACTUAL: %h)", expected_write_data, actual_write_data); 
    end
    else begin
        $display("TEST 2 - Simple Write 1: FAIL (EXPECTED: %h | ACTUAL: %h)", expected_write_data, actual_write_data); 
    end

// TEST CASE 3
    offset = 4;
    read(offset, actual_read_data);
    // No need for #1 if the task blocks until the clock edge
    if (actual_read_data == 32'hDEADBEEF) begin // Compare against the known value
        $display("TEST 3 - Simple Read 1: PASS (EXPECTED: %h | ACTUAL: %h)", 32'hDEADBEEF, actual_read_data); 
    end
    else begin
        $display("TEST 3 - Simple Read 1: FAIL (EXPECTED: %h | ACTUAL: %h)", 32'hDEADBEEF, actual_read_data); 
    end

    #1000;
    $finish;
end

task write(input int offset, input [DWIDTH-1:0] data_input);
    @(posedge clk);
    addr_i <= BASE_ADDR + offset;
    read_en_i <= 1'b0;
    write_en_i <= 1'b1;
    data_i <= data_input;
    @(posedge clk);
    write_en_i <= 1'b0;
endtask

task read(input int offset, output [DWIDTH-1:0] data_output);
    @(posedge clk);
    addr_i <= BASE_ADDR + offset;
    read_en_i <= 1'b1;
    write_en_i <= 1'b0;
    
    @(posedge clk);
    data_output = dut.data_o;
    read_en_i <= 1'b0;
endtask

endmodule