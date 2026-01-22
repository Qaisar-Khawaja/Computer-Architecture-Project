/*
 * Module: fetch_testbench
 *
 * Description: Testbench that drives the probes and displays the signal changes
 */
`include "probes.svh"

module fetch_testbench;
 logic clock;
 logic reset;


localparam int DWIDTH = 32;
localparam int AWIDTH = 32;
localparam logic [31:0] BASEADDR = 32'h01000000;


//Verification Variables
 integer counter = 0; 
 integer errors = 0;
 logic [31:0] prev_pc;

 clockgen clkg(
     .clk(clock),
     .rst(reset)
 );

 design_wrapper dut(
     .clk(clock),
     .reset(reset)
 );


// always_ff @(posedge clock) begin
//     if (!reset) begin
//         $display("[T=%0d] PC Output: %h | Instruction: %h", counter, dut.core.`PROBE_F_PC, dut.core.`PROBE_F_INSN);
//     end
// end

//Test: PC reset and increment
always_ff @(posedge clock) begin
    if(reset) begin
        counter <= 0;
        prev_pc <= BASEADDR;
    end
    else begin
        counter <= counter + 1;
        //Test: PC updates correctly
        if (counter > 0 && counter < 10) begin 
            if(dut.core.`PROBE_F_PC != prev_pc + 4) begin
                $display("[ERROR] PC didn't increment as expected.");
                errors <= errors + 1;
            end
        end

        if (counter == 10) begin
        //Test: Overflow of PC
            $display("Force Test: Setting PC value to the maxium");
            force dut.core.`PROBE_F_PC = 32'hFFFF_FFFC;
        end

        if (counter == 11) begin
            $display("releasing force");
            release dut.core.`PROBE_F_PC;
        end
        if (counter == 12)begin
            if(dut.core.`PROBE_F_PC == 32'h00000000) begin
                $display("PC Reached the edge and rolled to 0");
            end
            else if (dut.core.`PROBE_F_PC == BASEADDR) begin
                $display("PC reached the edge and back to baseaddr.");
                errors <= errors + 1;
            end
        end
    prev_pc <= dut.core.`PROBE_F_PC; //Update the PC for the next cycle.
    
    //Test: Alignment Check (Valid Word Boundary)
        if (dut.core.`PROBE_F_PC[1:0] != 2'b00)begin
            $display("Error in alignment");
            errors <= errors + 1;
        end


    end


end

initial begin
    wait(counter == 25);
    $display("Test Finished with %0d errors", errors);
    $finish;
end

 `ifdef VCD
  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars(0, fetch_testbench);
  end
  `endif
endmodule