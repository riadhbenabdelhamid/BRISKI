module Adder32 (
    input  logic [31:0] i_op1,
    input  logic [31:0] i_op2,
    output logic [31:0] o_sum
);

  assign o_sum = $signed(i_op1) + $signed(i_op2);

endmodule

