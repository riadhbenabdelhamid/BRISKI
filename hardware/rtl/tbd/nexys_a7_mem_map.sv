module nexys_a7_mem_map (
    input logic reset,
    input logic clk,
    output logic [15:0] gpio_led,
    input logic [15:0] gpio_sw,
    input logic i_mmio_wen,
    input logic i_mmio_enable,
    input logic [7:0] i_mmio_addr,
    input logic [31:0] i_mmio_data_in,
    output logic [31:0] o_mmio_data_out
);

  always_ff @(posedge clk) begin
    if (reset) begin
      gpio_led <= 0;
      o_mmio_data_out <= 0;
    end else if (i_mmio_enable) begin
      if (i_mmio_wen) begin
        case (i_mmio_addr)
          //write to general leds (16 leds on nexys a7)
          8'h1: gpio_led <= i_mmio_data_in[15:0];
        endcase
      end else begin
        case (i_mmio_addr)
          //read from switches (16 switches on nexys a7)
          8'h1: o_mmio_data_out <= {16'b0, gpio_sw[15:0]};  //nexys a7 16 switches
        endcase
      end
    end
  end

endmodule
