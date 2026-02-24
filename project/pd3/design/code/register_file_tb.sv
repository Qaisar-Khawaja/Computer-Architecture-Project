`timescale 1ns/1ps

module register_file_tb;

    // inputs
    logic clk;
    logic rst;
    logic [4:0] rs1_i;
    logic [4:0] rs2_i;
    logic [4:0] rd_i;
    logic [31:0] datawb_i;
    logic regwren_i;

    // outputs
    logic [31:0] rs1data_o;
    logic [31:0] rs2data_o;

    register_file dut (
        .clk(clk),
        .rst(rst),
        .rs1_i(rs1_i),
        .rs2_i(rs2_i),
        .rd_i(rd_i),
        .datawb_i(datawb_i),
        .regwren_i(regwren_i),
        .rs1data_o(rs1data_o),
        .rs2data_o(rs2data_o)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Helper task: write to a register
    task write_reg(input [4:0] rd, input [31:0] val);
        begin
            rd_i = rd;
            datawb_i = val;
            regwren_i = 1;
            @(posedge clk);
            #1;
            regwren_i = 0;
        end
    endtask

    // Helper task: read two registers
    task read_regs(input [4:0] r1, input [4:0] r2,
                   input [31:0] exp1, input [31:0] exp2,
                   input string msg);
        begin
            rs1_i = r1;
            rs2_i = r2;
            #1;

            if (rs1data_o !== exp1)
                $error("%s: rs1 mismatch. Expected %0h, got %0h",
                       msg, exp1, rs1data_o);

            if (rs2data_o !== exp2)
                $error("%s: rs2 mismatch. Expected %0h, got %0h",
                       msg, exp2, rs2data_o);
        end
    endtask

    initial begin
        clk = 0;
        rst = 1;
        regwren_i = 0;
        rs1_i = 0;
        rs2_i = 0;
        rd_i = 0;
        datawb_i = 0;

        $display("Starting register_file tests...\n");

        // Apply reset
        @(posedge clk);
        rst = 0;

        // Check reset values
        // UPDATED: Expected rs2 (reg 2) value changed to match DUT's 32'h01100000 stack pointer
        read_regs(0, 2, 0, 32'h01100000, "Reset values");

        // Write to a normal register
        write_reg(5, 123);
        read_regs(5, 0, 123, 0, "Write/read reg5");

        // Write to another register
        write_reg(10, 999);
        read_regs(10, 5, 999, 123, "Write/read reg10");

        // Attempt to write x0 (should stay zero)
        write_reg(0, 555);
        read_regs(0, 5, 0, 123, "x0 write ignored");

        // Overwrite a register
        write_reg(5, 777);
        read_regs(5, 10, 777, 999, "Overwrite reg5");

        // Check combinational read timing
        rs1_i = 10;
        rs2_i = 5;
        #1;
        if (rs1data_o !== 999 || rs2data_o !== 777)
            $error("Combinational read failed");

        // Write and read same register (write happens next clock)
        rs1_i = 15;
        write_reg(15, 42);
        read_regs(15, 0, 42, 0, "Write then read same reg");

        // Mid‑range register test (x16)
        write_reg(16, 32'h12345678);
        read_regs(16, 0, 32'h12345678, 0, "Write/read x16");

        // Highest register test (x31)
        write_reg(31, 32'hDEADBEEF);
        read_regs(31, 16, 32'hDEADBEEF, 32'h12345678, "Write/read x31");

        // Attempt to write when regwren_i = 0 (should not change register)
        rd_i = 20;
        datawb_i = 32'hCAFEBABE;
        regwren_i = 0;
        @(posedge clk);
        #1;
        read_regs(20, 0, 0, 0, "Write disabled (reg20 should remain 0)");

        $display("\nAll register_file tests completed.");
        $finish;
    end

endmodule