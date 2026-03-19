`timescale 1ns/1ps

module tb_register_file_advanced();
    logic clk, rst, wb_en;
    logic [4:0]  id_rs1, wb_rd;
    logic [31:0] wb_data, rf_out;

    register_file dut (
        .clk(clk), .rst(rst),
        .rs1_i(id_rs1), .rs2_i(5'd0), .rd_i(wb_rd),
        .datawb_i(wb_data), .regwren_i(wb_en),
        .rs1data_o(rf_out), .rs2data_o()
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $display("\n%-15s | %-15s | %-6s | %-10s | %-10s | %-8s", 
                 "Cycle Phase", "Instruction", "Stage", "Expected", "Actual", "Task");
        $display("-----------------------------------------------------------------------------------------");

        // --- TEST CASE 1: Reset Behavior ---
        rst = 1; wb_en = 0; #15; rst = 0;
        id_rs1 = 5'd1; 
        #1; $display("%-15s | %-15s | %-6s | %-10h | %-10h | %-8s", 
                     "Reset Check", "N/A", "ID", 32'h0, rf_out, "CLEAN?");

        // --- TEST CASE 2: The x0 Rule (Writing to x0 should fail) ---
        @(posedge clk);
        wb_rd = 5'd0; wb_data = 32'hDEADBEEF; wb_en = 1;
        id_rs1 = 5'd0;
        
        #4.9; // End of 1st Half
        $display("%-15s | %-15s | %-6s | %-10h | %-10h | %-8s", 
                 "Cycle 1: 1st H", "addi x0, x0, 5", "WB", 32'hDEADBEEF, rf_out, "X0 WRITE");
        #0.2; // 2nd Half
        $display("%-15s | %-15s | %-6s | %-10h | %-10h | %-8s", 
                 "Cycle 1: 2nd H", "sub x1, x0, x2", "ID", 32'h0, rf_out, "X0 CONSTANT");

        // --- TEST CASE 3: Standard Handoff (Your FACE case) ---
        @(posedge clk);
        wb_rd = 5'd1; wb_data = 32'h0000FACE; wb_en = 1;
        id_rs1 = 5'd1;
        
        #4.9; $display("%-15s | %-15s | %-6s | %-10h | %-10h | %-8s", 
                     "Cycle 2: 1st H", "add x1, x2, x3", "WB", 32'h0000face, rf_out, "WRITE DONE");
        #0.2; $display("%-15s | %-15s | %-6s | %-10h | %-10h | %-8s", 
                     "Cycle 2: 2nd H", "sub x4, x1, x5", "ID", 32'h0000face, rf_out, "READ DONE");

        // --- TEST CASE 4: Disable Write Enable (Check if memory stays same) ---
        @(posedge clk);
        wb_rd = 5'd1; wb_data = 32'hCAFEBABE; wb_en = 0; // Notice wb_en is 0
        id_rs1 = 5'd1;

        #5.1; // Check after negedge
        $display("%-15s | %-15s | %-6s | %-10h | %-10h | %-8s", 
                 "Cycle 3: 2nd H", "nop", "ID", 32'h0000face, rf_out, "NO WRITE");

        $display("-----------------------------------------------------------------------------------------");
        $finish;
    end
endmodule