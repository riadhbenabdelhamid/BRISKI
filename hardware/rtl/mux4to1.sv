module mux4to1 #(
    parameter MUX_DATA_WIDTH = 32
) (
    input logic [1:0] i_sel,  // Select input
    input logic [MUX_DATA_WIDTH-1:0] i_in0,  // Input
    input logic [MUX_DATA_WIDTH-1:0] i_in1,  // Input
    input logic [MUX_DATA_WIDTH-1:0] i_in2,  // Input
    input logic [MUX_DATA_WIDTH-1:0] i_in3,  // Input
    output logic [MUX_DATA_WIDTH-1:0] o_muxout  // Output
);
  always_comb begin
    case (i_sel)
      2'b00:   o_muxout = i_in0;
      2'b01:   o_muxout = i_in1;
      2'b10:   o_muxout = i_in2;
      2'b11:   o_muxout = i_in3;
      default: o_muxout = 'x;
    endcase
  end
endmodule

