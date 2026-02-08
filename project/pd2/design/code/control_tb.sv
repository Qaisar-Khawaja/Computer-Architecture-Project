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

    control #( .DWIDTH(DWIDTH) ) uut (
        .insn_i(insn), .opcode_i(opcode), .funct7_i(funct7), .funct3_i(funct3),
        .pcsel_o(pcsel), .immsel_o(immsel), .regwren_o(regwren),
        .rs1sel_o(rs1sel), .rs2sel_o(rs2sel), .memren_o(memren),
        .memwren_o(memwren), .wbsel_o(wbsel), .alusel_o(alusel)
    );

    // Helper
    task check_ctrl(
        input string name,
        input logic [6:0] op, input logic [2:0] f3, input logic [6:0] f7,
        input logic e_regwren, input logic [3:0] e_alusel, 
        input logic e_rs2sel,   input logic [1:0] e_wbsel,
        input logic e_memren,   input logic e_memwren
    );
        opcode = op; funct3 = f3; funct7 = f7; insn = 32'h0;
        #10;
        $display("%0t\t %-18s\t %b\t %b\t %b\t %b\t %b\t %s", 
            $time, name, regwren, alusel, rs2sel, wbsel, memwren,
            (regwren === e_regwren && alusel === e_alusel && rs2sel === e_rs2sel && 
             wbsel === e_wbsel     && memren === e_memren && memwren === e_memwren) ? "PASS" : "FAIL"
        );
    endtask

    initial begin
        $display("Time\t Type\t\t\t RegW\t ALU\t RS2S\t WB\t MemW\t Check");
        $display("--------------------------------------------------------------------------------------------------");

        // Test 1: ADD
        check_ctrl("R-Type ADD", `Opcode_RType, 3'h0, 7'h00, 1'b1, `ADD, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 2: SUB
        check_ctrl("R-Type SUB", `Opcode_RType, 3'h0, 7'h20, 1'b1, `SUB, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 3: SRL
        check_ctrl("R-Type SRL", `Opcode_RType, 3'h5, 7'h00, 1'b1, `SRL, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 4: SRA
        check_ctrl("R-Type SRA", `Opcode_RType, 3'h5, 7'h20, 1'b1, `SRA, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 5: SLT
        check_ctrl("R-Type SLT", `Opcode_RType, 3'h2, 7'h00, 1'b1, `SLT, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 6: SLTU
        check_ctrl("R-Type SLTU", `Opcode_RType, 3'h3, 7'h00, 1'b1, `SLTU, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 7: XOR
        check_ctrl("R-Type XOR", `Opcode_RType, 3'h4, 7'h00, 1'b1, `XOR, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 8: SLL
        check_ctrl("R-Type SLL", `Opcode_RType, 3'h1, 7'h00, 1'b1, `SLL, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 9: OR
        check_ctrl("R-Type OR",  `Opcode_RType, 3'h6, 7'h00, 1'b1, `OR,  `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 10: AND
        check_ctrl("R-Type AND", `Opcode_RType, 3'h7, 7'h00, 1'b1, `AND, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);





        // I-Type Tests
        // Test 1: ADDI
        check_ctrl("I-Type ADDI", `Opcode_IType, 3'h0, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test 2: XORI
        check_ctrl("I-Type XORI", `Opcode_IType, 3'h4, 7'h00, 1'b1, `XOR, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test 3: ORI
        check_ctrl("I-Type ORI",  `Opcode_IType, 3'h6, 7'h00, 1'b1, `OR,  `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test 4: ANDI
        check_ctrl("I-Type ANDI", `Opcode_IType, 3'h7, 7'h00, 1'b1, `AND, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test 5: SLLI
        check_ctrl("I-Type SLLI", `Opcode_IType, 3'h1, 7'h00, 1'b1, `SLL, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test 6: SRLI
        check_ctrl("I-Type SRLI", `Opcode_IType, 3'h5, 7'h00, 1'b1, `SRL, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test 7: SRAI
        check_ctrl("I-Type SRAI", `Opcode_IType, 3'h5, 7'h20, 1'b1, `SRA, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test 8: SLTI
        check_ctrl("I-Type SLTI", `Opcode_IType, 3'h2, 7'h00, 1'b1, `SLT, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test 9: SLTIU
        check_ctrl("I-Type SLTIU",`Opcode_IType, 3'h3, 7'h00, 1'b1, `SLTU, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);






        // I-Type Load Test
        // Test 1: LB
        check_ctrl("I-Type LB",   `Opcode_IType_Load, 3'h0, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_MEM, 1'b1, 1'b0);

        // Test 2: LH
        check_ctrl("I-Type LH",   `Opcode_IType_Load, 3'h1, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_MEM, 1'b1, 1'b0);

        // Test 3: LW
        check_ctrl("I-Type LW",   `Opcode_IType_Load, 3'h2, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_MEM, 1'b1, 1'b0);

        // Test 4: LBU
        check_ctrl("I-Type LBU",  `Opcode_IType_Load, 3'h4, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_MEM, 1'b1, 1'b0);

        // Test 5: LHU
        check_ctrl("I-Type LHU",  `Opcode_IType_Load, 3'h5, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_MEM, 1'b1, 1'b0);




        // S-Type Tests
        // Test 1: SB
        check_ctrl("S-Type SB",   `Opcode_SType, 3'h0, 7'h00, 1'b0, `ADD, `OP2_IMM, `WB_ALU, 1'b0, 1'b1);

        // Test 2: SH
        check_ctrl("S-Type SH",   `Opcode_SType, 3'h1, 7'h00, 1'b0, `ADD, `OP2_IMM, `WB_ALU, 1'b0, 1'b1);

        // Test 3: SW
        check_ctrl("S-Type SW",   `Opcode_SType, 3'h2, 7'h00, 1'b0, `ADD, `OP2_IMM, `WB_ALU, 1'b0, 1'b1);





        // B-Type Tests
        // Test 1: BEQ
        check_ctrl("B-Type BEQ",   `Opcode_BType, 3'h0, 7'h00, 1'b0, `SUB, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 2: BNE
        check_ctrl("B-Type BNE",   `Opcode_BType, 3'h1, 7'h00, 1'b0, `SUB, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 3: BLT
        check_ctrl("B-Type BLT",   `Opcode_BType, 3'h4, 7'h00, 1'b0, `SLT, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 4: BGE
        check_ctrl("B-Type BGE",   `Opcode_BType, 3'h5, 7'h00, 1'b0, `SLT, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 5: BLTU
        check_ctrl("B-Type BLTU",  `Opcode_BType, 3'h6, 7'h00, 1'b0, `SLTU,`OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        // Test 6: BGEU
        check_ctrl("B-Type BGEU",  `Opcode_BType, 3'h7, 7'h00, 1'b0, `SLTU,`OP2_RS2, `WB_ALU, 1'b0, 1'b0);




        // J-Type Tests
        // Test 1: JAL
        check_ctrl("J-Type JAL", `Opcode_JType_Jump_And_Link, 3'h0, 7'h00, 1'b1, `ADD, `OP2_RS2, `WB_PC4, 1'b0, 1'b0);

        // Test 2: JALR
        check_ctrl("I-Type JALR",  `Opcode_IType_Jump_And_LinkReg, 3'h0, 7'h00, 1'b1, `ADD, `OP2_IMM, `WB_PC4, 1'b0, 1'b0);

        //U-Type Tests
        // Test 1: LUI
        check_ctrl("U-Type LUI",   `Opcode_UType_Load_Upper_Imm, 3'h0, 7'h00, 1'b1, `LUI, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test 2: AUIPC
        check_ctrl("U-Type AUIPC", `Opcode_UType_Add_Upper_Imm,  3'h0, 7'h00, 1'b1, `AUIPC, `OP2_IMM, `WB_ALU, 1'b0, 1'b0);

        // Test Default Case
        check_ctrl("Default/Unknown", 7'h7F, 3'h7, 7'h7F, 1'b0, `ADD, `OP2_RS2, `WB_ALU, 1'b0, 1'b0);

        $display("--------------------------------------------------------------------------------------------------");
        $finish;
    end

endmodule