`timescale 1ns/1ps

module decode_tb();
    // Parameters
    localparam int AWIDTH = 32;
    localparam int DWIDTH = 32;
    localparam int CLK_PERIOD = 10;

    // Signals
    logic clk, rst;
    logic [DWIDTH-1:0] insn_i, pc_i;
    logic [DWIDTH-1:0] insn_o, imm_o;
    logic [AWIDTH-1:0] pc_o;
    logic [6:0] opcode_o, funct7_o;
    logic [4:0] rd_o, rs1_o, rs2_o, shamt_o;
    logic [2:0] funct3_o;

    // DUT Instance
    decode #(
        .AWIDTH(AWIDTH), 
        .DWIDTH(DWIDTH)
    ) dut (.*);

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // --- CHECK TASK ---
    // Automates verification to keep the main block clean
    task check(
        input string name,
        input [6:0]  exp_opcode,
        input [4:0]  exp_rd,
        input [4:0]  exp_rs1,
        input [4:0]  exp_rs2,
        input [2:0]  exp_funct3,
        input [6:0]  exp_funct7,
        input [31:0] exp_imm,
        input [4:0]  exp_shamt = 5'd0 // Optional, defaults to 0
    );
        begin
            #1; // Wait for combinational logic to settle
            if (opcode_o !== exp_opcode || rd_o !== exp_rd || rs1_o !== exp_rs1 || 
                rs2_o !== exp_rs2 || funct3_o !== exp_funct3 || funct7_o !== exp_funct7 || 
                imm_o !== exp_imm || shamt_o !== exp_shamt) begin

                $display("\n[FAILED] %s", name);
                $display("  Signal | Expected   | Got");
                $display("  -------|------------|------------");
                $display("  Opcode | %b    | %b", exp_opcode, opcode_o);
                $display("  Rd     | %d         | %d", exp_rd, rd_o);
                $display("  Rs1    | %d         | %d", exp_rs1, rs1_o);
                $display("  Rs2    | %d         | %d", exp_rs2, rs2_o);
                $display("  Funct3 | %b        | %b", exp_funct3, funct3_o);
                $display("  Funct7 | %b    | %b", exp_funct7, funct7_o);
                $display("  Imm    | %h   | %h", exp_imm, imm_o);
                $display("  Shamt  | %d         | %d", exp_shamt, shamt_o);
                $stop; // Stop simulation on first failure
            end else begin
                $display("[PASSED] %s", name);
            end
            @(negedge clk); // Align to next clock edge for cleanliness
        end
    endtask

    initial begin
        // Initialize
        rst = 1; insn_i = 0; pc_i = 0;
        #(CLK_PERIOD*2);
        rst = 0;

        $display("\n--- Starting Decoder Tests ---\n");

        // ---------------------------------------------------------
        // 1. R-TYPE TESTS
        // ---------------------------------------------------------

        // ADD x1, x2, x3
        // Op: 0110011, f3: 000, f7: 0000000
        insn_i = {7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, 7'b0110011};
        check("ADD x1, x2, x3", 7'b0110011, 5'd1, 5'd2, 5'd3, 3'b000, 7'b0000000, 32'h0);

        // SUB x10, x11, x12
        // Op: 0110011, f3: 000, f7: 0100000 (SUB flag)
        insn_i = {7'b0100000, 5'd12, 5'd11, 3'b000, 5'd10, 7'b0110011};
        check("SUB x10, x11, x12", 7'b0110011, 5'd10, 5'd11, 5'd12, 3'b000, 7'b0100000, 32'h0);

        // ---------------------------------------------------------
        // 2. I-TYPE TESTS (Arithmetic & Load)
        // ---------------------------------------------------------

        // ADDI x5, x6, 42
        // Op: 0010011, Imm: 42 (0x02A)
        insn_i = {12'h02A, 5'd6, 3'b000, 5'd5, 7'b0010011};
        check("ADDI x5, x6, 42", 7'b0010011, 5'd5, 5'd6, 5'd0, 3'b000, 7'h0, 32'h0000002A);

        // ADDI x7, x8, -1 (Sign Extension Test)
        // Imm: -1 (0xFFF in 12 bits)
        insn_i = {12'hFFF, 5'd8, 3'b000, 5'd7, 7'b0010011};
        check("ADDI x7, x8, -1", 7'b0010011, 5'd7, 5'd8, 5'd0, 3'b000, 7'h0, 32'hFFFFFFFF);

        // LB x1, 0(x2) (Load Byte)
        // Op: 0000011
        insn_i = {12'h000, 5'd2, 3'b000, 5'd1, 7'b0000011};
        check("LB x1, 0(x2)", 7'b0000011, 5'd1, 5'd2, 5'd0, 3'b000, 7'h0, 32'h00000000);

        // ---------------------------------------------------------
        // 3. I-TYPE SHIFTS (Special Handling)
        // ---------------------------------------------------------

        // SLLI x9, x10, 5 (Shift Left Logical Immediate)
        // Op: 0010011, f3: 001, Shamt: 5, f7: 0000000
        // COME BACK TO AND CONFIRM
        insn_i = {7'b0000000, 5'd5, 5'd10, 3'b001, 5'd9, 7'b0010011};
        check("SLLI x9, x10, 5", 7'b0010011, 5'd9, 5'd10, 5'd0, 3'b001, 7'h0, 32'h00000005, 5'd5);

        // SRAI x11, x12, 7 (Shift Right Arithmetic Immediate)
        // Op: 0010011, f3: 101, Shamt: 7, f7: 0100000 (Arithmetic flag)
        // COME BACK TO CONFIRM
        insn_i = {7'b0100000, 5'd7, 5'd12, 3'b101, 5'd11, 7'b0010011};
        check("SRAI x11, x12, 7", 7'b0010011, 5'd11, 5'd12, 5'd0, 3'b101, 7'b0100000, 32'h00000407, 5'd7);

        // ---------------------------------------------------------
        // 4. S-TYPE TESTS (Stores)
        // ---------------------------------------------------------

        // SW x15, 20(x16)
        // Op: 0100011, Imm split: 20 (0x014) -> Hi: 0000000, Lo: 10100
        insn_i = {7'b0000000, 5'd15, 5'd16, 3'b010, 5'b10100, 7'b0100011};
        check("SW x15, 20(x16)", 7'b0100011, 5'd0, 5'd16, 5'd15, 3'b010, 7'h0, 32'h00000014);

        // SB x17, -1(x18)
        // Imm split: -1 (0xFFF) -> Hi: 1111111, Lo: 11111
        insn_i = {7'b1111111, 5'd17, 5'd18, 3'b000, 5'b11111, 7'b0100011};
        check("SB x17, -1(x18)", 7'b0100011, 5'd0, 5'd18, 5'd17, 3'b000, 7'h0, 32'hFFFFFFFF);

        // ---------------------------------------------------------
        // 5. B-TYPE TESTS (Branches)
        // ---------------------------------------------------------

        // BEQ x1, x2, 12 (Offset 12 bytes = 3 instructions)
        // Imm: 12 (0x00C) -> Binary 0...0001100
        // RISC-V Encoding: [12|10:5] [rs2] [rs1] [f3] [4:1|11] [op]
        // Bit 12=0, Bits 10:5=000000, Bits 4:1=0110, Bit 11=0
        insn_i = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b0110, 1'b0, 7'b1100011};
        check("BEQ x1, x2, 12", 7'b1100011, 5'd0, 5'd1, 5'd2, 3'b000, 7'h0, 32'h0000000C);

        // BNE x1, x2, -4 (Jump back 4 bytes)
        // Imm: -4 (0xFF...C) -> Binary ...11111100
        // Bit 12=1, Bits 10:5=111111, Bits 4:1=1110, Bit 11=1
        insn_i = {1'b1, 6'b111111, 5'd2, 5'd1, 3'b001, 4'b1110, 1'b1, 7'b1100011};
        check("BNE x1, x2, -4", 7'b1100011, 5'd0, 5'd1, 5'd2, 3'b001, 7'h0, 32'hFFFFFFFC);

        // ---------------------------------------------------------
        // 6. U-TYPE TESTS (Upper Immediate)
        // ---------------------------------------------------------

        // LUI x1, 0x12345
        // Imm: 0x12345 << 12
        insn_i = {20'h12345, 5'd1, 7'b0110111};
        check("LUI x1, 0x12345", 7'b0110111, 5'd1, 5'd0, 5'd0, 3'b000, 7'h0, 32'h12345000);

        // AUIPC x2, 0xFFFFF (Max U-Type)
        insn_i = {20'hFFFFF, 5'd2, 7'b0010111};
        check("AUIPC x2, -4096", 7'b0010111, 5'd2, 5'd0, 5'd0, 3'b000, 7'h0, 32'hFFFFF000);

        // ---------------------------------------------------------
        // 7. J-TYPE TESTS (Jumps)
        // ---------------------------------------------------------

        // JAL x1, 1048574 (Max Positive JAL Offset)
        // Imm: 0x0FFFFE (20 bits active, LSB 0) -> ...0111...110
        // Encoding: [20][10:1][11][19:12]
        // Bit 20=0, Bits 10:1=1111111111, Bit 11=1, Bits 19:12=11111111
        insn_i = {1'b0, 10'b1111111111, 1'b1, 8'b11111111, 5'd1, 7'b1101111};
        check("JAL Max Positive", 7'b1101111, 5'd1, 5'd0, 5'd0, 3'b000, 7'h0, 32'h000FFFFE);

        // JAL x0, -2 (Smallest Negative Step)
        // Imm: -2 (0xFF...FE) -> Binary ...11110
        // Encoding: [20][10:1][11][19:12]
        // Bit 20=1, Bits 10:1=1111111111, Bit 11=1, Bits 19:12=11111111
        insn_i = {1'b1, 10'b1111111111, 1'b1, 8'b11111111, 5'd0, 7'b1101111};
        check("JAL x0, -2", 7'b1101111, 5'd0, 5'd0, 5'd0, 3'b000, 7'h0, 32'hFFFFFFFE);

// ---------------------------------------------------------
        // 1. EXTRA R-TYPE TESTS (Logic & SLT)
        // ---------------------------------------------------------

        // XOR x1, x2, x3
        // Op: 0110011, f3: 100
        insn_i = {7'b0000000, 5'd3, 5'd2, 3'b100, 5'd1, 7'b0110011};
        check("XOR x1, x2, x3", 7'b0110011, 5'd1, 5'd2, 5'd3, 3'b100, 7'b0000000, 32'h0);

        // SLT x4, x5, x6 (Set Less Than - Signed)
        // Op: 0110011, f3: 010
        insn_i = {7'b0000000, 5'd6, 5'd5, 3'b010, 5'd4, 7'b0110011};
        check("SLT x4, x5, x6", 7'b0110011, 5'd4, 5'd5, 5'd6, 3'b010, 7'b0000000, 32'h0);

        // SLTU x4, x5, x6 (Set Less Than - Unsigned)
        // Op: 0110011, f3: 011
        insn_i = {7'b0000000, 5'd6, 5'd5, 3'b011, 5'd4, 7'b0110011};
        check("SLTU x4, x5, x6", 7'b0110011, 5'd4, 5'd5, 5'd6, 3'b011, 7'b0000000, 32'h0);
        
        // SRA x7, x8, x9 (Shift Right Arithmetic - R-Type)
        // Op: 0110011, f3: 101, f7: 0100000
        insn_i = {7'b0100000, 5'd9, 5'd8, 3'b101, 5'd7, 7'b0110011};
        check("SRA x7, x8, x9", 7'b0110011, 5'd7, 5'd8, 5'd9, 3'b101, 7'b0100000, 32'h0);

// ---------------------------------------------------------
        // 2. EXTRA I-TYPE TESTS
        // ---------------------------------------------------------

        // ANDI x10, x11, -1 (Masking with 0xFFFFFFFF)
        // Imm: -1 (0xFFF) -> Sign extends to 0xFFFFFFFF
        insn_i = {12'hFFF, 5'd11, 3'b111, 5'd10, 7'b0010011};
        check("ANDI x10, x11, -1", 7'b0010011, 5'd10, 5'd11, 5'd0, 3'b111, 7'h0, 32'hFFFFFFFF);

        // ORI x12, x13, 0 (Identity)
        // Imm: 0
        insn_i = {12'h000, 5'd13, 3'b110, 5'd12, 7'b0010011};
        check("ORI x12, x13, 0", 7'b0010011, 5'd12, 5'd13, 5'd0, 3'b110, 7'h0, 32'h00000000);

        // JALR x1, 4(x2) (Indirect Jump)
        // Op: 1100111, Imm: 4
        insn_i = {12'h004, 5'd2, 3'b000, 5'd1, 7'b1100111};
        check("JALR x1, 4(x2)", 7'b1100111, 5'd1, 5'd2, 5'd0, 3'b000, 7'h0, 32'h00000004);

// ---------------------------------------------------------
        // 3. STORE (S) VS BRANCH (B) COMPARISON
        // ---------------------------------------------------------
        
        // SH x15, -2(x16) (Store Halfword)
        // Imm: -2 (0xFFE) -> Hi: 1111111, Lo: 11110
        insn_i = {7'b1111111, 5'd15, 5'd16, 3'b001, 5'b11110, 7'b0100011};
        check("SH x15, -2(x16)", 7'b0100011, 5'd0, 5'd16, 5'd15, 3'b001, 7'h0, 32'hFFFFFFFE);

        // BLT x5, x6, -2 (Branch Less Than)
        // Imm: -2 (0xFFE) -> bit[12]=1, bit[11]=1, bits[10:5]=111111, bits[4:1]=1111
        // Notice how this looks very different from the SH above despite same Immediate value
        insn_i = {1'b1, 6'b111111, 5'd6, 5'd5, 3'b100, 4'b1111, 1'b1, 7'b1100011};
        check("BLT x5, x6, -2", 7'b1100011, 5'd0, 5'd5, 5'd6, 3'b100, 7'h0, 32'hFFFFFFFE);

// ---------------------------------------------------------
        // 4. UPPER IMMEDIATE & JUMP EDGE CASES
        // ---------------------------------------------------------

        // LUI x1, 0x80000 (Setting the Sign Bit)
        // Imm: 0x80000 (Min 32-bit int)
        insn_i = {20'h80000, 5'd1, 7'b0110111};
        check("LUI x1, 0x80000", 7'b0110111, 5'd1, 5'd0, 5'd0, 3'b000, 7'h0, 32'h80000000);

        // JAL x0, 256 (Small positive jump, testing middle bit placement)
        // Imm: 256 (0x100) -> Binary ...0001 0000 0000
        // Encoding: [20]=0, [10:1]=0001000000, [11]=0, [19:12]=00000000
        insn_i = {1'b0, 10'b0010000000, 1'b0, 8'b00000000, 5'd0, 7'b1101111};
        check("JAL x0, 256", 7'b1101111, 5'd0, 5'd0, 5'd0, 3'b000, 7'h0, 32'h00000100);

// JAL x1, 2048 (Testing Imm[11] -> Inst[20])
        // Imm: 2048 (0x800)
        // Encoding: [31]=0, [30:21]=0, [20]=1, [19:12]=0
        insn_i = {1'b0, 10'd0, 1'b1, 8'd0, 5'd1, 7'b1101111};
        check("JAL x1, 2048", 7'b1101111, 5'd1, 5'd0, 5'd0, 3'b000, 7'h0, 32'h00000800);

// JAL x2, 4096 (Testing Imm[12] -> Inst[12])
        // Imm: 4096 (0x1000)
        // Encoding: [31]=0, [30:21]=0, [20]=0, [19:12]=00000001
        insn_i = {1'b0, 10'd0, 1'b0, 8'b00000001, 5'd2, 7'b1101111};
        check("JAL x2, 4096", 7'b1101111, 5'd2, 5'd0, 5'd0, 3'b000, 7'h0, 32'h00001000);

// JAL x3, -1048576 (Max Negative)
        // Imm: -1048576 (0xFFF00000)
        // Encoding: [31]=1, [30:21]=0, [20]=0, [19:12]=0
        insn_i = {1'b1, 10'd0, 1'b0, 8'd0, 5'd3, 7'b1101111};
        check("JAL x3, -1MB", 7'b1101111, 5'd3, 5'd0, 5'd0, 3'b000, 7'h0, 32'hFFF00000);

// JAL x4, 0x55554 (Alternating Bits)
        // Imm: 0x55554
        // Binary: 0000 0101 0101 0101 0101 0100
        //
        // Breakdown:
        // Imm[20] (Sign) = 0
        // Imm[19:12]     = 01010101 (0x55) -> Inst[19:12]
        // Imm[11]        = 0        (0x0)  -> Inst[20]
        // Imm[10:1]      = 1010101010      -> Inst[30:21]
        
        insn_i = {1'b0, 10'b1010101010, 1'b0, 8'b01010101, 5'd4, 7'b1101111};
        check("JAL x4, Alternating", 7'b1101111, 5'd4, 5'd0, 5'd0, 3'b000, 7'h0, 32'h00055554); 

// ---------------------------------------------------------
        // I-TYPE LOADS (LW, LH, LBU)
        // ---------------------------------------------------------

        // LW x5, 16(x6)  (Load Word: Offset 16)
        // Imm: 16 (0x010)
        // Funct3: 010 (LW)
        insn_i = {12'h010, 5'd6, 3'b010, 5'd5, 7'b0000011};
        check("LW x5, 16(x6)", 7'b0000011, 5'd5, 5'd6, 5'd0, 3'b010, 7'h0, 32'h00000010);

        // LH x7, -4(x8)  (Load Halfword: Negative Offset)
        // Imm: -4 (0xFFC) -> Sign Extended to 0xFFFFFFFC in 32-bit view
        // Funct3: 001 (LH)
        insn_i = {12'hFFC, 5'd8, 3'b001, 5'd7, 7'b0000011};
        check("LH x7, -4(x8)", 7'b0000011, 5'd7, 5'd8, 5'd0, 3'b001, 7'h0, 32'hFFFFFFFC);

        // LBU x9, 255(x10) (Load Byte Unsigned: Max Byte Offset)
        // Imm: 255 (0x0FF)
        // Funct3: 100 (LBU)
        insn_i = {12'h0FF, 5'd10, 3'b100, 5'd9, 7'b0000011};
        check("LBU x9, 255(x10)", 7'b0000011, 5'd9, 5'd10, 5'd0, 3'b100, 7'h0, 32'h000000FF);

// ---------------------------------------------------------
        // I-TYPE JUMP (JALR)
        // ---------------------------------------------------------

        // JALR x1, 0(x31) (Standard Return "ret")
        // Imm: 0
        // Rs1: x31 (Return Address register often used in testing)
        // Rd:  x0 (Discard return link, since this is a return)
        insn_i = {12'h000, 5'd31, 3'b000, 5'd0, 7'b1100111};
        check("JALR x0, 0(x31) [ret]", 7'b1100111, 5'd0, 5'd31, 5'd0, 3'b000, 7'h0, 32'h00000000);

        // JALR x1, -4(x2) (Function Call with negative offset)
        // Imm: -4 (0xFFC)
        // Rs1: x2
        // Rd:  x1 (Link Register)
        insn_i = {12'hFFC, 5'd2, 3'b000, 5'd1, 7'b1100111};
        check("JALR x1, -4(x2)", 7'b1100111, 5'd1, 5'd2, 5'd0, 3'b000, 7'h0, 32'hFFFFFFFC);

// ---------------------------------------------------------
        // OP-IMM (Arithmetic: ADDI)
        // ---------------------------------------------------------

        // ADDI x1, x2, 10
        // Imm: 10 (0x00A)
        insn_i = {12'h00A, 5'd2, 3'b000, 5'd1, 7'b0010011};
        check("ADDI x1, x2, 10", 7'b0010011, 5'd1, 5'd2, 5'd0, 3'b000, 7'h0, 32'h0000000A);

        // ADDI x3, x4, -15
        // Imm: -15 (0xFF1) -> Sign Extended to 0xFFFFFFF1
        insn_i = {12'hFF1, 5'd4, 3'b000, 5'd3, 7'b0010011};
        check("ADDI x3, x4, -15", 7'b0010011, 5'd3, 5'd4, 5'd0, 3'b000, 7'h0, 32'hFFFFFFF1);

        $display("\n--- All Tests Passed Successfully! ---\n");
        $finish;
    end

endmodule