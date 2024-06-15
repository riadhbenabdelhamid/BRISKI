`include "riscv_pkg.sv"
module alu #(
    parameter ALUOP_WIDTH = 4,
    DWIDTH = 32
) (
    input logic clk,
    input logic [DWIDTH-1:0] i_op1,
    input logic [DWIDTH-1:0] i_op2,
    input logic [ALUOP_WIDTH-1:0] i_aluop,
    output logic [DWIDTH-1:0] o_result
);

  logic [DWIDTH-1:0] o_result_add;
  logic [DWIDTH-1:0] o_result_sub;
  logic [DWIDTH-1:0] o_result_sll;
  logic [DWIDTH-1:0] o_result_xor;
  logic [DWIDTH-1:0] o_result_srl_sra;
  logic [DWIDTH-1:0] o_result_or;
  logic [DWIDTH-1:0] o_result_and;
  logic [DWIDTH-1:0] o_result_pass;

  logic [DWIDTH-1:0] result_srl_sra;
  logic [4:0] shamt;
  logic [DWIDTH-1:0] temp;
  logic [DWIDTH-1:0] mask;
  logic sign;

  always_comb begin
    shamt = i_op2[4:0];
  end

  always_comb begin
    o_result_add = (i_aluop == ADD_OP) ? i_op1 + i_op2 : 0;
    o_result_sub = (i_aluop == SUB_OP) ? i_op1 - i_op2 : 0;
    o_result_sll = (i_aluop == SLL_OP) ? i_op1 << shamt : 0;
    o_result_xor = (i_aluop == XOR_OP) ? i_op1 ^ i_op2 : 0;
    o_result_or = (i_aluop == OR_OP) ? i_op1 | i_op2 : 0;
    o_result_and = (i_aluop == AND_OP) ? i_op1 & i_op2 : 0;
    o_result_pass = (i_aluop == PASS_OP) ? i_op2 : 0;
    o_result_srl_sra = (i_aluop == SRL_OP || i_aluop == SRA_OP) ? temp : 0;
  end

  always_ff @(posedge clk) begin
    o_result <= o_result_add ^ o_result_sub ^ o_result_sll ^ o_result_xor ^ o_result_srl_sra ^ o_result_or ^ o_result_and ^ o_result_pass;
  end

  always_comb begin
    temp = (i_aluop[0]) ? ($signed(i_op1) >>> shamt) : (i_op1 >> shamt);
  end


endmodule

