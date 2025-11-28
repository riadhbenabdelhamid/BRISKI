/* verilator lint_off GENUNNAMED */
`include "riscv_pkg.sv"

module LUT_RAM #(
    parameter SIZE = 256,
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter INIT_VAL = {DATA_WIDTH{1'b0}},
    parameter bool ENABLE_LUTRAM_PCMEM = true
) (
    input  logic                  clka,
    input  logic                  ena,
    input  logic                  wea,
    input  logic [ADDR_WIDTH-1:0] addra,
    input  logic [DATA_WIDTH-1:0] dia,
    input  logic [ADDR_WIDTH-1:0] addrb,
    output logic [DATA_WIDTH-1:0] dob
);


    localparam RAM_STYLE_ATTR = (ENABLE_LUTRAM_PCMEM == true) ? "distributed" : "registers";
    (* ram_style = RAM_STYLE_ATTR *) logic [DATA_WIDTH-1:0] MEM[0:SIZE-1];

    always_ff @(posedge clka) begin
        if (ena == 1'b1) begin
            if (wea == 1'b1) begin
                MEM[addra] <= dia;
            end
        end
    end

    assign dob = MEM[addrb];

endmodule

