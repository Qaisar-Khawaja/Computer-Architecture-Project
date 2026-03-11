`timescale 1ns/1ps

module tb_pd4;

    // --- Signals ---
    logic clk;
    logic reset;
    int cycle = 0;
    int error_count = 0;
    int test_count = 0;

    // --- Addressing Point #1:
    localparam logic [31:0] START_ADDRESS     = 32'h01000004;
    localparam int          MAX_CYCLES        = 50;

    // --- Instantiate Design Under Test (DUT) ---
    pd4 dut(
        .clk(clk),
        .reset(reset)
    );

    // --- Clock Generation ---
    initial clk = 0;
    always #5 clk = ~clk;

    // --- Simulation Control ---
    initial begin
        reset = 1;
        #22; 
        reset = 0;
        
        print_header();

        while (cycle < MAX_CYCLES) begin
            @(posedge clk);
            #1; // Wait for logic to settle
            cycle++;
            
            print_pipeline();
            perform_checks();

            // Detect end of program
            if (dut.assign_f_insn == 32'h00008067 || dut.assign_f_insn == 32'h00000073) begin
                $display("\n[INFO] End of program detected at Cycle %0d", cycle);
                break;
            end
        end

        // Scorekeeping Summary
        $display("\n--- SIMULATION SUMMARY ---");
        if (error_count == 0 && test_count > 0)
            $display("*** ALL %0d CHECKS PASSED ***", test_count);
        else
            $error("*** %0d/%0d CHECKS FAILED ***", error_count, test_count);
            
        $finish;
    end

    // --- Helper Task: Header ---
    task print_header;
        $display("\nCyc | PC       | HEX VAL| [Fetch] PC | [Decode] | [Execute]  | [Memory]| [WB]| STATUS");
        $display("-----------------------------------------------------------------------------------------------------------------------------------");
    endtask

    // --- Addressing Point #3 & #6: Self-Checking Logic ---
    task perform_checks;
        test_count++; 

        // Health Check: PC should not be 'X'
        if (^dut.assign_f_pc === 1'bX) begin
            $error("FAIL: Cycle %0d - PC is Unknown!", cycle);
            error_count++;
        end

        // Functional Check: Initialization
        if (cycle == 1 && dut.assign_f_pc !== START_ADDRESS) begin
            $error("FAIL: Start Address Mismatch! Expected %h, Got %h", START_ADDRESS, dut.assign_f_pc);
            error_count++;
        end
    endtask

    // --- Monitor Task (Matches your pd4.sv internal wires) ---
    task automatic print_pipeline;
        $display("%3d | %8h | %8h | %8h | %8h | %8h | %8h | %8h | %s",
            cycle,
            dut.assign_f_pc,      // Main PC Column
            dut.assign_f_insn,    // Main Hex Column
            dut.assign_f_pc,      // [F] Stage PC
            dut.assign_d_insn,    // [D] Stage Instruction
            dut.assign_e_alu_res, // [E] Stage ALU Result
            dut.assign_m_data,    // [M] Stage Memory Data (matches your pd4 line 125)
            dut.assign_w_data,    // [W] Stage Writeback Data (matches your pd4 line 140)
            (^dut.assign_f_pc === 1'bX) ? "FAIL" : "PASS"
        );
    endtask

endmodule