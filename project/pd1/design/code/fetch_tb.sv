`timescale 1ns/1ps

module fetch_tb ();

// Parameters
localparam int AWIDTH = 32;
localparam int DWIDTH = 32;
localparam logic [31:0] BASE_ADDR = 32'h01000000;
localparam int CLK_PERIOD = 20;

// is there a clock frequency req?

logic flag = 0;
logic clk = 0;
logic rst;
logic [AWIDTH-1:0] w_pc_o, expected_pc; // PC wire
logic [DWIDTH-1:0] w_insn_i, w_insn_o; // instruction wire

logic [31:0] mem [0:1023]; 

// load all the instructions
initial begin
    $readmemh("/cs/home/icabuent/Computer-Architecture-Project/project/pd1/verif/data/test1.x", mem); // loads hex values into memory
end

fetch #(
    .DWIDTH         (DWIDTH),
    .AWIDTH         (AWIDTH),
    .BASEADDR       (BASE_ADDR)
) fetch_test (
	// inputs
	.clk            (clk),
	.rst            (rst),
    //additional input for instruction input:
	// outputs	
	.pc_o            (w_pc_o),
    .insn_o          (w_insn_o)
);

// generate clock
initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
end

// first clk cycle should read from addr 01000000

initial begin
    expected_pc = BASE_ADDR;
    flag = 0;
    rst = 1;
    #(CLK_PERIOD * 2);
    rst = 0;

    $display("\n ------------ Starting Fetch Test ------------");
    repeat (10) @(posedge clk) begin
        if ($time <= (CLK_PERIOD * 3)) begin // check for the first cycle
            flag = 1;
            if (w_pc_o !== expected_pc) begin
                $display("FAIL: PC Increment Error! Expected %h, Got %h", expected_pc, w_pc_o);
            end else begin
                $display("PASS: PC correctly incremented to %h", w_pc_o);
            end
        end
        else begin
            // --- Subsequent Cycles Check ---
            // Calculate what the PC should be based on the last known good value
            if (w_pc_o !== (expected_pc + 4)) begin
                $display("FAIL: PC Increment Error! Expected %h, Got %h", (expected_pc + 4), w_pc_o);
            end else begin
                $display("PASS: PC correctly incremented to %h", w_pc_o);
            end
            // Update our tracker for the next loop iteration
            expected_pc = w_pc_o;
        end
    end
    $display("\n ------------ Finished Fetch Test ------------");
    #1000
    $finish;
end

endmodule