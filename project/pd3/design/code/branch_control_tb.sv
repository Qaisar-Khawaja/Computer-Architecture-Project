`timescale 1ns/1ps

module branch_control_tb;

    // DUT inputs
    logic [6:0] opcode_i;
    logic [2:0] funct3_i;
    logic [31:0] rs1_i;
    logic [31:0] rs2_i;

    // DUT outputs
    logic breq_o;
    logic brlt_o;

    // Instantiate DUT
    branch_control dut (
        .opcode_i(opcode_i),
        .funct3_i(funct3_i),
        .rs1_i(rs1_i),
        .rs2_i(rs2_i),
        .breq_o(breq_o),
        .brlt_o(brlt_o)
    );

    // Self-checking task
    task run_test(input [31:0] a, input [31:0] b);
        begin
            rs1_i = a;
            rs2_i = b;

            #1; // allow combinational logic to settle

            $display("rs1=%0d  rs2=%0d  | breq=%0b  brlt=%0b",
                     a, b, breq_o, brlt_o);

            if (breq_o !== (a == b))
                $error("breq_o incorrect for rs1=%0d rs2=%0d", a, b);

            if (brlt_o !== ($signed(a) < $signed(b)))
                $error("brlt_o incorrect for rs1=%0d rs2=%0d", a, b);
        end
    endtask

    initial begin
        $display("Starting branch_control tests...\n");

        opcode_i = 7'b0;
        funct3_i = 3'b0;

        // Equal
        run_test(5, 5);
        run_test(0, 0);
        run_test(-1, -1);

        // rs1 < rs2
        run_test(1, 2);
        run_test(10, 100);

        // rs1 > rs2
        run_test(50, 10);

        // Signed negative comparisons
        run_test(-5, 3);
        run_test(3, -5);
        run_test(-10, -2);
        run_test(-1, -20);

        // Edge cases
        run_test(32'h80000000, 0);
        run_test(0, 32'h80000000);

        run_test(0, -1);   // 0 > -1, so brlt = 0
        run_test(-1, 0);   // -1 < 0, so brlt = 1

        $display("\nAll branch_control tests completed.");
        $finish;
    end

endmodule