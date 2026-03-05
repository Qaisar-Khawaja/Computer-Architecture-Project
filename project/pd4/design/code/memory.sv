/*
 * -------- REPLACE THIS FILE WITH THE MEMORY MODULE DEVELOPED IN PD1 -----------
 * Module: memory
 *
 * Description: Byte-addressable memory implementation. Supports both read and write.
 *
 * Inputs:
 * 1) clk
 * 2) rst signal
 * 3) AWIDTH address addr_i
 * 4) DWIDTH data to write data_i
 * 5) read enable signal read_en_i
 * 6) write enable signal write_en_i
 *
 * Outputs:
 * 1) DWIDTH data output data_o
 * 2) data out valid signal data_vld_o
 */
// `include "constants.svh"

// module memory #(
//   // parameters
//   parameter int AWIDTH = 32,
//   parameter int DWIDTH = 32,
//   parameter logic [31:0] BASE_ADDR = 32'h01000000
// ) (
//   // inputs
//   input logic clk,
//   input logic rst,
//   input logic [AWIDTH-1:0] addr_i = BASE_ADDR,
//   input logic [DWIDTH-1:0] data_i, //32 bits
//   input logic [2:0] funct3_i, // <<--- add this
//   input logic read_en_i,
//   input logic write_en_i,
//   // outputs
//   output logic [DWIDTH-1:0] data_o
// );

//   logic [DWIDTH-1:0] temp_memory [0:`MEM_DEPTH];
//   // Byte-addressable memory
//   logic [7:0] main_memory [0:`MEM_DEPTH];
//   logic [AWIDTH-1:0] address;
//   assign address = addr_i - BASE_ADDR;

//   initial begin
//     $readmemh(`MEM_PATH, temp_memory);
//     // Load data from temp_memory into main_memory
//     for (int i = 0; i < `LINE_COUNT; i++) begin
//         main_memory[4*i]     = temp_memory[i][7:0];
//         main_memory[4*i + 1] = temp_memory[i][15:8];
//         main_memory[4*i + 2] = temp_memory[i][23:16];
//         main_memory[4*i + 3] = temp_memory[i][31:24];
//     end
//     $display("IMEMORY: Loaded %0d 32-bit words from %s", `LINE_COUNT, `MEM_PATH);
//   end

//   /*
//    * Process definitions to be filled by
//    * student below....
//    *
//    */
//   // ----------------- Load logic -----------------
//   always_comb begin
//     if (read_en_i) begin
//         case (funct3_i)
//             3'b000: data_o = {{24{main_memory[address][7]}}, main_memory[address]};           // lb
//             3'b001: data_o = {{16{main_memory[address+1][7]}}, main_memory[address+1], main_memory[address]}; // lh
//             3'b010: data_o = {main_memory[address+3], main_memory[address+2], main_memory[address+1], main_memory[address]}; // lw
//             3'b100: data_o = {24'd0, main_memory[address]};                                   // lbu
//             3'b101: data_o = {16'd0, main_memory[address+1], main_memory[address]};           // lhu
//             default: data_o = 32'd0;
//         endcase
//     end else begin
//         data_o = 32'd0;
//     end
//   end

//   // ----------------- Store logic -----------------
//   always_ff @(posedge clk) begin
//     if (write_en_i) begin
//         case (funct3_i)
//             3'b000: main_memory[address] <= data_i[7:0];                                      // sb
//             3'b001: begin                                                                      // sh
//                 main_memory[address]   <= data_i[7:0];
//                 main_memory[address+1] <= data_i[15:8];
//             end
//             3'b010: begin                                                                      // sw
//                 main_memory[address]   <= data_i[7:0];
//                 main_memory[address+1] <= data_i[15:8];
//                 main_memory[address+2] <= data_i[23:16];
//                 main_memory[address+3] <= data_i[31:24];
//             end
//         endcase
//     end
//   end

// endmodule : memory





// `include "constants.svh"

// module memory #(
//   parameter int DWIDTH = 32,
//   parameter int AWIDTH = 32,
//   parameter logic [31:0] BASE_ADDR = 32'h01000000
// )(
//   // Clock/reset
//   input  logic clk,
//   input  logic rst,

//   // --- Instruction port ---
//   input  logic [AWIDTH-1:0] instr_addr_i,
//   output logic [DWIDTH-1:0] instr_data_o,

//   // --- Data port ---
//   input  logic [AWIDTH-1:0] data_addr_i,
//   input  logic [DWIDTH-1:0] data_i,
//   input  logic read_en_i,
//   input  logic write_en_i,
//   input  logic [2:0] funct3_i,      // lb/lh/lw/lbu/lhu/sb/sh/sw
//   output logic [DWIDTH-1:0] data_o
// );

//   // Byte-addressable memory
//   logic [7:0] main_memory [0:`MEM_DEPTH];
// logic [AWIDTH-1:0] instr_address = instr_addr_i - BASE_ADDR;
// logic [AWIDTH-1:0] data_address  = data_addr_i  - BASE_ADDR;

// // ----------------- Instruction fetch -----------------
// always_comb begin
//     instr_data_o = {main_memory[instr_address+3],
//                      main_memory[instr_address+2],
//                      main_memory[instr_address+1],
//                      main_memory[instr_address]};
// end

// // ----------------- Data read -----------------
// always_comb begin
//     if (read_en_i) begin
//         case (funct3_i)
//             3'b000: data_o = {{24{main_memory[data_address][7]}}, main_memory[data_address]}; // lb
//             3'b001: data_o = {{16{main_memory[data_address+1][7]}}, main_memory[data_address+1], main_memory[data_address]}; // lh
//             3'b010: data_o = {main_memory[data_address+3], main_memory[data_address+2], main_memory[data_address+1], main_memory[data_address]}; // lw
//             3'b100: data_o = {24'd0, main_memory[data_address]}; // lbu
//             3'b101: data_o = {16'd0, main_memory[data_address+1], main_memory[data_address]}; // lhu
//             default: data_o = 32'd0;
//         endcase
//     end else begin
//         data_o = 32'd0;
//     end
// end

