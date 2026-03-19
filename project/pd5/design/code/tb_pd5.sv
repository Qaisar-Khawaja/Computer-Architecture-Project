`timescale 1ns/1ps

module tb_pd5;
    parameter int AWIDTH = 32;
    parameter int DWIDTH = 32;
    parameter logic [31:0] BASEADDR = 32'h01000000;

    logic clk;
    logic reset;
    integer cycle_count;

    // Instantiate your 5-stage pipeline
    pd5 #(AWIDTH, DWIDTH, BASEADDR) dut (
        .clk(clk),
        .reset(reset)
    );

    // --- DISASSEMBLER FUNCTION ---
    // This turns the 32-bit hex instruction into a human-readable string
    function string disassemble(logic [31:0] insn);
        logic [6:0] opcode = insn[6:0];
        logic [2:0] funct3 = insn[14:12];
        logic [6:0] funct7 = insn[31:25];
        logic [4:0] rd     = insn[11:7];
        logic [4:0] rs1    = insn[19:15];
        logic [4:0] rs2    = insn[24:20];
        logic [31:0] imm_i = {{20{insn[31]}}, insn[31:20]};
        logic [31:0] imm_s = {{20{insn[31]}}, insn[31:25], insn[11:7]};

        if (insn == 32'h00000013) return "nop";
        if (insn == 32'h00000073) return "ebreak";

        case (opcode)
            7'h33: begin // R-type
                case ({funct7, funct3})
                    10'h000: return $sformatf("add  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'h100: return $sformatf("sub  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'h007: return $sformatf("and  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'h006: return $sformatf("or   x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'h004: return $sformatf("xor  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    default: return "r-type";
                endcase
            end
            7'h13: begin // I-type ALU
                case (funct3)
                    3'h0: return $sformatf("addi x%0d, x%0d, %0d", rd, rs1, $signed(imm_i));
                    3'h4: return $sformatf("xori x%0d, x%0d, %0d", rd, rs1, $signed(imm_i));
                    3'h6: return $sformatf("ori  x%0d, x%0d, %0d", rd, rs1, $signed(imm_i));
                    3'h7: return $sformatf("andi x%0d, x%0d, %0d", rd, rs1, $signed(imm_i));
                    default: return "i-alu";
                endcase
            end
            7'h03: return $sformatf("lw   x%0d, %0d(x%0d)", rd, $signed(imm_i), rs1);
            7'h23: return $sformatf("sw   x%0d, %0d(x%0d)", rs2, $signed(imm_s), rs1);
            7'h63: return "branch";
            7'h6f: return "jal";
            7'h67: return "jalr";
            7'h37: return "lui";
            7'h17: return "auipc";
            default: return "unknown";
        endcase
    endfunction

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $display("--- SIMULATION STARTED ---");
        reset = 1;
        cycle_count = 0;
        #22 reset = 0; 
        
        $display("\n--- PIPELINE EXECUTION TRACE ---");
        $display("Cycle | IF_PC    | ID_Insn (Current)      | Pipe | WB_Data  | Hazards");
        $display("-------------------------------------------------------------------------");
    end

    // Monitor logic on the falling edge (signals are stable here)
    always @(negedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;
            
            // 1. Basic Info
            $write("C%-4d | %h | ", cycle_count, dut.if_pc);
            
            // 2. Disassemble what is currently in the DECODE stage
            $write("%-22s | ", disassemble(dut.id_insn));

            // 3. Visual Pipeline Map
            $write("%s|%s|%s| M | W | ", 
                dut.stall   ? "F*" : " F ", 
                dut.stall   ? "D*" : " D ",
                dut.brtaken ? "X#" : " X ");

            // 4. Writeback Data
            if (dut.wb_regwren && (dut.wb_rd != 0))
                $write("%h | ", dut.wb_data);
            else
                $write("-------- | ");

            // 5. Diagnostics
            if (dut.stall)   $write("[STALL] ");
            if (dut.brtaken) $write("[FLUSH] ");
            
            // Check for Forwarding
            if (dut.fwd_a_data != dut.ex_rs1_data || dut.fwd_b_data != dut.ex_rs2_data)
                $write("[FWD] ");

            $display(""); 

            // Safety timeout
            if (cycle_count > 2000) begin
                $display("\n--- TIMEOUT reached ---");
                $finish;
            end
        end
    end

endmodule