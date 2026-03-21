`timescale 1ns/1ps

module tb_pd5;

    parameter int AWIDTH = 32;
    parameter int DWIDTH = 32;
    parameter logic [31:0] BASEADDR = 32'h01000000;

    logic clk;
    logic reset;
    integer cycle_count = 0;
    integer stall_count = 0;

    pd5 #(AWIDTH, DWIDTH, BASEADDR) dut (
        .clk   (clk),
        .reset (reset)
    );

    // ============================================================
    // Clock
    // ============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // Small disassembler for readable traces
    // ============================================================
    function automatic string disassemble(logic [31:0] insn);
        logic [6:0] opcode;
        logic [4:0] rd, rs1, rs2;
        logic [2:0] funct3;
        logic [6:0] funct7;
        logic signed [31:0] imm_i;
        logic signed [31:0] imm_s;
        logic signed [31:0] imm_b;

        opcode = insn[6:0];
        rd     = insn[11:7];
        funct3 = insn[14:12];
        rs1    = insn[19:15];
        rs2    = insn[24:20];
        funct7 = insn[31:25];

        imm_i = {{20{insn[31]}}, insn[31:20]};
        imm_s = {{20{insn[31]}}, insn[31:25], insn[11:7]};
        imm_b = {{19{insn[31]}}, insn[31], insn[7], insn[30:25], insn[11:8], 1'b0};

        if (insn === 32'hxxxxxxxx) return "x";
        if (insn == 32'h00000000)  return "—";
        if (insn == 32'h00000013)  return "nop";
        if (insn == 32'h00100073)  return "ebreak";
        if (insn == 32'h00000073)  return "ecall/unk";

        case (opcode)
            7'h33: begin
                case ({funct7, funct3})
                    10'b0000000_000: return $sformatf("add  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'b0100000_000: return $sformatf("sub  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'b0000000_111: return $sformatf("and  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'b0000000_110: return $sformatf("or   x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'b0000000_100: return $sformatf("xor  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'b0000000_001: return $sformatf("sll  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'b0000000_101: return $sformatf("srl  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'b0100000_101: return $sformatf("sra  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'b0000000_010: return $sformatf("slt  x%0d, x%0d, x%0d", rd, rs1, rs2);
                    10'b0000000_011: return $sformatf("sltu x%0d, x%0d, x%0d", rd, rs1, rs2);
                    default:         return "r-type";
                endcase
            end

            7'h13: begin
                case (funct3)
                    3'b000: return $sformatf("addi x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b010: return $sformatf("slti x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b011: return $sformatf("sltiu x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b100: return $sformatf("xori x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b110: return $sformatf("ori  x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b111: return $sformatf("andi x%0d, x%0d, %0d", rd, rs1, imm_i);
                    3'b001: return $sformatf("slli x%0d, x%0d, %0d", rd, rs1, insn[24:20]);
                    3'b101: begin
                        if (funct7 == 7'b0000000)
                            return $sformatf("srli x%0d, x%0d, %0d", rd, rs1, insn[24:20]);
                        else
                            return $sformatf("srai x%0d, x%0d, %0d", rd, rs1, insn[24:20]);
                    end
                    default: return "i-alu";
                endcase
            end

            7'h03: begin
                case (funct3)
                    3'b000: return $sformatf("lb   x%0d, %0d(x%0d)", rd, imm_i, rs1);
                    3'b001: return $sformatf("lh   x%0d, %0d(x%0d)", rd, imm_i, rs1);
                    3'b010: return $sformatf("lw   x%0d, %0d(x%0d)", rd, imm_i, rs1);
                    3'b100: return $sformatf("lbu  x%0d, %0d(x%0d)", rd, imm_i, rs1);
                    3'b101: return $sformatf("lhu  x%0d, %0d(x%0d)", rd, imm_i, rs1);
                    default: return "load";
                endcase
            end

            7'h23: begin
                case (funct3)
                    3'b000: return $sformatf("sb   x%0d, %0d(x%0d)", rs2, imm_s, rs1);
                    3'b001: return $sformatf("sh   x%0d, %0d(x%0d)", rs2, imm_s, rs1);
                    3'b010: return $sformatf("sw   x%0d, %0d(x%0d)", rs2, imm_s, rs1);
                    default: return "store";
                endcase
            end

            7'h63: begin
                case (funct3)
                    3'b000: return $sformatf("beq  x%0d, x%0d, %0d", rs1, rs2, imm_b);
                    3'b001: return $sformatf("bne  x%0d, x%0d, %0d", rs1, rs2, imm_b);
                    3'b100: return $sformatf("blt  x%0d, x%0d, %0d", rs1, rs2, imm_b);
                    3'b101: return $sformatf("bge  x%0d, x%0d, %0d", rs1, rs2, imm_b);
                    3'b110: return $sformatf("bltu x%0d, x%0d, %0d", rs1, rs2, imm_b);
                    3'b111: return $sformatf("bgeu x%0d, x%0d, %0d", rs1, rs2, imm_b);
                    default: return "branch";
                endcase
            end

            7'h6f: return $sformatf("jal  x%0d, ...", rd);
            7'h67: return $sformatf("jalr x%0d, %0d(x%0d)", rd, imm_i, rs1);
            7'h37: return $sformatf("lui  x%0d, 0x%08h", rd, {insn[31:12], 12'b0});
            7'h17: return $sformatf("auipc x%0d, 0x%08h", rd, {insn[31:12], 12'b0});
            default: return $sformatf("unknown(%08h)", insn);
        endcase
    endfunction

    // ============================================================
    // Reset
    // ============================================================
    initial begin
        $display("\n=========== SIMULATION START ===========");
        reset = 1'b1;
        #20;
        reset = 1'b0;
    end

    // ============================================================
    // Cycle-by-cycle trace
    // ============================================================
    always @(negedge clk) begin
        if (!reset) begin
            cycle_count = cycle_count + 1;

            $display("\n=========== CYCLE %0d ===========", cycle_count);
            $display("IF : PC=%08h INSN=%08h   %s", dut.if_pc,    dut.if_insn,    disassemble(dut.if_insn));
            $display("ID : PC=%08h INSN=%08h   %s", dut.if_id_pc, dut.id_insn,    disassemble(dut.id_insn));
            $display("EX : PC=%08h INSN=%08h   ALU=%08h", dut.id_ex_pc,  dut.id_ex_insn,  dut.ex_alu_res_raw);
            if (dut.ex_mem_memwren)
                $display("MEM: PC=%08h RD=x%0d ADDR=%08h DATA=%08h MEMR=%0b MEMW=%0b",
                        dut.ex_mem_pc, dut.ex_mem_rd, dut.ex_mem_alu_res, dut.ex_mem_rs2_data,
                        dut.ex_mem_memren, dut.ex_mem_memwren);
            else
                $display("MEM: PC=%08h RD=x%0d ADDR=%08h DATA=%08h MEMR=%0b MEMW=%0b",
                        dut.ex_mem_pc, dut.ex_mem_rd, dut.ex_mem_alu_res, dut.mem_read_data,
                        dut.ex_mem_memren, dut.ex_mem_memwren);

            if (dut.assign_w_write_enable && (dut.assign_w_write_destination != 0))
                $display("WB : PC=%08h WE=1 RD=x%0d DATA=%08h",
                         dut.mem_wb_pc, dut.assign_w_write_destination, dut.assign_w_data);
            else
                $display("WB : PC=%08h WE=0 RD=x%0d DATA=%08h",
                         dut.mem_wb_pc, dut.assign_w_write_destination, dut.assign_w_data);

            if (dut.stall) begin
                stall_count = stall_count + 1;
                $display("*** STALL ASSERTED ***");
                $display("    load in EX/MEM path: rd=x%0d, memren=%0b", dut.id_ex_rd, dut.id_ex_memren);
                $display("    decode wants: rs1=x%0d rs2=x%0d", dut.id_rs1, dut.id_rs2);
            end

            if (dut.ex_redirect_taken)
                $display("*** FLUSH / REDIRECT *** target=%08h", dut.ex_redirect_target);

            // Helpful sanity check for a correct load-use stall:
            // during a stall, IF/ID should hold while ID/EX becomes a bubble on the next posedge.
            if (dut.stall) begin
                $display("    IF/ID currently holding: PC=%08h INSN=%08h", dut.if_id_pc, dut.if_id_insn);
            end

            // Stop when ebreak reaches decode/fetch
            if ((dut.if_insn == 32'h00100073) || (dut.id_insn == 32'h00100073) ||
                (dut.if_insn == 32'h00000073) || (dut.id_insn == 32'h00000073)) begin
                $display("\n=========== PROGRAM STOP ===========");
                $display("Total cycles : %0d", cycle_count);
                $display("Total stalls : %0d", stall_count);
                $finish;
            end

            if (cycle_count > 10000) begin
                $display("\n=========== TIMEOUT ===========");
                $display("Total cycles : %0d", cycle_count);
                $display("Total stalls : %0d", stall_count);
                $finish;
            end
        end
    end

endmodule
