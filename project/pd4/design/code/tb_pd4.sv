`timescale 1ns/1ps
`define MEM_DEPTH 1024  // or whatever your memory depth is
`include "fetch.sv"
`include "decode.sv"
`include "control.sv"
`include "register_file.sv"
`include "execute.sv"
`include "memory.sv"
`include "writeback.sv"
module tb_pd4;

    parameter AWIDTH = 32;
    parameter DWIDTH = 32;

    // Inputs
    logic clk;
    logic reset;

    // Instantiate the top module
    pd4 #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH)
    ) dut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 10 ns period

    // Reset sequence
    initial begin
        reset = 1;
        #20;
        reset = 0;
    end

    // Load a small test program into memory
    initial begin
        // Clear memory first
        for (int i = 0; i < `MEM_DEPTH; i++) begin
            dut.mem_0.main_memory[i] = 8'h00;
        end

        // Program: add x1, x0, x0; addi x2, x0, 16; ecall
        // Encode instructions little-endian
        // add x1, x0, x0 -> 0x00000033
        dut.mem_0.main_memory[0] = 8'h33;
        dut.mem_0.main_memory[1] = 8'h00;
        dut.mem_0.main_memory[2] = 8'h00;
        dut.mem_0.main_memory[3] = 8'h00;

        // addi x2, x0, 16 -> 0x01000113
        dut.mem_0.main_memory[4] = 8'h13;
        dut.mem_0.main_memory[5] = 8'h01;
        dut.mem_0.main_memory[6] = 8'h00;
        dut.mem_0.main_memory[7] = 8'h00;

        // ecall -> 0x00000073
        dut.mem_0.main_memory[8]  = 8'h73;
        dut.mem_0.main_memory[9]  = 8'h00;
        dut.mem_0.main_memory[10] = 8'h00;
        dut.mem_0.main_memory[11] = 8'h00;
    end

    // Monitor key signals
    initial begin
        $display("Time\tPC\tInstr\tRS1\tRS2\tRD\tALUres\tMemData\tWBData\tx2");
        $monitor("%0t\t%h\t%h\t%h\t%h\t%h\t%h\t%h\t%h\t%h",
            $time,
            dut.pc_fetch,
            dut.instr_fetch,
            dut.rs1,
            dut.rs2,
            dut.rd,
            dut.alu_result,
            dut.mem_data,
            dut.wb_data,
            dut.rf_0.regs[2]   // stack pointer / x2
        );
    end

    // Simulation timeout
    initial begin
        #1000;
        $display("Simulation timeout, finishing");
        $finish;
    end

    // Dump waveform
    initial begin
        $dumpfile("pd4_tb.vcd");
        $dumpvars(0, tb_pd4);
    end

endmodule