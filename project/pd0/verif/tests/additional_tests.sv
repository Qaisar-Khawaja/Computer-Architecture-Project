/*
 * Module: top
 *
 * Description: Testbench that drives the probes and displays the signal changes
 */
`include "probes.svh"

module top;
 logic clock;
 logic reset;

 clockgen clkg(
     .clk(clock),
     .rst(reset)
 );

 design_wrapper dut(
     .clk(clock),
     .reset(reset)
 );

 integer counter = 0;
 integer errors = 0;


 always_ff @(posedge clock) begin
    counter <= counter + 1;
    if(counter == 25) begin
        $display("[PD0] No error encountered");
        $finish;
    end
 end

 initial begin
    $monitor(" clk = %0b", clock);
 end

 always_ff @(negedge clock) begin
    $display("###########");
 end

 logic       reset_done;
 logic       reset_neg;
 logic       reset_reg;
 integer     reset_counter;
 always_ff @(posedge clock) begin
   if(reset) reset_counter <= 0;
   else      reset_counter <= reset_counter + 1;
   // detect negedge
   reset_reg <= reset;
   if(reset_reg && !reset) reset_neg <= 1;
   // delay for some cycles
   if(reset_neg && reset_counter >= 3) begin
     reset_done <= 1;
   end
 end

 // assign_xor
 logic assign_xor_op1;
 logic assign_xor_op2;
 logic assign_xor_res;

 always_comb begin: assign_xor_input
     dut.core.`PROBE_ASSIGN_XOR_OP1 = counter[0];
     dut.core.`PROBE_ASSIGN_XOR_OP2 = counter[1];
 end

 always_ff @(posedge clock) begin: assign_xor_test
     if (reset_done) begin
        $display("[ASSIGN_XOR] op1=%b, op2=%b, res=%b", assign_xor_op1, assign_xor_op2, assign_xor_res);
     end
     assign_xor_op1 <= dut.core.`PROBE_ASSIGN_XOR_OP1;
     assign_xor_op2 <= dut.core.`PROBE_ASSIGN_XOR_OP2;
     assign_xor_res <= dut.core.`PROBE_ASSIGN_XOR_RES;
 end

`ifdef PROBE_ALU_OP1 `ifdef PROBE_ALU_OP2 `ifdef PROBE_ALU_SEL `ifdef PROBE_ALU_RES
    `define PROBE_ALU_OK
`endif  `endif `endif `endif
`ifdef PROBE_ALU_OK

 wire [1:0]  alu_sel = dut.core.`PROBE_ALU_SEL;  
 wire [31:0] alu_op1 = dut.core.`PROBE_ALU_OP1;  
 wire [31:0] alu_op2 = dut.core.`PROBE_ALU_OP2;  
 wire [31:0] alu_res = dut.core.`PROBE_ALU_RES;

integer count_alu = 0;

// to cycle through different testcases
  always_ff @(posedge clock) begin
    if (reset_done) begin
        count_alu <= count_alu + 1;
    end
 end

 always_comb begin: alu_input
    case (count_alu)
        'd0: begin // ADD 
            dut.core.`PROBE_ALU_SEL = 2'b00;
            dut.core.`PROBE_ALU_OP1 = 'd10;
            dut.core.`PROBE_ALU_OP2 = 'd20;
        end

        'd1: begin //ADD edge case
            dut.core.`PROBE_ALU_SEL = 2'b00;
            dut.core.`PROBE_ALU_OP1 = 32'b11111111111111111111111111111111;
            dut.core.`PROBE_ALU_OP2 = 'b1;
        end

        'd2: begin // SUBTRACT
            dut.core.`PROBE_ALU_SEL = 2'b01;
            dut.core.`PROBE_ALU_OP1 = 'd20;
            dut.core.`PROBE_ALU_OP2 = 'd10;
        end

        'd3: begin // SUBTRACT edge case
            dut.core.`PROBE_ALU_SEL = 2'b01;
            dut.core.`PROBE_ALU_OP1 = 32'b00000000000000000000000000000000;
            dut.core.`PROBE_ALU_OP2 = 'd1;
        end

        'd4: begin // AND - bitmasking
            dut.core.`PROBE_ALU_SEL = 2'b10;
            dut.core.`PROBE_ALU_OP1 = 32'hAAAA_AAAA;
            dut.core.`PROBE_ALU_OP2 = 32'h5555_5555;
        end

        'd5: begin // OR
            dut.core.`PROBE_ALU_SEL = 2'b11;
            dut.core.`PROBE_ALU_OP1 = 32'hF0F0_F0F0;
            dut.core.`PROBE_ALU_OP2 = 32'h0F0F_0F0F;
        end

        default : begin
            dut.core.`PROBE_ALU_SEL = 'b00;
            dut.core.`PROBE_ALU_OP1 = 'd0;
            dut.core.`PROBE_ALU_OP2 = 'd0;
        end
    endcase
  end
  always_ff @(posedge clock) begin: alu_test
      if (reset_done) begin
          $display("[ALU] inp1=%b, inp2=%b, alusel=%b, res=%b, alu_count=%b", alu_op1, alu_op2, alu_sel, alu_res, count_alu);
      end
  end
 `else
    always_ff @(posedge clock) begin: alu_test
        $fatal(1, "[ALU] Probe signals not defined");
    end
`endif


`ifdef PROBE_REG_IN `ifdef PROBE_REG_OUT
`define PROBE_REG_OK
`endif `endif
`ifdef PROBE_REG_OK
  logic [31:0] reg_rst_inp;
  logic [31:0] reg_rst_out;

  always_comb begin: reg_rst_input
      dut.core.`PROBE_REG_IN = counter[31:0];
  end
  always_ff @(posedge clock) begin: reg_rst_test
      if (reset_done) begin
        $display("[REG] inp=%b, out=%b", reg_rst_inp, reg_rst_out);
      end
      reg_rst_inp <= dut.core.`PROBE_REG_IN;
      reg_rst_out <= dut.core.`PROBE_REG_OUT;
  end
  `else
    always_ff @(posedge clock) begin: reg_rst_test
        $fatal(1, "[REG] Probe signals not defined");
    end
`endif

`ifdef PROBE_TSP_OP1 `ifdef PROBE_TSP_OP2 `ifdef PROBE_TSP_RES
`define PROBE_TSP_OK
`endif `endif `endif
`ifdef PROBE_TSP_OK

  // three_stage_pipeline
  logic [31:0] tsp_op1;
  logic [31:0] tsp_op2;
  logic [31:0] tsp_out;
  always_comb begin: tsp_input
      dut.core.`PROBE_TSP_OP1 = counter[31:0];
      dut.core.`PROBE_TSP_OP2 = {counter[1], counter[2], counter[0], counter[31:3]};
  end
  always_ff @(posedge clock) begin: tsp_test
      if (reset_done) begin
        $display("[TSP] op1=%b, op2=%b, out=%b", tsp_op1, tsp_op2, tsp_out);
      end
      tsp_op1 <= dut.core.`PROBE_TSP_OP1;
      tsp_op2 <= dut.core.`PROBE_TSP_OP2;
      tsp_out <= dut.core.`PROBE_TSP_RES;
  end
    `else
    always_ff @(posedge clock) begin: tsp_test
        $fatal(1, "[TSP] Probe signals not defined");
    end
`endif


 `ifdef VCD
  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars;
  end
  `endif
endmodule
