// ----  Probes  ----
`define PROBE_F_PC    assign_f_pc
`define PROBE_F_INSN  assign_f_insn
`define PROBE_D_PC     assign_d_pc
`define PROBE_D_OPCODE assign_d_opcode
`define PROBE_D_RD     assign_d_rd
`define PROBE_D_FUNCT3 assign_d_funct3
`define PROBE_D_RS1    assign_d_rs1
`define PROBE_D_RS2    assign_d_rs2
`define PROBE_D_FUNCT7 assign_d_funct7
`define PROBE_D_IMM    assign_d_imm
`define PROBE_D_SHAMT  assign_d_shamt

`define PROBE_R_WRITE_ENABLE      assign_r_write_enable
`define PROBE_R_WRITE_DESTINATION assign_r_write_destination
`define PROBE_R_WRITE_DATA        assign_r_write_data
`define PROBE_R_READ_RS1          assign_r_read_rs1
`define PROBE_R_READ_RS2          assign_r_read_rs2
`define PROBE_R_READ_RS1_DATA     assign_r_read_rs1_data
`define PROBE_R_READ_RS2_DATA     assign_r_read_rs2_data

`define PROBE_E_PC                assign_e_pc
`define PROBE_E_ALU_RES           assign_e_alu_res
`define PROBE_E_BR_TAKEN          assign_e_br_taken
// ----  Probes  ----

// ----  Top module  ----
`define TOP_MODULE  pd3
// ----  Top module  ----