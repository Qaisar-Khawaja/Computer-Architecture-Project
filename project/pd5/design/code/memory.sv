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
`include "constants.svh"

module memory #(
    parameter int AWIDTH                = 32,
    parameter int DWIDTH                = 32,
    parameter logic [31:0] BASE_ADDR    = 32'h01000000
)(
    input  logic        clk,
    input  logic        rst,

    // DATA PORT
    input  logic [AWIDTH-1:0]   addr_i,
    input  logic [DWIDTH-1:0]   data_i,
    input  logic                read_en_i,
    input  logic                write_en_i,
    input  logic [1:0]          size_i,
    input  logic                sign_en_i,
    output logic [DWIDTH-1:0]   data_o,

    // INSTRUCTION PORT
    input  logic [AWIDTH-1:0]   insn_addr_i,
    output logic [DWIDTH-1:0]   insn_o
);

    /*
     * Memory Arrays
     * temp_memory is used for file loading (word-addressable).
     * main_memory is the actual byte-addressable storage.
     */
    logic [DWIDTH-1:0] temp_memory [0:`LINE_COUNT-1];
    logic [7:0] main_memory [0:`MEM_DEPTH-1];

    // ADDRESS WRAPPING
    function logic [AWIDTH-1:0] wrap_addr(logic [AWIDTH-1:0] a);
        logic [AWIDTH-1:0] adj;
        adj = (a >= BASE_ADDR) ? (a - BASE_ADDR) : a;
        return adj % `MEM_DEPTH;
    endfunction

    // Wrapped addresses
    logic [AWIDTH-1:0] addr0, addr1, addr2, addr3;
    logic [AWIDTH-1:0] insn0, insn1, insn2, insn3;

    always_comb begin
        addr0 = wrap_addr(addr_i + 0);
        addr1 = wrap_addr(addr_i + 1);
        addr2 = wrap_addr(addr_i + 2);
        addr3 = wrap_addr(addr_i + 3);

        insn0 = wrap_addr(insn_addr_i + 0);
        insn1 = wrap_addr(insn_addr_i + 1);
        insn2 = wrap_addr(insn_addr_i + 2);
        insn3 = wrap_addr(insn_addr_i + 3);
    end

    // MEMORY INITIALIZATION
    initial begin : init_block
        // 1. Clear memory
        for (int i = 0; i < `MEM_DEPTH; i++) main_memory[i] = 8'h00;

        // 2. Load program
        $readmemh(`MEM_PATH, temp_memory);

        // 3. Map into byte-memory
        for (int i = 0; i < `LINE_COUNT; i++) begin
            // We don't need to offset 'i' here because wrap_addr 
            // will handle the 01000000 -> 0 conversion.
            main_memory[4*i + 0] = temp_memory[i][7:0];
            main_memory[4*i + 1] = temp_memory[i][15:8];
            main_memory[4*i + 2] = temp_memory[i][23:16];
            main_memory[4*i + 3] = temp_memory[i][31:24];
        end
    end

    // INSTRUCTION FETCH
    always_comb begin
        insn_o = {
            main_memory[insn3],
            main_memory[insn2],
            main_memory[insn1],
            main_memory[insn0]
        };
    end

    // RAW BYTE READS
    logic [7:0] b0, b1, b2, b3;

    always_comb begin
        b0 = main_memory[addr0];
        b1 = main_memory[addr1];
        b2 = main_memory[addr2];
        b3 = main_memory[addr3];
    end

    // DATA READ DECODE
    logic [15:0] half;

    always @* begin
        data_o = '0;
        if (read_en_i) begin
            case (size_i)
                2'b00: begin
                    if (sign_en_i)
                        data_o = {{24{b0[7]}}, b0};
                    else
                        data_o = {24'b0, b0};
                end

                2'b01: begin
                    half = {b1, b0};
                    if (sign_en_i)
                        data_o = {{16{half[15]}}, half};
                    else
                        data_o = {16'b0, half};
                end

                2'b10: begin
                    data_o = {b3, b2, b1, b0};
                end
            endcase
        end
    end

    // DATA WRITE
    always_ff @(posedge clk) begin
        if (write_en_i) begin
            main_memory[addr0] <= data_i[7:0];

            if (size_i >= 2'b01) begin
                main_memory[addr1] <= data_i[15:8];
            end

            if (size_i == 2'b10) begin
                main_memory[addr2] <= data_i[23:16];
                main_memory[addr3] <= data_i[31:24];
            end
        end
    end

endmodule : memory


