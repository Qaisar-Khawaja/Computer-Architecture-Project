`timescale 1ns/1ps
`include "constants.svh"

module control_tb;

    // Signals
    localparam DWIDTH = 32;
    logic [DWIDTH-1:0] insn;
    logic [6:0] opcode, funct7;
    logic [2:0] funct3;

    // DUT Outputs
    logic pcsel, immsel, regwren, rs1sel, rs2sel, memren, memwren;
    logic [1:0] wbsel;
    logic [3:0] alusel;

    // Instantiate the Unit Under Test (UUT)
    control #( .DWIDTH(DWIDTH) ) uut (
        .insn_i(insn), .opcode_i(opcode), .funct7_i(funct7), .funct3_i(funct3),
        .pcsel_o(pcsel), .immsel_o(immsel), .regwren_o(regwren),
        .rs1sel_o(rs1sel), .rs2sel_o(rs2sel), .memren_o(memren),
        .memwren_o(memwren), .wbsel_o(wbsel), .alusel_o(alusel)
    );

    // Helper task to check signals and print in your style
    task check_ctrl(
        input string name,
        input logic [6:0] op, input logic [2:0] f3, input logic [6:0] f7,
        input logic e_regwren, input logic [3:0] e_alusel, 
        input logic e_rs2sel,   input logic [1:0] e_wbsel,
        input logic e_memren,   input logic e_memwren
    );
        opcode = op; funct3 = f3; funct7 = f7; insn = 32'h0; // insn not used in logic yet
        #10;
        $display("%0t\t %-18s\t %b\t %h\t %b\t %b\t %b\t %s", 
            $time, name, regwren, alusel, rs2sel, wbsel, memwren,
            (regwren === e_regwren && alusel === e_alusel && rs2sel === e_rs2sel && 
             wbsel === e_wbsel     && memren === e_memren && memwren === e_memwren) ? "PASS" : "FAIL !!!"
        );
    endtask

    initial begin
        $display("Time\t Type\t\t\t RegW\t ALU\t RS2S\t WB\t MemW\t Check");
        $display("--------------------------------------------------------------------------------------------------");

        // Test 1: R-Type ADD
        check_ctrl("R-Type ADD", `Opcode_RType, 3'h0, 7'h00, 1'b1, `ADD, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 2: R-Type SUB (The Funct7 edge case)
        check_ctrl("R-Type SUB", `Opcode_RType, 3'h0, 7'h20, 1'b1, `SUB, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);
        // --- Additional R-Type Edge Cases ---

        // Test R-1: SRL (Shift Right Logical) - Shares funct3 with SRA
        check_ctrl("R-Type SRL", `Opcode_RType, 3'h5, 7'h00, 1'b1, `SRL, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test R-2: SRA (Shift Right Arithmetic) - The funct7 edge case
        check_ctrl("R-Type SRA", `Opcode_RType, 3'h5, 7'h20, 1'b1, `SRA, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test R-3: SLT (Set Less Than) - Basic comparison
        check_ctrl("R-Type SLT", `Opcode_RType, 3'h2, 7'h00, 1'b1, `SLT, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test R-4: SLTU (Set Less Than Unsigned) - Unsigned variant
        check_ctrl("R-Type SLTU", `Opcode_RType, 3'h3, 7'h00, 1'b1, `SLTU, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test R-5: XOR - Logical check
        check_ctrl("R-Type XOR", `Opcode_RType, 3'h4, 7'h00, 1'b1, `XOR, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test R-6: SLL (Shift Left Logical)
        check_ctrl("R-Type SLL", `Opcode_RType, 3'h1, 7'h00, 1'b1, `SLL, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test R-7: OR - Logical OR
        check_ctrl("R-Type OR",  `Opcode_RType, 3'h6, 7'h00, 1'b1, `OR,  `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test R-8: AND - Logical AND
        check_ctrl("R-Type AND", `Opcode_RType, 3'h7, 7'h00, 1'b1, `AND, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);














        // --- I-Type Arithmetic Tests (Opcode 0010011) ---

        // Test I-1: ADDI
        check_ctrl("I-Type ADDI", `Opcode_IType, 3'h0, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test I-2: XORI
        check_ctrl("I-Type XORI", `Opcode_IType, 3'h4, 7'h00, 1'b1, `XOR, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test I-3: ORI
        check_ctrl("I-Type ORI",  `Opcode_IType, 3'h6, 7'h00, 1'b1, `OR,  `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test I-4: ANDI
        check_ctrl("I-Type ANDI", `Opcode_IType, 3'h7, 7'h00, 1'b1, `AND, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test I-5: SLLI (Shift Left Logical Imm)
        check_ctrl("I-Type SLLI", `Opcode_IType, 3'h1, 7'h00, 1'b1, `SLL, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test I-6: SRLI (Shift Right Logical Imm)
        check_ctrl("I-Type SRLI", `Opcode_IType, 3'h5, 7'h00, 1'b1, `SRL, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test I-7: SRAI (Shift Right Arith Imm) - Edge Case: Funct7 Bit 30
        check_ctrl("I-Type SRAI", `Opcode_IType, 3'h5, 7'h20, 1'b1, `SRA, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test I-8: SLTI (Set Less Than Imm)
        check_ctrl("I-Type SLTI", `Opcode_IType, 3'h2, 7'h00, 1'b1, `SLT, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test I-9: SLTIU (Set Less Than Imm Unsigned)
        check_ctrl("I-Type SLTIU",`Opcode_IType, 3'h3, 7'h00, 1'b1, `SLTU, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);












        // --- I-Type Load Tests (Opcode 0000011) ---

        // Test L-1: LB (Load Byte)
        check_ctrl("I-Type LB",   `Opcode_IType_Load, 3'h0, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_MEM, 1'b1, 1'b0);

        // Test L-2: LH (Load Halfword)
        check_ctrl("I-Type LH",   `Opcode_IType_Load, 3'h1, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_MEM, 1'b1, 1'b0);

        // Test L-3: LW (Load Word)
        check_ctrl("I-Type LW",   `Opcode_IType_Load, 3'h2, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_MEM, 1'b1, 1'b0);

        // Test L-4: LBU (Load Byte Unsigned)
        check_ctrl("I-Type LBU",  `Opcode_IType_Load, 3'h4, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_MEM, 1'b1, 1'b0);

        // Test L-5: LHU (Load Halfword Unsigned)
        check_ctrl("I-Type LHU",  `Opcode_IType_Load, 3'h5, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_MEM, 1'b1, 1'b0);









        // Test 6: Store Word (SW)
        // Test S-1: SB (Store Byte)
        check_ctrl("S-Type SB",   `Opcode_SType, 3'h0, 7'h00, 1'b0, `ADD, `OP2_IMM, `WB_ALU, 1'b0, 1'b1);

        // Test S-2: SH (Store Halfword)
        check_ctrl("S-Type SH",   `Opcode_SType, 3'h1, 7'h00, 1'b0, `ADD, `OP2_IMM, `WB_ALU, 1'b0, 1'b1);

        // Test S-3: SW (Store Word)
        check_ctrl("S-Type SW",   `Opcode_SType, 3'h2, 7'h00, 1'b0, `ADD, `OP2_IMM, `WB_ALU, 1'b0, 1'b1);







        // Test B-1: BEQ (Branch Equal) - Uses Subtraction to check equality
        check_ctrl("B-Type BEQ",   `Opcode_BType, 3'h0, 7'h00, 1'b0, `SUB, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test B-2: BNE (Branch Not Equal) - Also uses Subtraction
        check_ctrl("B-Type BNE",   `Opcode_BType, 3'h1, 7'h00, 1'b0, `SUB, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test B-3: BLT (Branch Less Than) - Uses Set Less Than
        check_ctrl("B-Type BLT",   `Opcode_BType, 3'h4, 7'h00, 1'b0, `SLT, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test B-4: BGE (Branch Greater/Equal) - Usually uses SLT logic
        check_ctrl("B-Type BGE",   `Opcode_BType, 3'h5, 7'h00, 1'b0, `SLT, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test B-5: BLTU (Branch Less Than Unsigned)
        check_ctrl("B-Type BLTU",  `Opcode_BType, 3'h6, 7'h00, 1'b0, `SLTU,`OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test B-6: BGEU (Branch Greater/Equal Unsigned)
        check_ctrl("B-Type BGEU",  `Opcode_BType, 3'h7, 7'h00, 1'b0, `SLTU,`OP2_RS2, `WB_ALU, 1'b0, 1'b0);







        // Test 8: JAL (Jump)
        check_ctrl("J-Type JAL", `Opcode_JType_Jump_And_Link, 3'h0, 7'h00, 1'b1, `ADD, `OP2_RS2, `WB_PC4, 1'b0, 1'b0);
        // --- Jump Instructions ---

        // Test J-2: JALR (Jump And Link Register)
        // Calculates address as (rs1 + imm) and saves PC+4 to rd
        check_ctrl("I-Type JALR",  `Opcode_IType_Jump_And_LinkReg, 3'h0, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_PC4, 1'b0, 1'b0);







        // --- U-Type Upper Immediate Tests ---

        // Test U-1: LUI (Load Upper Immediate)
        // Operation: rd = Imm << 12. Usually, rs1 is set to 0 or ignored.
        check_ctrl("U-Type LUI",   `Opcode_UType_Load_Upper_Imm, 3'h0, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test U-2: AUIPC (Add Upper Immediate to PC)
        // Operation: rd = PC + (Imm << 12). 
        // CRITICAL: rs1sel must be set to select the PC, not a register.
        check_ctrl("U-Type AUIPC", `Opcode_UType_Add_Upper_Imm,  3'h0, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);








        // Test 11: Default Case (Unimplemented Opcode)
        check_ctrl("Default/Unknown", 7'h7F, 3'h7, 7'h7F, 1'b0, `ADD, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        $display("--------------------------------------------------------------------------------------------------");
        $finish;
    end

endmodule