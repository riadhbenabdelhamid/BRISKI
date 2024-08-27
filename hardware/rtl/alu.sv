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

  logic [DWIDTH-1:0] result_add;
  //logic [DWIDTH-1:0] result_sub;
  logic [DWIDTH-1:0] result_sll;
  logic [DWIDTH-1:0] result_xor;
  logic [DWIDTH-1:0] result_or;
  logic [DWIDTH-1:0] result_and;
  logic [DWIDTH-1:0] result_pass;

  logic [DWIDTH-1:0] result_srl_sra;
  logic [4:0] shamt;
  //logic [DWIDTH-1:0] temp;
  logic [DWIDTH:0] temp;
  logic [DWIDTH-1:0] mask;


  // negate second operand when aluop is sub
  logic [DWIDTH-1:0] op2_negated_or_not;

  //assign op2_negated_or_not = i_op2 ^ {32{i_aluop[0]}};  // xored with zeros when aluop is add (aluop[0]=0) else xored with ones
  assign op2_negated_or_not = i_op2 ^ {DWIDTH{i_aluop[0]}};  // xored with zeros when aluop is add (aluop[0]=0) else xored with ones

  always_comb begin
    shamt = i_op2[4:0];
  end

  always_comb begin
    //result_add = (i_aluop == ADD_OP || i_aluop == SUB_OP) ? i_op1 + op2_negated_or_not + {31'b0,i_aluop[0]} : 0;   //i_aluop[0] is 1 for sub and 0 for add
    result_add = (i_aluop == ADD_OP || i_aluop == SUB_OP) ? i_op1 + op2_negated_or_not + {{(DWIDTH-1){1'b0}},i_aluop[0]} : 0;   //i_aluop[0] is 1 for sub and 0 for add
    //result_add = (i_aluop == ADD_OP) ? i_op1 + i_op2 : 0;
    //result_sub = (i_aluop == SUB_OP) ? i_op1 - i_op2 : 0;
    result_sll = (i_aluop == SLL_OP) ? i_op1 << shamt : 0;
    result_xor = (i_aluop == XOR_OP) ? i_op1 ^ i_op2 : 0;
    result_or = (i_aluop == OR_OP) ? i_op1 | i_op2 : 0;
    result_and = (i_aluop == AND_OP) ? i_op1 & i_op2 : 0;
    result_pass = (i_aluop == PASS_OP) ? i_op2 : 0;
    //result_srl_sra = (i_aluop == SRL_OP || i_aluop == SRA_OP) ? temp : 0;
    result_srl_sra = (i_aluop == SRL_OP || i_aluop == SRA_OP) ? temp[DWIDTH-1:0] : 0;
  end

  always_ff @(posedge clk) begin
         //o_result <= result_add ^ result_sub ^ result_sll ^ result_xor ^ result_srl_sra ^ result_or ^ result_and ^ result_pass;
         o_result <= result_add ^ result_sll ^ result_xor ^ result_srl_sra ^ result_or ^ result_and ^ result_pass;
  end

  always_comb begin
    //temp = (i_aluop[0]) ? ($signed(i_op1) >>> shamt) : (i_op1 >> shamt);
    temp = ($signed({(i_aluop[0] & i_op1[DWIDTH-1]),i_op1}) >>> shamt);
  end
endmodule

