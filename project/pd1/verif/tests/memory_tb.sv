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

// TEST CASE 4
    // Verify that when read_en_i is 0, data_o is 0 
    offset = 4;
    addr_i = BASE_ADDR + offset;
    read_en_i = 0; 
    #1; 
    if (data_o == 32'h0) 
        $display("TEST 4 -  PASS (Output is 0 when Read Enable is LOW)");
    else 
        $display("TEST 4 - FAIL (Output should be 0, but got %h)", data_o);

    // TEST CASE 5 Combinational Read 
    // Verify data updates instantly without waiting for a clock edge
    offset = 32;
    read_en_i = 1;
    addr_i = BASE_ADDR + offset; 
    #1; 
    if (data_o == 32'hCAFEBABE)
        $display("TEST 5 - Comb. Timing:  PASS (Data changed instantly)");
    else
        $display("TEST 5 - Comb. Timing:  FAIL (Data did not update combinationally)");

    //TEST CASE 6
    // Write at offset 0, read at offset 1. checks if your main_memory[address + 1, +2, +3] logic works.
    offset = 0;
    write(offset, 32'hAABBCCDD); 
    
    // Reading from offset 1 should give: [Byte 4][Byte 3][Byte 2][Byte 1]
    read(1, actual_read_data);
    if (actual_read_data == 32'h00AABBCC)
        $display("TEST 6 - PASS (Offset 1 returned correct straddled bytes)");
    else
        $display("TEST 6 - FAIL (Got %h, expected 00AABBCC)", actual_read_data);


    // CASE 7
    //Ensure memory DOES NOT change if write_en_i is 0
    offset = 12; // Currently holds 12345678
    @(posedge clk);
    addr_i = BASE_ADDR + offset;
    data_i = 32'hFFFFFFFF; // Attempt to overwrite
    write_en_i = 0;        // But disable write
    @(posedge clk);
    read(offset, actual_read_data);
    if (actual_read_data == 32'h12345678)
        $display("TEST 8 - Write Protection: PASS (Memory did not overwrite)");
    else
        $display("TEST 8 - Write Protection: FAIL (Memory was overwritten!)");
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