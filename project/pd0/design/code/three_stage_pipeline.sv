/*
 * Module: three_stage_pipeline
 *
 * A 3-stage pipeline (TSP) where the first stage performs an addition of two
 * operands (op1_i, op2_i) and registers the output, and the second stage computes
 * the difference between the output from the first stage and op1_i and registers the
 * output. This means that the output (res_o) must be available two cycles after the
 * corresponding inputs have been observed on the rising clock edge
 *
 * Visually, the circuit should look like this:
 *               <---         Stage 1           --->
 *                                                        <---         Stage 2           --->
 *                                                                                               <--    Stage 3    -->
 *                                    |------------------>|                    |
 * -- op1_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *             | pipeline registers |     | ALU add | --> | pipeline registers |   | ALU sub |-->| pipeline register  | -- res_o -->
 * -- op2_i -->|                    | --> |         |     |                    |-->|         |   |                    |
 *
 * Inputs:
 * 1) 1-bit clock signal
 * 2) 1-bit wide synchronous reset
 * 3) DWIDTH-wide input op1_i
 * 4) DWIDTH-wide input op2_i
 *
 * Outputs:
 * 1) DWIDTH-wide result res_o
 */

module three_stage_pipeline #(
parameter int DWIDTH = 32)(
        input logic clk,
        input logic rst,
        input logic [DWIDTH-1:0] op1_i,
        input logic [DWIDTH-1:0] op2_i,
        output logic [DWIDTH-1:0] res_o
    );

    /*
     * Process definitions to be filled by
     * student below...
     * [HINT] Instantiate the alu and reg_rst modules
     * and set up the necessary connections
     *
     */

    logic [DWIDTH-1:0] adder_i_1, adder_i_2, op1_stg2; //stage 1 putputs
    logic [DWIDTH-1:0] adder_o, subtractor_o;
    logic [DWIDTH-1:0] subtractor_i_1, subtractor_i_2;

    // Stage 1 //
    reg_rst #(
        .DWIDTH(DWIDTH)
    ) pipeline_stage_1_1 (
        .clk                (clk),
        .rst                (rst),
        .in_i               (op1_i),
        .out_o              (adder_i_1)
    );
    
    reg_rst #(
        .DWIDTH(DWIDTH)
    ) pipeline_stage_1_2 (
        .clk                (clk),
        .rst                (rst),
        .in_i               (op2_i),
        .out_o              (adder_i_2)
    );

    reg_rst #(
        .DWIDTH(DWIDTH)
    ) pipeline_stage_1_3 (
        .clk                (clk),
        .rst                (rst),
        .in_i               (op1_i),
        .out_o              (op1_stg2)
    );

    // Stage 2 //

    reg_rst #( 
        .DWIDTH(DWIDTH)
    ) pipeline_stage_2_1 (
        .clk                (clk),
        .rst                (rst),
        .in_i               (adder_o),
        .out_o              (subtractor_i_1)
    );

    reg_rst #( 
        .DWIDTH(DWIDTH)
    ) pipeline_stage_2_2 (
        .clk                (clk),
        .rst                (rst),
        .in_i               (op1_stg2),
        .out_o              (subtractor_i_2)
    );

    // Stage 3 //

    reg_rst #( 
        .DWIDTH(DWIDTH)
    ) pipeline_stage_2_3 (
        .clk                (clk),
        .rst                (rst),
        .in_i               (subtractor_o),
        .out_o              (res_o)
    );


    ////////////////////////////
    //         ALUs           //
    ////////////////////////////

    alu #(
        .DWIDTH(DWIDTH)
    ) adder (
        .sel_i              (2'b00),
        .op1_i              (adder_i_1),
        .op2_i              (adder_i_2),
        .res_o              (adder_o),
        .zero_o             (),
        .neg_o              ()
    );

    alu #(
        .DWIDTH(DWIDTH)
    ) subctractor (
        .sel_i              (2'b01),
        .op1_i              (subtractor_i_1),
        .op2_i              (subtractor_i_2),
        .res_o              (subtractor_o),
        .zero_o             (),
        .neg_o              ()
    );


endmodule: three_stage_pipeline
