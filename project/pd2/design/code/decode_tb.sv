// AI was used in this testbench to:
// 1. come up with more testcases that might have been missed
// 2. to make it match igen and control testbenches, as it initially had a different format (so for reformatting only)

`timescale 1ns/1ps

module decode_tb();
    // Parameters
    localparam int AWIDTH = 32;
    localparam int DWIDTH = 32;
    localparam int CLK_PERIOD = 20;

    // Signals
    logic clk, rst;
    logic [DWIDTH-1:0] insn_i;
    logic [AWIDTH-1:0] pc_i;
    logic [DWIDTH-1:0] insn_o, imm_o;
    logic [AWIDTH-1:0] pc_o;
    logic [6:0] opcode_o, funct7_o;
    logic [4:0] rd_o, rs1_o, rs2_o, shamt_o;
    logic [2:0] funct3_o;

    // DUT Instance
    decode #( .DWIDTH(DWIDTH), .AWIDTH(AWIDTH) ) decode_inst (
        .clk(clk), .rst(rst),
        .insn_i(insn_i), .pc_i(pc_i),
        .pc_o(pc_o), .insn_o(insn_o),
        .opcode_o(opcode_o), .rd_o(rd_o), .rs1_o(rs1_o), .rs2_o(rs2_o),
        .funct7_o(funct7_o), .funct3_o(funct3_o), .shamt_o(shamt_o), .imm_o(imm_o)
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // -------------------------------------------------------------------------
    // Helper Tasks
    // -------------------------------------------------------------------------

    // Standard Check Task
// -------------------------------------------------------------------------
    // Helper Tasks (Fixed Formatting)
    // -------------------------------------------------------------------------
    // Standard Check Task
    task check(
        input string name,
        input logic [6:0] exp_opcode,
        input logic [4:0] exp_rd,
        input logic [4:0] exp_rs1,
        input logic [4:0] exp_rs2,
        input logic [2:0] exp_funct3,
        input logic [6:0] exp_funct7,
        input logic [31:0] exp_imm
    );
        @(posedge clk);
        @(posedge clk);
        #1;
        // Use %-8t to reserve 8 chars for Time, and %-24s for Name to match header alignment
        $display("%-8t %-24s %b    %2d      %2d      %2d      %h       %s",
            $time, name, opcode_o, rd_o, rs1_o, rs2_o, imm_o,
            (opcode_o === exp_opcode && rd_o === exp_rd && rs1_o === exp_rs1 &&
             rs2_o === exp_rs2 && funct3_o === exp_funct3 && funct7_o === exp_funct7 &&
             imm_o === exp_imm) ? "PASS" : "FAIL"
        );
    endtask

    // Special Check Task for Shift Instructions
    task check_shift(
        input string name,
        input logic [6:0] exp_opcode,
        input logic [4:0] exp_rd,
        input logic [4:0] exp_rs1,
        input logic [4:0] exp_rs2,
        input logic [2:0] exp_funct3,
        input logic [6:0] exp_funct7,
        input logic [31:0] exp_imm,
        input logic [4:0]  exp_shamt
    );
        @(posedge clk);
        @(posedge clk);
        #1;
        // Identical formatting to check() for consistency
        $display("%-8t %-24s %b    %2d      %2d      %2d      %h       %s",
            $time, name, opcode_o, rd_o, rs1_o, rs2_o, imm_o,
            (opcode_o === exp_opcode && rd_o === exp_rd && rs1_o === exp_rs1 &&
             funct3_o === exp_funct3 && funct7_o === exp_funct7 &&
             imm_o === exp_imm && shamt_o === exp_shamt) ? "PASS" : "FAIL"
        );
    endtask
    // -------------------------------------------------------------------------
    // Main Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        // Reset
        rst = 1; insn_i = 0; pc_i = 0;
        @(posedge clk);
        rst = 0;

        // Print Header
        $display("Time\t Type\t\t\t    Opcode\tRD\tRS1\tRS2\tImm\t      Check");
        $display("----------------------------------------------------------------------------------------------------------");

        // ---------------------------------------------------------
        // 1. R-TYPE TESTS
        // ---------------------------------------------------------

        // ADD x1, x2, x3
        insn_i = {7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011};
        check("ADD x1, x2, x3", 7'b0110011, 5'd1, 5'd2, 5'd3, 3'b000, 7'b0000000, 32'h0);

        // SUB x10, x11, x12
        insn_i = {7'b0100000, 5'd12, 5'd11, 3'b000, 5'd10, 7'b0110011};
        check("SUB x10, x11, x12", 7'b0110011, 5'd10, 5'd11, 5'd12, 3'b000, 7'b0100000, 32'h0);

        // XOR x1, x2, x3
        insn_i = {7'b0000000, 5'd3, 5'd2, 3'b100, 5'd1, 7'b0110011};
        check("XOR x1, x2, x3", 7'b0110011, 5'd1, 5'd2, 5'd3, 3'b100, 7'b0000000, 32'h0);

        // SLT x4, x5, x6
        insn_i = {7'b0000000, 5'd6, 5'd5, 3'b010, 5'd4, 7'b0110011};
        check("SLT x4, x5, x6", 7'b0110011, 5'd4, 5'd5, 5'd6, 3'b010, 7'b0000000, 32'h0);

        // SLTU x4, x5, x6
        insn_i = {7'b0000000, 5'd6, 5'd5, 3'b011, 5'd4, 7'b0110011};
        check("SLTU x4, x5, x6", 7'b0110011, 5'd4, 5'd5, 5'd6, 3'b011, 7'b0000000, 32'h0);

        // SRA x7, x8, x9
        insn_i = {7'b0100000, 5'd9, 5'd8, 3'b101, 5'd7, 7'b0110011};
        check("SRA x7, x8, x9", 7'b0110011, 5'd7, 5'd8, 5'd9, 3'b101, 7'b0100000, 32'h0);

        // ---------------------------------------------------------
        // 2. I-TYPE TESTS (Arithmetic & Load)
        // ---------------------------------------------------------

        // ADDI x5, x6, 42
        insn_i = {12'h02A, 5'd6, 3'b000, 5'd5, 7'b0010011};
        check("ADDI x5, x6, 42", 7'b0010011, 5'd5, 5'd6, 5'd0, 3'b000, 7'h0, 32'h0000002A);

        // ADDI x7, x8, -1
        insn_i = {12'hFFF, 5'd8, 3'b000, 5'd7, 7'b0010011};
        check("ADDI x7, x8, -1", 7'b0010011, 5'd7, 5'd8, 5'd0, 3'b000, 7'h0, 32'hFFFFFFFF);

        // ANDI x10, x11, -1
        insn_i = {12'hFFF, 5'd11, 3'b111, 5'd10, 7'b0010011};
        check("ANDI x10, x11, -1", 7'b0010011, 5'd10, 5'd11, 5'd0, 3'b111, 7'h0, 32'hFFFFFFFF);

        // ORI x12, x13, 0
        insn_i = {12'h000, 5'd13, 3'b110, 5'd12, 7'b0010011};
        check("ORI x12, x13, 0", 7'b0010011, 5'd12, 5'd13, 5'd0, 3'b110, 7'h0, 32'h00000000);

        // LB x1, 0(x2)
        insn_i = {12'h000, 5'd2, 3'b000, 5'd1, 7'b0000011};
        check("LB x1, 0(x2)", 7'b0000011, 5'd1, 5'd2, 5'd0, 3'b000, 7'h0, 32'h00000000);

        // LW x5, 16(x6)
        insn_i = {12'h010, 5'd6, 3'b010, 5'd5, 7'b0000011};
        check("LW x5, 16(x6)", 7'b0000011, 5'd5, 5'd6, 5'd0, 3'b010, 7'h0, 32'h00000010);

        // LH x7, -4(x8)
        insn_i = {12'hFFC, 5'd8, 3'b001, 5'd7, 7'b0000011};
        check("LH x7, -4(x8)", 7'b0000011, 5'd7, 5'd8, 5'd0, 3'b001, 7'h0, 32'hFFFFFFFC);

        // LBU x9, 255(x10)
        insn_i = {12'h0FF, 5'd10, 3'b100, 5'd9, 7'b0000011};
        check("LBU x9, 255(x10)", 7'b0000011, 5'd9, 5'd10, 5'd0, 3'b100, 7'h0, 32'h000000FF);

        // ---------------------------------------------------------
        // 3. I-TYPE SHIFTS (Using check_shift)
        // ---------------------------------------------------------

        // SLLI x9, x10, 5
        insn_i = {7'b0000000, 5'd5, 5'd10, 3'b001, 5'd9, 7'b0010011};
        check_shift("SLLI x9, x10, 5", 7'b0010011, 5'd9, 5'd10, 5'd0, 3'b001, 7'h0, 32'h00000005, 5'd5);

        // SRAI x11, x12, 7
        insn_i = {7'b0100000, 5'd7, 5'd12, 3'b101, 5'd11, 7'b0010011};
        check_shift("SRAI x11, x12, 7", 7'b0010011, 5'd11, 5'd12, 5'd0, 3'b101, 7'b0100000, 32'h00000407, 5'd7);

        // ---------------------------------------------------------
        // 4. S-TYPE TESTS (Stores)
        // ---------------------------------------------------------

        // SW x15, 20(x16)
        insn_i = {7'b0000000, 5'd15, 5'd16, 3'b010, 5'b10100, 7'b0100011};
        check("SW x15, 20(x16)", 7'b0100011, 5'd0, 5'd16, 5'd15, 3'b010, 7'h0, 32'h00000014);

        // SB x17, -1(x18)
        insn_i = {7'b1111111, 5'd17, 5'd18, 3'b000, 5'b11111, 7'b0100011};
        check("SB x17, -1(x18)", 7'b0100011, 5'd0, 5'd18, 5'd17, 3'b000, 7'h0, 32'hFFFFFFFF);

        // SH x15, -2(x16)
        insn_i = {7'b1111111, 5'd15, 5'd16, 3'b001, 5'b11110, 7'b0100011};
        check("SH x15, -2(x16)", 7'b0100011, 5'd0, 5'd16, 5'd15, 3'b001, 7'h0, 32'hFFFFFFFE);

        // ---------------------------------------------------------
        // 5. B-TYPE TESTS (Branches)
        // ---------------------------------------------------------

        // BEQ x1, x2, 12
        insn_i = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b0110, 1'b0, 7'b1100011};
        check("BEQ x1, x2, 12", 7'b1100011, 5'd0, 5'd1, 5'd2, 3'b000, 7'h0, 32'h0000000C);

        // BNE x1, x2, -4
        insn_i = {1'b1, 6'b111111, 5'd2, 5'd1, 3'b001, 4'b1110, 1'b1, 7'b1100011};
        check("BNE x1, x2, -4", 7'b1100011, 5'd0, 5'd1, 5'd2, 3'b001, 7'h0, 32'hFFFFFFFC);

        // BLT x5, x6, -2
        insn_i = {1'b1, 6'b111111, 5'd6, 5'd5, 3'b100, 4'b1111, 1'b1, 7'b1100011};
        check("BLT x5, x6, -2", 7'b1100011, 5'd0, 5'd5, 5'd6, 3'b100, 7'h0, 32'hFFFFFFFE);

        // ---------------------------------------------------------
        // 6. U-TYPE TESTS (Upper Immediate)
        // ---------------------------------------------------------

        // LUI x1, 0x12345
        insn_i = {20'h12345, 5'd1, 7'b0110111};
        check("LUI x1, 0x12345", 7'b0110111, 5'd1, 5'd0, 5'd0, 3'b000, 7'h0, 32'h12345000);

        // AUIPC x2, 0xFFFFF
        insn_i = {20'hFFFFF, 5'd2, 7'b0010111};
        check("AUIPC x2, -4096", 7'b0010111, 5'd2, 5'd0, 5'd0, 3'b000, 7'h0, 32'hFFFFF000);

        // LUI x1, 0x80000
        insn_i = {20'h80000, 5'd1, 7'b0110111};
        check("LUI x1, 0x80000", 7'b0110111, 5'd1, 5'd0, 5'd0, 3'b000, 7'h0, 32'h80000000);

        // ---------------------------------------------------------
        // 7. J-TYPE TESTS (Jumps)
        // ---------------------------------------------------------

        // JAL x1, Max Positive
        insn_i = {1'b0, 10'b1111111111, 1'b1, 8'b11111111, 5'd1, 7'b1101111};
        check("JAL Max Positive", 7'b1101111, 5'd1, 5'd0, 5'd0, 3'b000, 7'h0, 32'h000FFFFE);

        // JAL x0, -2
        insn_i = {1'b1, 10'b1111111111, 1'b1, 8'b11111111, 5'd0, 7'b1101111};
        check("JAL x0, -2", 7'b1101111, 5'd0, 5'd0, 5'd0, 3'b000, 7'h0, 32'hFFFFFFFE);

        // JAL x0, 256
        insn_i = {1'b0, 10'b0010000000, 1'b0, 8'b00000000, 5'd0, 7'b1101111};
        check("JAL x0, 256", 7'b1101111, 5'd0, 5'd0, 5'd0, 3'b000, 7'h0, 32'h00000100);

        // JAL x1, 2048
        insn_i = {1'b0, 10'd0, 1'b1, 8'd0, 5'd1, 7'b1101111};
        check("JAL x1, 2048", 7'b1101111, 5'd1, 5'd0, 5'd0, 3'b000, 7'h0, 32'h00000800);

        // JAL x2, 4096
        insn_i = {1'b0, 10'd0, 1'b0, 8'b00000001, 5'd2, 7'b1101111};
        check("JAL x2, 4096", 7'b1101111, 5'd2, 5'd0, 5'd0, 3'b000, 7'h0, 32'h00001000);

        // JAL x3, -1MB
        insn_i = {1'b1, 10'd0, 1'b0, 8'd0, 5'd3, 7'b1101111};
        check("JAL x3, -1MB", 7'b1101111, 5'd3, 5'd0, 5'd0, 3'b000, 7'h0, 32'hFFF00000);

        // JAL x4, Alternating
        insn_i = {1'b0, 10'b1010101010, 1'b0, 8'b01010101, 5'd4, 7'b1101111};
        check("JAL x4, Alternating", 7'b1101111, 5'd4, 5'd0, 5'd0, 3'b000, 7'h0, 32'h00055554);

        // ---------------------------------------------------------
        // 8. JALR
        // ---------------------------------------------------------

        // JALR x1, 4(x2)
        insn_i = {12'h004, 5'd2, 3'b000, 5'd1, 7'b1100111};
        check("JALR x1, 4(x2)", 7'b1100111, 5'd1, 5'd2, 5'd0, 3'b000, 7'h0, 32'h00000004);

        // JALR x0, 0(x31)
        insn_i = {12'h000, 5'd31, 3'b000, 5'd0, 7'b1100111};
        check("JALR x0, 0(x31) [ret]", 7'b1100111, 5'd0, 5'd31, 5'd0, 3'b000, 7'h0, 32'h00000000);

        // JALR x1, -4(x2)
        insn_i = {12'hFFC, 5'd2, 3'b000, 5'd1, 7'b1100111};
        check("JALR x1, -4(x2)", 7'b1100111, 5'd1, 5'd2, 5'd0, 3'b000, 7'h0, 32'hFFFFFFFC);

        $display("----------------------------------------------------------------------------------------------------------");
        $finish;
    end
endmodule