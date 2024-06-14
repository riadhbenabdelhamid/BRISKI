module LUT_RAM #(
    parameter SIZE = 256,
    ADDR_WIDTH = 8,
    DATA_WIDTH = 32,
    INIT_VAL = 12'b0,
    RAM_STYLE_ATTR = "distributed"
) (
    input logic clka,
    input logic ena,
    input logic wea,
    input logic [ADDR_WIDTH-1:0] addra,
    input logic [DATA_WIDTH-1:0] dia,
    input logic [ADDR_WIDTH-1:0] addrb,
    output logic [DATA_WIDTH-1:0] dob
);

  //(* ram_style = RAM_STYLE_ATTR *) logic [DATA_WIDTH-1:0] MEM [0:SIZE-1]= '{default: INIT_VAL};
  (* ram_style = RAM_STYLE_ATTR *) logic [DATA_WIDTH-1:0] MEM[0:SIZE-1] = '{SIZE{INIT_VAL}};

  always_ff @(posedge clka) begin
    if (ena == 1'b1) begin
      if (wea == 1'b1) begin
        MEM[addra] <= dia;
      end
    end
  end

  assign dob = MEM[addrb];

endmodule

