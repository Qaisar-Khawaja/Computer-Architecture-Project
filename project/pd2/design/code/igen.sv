/*
 * Module: igen
 *
 * Description: Immediate value generator
 *
 * Inputs:
 * 1) opcode opcode_i
 * 2) input instruction insn_i
 * Outputs:
 * 2) 32-bit immediate value imm_o
 */

module igen #(
    parameter int DWIDTH=32
    )(
    input logic [6:0] opcode_i,
    input logic [DWIDTH-1:0] insn_i,
    output logic [31:0] imm_o
);
    
    /*
     * Process definitions to be filled by
     * student below...
     * Operating data needs to be 32-bit in order for ALU to work
     * Registers already have 32-bit data 
     */

    // Temporary Variables
    logic [11:0] store_holder;
    logic [12:0] branch_holder;
    logic [20:0] jump_holder;

    always_comb begin

        case (opcode_i)
            `Opcode_IType,
            `Opcode_IType_Jump_And_LinkReg,
            `Opcode_IType_Load: begin
                /* The 31st bit is 1 representing negative value -> assign one 20 times on the left side
                 * The 31st bit is 0 representing positive value -> assign zero 20 times on the left side
                 */
                if (insn_i[31]==1'b1) begin
                    imm_o = { 20'hFFFFF, insn_i[31:20] };
                end
                else begin
                    imm_o = { 20'h00000, insn_i[31:20] };
                end        
            end


            
            `Opcode_UType_Add_Upper_Imm,
            `Opcode_UType_Load_Upper_Imm: begin
                /* Grab 20 bits from the instruction 
                 * Add zeros 12 times on the right side because right side will be stored at different place
                 * Not adding zeros on right can create a different number we need to keep the same number (total 32 bit)
                 */
                imm_o = { insn_i[31:12], 12'h000 };       
            end

            `Opcode_SType: begin
                /* Grab the immediate value's upper and lower parts and combine them (we store 32 bits)
                 * MSB is in [31:25] and LSB in [11:7] join them using concatenation oepration { } into 12-bit number
                 * Check the 31st bit 1 or 0 and accordingly assign zeros or ones (turn into total 32 bits)
                 */
                 store_holder = {insn_i[31:25],insn_i[11:7]};
                 
                 if (insn_i[31]==1'b1) begin
                    imm_o = { 20'hFFFFF, store_holder };
                end
                else begin
                    imm_o = { 20'h00000, store_holder };
                end
            end  

            `Opcode_BType: begin
                /* Grab the immediate values and combine them in order  into 12-bit number
                 * Make the final value in 32 bits (add zeros or ones based on negative or positive numebr)
                 * The instruction must land on positive value so 1'b0
                 * manually add the 1'b0 at the end to turn our 12 bits of data into a 13-bit signed offset.
                 */     
                branch_holder = { insn_i[31], insn_i[7], insn_i[30:25], insn_i[11:8], 1'b0};
                if (insn_i[31] == 1'b1) begin
                    imm_o = { 19'h7FFFF, branch_holder }; 
                end 
                else begin
                     imm_o = { 19'h00000, branch_holder };
                end 
            end

            `Opcode_JType_Jump_And_Link: begin
                jump_holder = { insn_i[31], insn_i[19:12], insn_i[20], insn_i[30:21], 1'b0};
                if (insn_i[31] == 1'b1) begin
                    imm_o = { 11'h7FF, jump_holder }; 
                end
                else begin
                     imm_o = { 11'h000, jump_holder };
                end 
            end
            default: begin
                imm_o = 32'h00000000;
            end


        endcase
    end
endmodule : igen
