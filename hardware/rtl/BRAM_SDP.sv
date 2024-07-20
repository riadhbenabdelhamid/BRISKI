`include "riscv_pkg.sv"
//import riscv_pkg::*;

module BRAM_SDP #(
    parameter SIZE = 512,
    ADDR_WIDTH = 9,
    DATA_WIDTH = 32,
    RAM_STYLE_ATTR = "block"
) (
    input logic clka,
    input logic ena,
    input logic wea,
    input logic [ADDR_WIDTH-1:0] addra,
    input logic [DATA_WIDTH-1:0] dia,
    input logic clkb,
    input logic enb,
    input logic [ADDR_WIDTH-1:0] addrb,
    output logic [DATA_WIDTH-1:0] dob
);

  (* ram_style = RAM_STYLE_ATTR *) logic [DATA_WIDTH-1:0] MEM[SIZE-1:0];
  integer j;
  initial
    for (j = 0; j < SIZE; j = j + 1) MEM[j] = {DATA_WIDTH{1'b0}};  // should at least init x0 to 0

  always_ff @(posedge clka) begin
    if (ena) begin
      if (wea) begin
        MEM[addra] <= dia;
      end
    end
  end

  always_ff @(posedge clkb) begin
    if (enb) begin
      dob <= MEM[addrb];
    end
  end

endmodule

