`timescale 1ns/1ps

// Note: Ensure your "constants.svh" is included or compiled with this testbench 
// so the macros (`ADD, `SUB, etc.) are recognized.
`include "constants.svh"

module alu_tb;

    // inputs
    logic [31:0] pc_i;
    logic [31:0] rs1_i;
    logic [31:0] rs2_i;
    logic [2:0]  funct3_i;
    logic [6:0]  funct7_i;
    logic [3:0]  alusel_i; // ADDED: Required to drive the updated ALU

    // outputs
    logic [31:0] res_o;
    logic        brtaken_o;

    alu dut (
        .pc_i(pc_i),
        .rs1_i(rs1_i),
        .rs2_i(rs2_i),
        .funct3_i(funct3_i),
        .funct7_i(funct7_i),
        .alusel_i(alusel_i), // ADDED: Connected to DUT
        .res_o(res_o),
        .brtaken_o(brtaken_o)
    );

    // self check
    task check(input logic [31:0] exp_res,
               input logic        exp_br,
               input string       msg,
               input logic        check_res = 1'b1);
        begin
            #1; // wait for combinational logic to settle
            if (check_res && (res_o !== exp_res))
                $error("%s: res mismatch. Expected %0d (0x%08h), got %0d (0x%08h)",
                       msg, $signed(exp_res), exp_res, $signed(res_o), res_o);

            if (brtaken_o !== exp_br)
                $error("%s: brtaken mismatch. Expected %0b, got %0b",
                       msg, exp_br, brtaken_o);
        end
    endtask

    initial begin
        $display("=== Starting ALU tests ===");

        // Initialize unused signals to 0 to prevent 'X' values in simulation
        funct3_i = 3'b000;
        funct7_i = 7'b0000000;

        // -------------------------
        // Arithmetic ops
        // -------------------------
        pc_i = 32'h1000_0000;
        rs1_i = 10;
        rs2_i = 5;

        // TEST1: ADD
        alusel_i = `ADD;
        check(15, 0, "ADD");

        // TEST2: SUB
        alusel_i = `SUB;
        check(5, 0, "SUB");

        // -------------------------
        // Logical ops
        // -------------------------
        rs1_i = 32'h0F0F0F0F;
        rs2_i = 32'h00FF00FF;

        // TEST3: XOR
        alusel_i = `XOR;
        check(32'h0FF00FF0, 0, "XOR");

        // TEST4: OR
        alusel_i = `OR;
        check(32'h0FFF0FFF, 0, "OR");

        // TEST5: AND
        alusel_i = `AND;
        check(32'h000F000F, 0, "AND");

        // -------------------------
        // Shifts
        // -------------------------
        rs1_i = 32'h8000_0000;
        rs2_i = 4;

        // TEST6: SLL
        alusel_i = `SLL;
        check(32'h0000_0000, 0, "SLL");

        // TEST7: SRL
        alusel_i = `SRL;
        check(32'h0800_0000, 0, "SRL");

        // TEST8: SRA
        alusel_i = `SRA;
        check($signed(32'h8000_0000) >>> 4, 0, "SRA");

        // TEST9: SRL shift by 0
        rs1_i = 32'hF0000000;
        rs2_i = 0;
        alusel_i = `SRL;
        check(32'hF0000000, 0, "SRL shift by 0");

        // TEST10: SRA shift by 31
        rs1_i = 32'h80000000;
        rs2_i = 31;
        alusel_i = `SRA;
        check($signed(32'h80000000) >>> 31, 0, "SRA shift by 31");

        // TEST11: SLL shift by 31
        rs1_i = 32'h00000001;
        rs2_i = 31;
        alusel_i = `SLL;
        check(32'h80000000, 0, "SLL shift by 31");

        // -------------------------
        // SLT / SLTU
        // -------------------------

        // TEST12: SLT
        rs1_i = -5;
        rs2_i = 3;
        alusel_i = `SLT;
        check(1, 0, "SLT");

        // TEST13: SLTU
        alusel_i = `SLTU;
        check(0, 0, "SLTU");

        // TEST14: SLTU 1 < max
        rs1_i = 1;
        rs2_i = 32'hFFFF_FFFF;
        alusel_i = `SLTU;
        check(1, 0, "SLTU 1 < max");

        // -------------------------
        // Specialized Instructions (LUI / PCADD)
        // -------------------------

        // TEST15: PCADD
        pc_i = 32'h1000_0000;
        rs2_i = 32'h0000_0014;
        alusel_i = `PCADD;
        check(32'h1000_0014, 0, "PCADD");

        // TEST16: LUI
        rs1_i = 32'hDEAD_BEEF; // Shouldn't matter
        rs2_i = 32'h1234_5000;
        alusel_i = `LUI;
        check(32'h1234_5000, 0, "LUI");

        $display("=== ALU tests complete ===");
        $finish;
    end

endmodule