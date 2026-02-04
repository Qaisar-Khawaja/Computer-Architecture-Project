`timescale 1ns/1ps

module igen_tb;

    // Parameters and signals
    localparam DWIDTH = 32;
    logic [6:0]  opcode;
    logic [31:0] insn;
    logic [31:0] imm_out;

    // 1. Instantiate the Unit Under Test (UUT)
    igen #( .DWIDTH(DWIDTH) ) uut (
        .opcode_i(opcode),
        .insn_i(insn),
        .imm_o(imm_out)
    );

    initial begin

        $dumpfile("igen_waves.vcd"); // Name of the recording file
        $dumpvars(0, igen_tb);        // Record everything in this module and below
    
        // Format for printing
        $display("Time\t Type\t Instruction\t Expected\t Actual");
        $display("------------------------------------------------------------");

        // --- TEST 1: I-Type (addi x1, x2, -5) ---
        // imm = -5 (12'hFFB), rs1=x2, funct3=0, rd=x1, op=0010011
        opcode = 7'b0010011; 
        insn   = 32'hFFB10093; 
        #10;
        $display("%0t\t I\t %H\t FFFFFFFB\t %H", $time, insn, imm_out);

        // --- TEST 2: S-Type (sw x5, 8(x2)) ---
        // imm = 8 (12'h008), rs2=x5, rs1=x2, op=0100011
        // imm[11:5]=0000000, imm[4:0]=01000
        opcode = 7'b0100011;
        insn   = 32'h00512423; 
        #10;
        $display("%0t\t S\t %H\t 00000008\t %H", $time, insn, imm_out);

        // --- TEST 3: B-Type (beq x1, x2, -4) ---
        // imm = -4 (13'h1FFC), bit 0 is hidden.
        // imm[12]=1, imm[11]=1, imm[10:5]=3F, imm[4:1]=E
        opcode = 7'b1100011;
        insn   = 32'hFE208EE3; 
        #10;
        $display("%0t\t B\t %H\t FFFFFFC\t %H", $time, insn, imm_out);

        // --- TEST 4: U-Type (lui x1, 0x12345) ---
        // imm = 0x12345000
        opcode = 7'b0110111;
        insn   = 32'h123450B7;
        #10;
        $display("%0t\t U\t %H\t 12345000\t %H", $time, insn, imm_out);

        // --- TEST 5: J-Type (jal x1, 2048) ---
        // imm = 2048 (21'h00800), bit 0 hidden.
        opcode = 7'b1101111;
        insn   = 32'h001000ef; 
        #10;
        $display("%0t\t J\t %H\t 00000800\t %H", $time, insn, imm_out);


        // --- I-TYPE EDGE CASES ---
        // Max Positive: 2047 (12'h7FF)
        opcode = 7'b0010011; insn = 32'h7FF00093; #10;
        $display("%0t\t I-Max\t %H\t 000007FF\t %H", $time, insn, imm_out);
        // Max Negative: -2048 (12'h800)
        opcode = 7'b0010011; insn = 32'h80000093; #10;
        $display("%0t\t I-Min\t %H\t FFFFF800\t %H", $time, insn, imm_out);

        // --- S-TYPE EDGE CASES ---
        // Max Positive: 2047 (12'h7FF -> imm[11:5]=3F, imm[4:0]=1F)
        opcode = 7'b0100011; insn = 32'h7E000FA3; #10;
        $display("%0t\t S-Max\t %H\t 000007FF\t %H", $time, insn, imm_out);

        // --- B-TYPE EDGE CASES (The Scrambled One) ---
        // Zero Jump: imm = 0
        opcode = 7'b1100011; insn = 32'h00000063; #10;
        $display("%0t\t B-Zero\t %H\t 00000000\t %H", $time, insn, imm_out);
        // Backward Jump: -2 (13'h1FFE -> imm[12]=1, [11]=1, [10:5]=3F, [4:1]=F)
        opcode = 7'b1100011; insn = 32'hFE000FE3; #10;
        $display("%0t\t B-Neg\t %H\t FFFFFFFE\t %H", $time, insn, imm_out);

        // --- U-TYPE EDGE CASES ---
        // All F's in the upper 20 bits
        opcode = 7'b0110111; insn = 32'hFFFFF0B7; #10;
        $display("%0t\t U-Max\t %H\t FFFFF000\t %H", $time, insn, imm_out);

        // --- J-TYPE EDGE CASES (The Really Scrambled One) ---
        
        // Max Positive Jump: (approx +1MB)
        // Let's set bits to get something recognizable
        opcode = 7'b1101111; 
        insn   = 32'h7FFFF0EF; 
        #10;
        $display("%0t\t J-Max\t %H\t 000FFFFE\t %H", $time, insn, imm_out);

        
        // Maximum Negative Jump: (Sign bit 31 is 1, all other imm bits 0)
        opcode = 7'b1101111; insn = 32'h800000ef; #10;
        $display("%0t\t J-Min\t %H\t FFF00000\t %H", $time, insn, imm_out);

        // --- EDGE 1: I-Type Zero Check ---
        // Ensuring no bits "leak" when the immediate is zero.
        opcode = 7'b0010011; insn = 32'h00000013; #10;
        $display("%0t\t I-Zero\t %H\t 00000000\t %H", $time, insn, imm_out);


        // --- EDGE 2: B-Type Max Negative (The "Backwards" Limit) ---
        // imm = -4096 (The furthest back a branch can go)
        // Instruction bits: imm[12]=1, others=0.
        opcode = 7'b1100011; insn = 32'h80000063; #10;
        $display("%0t\t B-Limit\t %H\t FFFFF000\t %H", $time, insn, imm_out);

        // --- EDGE 3: J-Type Sign Extension Flip ---
        // Testing the exact moment the sign bit (31) turns on.
        // This should fill the top 12 bits with 'F'.
        opcode = 7'b1101111; insn = 32'h800000ef; #10;
        $display("%0t\t J-Sign\t %H\t FFF00000\t %H", $time, insn, imm_out);

        // --- EDGE 4: S-Type Alternating Bits (Crosstalk Test) ---
        // imm = 101010101010 (Hex 0xAAA)
        // Tests if bits from rs2 or rs1 are accidentally leaking into the immediate.
        opcode = 7'b0100011; insn = 32'hAAA00523; #10;
        $display("%0t\t S-Cross\t %H\t FFFFFAAA\t %H", $time, insn, imm_out);

        // --- EDGE 5: U-Type Minimum ---
        // Only the lowest bit of the upper immediate is set.
        opcode = 7'b0110111; insn = 32'h000010b7; #10;
        $display("%0t\t U-Min\t %H\t 00001000\t %H", $time, insn, imm_out);



        $display("------------------------------------------------------------");
        $finish;
    end

endmodule