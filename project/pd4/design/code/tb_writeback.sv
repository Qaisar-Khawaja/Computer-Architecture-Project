`timescale 1ns/1ps
`include "constants.svh"

module write_back_tb;
    // Signals
    logic [31:0] pc, alu_res, mem_data, wb_out;
    logic [1:0] wbsel;
    
    // Internal helper for validation
    logic [31:0] expected;
    
    // DUT Instance
    writeback uut (
        .pc_i(pc), 
        .alu_res_i(alu_res), 
        .memory_data_i(mem_data),
        .wbsel_i(wbsel), 
        .writeback_data_o(wb_out)
    );

    // Array for 30 instructions from your dump
    logic [31:0] trace[30];
    
    // Use an integer for the loop to satisfy Icarus requirements
    integer i;
    // Use a string variable that matches your assignments
    string t_name; 

    initial begin
        // --- 1. ALU/Arithmetic Path ---
        trace[0]=32'hfd010113; trace[1]=32'h010007b7; trace[2]=32'h24878713;
        trace[3]=32'h24878793; trace[4]=32'h00010793; trace[5]=32'h00800593;
        trace[6]=32'h00078513; trace[7]=32'h00050793; trace[8]=32'h03010113;
        trace[9]=32'hfe010113; trace[10]=32'h2487a883; trace[11]=32'h00472803;
        trace[12]=32'h00872503; trace[13]=32'h00c72583; trace[14]=32'h01072603;
        trace[15]=32'h01472683; trace[16]=32'h01872703; trace[17]=32'h01c7a783;
        trace[18]=32'h02c12083; trace[19]=32'h01812703; trace[20]=32'h024000ef;
        trace[21]=32'h124000ef; trace[22]=32'h00008067; trace[23]=32'h0e40006f;
        trace[24]=32'h0b80006f; trace[25]=32'hfd1ff0ef; trace[26]=32'hfbdff0ef;
        trace[27]=32'h048000ef; trace[28]=32'h018000ef; trace[29]=32'h024000ef;

        // Waveform Setup
        $dumpfile("writeback_full_test.vcd");
        $dumpvars(0, write_back_tb);

        $display("\n--- PHASE 1: PROGRAM TRACE (30 INSTRUCTIONS) ---");
        $display("Idx\t Instruction\t Type\t Sel\t Expected\t Actual\t\t Result");
        $display("---------------------------------------------------------------------------------------");

        for (i = 0; i < 30; i = i + 1) begin
            pc = 32'h00010000 + (i * 4); 
            alu_res = 32'hAAAA_0000 + i; 
            mem_data = 32'hBEEF_0000 + i;

            case (trace[i][6:0])
                7'h03:   begin t_name="LOAD "; wbsel=`WB_MEM; expected=mem_data; end
                7'h6f, 7'h67: begin t_name="JUMP "; wbsel=`WB_PC4; expected=pc + 4;   end
                default: begin t_name="ALU  "; wbsel=`WB_ALU; expected=alu_res;  end
            endcase

            #10;
            $display("%0d\t %h\t %s\t %b\t %h\t %h\t %s", 
                i, trace[i], t_name, wbsel, expected, wb_out, (wb_out === expected) ? "PASS" : "FAIL");
        end

        $display("\n--- PHASE 2: EDGE CASES ---");
        $display("Test Case\t\t\t Sel\t Expected\t Actual\t\t Result");
        $display("---------------------------------------------------------------------------------------");

        // 1. PC Overflow Wrap
        pc = 32'hFFFF_FFFC; alu_res = 32'h0; mem_data = 32'h0; wbsel = `WB_PC4; expected = 32'h0;
        #10; $display("PC Wrap-around (Max+4)\t %b\t %h\t %h\t %s", wbsel, expected, wb_out, (wb_out === expected) ? "PASS" : "FAIL");

        // 2. Default Case (Invalid Selector 2'b11)
        pc = 32'h1234_5678; alu_res = 32'hDEAD_BEEF; wbsel = 2'b11; expected = alu_res;
        #10; $display("Invalid Sel (Default)\t %b\t %h\t %h\t %s", wbsel, expected, wb_out, (wb_out === expected) ? "PASS" : "FAIL");

        // 3. All Bits Toggling
        pc = 32'h0; alu_res = 32'hFFFF_FFFF; wbsel = `WB_ALU; expected = 32'hFFFF_FFFF;
        #10; $display("Full Bit Stress (All 1s)\t %b\t %h\t %h\t %s", wbsel, expected, wb_out, (wb_out === expected) ? "PASS" : "FAIL");

        // 4. Data Unknown (X) Propagation
        // Note: === is used to compare X values correctly
        alu_res = 32'hX; wbsel = `WB_ALU; expected = 32'hX;
        #10; $display("X-Value Propagation   \t %b\t %h\t %h\t %s", wbsel, expected, wb_out, (wb_out === expected) ? "PASS" : "FAIL");

        // 5. High-Address JALR
        pc = 32'h8000_0000; wbsel = `WB_PC4; expected = 32'h8000_0004;
        #10; $display("High PC + 4 Check     \t %b\t %h\t %h\t %s", wbsel, expected, wb_out, (wb_out === expected) ? "PASS" : "FAIL");

        $display("---------------------------------------------------------------------------------------\n");
        $finish;
    end
endmodule