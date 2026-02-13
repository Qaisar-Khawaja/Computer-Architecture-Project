`timescale 1ns/1ps

module alu_tb;

    // DUT inputs
    logic [31:0] pc_i;
    logic [31:0] rs1_i;
    logic [31:0] rs2_i;
    logic [2:0]  funct3_i;
    logic [6:0]  funct7_i;

    // DUT outputs
    logic [31:0] res_o;
    logic        brtaken_o;

    // Instantiate DUT
    alu dut (
        .pc_i(pc_i),
        .rs1_i(rs1_i),
        .rs2_i(rs2_i),
        .funct3_i(funct3_i),
        .funct7_i(funct7_i),
        .res_o(res_o),
        .brtaken_o(brtaken_o)
    );

    // Self-checking helper
    task check(input [31:0] exp_res,
               input        exp_br,
               input string msg);
        begin
            #1;
            if (res_o !== exp_res)
                $error("%s: res mismatch. Expected %0d (0x%08h), got %0d (0x%08h)",
                       msg, $signed(exp_res), exp_res, $signed(res_o), res_o);

            if (brtaken_o !== exp_br)
                $error("%s: brtaken mismatch. Expected %0b, got %0b",
                       msg, exp_br, brtaken_o);
        end
    endtask

    initial begin
        pc_i = 32'h1000_0000;

        $display("=== Starting ALU tests ===");

        // -------------------------
        // ADD / SUB
        // -------------------------
        rs1_i = 10; rs2_i = 5;
        funct3_i = 3'b000; funct7_i = 7'b0000000; // ADD
        check(15, 0, "ADD");

        funct7_i = 7'b0100000; // SUB
        check(5, 0, "SUB");

        // -------------------------
        // Logical ops
        // -------------------------
        rs1_i = 32'h0F0F0F0F;
        rs2_i = 32'h00FF00FF;

        funct3_i = 3'b100; funct7_i = 0; // XOR
        check(32'h0FF00FF0, 0, "XOR");

        funct3_i = 3'b110; // OR
        check(32'h0FFF0FFF, 0, "OR");

        funct3_i = 3'b111; // AND
        check(32'h000F000F, 0, "AND");

        // -------------------------
        // Shifts
        // -------------------------
        rs1_i = 32'h8000_0000;
        rs2_i = 4;

        funct3_i = 3'b001; // SLL
        check(32'h0000_0000, 0, "SLL");

        funct3_i = 3'b101; funct7_i = 0; // SRL
        check(32'h0800_0000, 0, "SRL");

        funct7_i = 7'b0100000; // SRA
        check($signed(32'h8000_0000) >>> 4, 0, "SRA");

        // -------------------------
        // SLT / SLTU
        // -------------------------
        rs1_i = -5; rs2_i = 3;
        funct3_i = 3'b010; // SLT
        check(1, 0, "SLT");

        funct3_i = 3'b011; // SLTU
        check(0, 0, "SLTU");

        rs1_i = 1; rs2_i = 32'hFFFF_FFFF;
        funct3_i = 3'b011; // SLTU
        check(1, 0, "SLTU 1 < max");

        // -------------------------
        // Branch conditions
        // -------------------------
        rs1_i = 10; rs2_i = 10;

        funct3_i = 3'b000; // BEQ
        check(res_o, 1, "BEQ");

        funct3_i = 3'b001; // BNE
        check(res_o, 0, "BNE");

        rs1_i = 5; rs2_i = 10;

        funct3_i = 3'b100; // BLT
        check(res_o, 1, "BLT");

        funct3_i = 3'b101; // BGE
        check(res_o, 0, "BGE");

        funct3_i = 3'b110; // BLTU
        check(res_o, 1, "BLTU");

        funct3_i = 3'b111; // BGEU
        check(res_o, 0, "BGEU");

        // Shift by 0
        rs1_i = 32'hF0000000;
        rs2_i = 0;
        funct3_i = 3'b101; funct7_i = 0; // SRL
        check(32'hF0000000, 0, "SRL shift by 0");

        // Shift by 31
        rs1_i = 32'h80000000;
        rs2_i = 31;
        funct3_i = 3'b101; funct7_i = 7'b0100000; // SRA
        check($signed(32'h80000000) >>> 31, 0, "SRA shift by 31");

        rs1_i = 32'h00000001;
        rs2_i = 31;
        funct3_i = 3'b001; // SLL
        check(32'h80000000, 0, "SLL shift by 31");

        $display("=== ALU tests complete ===");
        $finish;
    end

endmodule