module memory_map_decoder (
    input  logic       clk,
    input  logic       reset,
    input  logic [1:0] i_address_lines,      // RV_mem_addr(14 downto 13)
    output logic       o_dmem_enable,        // BRAM data port enable
    output logic       o_shared_mem_enable,  // BRAM data port enable
    output logic       o_MMIO_enable,        // MMIO registers memory enable
    output logic [1:0] o_readmem_mux_sel
);

  always_comb begin
    o_dmem_enable = 1'b0;
    o_shared_mem_enable = 1'b0;
    o_MMIO_enable = 1'b0;
    case (i_address_lines)
      2'b00: o_dmem_enable = 1'b1;
      2'b01: o_shared_mem_enable = 1'b1;
      2'b10: o_MMIO_enable = 1'b1;
      default: begin
      end
    endcase
  end

  // o_readmem_mux_sel <= i_address_lines;
  always_ff @(posedge clk) begin
    if (reset) begin
      o_readmem_mux_sel <= 2'b0;
    end else begin
      o_readmem_mux_sel <= i_address_lines;
    end
  end

endmodule

