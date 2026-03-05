module branch_control #(
    parameter int DWIDTH=32
)(
    input logic [6:0] opcode_i,
    input logic [2:0] funct3_i,
    input logic [DWIDTH-1:0] rs1_i,
    input logic [DWIDTH-1:0] rs2_i,
    output logic breq_o,
    output logic brlt_o,
    output logic brltu_o // <-- ADDED
);
    always_comb begin
        breq_o = (rs1_i == rs2_i);
        brlt_o = ($signed(rs1_i) < $signed(rs2_i));
        brltu_o = (rs1_i < rs2_i); // <-- Unsigned comparison
    end
endmodule : branch_control