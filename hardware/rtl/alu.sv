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
    o_result_add = (i_aluop == 4'b0000) ? i_op1 + i_op2 : '0;
    o_result_sub = (i_aluop == 4'b0001) ? i_op1 - i_op2 : '0;
    o_result_sll = (i_aluop == 4'b0010) ? i_op1 << shamt : '0;
    o_result_xor = (i_aluop == 4'b0011) ? i_op1 ^ i_op2 : '0;
    o_result_or = (i_aluop == 4'b0100) ? i_op1 | i_op2 : '0;
    o_result_and = (i_aluop == 4'b0101) ? i_op1 & i_op2 : '0;
    o_result_pass = (i_aluop == 4'b0110) ? i_op2 : '0;
    o_result_srl_sra = (i_aluop == 4'b0111 || i_aluop == 4'b1000) ? temp : '0;
  end

  always_ff @(posedge clk) begin
    o_result <= o_result_add ^ o_result_sub ^ o_result_sll ^ o_result_xor ^ o_result_srl_sra ^ o_result_or ^ o_result_and ^ o_result_pass;
  end

  always_comb begin
    temp = (i_aluop[0]) ? ($signed(i_op1) >>> shamt) : (i_op1 >> shamt);
  end


endmodule

