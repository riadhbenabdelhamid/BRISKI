module reservation_set (
    input logic clk,
    input logic reset,
    input logic [11:0] i_addr,
    input logic i_store_op,
    input logic i_store_cond_op,
    input logic i_load_reserved_op,
    output logic o_sc_success
);

  logic [11:0] reserved_address ;
  logic reserved_valid;
  logic address_match ;
  assign address_match = (i_addr == reserved_address) ? 1'b1 : 1'b0;

  always_ff @(posedge clk) begin
    if (reset) begin
      reserved_valid <= 1'b0;
    end else begin
      if (i_load_reserved_op) begin
        reserved_valid <= 1'b1;
      end else if (i_store_cond_op || (i_store_op && address_match)) begin
        reserved_valid <= 1'b0;
      end
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      o_sc_success <= 1'b0;
    end else begin
      o_sc_success <= reserved_valid && address_match && i_store_cond_op;
    end
  end

  always_ff @(posedge clk) begin
    if (i_load_reserved_op) begin
      reserved_address <= i_addr;
    end
  end

endmodule

