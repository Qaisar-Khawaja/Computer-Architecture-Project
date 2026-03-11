`timescale 1ns/1ps

module tb_pd4;

logic clk;
logic reset;
int cycle;

//////////////////////////////////////////////////
// DUT
//////////////////////////////////////////////////

pd4 dut(
    .clk(clk),
    .reset(reset)
);

//////////////////////////////////////////////////
// CLOCK
//////////////////////////////////////////////////

always #5 clk = ~clk;

//////////////////////////////////////////////////
// CYCLE COUNTER
//////////////////////////////////////////////////

always @(posedge clk)
cycle++;

//////////////////////////////////////////////////
// PIPELINE TRACE
//////////////////////////////////////////////////

task print_pipeline;
    $display("%3d | %8h | %8h | %8h | %8h | %8h",
        cycle,
        dut.assign_f_pc,
        dut.assign_d_pc,
        dut.assign_e_pc,
        dut.assign_m_pc,
        dut.assign_w_pc
    );
endtask

//////////////////////////////////////////////////
// HEADER
//////////////////////////////////////////////////

task print_header;
    $display("");
    $display("Cycle | Fetch_PC | Decode_PC | Execute_PC | Memory_PC | Writeback_PC");
    $display("--------------------------------------------------------------------");
endtask

//////////////////////////////////////////////////
// WAVEFORM (optional)
//////////////////////////////////////////////////

initial begin
    $dumpfile("pd4_wave.vcd");
    $dumpvars(0,tb_pd4);
end

//////////////////////////////////////////////////
// MAIN TEST
//////////////////////////////////////////////////

initial begin

    clk = 0;
    reset = 1;
    cycle = 0;

    print_header();

    // Reset
    #20;
    reset = 0;

    // Run simulation for 40 cycles
    repeat(40) begin
        @(posedge clk);
        print_pipeline();
    end

    $display("\nSimulation finished.\n");
    $finish;

end

endmodule

