`timescale 1ns/1ps

module pd2_tb();
    // Parameters
    localparam int AWIDTH = 32;
    localparam int DWIDTH = 32;
    localparam int CLK_PERIOD = 10;

    logic clk, reset;

    pd2 #(
        .AWIDTH (32),
        .DWIDTH (32)
    ) dut (.*);

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

initial begin
        // 1. Initialize signals at Time 0
        reset = 1; 
        
        // 2. Hold reset for a few clock cycles (e.g., 2 cycles)
        #(CLK_PERIOD * 2);
        
        // 3. Release reset to start the processor
        reset = 0;
        
        // 4. Run simulation for a set time (e.g., 1000ns)
        #(CLK_PERIOD * 2);
        
        // 5. End simulation
        $finish;
    end

endmodule