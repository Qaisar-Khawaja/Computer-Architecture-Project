`timescale 1ns/1ps
`include "constants.svh" 

module tb_memory;

    // =========================================================================
    // Parameters & Signals
    // =========================================================================
    parameter int AWIDTH = 32;
    parameter int DWIDTH = 32;
    parameter logic [31:0] BASE_ADDR = 32'h01000000;

    // Testbench signals
    logic clk;
    logic rst;
    logic [AWIDTH-1:0] addr_i;
    logic [DWIDTH-1:0] data_i;
    logic read_en_i;
    logic write_en_i;
    logic [1:0] size_i;
    logic sign_en_i;
    logic [DWIDTH-1:0] data_o;

    // Instruction port signals
    logic [AWIDTH-1:0] insn_addr_i;
    logic [DWIDTH-1:0] insn_o;

    int test_idx = 0;

    // =========================================================================
    // Instantiate memory
    // =========================================================================
    memory #(
        .AWIDTH(AWIDTH),
        .DWIDTH(DWIDTH),
        .BASE_ADDR(BASE_ADDR)
    ) dut (
        .clk(clk),
        .rst(rst),
        .addr_i(addr_i),
        .data_i(data_i),
        .read_en_i(read_en_i),
        .write_en_i(write_en_i),
        .size_i(size_i),
        .sign_en_i(sign_en_i),
        .data_o(data_o),
        .insn_addr_i(insn_addr_i),
        .insn_o(insn_o)
    );

    // =========================================================================
    // Clock Generation
    // =========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // =========================================================================
    // Helper Tasks
    // =========================================================================
    task check_result(
        input string op_type,
        input logic [AWIDTH-1:0] addr,
        input string size_str,
        input logic [DWIDTH-1:0] expected,
        input logic [DWIDTH-1:0] actual
    );
        string result_str;
        begin
            result_str = (actual === expected) ? "PASS" : "FAIL";
            $display("# %-2d     %08x     %-10s %-4s    %08x        %08x        %s", 
                     test_idx, addr, op_type, size_str, expected, actual, result_str);
            test_idx++;
        end
    endtask

    task mem_write(
        input logic [AWIDTH-1:0] addr,
        input logic [DWIDTH-1:0] data,
        input logic [1:0] size,
        input logic wen = 1'b1 // Default to 1, but can be overridden for edge cases
    );
        begin
            @(negedge clk);
            addr_i = addr;
            data_i = data;
            size_i = size;
            write_en_i = wen;
            read_en_i = 1'b0;
            @(negedge clk); // Wait for write to occur on posedge
            write_en_i = 1'b0;
        end
    endtask

    task mem_read(
        input logic [AWIDTH-1:0] addr,
        input logic [1:0] size,
        input logic sign_en,
        input string size_str,
        input logic [DWIDTH-1:0] expected,
        input logic ren = 1'b1 // Default to 1, but can be overridden for edge cases
    );
        begin
            @(negedge clk);
            addr_i = addr;
            size_i = size;
            sign_en_i = sign_en;
            read_en_i = ren;
            write_en_i = 1'b0;
            #1; // small delay for combinational read logic to settle
            check_result("READ", addr, size_str, expected, data_o);
            read_en_i = 1'b0;
        end
    endtask

    task check_insn(
        input logic [AWIDTH-1:0] addr,
        input logic [DWIDTH-1:0] expected
    );
        begin
            @(negedge clk);
            insn_addr_i = addr;
            #1; // Wait for combinational logic
            check_result("INSN_FETCH", addr, "WORD", expected, insn_o);
        end
    endtask

    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    initial begin
        // Initialize inputs
        rst = 1;
        addr_i = 0;
        data_i = 0;
        read_en_i = 0;
        write_en_i = 0;
        size_i = 0;
        sign_en_i = 0;
        insn_addr_i = BASE_ADDR;

        #15 rst = 0;

        // ---------------------------------------------------------------------
        $display("\n# --- PHASE 1: STANDARD READ/WRITE OPERATIONS ---");
        $display("# Idx    Address       Operation  Size    Expected        Actual          Result");
        $display("# ---------------------------------------------------------------------------------------");

        // Write a full word: 0xAABBCCDD at BASE_ADDR
        mem_write(BASE_ADDR, 32'hAABBCCDD, 2'b10);

        // Read full word back
        mem_read(BASE_ADDR, 2'b10, 1'b0, "WORD", 32'hAABBCCDD);

        // Read individual bytes (Little Endian check)
        mem_read(BASE_ADDR + 0, 2'b00, 1'b0, "BYTE", 32'h000000DD);
        mem_read(BASE_ADDR + 1, 2'b00, 1'b0, "BYTE", 32'h000000CC);
        mem_read(BASE_ADDR + 2, 2'b00, 1'b0, "BYTE", 32'h000000BB);
        mem_read(BASE_ADDR + 3, 2'b00, 1'b0, "BYTE", 32'h000000AA);

        // Read halfwords
        mem_read(BASE_ADDR + 0, 2'b01, 1'b0, "HALF", 32'h0000CCDD);
        mem_read(BASE_ADDR + 2, 2'b01, 1'b0, "HALF", 32'h0000AABB);


        // ---------------------------------------------------------------------
        $display("\n# --- PHASE 2: ENABLE SIGNAL RESTRICTIONS ---");
        $display("# Idx    Address       Operation  Size    Expected        Actual          Result");
        $display("# ---------------------------------------------------------------------------------------");

        // Try to write without write_en_i (should be ignored)
        mem_write(BASE_ADDR + 8, 32'hBADBAD11, 2'b10, 1'b0); // wen = 0
        mem_read(BASE_ADDR + 8, 2'b10, 1'b0, "WORD", 32'h00000000); // Assuming initialized to 0

        // Try to read without read_en_i (should output 0 based on your implementation)
        mem_write(BASE_ADDR + 12, 32'hCAFEBABE, 2'b10);
        mem_read(BASE_ADDR + 12, 2'b10, 1'b0, "NO_REN", 32'h00000000, 1'b0); // ren = 0


        // ---------------------------------------------------------------------
        $display("\n# --- PHASE 3: SIGN EXTENSION ---");
        $display("# Idx    Address       Operation  Size    Expected        Actual          Result");
        $display("# ---------------------------------------------------------------------------------------");

        // Write a byte with the MSB set (negative if signed)
        mem_write(BASE_ADDR + 4, 32'h000000F0, 2'b00);

        // Read it back unsigned vs signed
        mem_read(BASE_ADDR + 4, 2'b00, 1'b0, "U_BYTE", 32'h000000F0);
        mem_read(BASE_ADDR + 4, 2'b00, 1'b1, "S_BYTE", 32'hFFFFFFF0);

        // Write a halfword with the MSB set
        mem_write(BASE_ADDR + 6, 32'h00008005, 2'b01);

        // Read it back unsigned vs signed
        mem_read(BASE_ADDR + 6, 2'b01, 1'b0, "U_HALF", 32'h00008005);
        mem_read(BASE_ADDR + 6, 2'b01, 1'b1, "S_HALF", 32'hFFFF8005);


        // ---------------------------------------------------------------------
        $display("\n# --- PHASE 4: PARTIAL OVERWRITES (BYTE MASKING) ---");
        $display("# Idx    Address       Operation  Size    Expected        Actual          Result");
        $display("# ---------------------------------------------------------------------------------------");

        // Write a full word
        mem_write(BASE_ADDR + 32, 32'h11223344, 2'b10);

        // Overwrite only the second byte (index +1) with 0xFF
        mem_write(BASE_ADDR + 33, 32'h000000FF, 2'b00);

        // Read the word back. The expected result is Little Endian:
        mem_read(BASE_ADDR + 32, 2'b10, 1'b0, "WORD", 32'h1122FF44);


        // ---------------------------------------------------------------------
        $display("\n# --- PHASE 5: UNALIGNED ACCESSES ---");
        $display("# Idx    Address       Operation  Size    Expected        Actual          Result");
        $display("# ---------------------------------------------------------------------------------------");

        // Write a word starting at an unaligned address (BASE_ADDR + 1)
        mem_write(BASE_ADDR + 1, 32'h11223344, 2'b10);

        // Check the unaligned word read
        mem_read(BASE_ADDR + 1, 2'b10, 1'b0, "WORD", 32'h11223344);

        // Verify it didn't overwrite BASE_ADDR + 0 (Should be 0xDD from Phase 1)
        mem_read(BASE_ADDR + 0, 2'b00, 1'b0, "BYTE", 32'h000000DD);

        // Verify the bytes landed correctly
        mem_read(BASE_ADDR + 1, 2'b00, 1'b0, "BYTE", 32'h00000044);
        mem_read(BASE_ADDR + 4, 2'b00, 1'b0, "BYTE", 32'h00000011);


        // ---------------------------------------------------------------------
        $display("\n# --- PHASE 6: READ DURING WRITE ---");
        $display("# Idx    Address       Operation  Size    Expected        Actual          Result");
        $display("# ---------------------------------------------------------------------------------------");

        // Pre-fill a location
        mem_write(BASE_ADDR + 48, 32'h11111111, 2'b10);

        @(negedge clk);
        addr_i = BASE_ADDR + 48;
        data_i = 32'h99999999;
        size_i = 2'b10;
        write_en_i = 1'b1;
        read_en_i = 1'b1; // Both enabled

        #1;
        // Before posedge, combinational read should show the OLD data
        check_result("READ_OLD", addr_i, "WORD", 32'h11111111, data_o);

        @(posedge clk);
        #1;
        // After posedge, write has occurred, combinational read should show NEW data
        check_result("READ_NEW", addr_i, "WORD", 32'h99999999, data_o);

        @(negedge clk);
        write_en_i = 1'b0;
        read_en_i  = 1'b0;


        // ---------------------------------------------------------------------
        $display("\n# --- PHASE 7: INSTRUCTION PORT FETCHING ---");
        $display("# Idx    Address       Operation  Size    Expected        Actual          Result");
        $display("# ---------------------------------------------------------------------------------------");

        // Write an instruction to memory using the data port
        mem_write(BASE_ADDR + 16, 32'h00500093, 2'b10); // addi x1, x0, 5

        // Check if the instruction port fetches it correctly
        check_insn(BASE_ADDR + 16, 32'h00500093);

        // Check unaligned instruction fetch (if PC gets misaligned)
        mem_write(BASE_ADDR + 21, 32'hFFFFFFFF, 2'b10);
        check_insn(BASE_ADDR + 21, 32'hFFFFFFFF);


        // ---------------------------------------------------------------------
        $display("\n# --- PHASE 8: SIMULTANEOUS DUAL-PORT ACCESS ---");
        $display("# Idx    Address       Operation  Size    Expected        Actual          Result");
        $display("# ---------------------------------------------------------------------------------------");

        // Set up simultaneous data write and instruction fetch
        @(negedge clk);
        addr_i = BASE_ADDR + 40;     // Data write address
        data_i = 32'hFACEB00C;       // Data to write
        size_i = 2'b10;
        write_en_i = 1'b1;
        read_en_i = 1'b0;

        insn_addr_i = BASE_ADDR + 16; // Instruction fetch address (from Phase 7)

        #1; // Wait for combinational logic of instruction port
        // The instruction port should output the old data from Phase 7 (0x00500093)
        check_result("INSN_FETCH", insn_addr_i, "WORD", 32'h00500093, insn_o);

        @(negedge clk);
        write_en_i = 1'b0; // Drop write enable

        // Verify the write succeeded without breaking the fetch
        mem_read(BASE_ADDR + 40, 2'b10, 1'b0, "WORD", 32'hFACEB00C);


        // ---------------------------------------------------------------------
        $display("\n# --- PHASE 9: INSTRUCTION TRACE SIMULATION ---");
        $display("# Idx    Address       Operation  Size    Expected        Actual          Result");
        $display("# ---------------------------------------------------------------------------------------");

        // Load the program into memory
        mem_write(BASE_ADDR + 100, 32'hfd010113, 2'b10); // addi sp, sp, -48
        mem_write(BASE_ADDR + 104, 32'h02112623, 2'b10); // sw ra, 44(sp)
        mem_write(BASE_ADDR + 108, 32'h01112023, 2'b10); // sw a1, 0(sp)

        // Simulate the processor Fetching the instructions
        check_insn(BASE_ADDR + 100, 32'hfd010113);
        check_insn(BASE_ADDR + 104, 32'h02112623);
        check_insn(BASE_ADDR + 108, 32'h01112023);

        // Simulate the processor executing the 'sw' instructions
        $display("# -> Simulating CPU executing: sw ra, 44(sp)");
        mem_write(32'h010FFFFC, 32'hAAAAAAAA, 2'b10);
        mem_read(32'h010FFFFC, 2'b10, 1'b0, "WORD", 32'hAAAAAAAA);

        $display("# -> Simulating CPU executing: sw a1, 0(sp)");
        mem_write(32'h010FFFD0, 32'h11111111, 2'b10);
        mem_read(32'h010FFFD0, 2'b10, 1'b0, "WORD", 32'h11111111);


        // ---------------------------------------------------------------------
        $display("\n# --- PHASE 10: MORE EDGE CASES ---");
        $display("# Idx    Address       Operation  Size    Expected        Actual          Result");
        $display("# ---------------------------------------------------------------------------------------");

        // 1. Misaligned store word across word boundaries
        mem_write(BASE_ADDR + 3, 32'hAABBCCDD, 2'b10);
        mem_read(BASE_ADDR + 3, 2'b10, 1'b0, "WORD", 32'hAABBCCDD);

        // 2. Maximum signed halfword (0x7FFF) vs negative halfword (0x8000)
        mem_write(BASE_ADDR + 20, 32'h00008000, 2'b01);
        mem_read(BASE_ADDR + 20, 2'b01, 1'b1, "S_HALF", 32'hFFFF8000); // Should sign extend
        mem_read(BASE_ADDR + 20, 2'b01, 1'b0, "U_HALF", 32'h00008000); // Should zero extend

        // 3. Address wrap-around test (writing to absolute 0 which should wrap)
        mem_write(32'h00000000, 32'hDEADBEEF, 2'b10);
        mem_read(32'h00000000, 2'b10, 1'b0, "WORD", 32'hDEADBEEF);

        // 4. Wrap-around at memory limit
        mem_write(BASE_ADDR + `MEM_DEPTH - 1, 32'h12345678, 2'b10);
        mem_read(BASE_ADDR + `MEM_DEPTH - 1, 2'b10, 1'b0, "WRAP", 32'h12345678);

        $display("\n# --- SIMULATION COMPLETE ---");
        $finish;
    end

endmodule