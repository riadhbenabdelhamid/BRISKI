module instruction_decoder (
    input  logic [31:0] i_instruction,
    output logic [ 6:0] o_opcode,
    output logic [ 2:0] o_funct3,
    output logic [ 6:0] o_funct7,
    output logic [ 4:0] o_rs1,
    output logic [ 4:0] o_rs2,
    output logic [ 4:0] o_wa
);

  assign o_opcode = i_instruction[6:0];
  assign o_funct3 = i_instruction[14:12];
  assign o_funct7 = i_instruction[31:25];
  assign o_rs1 = i_instruction[19:15];
  assign o_rs2 = i_instruction[24:20];
  assign o_wa = i_instruction[11:7];

endmodule

