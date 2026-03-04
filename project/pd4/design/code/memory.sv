/*
 * Module: memory
 *
 * Description: Byte-addressable dual-ported memory implementation.
 * Supports simultaneous instruction fetch and data read/write.
 */

module memory #(
  // parameters
  parameter int AWIDTH = 32,
  parameter int DWIDTH = 32,
  parameter logic [31:0] BASE_ADDR = 32'h01000000
) (
  // inputs
  input logic clk,
  input logic rst,
  
  // ==========================================
  // Port A: Data Memory (Loads / Stores)
  // ==========================================
  input logic [AWIDTH-1:0] addr_i,
  input logic [DWIDTH-1:0] data_i, // 32 bits
  input logic read_en_i,
  input logic write_en_i,
  input logic [1:0] size_i,        // 00: Byte, 01: HW, 10: Word
  input logic sign_en_i,           // 1: Signed, 0: Unsigned
  output logic [DWIDTH-1:0] data_o,

  // ==========================================
  // Port B: Instruction Memory (Fetch)
  // ==========================================
  input logic [AWIDTH-1:0] insn_addr_i,
  output logic [DWIDTH-1:0] insn_o
);

  logic [DWIDTH-1:0] temp_memory [0:`MEM_DEPTH];
  // Byte-addressable memory
  logic [7:0] main_memory [0:`MEM_DEPTH];
  
  logic [AWIDTH-1:0] address;
  logic [AWIDTH-1:0] insn_address;

  // Address calculation (offsetting by BASE_ADDR)
  assign address = addr_i - BASE_ADDR;
  assign insn_address = insn_addr_i - BASE_ADDR;

  initial begin
    $readmemh(`MEM_PATH, temp_memory);
    // Load data from temp_memory into main_memory
    for (int i = 0; i < `LINE_COUNT; i++) begin
        main_memory[4*i]     = temp_memory[i][7:0];
        main_memory[4*i + 1] = temp_memory[i][15:8];
        main_memory[4*i + 2] = temp_memory[i][23:16];
        main_memory[4*i + 3] = temp_memory[i][31:24];
    end
    $display("IMEMORY: Loaded %0d 32-bit words from %s", `LINE_COUNT, `MEM_PATH);
  end

  // --------------------------------------------------------
  // INSTRUCTION FETCH PORT (Continuous Read)
  // --------------------------------------------------------
  always_comb begin
      // Always fetch a full 32-bit word for the instruction
      insn_o = {main_memory[insn_address+3], 
                main_memory[insn_address+2], 
                main_memory[insn_address+1], 
                main_memory[insn_address]};
  end

  // --------------------------------------------------------
  // DATA READ PORT (Combinational)
  // --------------------------------------------------------
  always_comb begin
    data_o = '0;
    if (read_en_i) begin
        case (size_i)
            // Byte
            2'b00: begin
                if(sign_en_i) begin
                    data_o = {{24{main_memory[address][7]}}, main_memory[address]};
                end else begin
                    data_o = {24'b0, main_memory[address]};
                end
            end
            
            // Half-Word
            2'b01: begin 
                if(sign_en_i) begin
                    data_o = {{16{main_memory[address+1][7]}}, main_memory[address+1], main_memory[address]};
                end else begin    
                    data_o = {16'b0, main_memory[address+1], main_memory[address]};
                end
            end

            // Word
            2'b10: begin 
                data_o = {main_memory[address+3], main_memory[address+2], main_memory[address+1], main_memory[address]};
            end
            
            default: data_o = '0;
        endcase
    end
  end

  // --------------------------------------------------------
  // DATA WRITE PORT (Sequential)
  // --------------------------------------------------------
  always_ff @(posedge clk) begin
    if (write_en_i) begin
        // Always write the first byte (sb, sh, sw)
        main_memory[address] <= data_i[7:0];

        // Second byte if HW or word (sh, sw)
        if (size_i >= 2'b01) begin
            main_memory[address + 1] <= data_i[15:8];
        end

        // Write remaining bytes only if word (sw)
        if (size_i == 2'b10) begin
            main_memory[address + 2] <= data_i[23:16];
            main_memory[address + 3] <= data_i[31:24];
        end
    end
  end

endmodule : memory