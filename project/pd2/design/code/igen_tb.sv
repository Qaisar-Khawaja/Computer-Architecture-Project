`timescale 1ns/1ps

module igen_tb;

    // Parameters and signals
    localparam DWIDTH = 32;
    logic [6:0]  opcode;
    logic [31:0] insn;
    logic [31:0] imm_out;
    logic [31:0] expected_imm;

    igen #( .DWIDTH(DWIDTH) ) uut (
        .opcode_i(opcode),
        .insn_i(insn),
        .imm_o(imm_out)
    );

    initial begin
        // Format for printing
        $display("Time\t Type\t\t\t\t Instruction\t Expected\t Actual\t\t Check");
        $display("--------------------------------------------------------------------------------------------------");

        // Test 1: I-Type addi
        opcode = 7'b0010011;
        insn   = 32'hFFB10093;
        expected_imm = 32'hFFFFFFFB;
        #10;
        $display("%0t\t I-Type addi\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");
        // Test 2: I-Type Max Positive
        opcode = 7'b0010011;
        insn = 32'h7FF00093;
        expected_imm = 32'h000007FF;
        #10;
        $display("%0t\t I-Type Max Positive\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 3: I-Type Max Negative
        opcode = 7'b0010011;
        insn = 32'h80000093;
        expected_imm = 32'hFFFFF800;
        #10;
        $display("%0t\t I-Type Max Negative\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");
        // Test 4: I-Type Zero Check
        opcode = 7'b0010011;
        insn = 32'h00000013;
        expected_imm = 32'h00000000;
        #10;
        $display("%0t\t I-Type Zero Check\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 5: I-Type Load
        opcode = 7'b0000011;
        insn   = 32'h02812083;
        expected_imm = 32'h00000028;
        #10;
        $display("%0t\t I-Type Load\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 6: I-Type All Ones
        opcode = 7'b0010011;
        insn = 32'hFFF00093;
        expected_imm = 32'hFFFFFFFF;
        #10;
        $display("%0t\t I-Type All Ones\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 7: I-Type JALR with positive offset
        opcode = 7'b1100111;
        insn   = 32'h00A100E7;
        expected_imm = 32'h0000000A;
        #10;
        $display("%0t\t I-Type JALR Positive Offset\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 8: I-Type JALR with negative offset
        opcode = 7'b1100111;
        insn   = 32'hFFC100E7;
        expected_imm = 32'hFFFFFFFC;
        #10;
        $display("%0t\t I-Type JALR Negative Offset\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 9: S-Type Max Negative
        opcode = 7'b0100011;
        insn = 32'h80000023;
        expected_imm = 32'hFFFFF800;
        #10;
        $display("%0t\t S-Type Max Negative\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");
        // Test 10: S-Type
        opcode = 7'b0100011;
        insn   = 32'h00512423;
        expected_imm = 32'h00000008;
        #10;
        $display("%0t\t S-Type\t\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 11: S-Type Max Positive
        opcode = 7'b0100011;
        insn = 32'h7E000FA3;
        expected_imm = 32'h000007FF;
        #10;
        $display("%0t\t S-Type Max Positive\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");
        // Test 12: S-Type Alternating Bits
        opcode = 7'b0100011;
        insn = 32'hAAA00523;
        expected_imm = 32'hFFFFFAAA;
        #10;
        $display("%0t\t S-Type Alternating Bits\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 13: B-Type
        opcode = 7'b1100011;
        insn   = 32'hFE208EE3;
        expected_imm = 32'hFFFFFFFC;
        #10;
        $display("%0t\t B-Type\t\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 14: B-Type Zero Offset
        opcode = 7'b1100011;
        insn = 32'h00000063;
        expected_imm = 32'h00000000;
        #10;
        $display("%0t\t B-Type Zero Offset\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 15: B-Type Min Negative(-2)
        opcode = 7'b1100011;
        insn = 32'hFE000FE3;
        expected_imm = 32'hFFFFFFFE;
        #10;
        $display("%0t\t B-Type Min Negative\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 16: B-Type Max Negative
        opcode = 7'b1100011;
        insn = 32'h80000063;
        expected_imm = 32'hFFFFF000;
        #10;
        $display("%0t\t B-Type Max Negative\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 17: B-Type Bit 11 Verification (Instruction bit 7 > Immediate bit 11)
        opcode = 7'b1100011;
        insn = 32'h000000E3;
        expected_imm = 32'h00000800;
        #10;
        $display("%0t\t B-Type Bit 11\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 18: B-Type Max Positive
        opcode = 7'b1100011;
        insn = 32'h7E000F63;
        expected_imm = 32'h000007FE;
        #10;
        $display("%0t\t B-Type Max Positive\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");
        //Test 19: J-Type
        opcode = 7'b1101111;
        insn   = 32'h001000ef;
        expected_imm = 32'h00000800;
        #10;
        $display("%0t\t J-Type\t\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 20: J-Type Max Positive Jump
        opcode = 7'b1101111;
        insn   = 32'h7FFFF0EF;
        expected_imm = 32'h000FFFFE;
        #10;
        $display("%0t\t J-Type Max Positive Jump\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 21: J-Type Maximum Negative Jump
        opcode = 7'b1101111;
        insn = 32'h800000ef;
        expected_imm = 32'hFFF00000;
        #10;
        $display("%0t\t J-Type Maximum Negative Jump\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");
        //Test 22: J-Type Bit 12 confirms instruction bits 19:12 map to immediate bits 19:12
        opcode = 7'b1101111;
        insn = 32'h000010ef;
        expected_imm = 32'h00001000;
        #10;
        $display("%0t\t J-Bit12\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 23: smallest Jump (+2) check instruction bit 21 maps to immediate bit 1 (bit 0 is always 0)
        opcode = 7'b1101111;
        insn = 32'h002000ef;
        expected_imm = 32'h00000002;
        #10;
        $display("%0t\t J-Small\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");
        // Test 24: U-Type
        opcode = 7'b0110111;
        insn   = 32'h123450B7;
        expected_imm = 32'h12345000;
        #10;
        $display("%0t\t U-Type\t\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 25: U-Type Maximum
        opcode = 7'b0110111;
        insn = 32'hFFFFF0B7;
        expected_imm = 32'hFFFFF000;
        #10;
        $display("%0t\t U-Type Maximum\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 26: U-Type Minimum
        opcode = 7'b0110111;
        insn = 32'h000010b7;
        expected_imm = 32'h00001000;
        #10;
        $display("%0t\t U-Min\t\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");
        //Test 27: U-Type Padding and Bit Capture Check
        opcode = 7'b0010111;
        insn = 32'hABCDE097;
        expected_imm = 32'hABCDE000;
        #10;
        $display("%0t\t U-Type Padding_Bits\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        //Test 28: U-Type MSB Only checks that bit 31 of the instruction maps to bit 31 of the output 
        opcode = 7'b0110111;
        insn = 32'h800000B7;
        expected_imm = 32'h80000000;
        #10;
        $display("%0t\t U-Type-MSB\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        // Test 29: Default Case (R-Type)
        opcode = 7'b0110011;
        insn   = 32'h00A582B3;
        expected_imm = 32'h00000000;
        #10;
        $display("%0t\t Default/R-Type\t\t\t %H\t %H\t %H\t %s", $time, insn, expected_imm, imm_out, (imm_out === expected_imm) ? "PASS" : "FAIL !!!");

        $display("--------------------------------------------------------------------------------------------------");
        $finish;
    end

endmodule