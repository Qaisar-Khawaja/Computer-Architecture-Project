module memory #(
  parameter int AWIDTH = 32,
  parameter int DWIDTH = 32,
  parameter logic [31:0] BASE_ADDR = 32'h01000000
) (
  input logic clk,
  input logic rst,
  
  // Port A
  input logic [AWIDTH-1:0] addr_i,
  input logic [DWIDTH-1:0] data_i,
  input logic read_en_i,
  input logic write_en_i,
  input logic [1:0] size_i,
  input logic sign_en_i,
  output logic [DWIDTH-1:0] data_o,

  // Port B
  input logic [AWIDTH-1:0] insn_addr_i,
  output logic [DWIDTH-1:0] insn_o
);

  logic [DWIDTH-1:0] temp_memory [0:`MEM_DEPTH];
  logic [7:0] main_memory [0:`MEM_DEPTH];

  // Helper function to safely calculate byte addresses
  // 1. Applies the 16MB mask (0x00FFFFFF) to replicate the testbench's aliasing.
  // 2. Modulos by the physical memory size to prevent out-of-bounds array access.
  function logic [AWIDTH-1:0] get_addr(logic [AWIDTH-1:0] in_addr);
      return (in_addr & 32'h00FFFFFF) % (`MEM_DEPTH + 1);
  endfunction
  
  initial begin
    // Initialize all memory to 0 to prevent 'x' values
    for (int i = 0; i <= `MEM_DEPTH; i++) begin
        main_memory[i] = 8'h00;
    end
    
    $readmemh(`MEM_PATH, temp_memory);
    for (int i = 0; i < `LINE_COUNT; i++) begin
        main_memory[get_addr(4*i + 0)] = temp_memory[i][7:0];
        main_memory[get_addr(4*i + 1)] = temp_memory[i][15:8];
        main_memory[get_addr(4*i + 2)] = temp_memory[i][23:16];
        main_memory[get_addr(4*i + 3)] = temp_memory[i][31:24];
    end
    $display("IMEMORY: Loaded %0d 32-bit words from %s", `LINE_COUNT, `MEM_PATH);
  end

  // INSTRUCTION FETCH PORT
  always_comb begin
      insn_o = {
          main_memory[get_addr(insn_addr_i + 3)], 
          main_memory[get_addr(insn_addr_i + 2)], 
          main_memory[get_addr(insn_addr_i + 1)], 
          main_memory[get_addr(insn_addr_i + 0)]
      };
  end

  // DATA READ PORT
  always_comb begin
    data_o = '0;
    if (read_en_i) begin
        case (size_i)
            2'b00: begin
                logic [7:0] b0;
                b0 = main_memory[get_addr(addr_i + 0)];
                if(sign_en_i) data_o = {{24{b0[7]}}, b0};
                else          data_o = {24'b0, b0};
            end
            2'b01: begin 
                logic [7:0] b0, b1;
                b0 = main_memory[get_addr(addr_i + 0)];
                b1 = main_memory[get_addr(addr_i + 1)];
                if(sign_en_i) data_o = {{16{b1[7]}}, b1, b0};
                else          data_o = {16'b0, b1, b0};
            end
            2'b10: begin 
                logic [7:0] b0, b1, b2, b3;
                b0 = main_memory[get_addr(addr_i + 0)];
                b1 = main_memory[get_addr(addr_i + 1)];
                b2 = main_memory[get_addr(addr_i + 2)];
                b3 = main_memory[get_addr(addr_i + 3)];
                data_o = {b3, b2, b1, b0};
            end
            default: data_o = '0;
        endcase
    end
  end

  // DATA WRITE PORT
  always_ff @(posedge clk) begin
    if (write_en_i) begin
        main_memory[get_addr(addr_i + 0)] <= data_i[7:0];
        if (size_i >= 2'b01) begin
            main_memory[get_addr(addr_i + 1)] <= data_i[15:8];
        end
        if (size_i == 2'b10) begin
            main_memory[get_addr(addr_i + 2)] <= data_i[23:16];
            main_memory[get_addr(addr_i + 3)] <= data_i[31:24];
        end
    end
  end

endmodule : memory