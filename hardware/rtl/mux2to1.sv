module mux2to1 #(
    parameter MUX_DATA_WIDTH = 32
) (
    input logic i_sel,  // Select input
    input logic [MUX_DATA_WIDTH-1:0] i_in0,  // Input
    input logic [MUX_DATA_WIDTH-1:0] i_in1,  // Input
    output logic [MUX_DATA_WIDTH-1:0] o_muxout  // Output
);
  always_comb begin
    case (i_sel)
      1'b0: o_muxout = i_in0;
      1'b1: o_muxout = i_in1;
      default: o_muxout = 'x;
    endcase
  end
endmodule