// // ----------------- Data write -----------------
// always_ff @(posedge clk) begin
//     if (write_en_i) begin
//         case (funct3_i)
//             3'b000: main_memory[data_address] <= data_i[7:0]; // sb
//             3'b001: begin // sh
//                 main_memory[data_address]   <= data_i[7:0];
//                 main_memory[data_address+1] <= data_i[15:8];
//             end
//             3'b010: begin // sw
//                 main_memory[data_address]   <= data_i[7:0];
//                 main_memory[data_address+1] <= data_i[15:8];
//                 main_memory[data_address+2] <= data_i[23:16];
//                 main_memory[data_address+3] <= data_i[31:24];
//             end
//         endcase
//     end
// end

// // ----------------- Initialization -----------------
// initial begin
//     logic [DWIDTH-1:0] temp_memory [0:`MEM_DEPTH];
//     $readmemh(`MEM_PATH, temp_memory);
//     for (int i = 0; i < `LINE_COUNT; i++) begin
//         main_memory[4*i]     = temp_memory[i][7:0];
//         main_memory[4*i + 1] = temp_memory[i][15:8];
//         main_memory[4*i + 2] = temp_memory[i][23:16];
//         main_memory[4*i + 3] = temp_memory[i][31:24];
//     end
//     $display("MEMORY: Loaded %0d 32-bit words from %s", `LINE_COUNT, `MEM_PATH);
// end

// endmodule : memory


`include "constants.svh"

module memory #(
    parameter int          DWIDTH    = 32,
    parameter int          AWIDTH    = 32,
    parameter logic [31:0] BASE_ADDR = 32'h01000000
)(
    input  logic                 clk,
    input  logic                 rst_n,          // ACTIVE-LOW RESET (not really used here)
    // Instruction port
    input  logic [AWIDTH-1:0]    instr_addr_i,
    output logic [DWIDTH-1:0]    instr_data_o,
    // Data port
    input  logic [AWIDTH-1:0]    data_addr_i,
    input  logic [DWIDTH-1:0]    data_i,
    input  logic                 read_en_i,
    input  logic                 write_en_i,
    input  logic [2:0]           funct3_i,
    output logic [DWIDTH-1:0]    data_o
);

    logic [7:0] main_memory [0:`MEM_DEPTH-1];

    logic [AWIDTH-1:0] instr_idx;
    logic [AWIDTH-1:0] data_idx;

    always_comb begin
        instr_idx = (instr_addr_i >= BASE_ADDR) ? (instr_addr_i - BASE_ADDR) : 32'd0;
        data_idx  = (data_addr_i  >= BASE_ADDR) ? (data_addr_i  - BASE_ADDR) : 32'd0;
    end

    // Instruction fetch
    always_comb begin
        if (instr_addr_i < BASE_ADDR) begin
            instr_data_o = 32'h00000013; // NOP
        end else begin
            instr_data_o = { main_memory[instr_idx+3],
                             main_memory[instr_idx+2],
                             main_memory[instr_idx+1],
                             main_memory[instr_idx] };
        end
    end

    // Data read
    always_comb begin
        data_o = 32'd0;
        if (read_en_i && (data_addr_i >= BASE_ADDR)) begin
            unique case (funct3_i)
                3'b000: data_o = {{24{main_memory[data_idx][7]}}, main_memory[data_idx]}; // LB
                3'b001: data_o = {{16{main_memory[data_idx+1][7]}},
                                   main_memory[data_idx+1], main_memory[data_idx]};      // LH
                3'b010: data_o = { main_memory[data_idx+3], main_memory[data_idx+2],
                                   main_memory[data_idx+1], main_memory[data_idx] };     // LW
                3'b100: data_o = {24'd0, main_memory[data_idx]};                           // LBU
                3'b101: data_o = {16'd0, main_memory[data_idx+1], main_memory[data_idx]};  // LHU
                default: data_o = 32'd0;
            endcase
        end
    end

    // Data write
    always_ff @(posedge clk) begin
        if (write_en_i && (data_addr_i >= BASE_ADDR)) begin
            unique case (funct3_i)
                3'b000: begin // SB
                    main_memory[data_idx] <= data_i[7:0];
                end
                3'b001: begin // SH
                    main_memory[data_idx]   <= data_i[7:0];
                    main_memory[data_idx+1] <= data_i[15:8];
                end
                3'b010: begin // SW
                    main_memory[data_idx]   <= data_i[7:0];
                    main_memory[data_idx+1] <= data_i[15:8];
                    main_memory[data_idx+2] <= data_i[23:16];
                    main_memory[data_idx+3] <= data_i[31:24];
                end
            endcase
        end
    end

    // Initialization
    initial begin
        logic [DWIDTH-1:0] temp_memory [0:(`MEM_DEPTH/4)-1];

        for (int j = 0; j < `MEM_DEPTH; j++)
            main_memory[j] = 8'h00;

        $readmemh(`MEM_PATH, temp_memory);

        for (int i = 0; i < `LINE_COUNT; i++) begin
            main_memory[4*i]     = temp_memory[i][7:0];
            main_memory[4*i + 1] = temp_memory[i][15:8];
            main_memory[4*i + 2] = temp_memory[i][23:16];
            main_memory[4*i + 3] = temp_memory[i][31:24];
        end

        $display("MEMORY: Successfully mapped %0d words into byte-array from %s",
                 `LINE_COUNT, `MEM_PATH);
    end

endmodule
