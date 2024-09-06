`include "riscv_pkg.sv"

module BRAM #(
    parameter SIZE = 1024,
    parameter ADDR_WIDTH = 10,
    parameter COL_WIDTH = 8,
    parameter NB_COL = 4,
    parameter INIT_FILE = "",
    parameter RAM_STYLE_ATTR = "block"
) (
    input logic clka,
    input logic ena,
    input logic [NB_COL-1:0] wea,
    input logic [ADDR_WIDTH-1:0] addra,
    input logic [NB_COL*COL_WIDTH-1:0] dia,
    output logic [NB_COL*COL_WIDTH-1:0] doa,
    input logic clkb,
    input logic enb,
    input logic [NB_COL-1:0] web,
    input logic [ADDR_WIDTH-1:0] addrb,
    input logic [NB_COL*COL_WIDTH-1:0] dib,
    output logic [NB_COL*COL_WIDTH-1:0] dob
);

  
  (*rw_addr_collision = "no" *)(* ram_style = RAM_STYLE_ATTR *) logic [NB_COL*COL_WIDTH-1:0] RAM[SIZE-1:0];
  integer j;
  initial begin
    for (j = 0; j < SIZE; j = j + 1) RAM[j] = {NB_COL*COL_WIDTH{1'b0}};  // should at least init x0 to 0
    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, RAM);
    end
  end

  always @(posedge clka) begin
    if (ena) begin
      if (~|wea)
        doa <= RAM[addra];
      for (int i = 0; i < NB_COL; i++) begin
        if (wea[i]) begin
          RAM[addra][(i+1)*COL_WIDTH-1-:COL_WIDTH] <= dia[(i+1)*COL_WIDTH-1-:COL_WIDTH];
        end
      end
    end
  end

  always @(posedge clkb) begin
    if (enb) begin
      if (~|web)
        dob <= RAM[addrb];
      for (int i = 0; i < NB_COL; i++) begin
        if (web[i]) begin
          RAM[addrb][(i+1)*COL_WIDTH-1-:COL_WIDTH] <= dib[(i+1)*COL_WIDTH-1-:COL_WIDTH];
        end
      end
    end
  end


endmodule

