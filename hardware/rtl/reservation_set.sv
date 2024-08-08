module reservation_set #(
    parameter integer NUM_THREADS = 16
) (
    input logic clk,
    input logic reset,
    input logic [11:0] i_addr,
    input logic i_store_op,
    input logic i_store_cond_op,
    input logic i_load_reserved_op,
    input logic [$clog2(NUM_THREADS)-1:0] i_mhartid,
    output logic o_sc_success
);

  logic [11:0] reserved_address ;
  logic [$clog2(NUM_THREADS)-1:0] reserving_hart ;
  logic reserved_valid;
  logic address_match ;
  logic hart_match ;
  assign address_match = (i_addr == reserved_address) ? 1'b1 : 1'b0;
  assign hart_match = (i_mhartid == reserving_hart) ? 1'b1 : 1'b0;

  always_ff @(posedge clk) begin
    if (reset) begin
      reserved_valid <= 1'b0;
    end else begin
      if (i_load_reserved_op) 
        reserved_valid <= 1'b1;

      //if (i_store_cond_op && hart_match && address_match) 
      if (i_store_cond_op && hart_match) 
        reserved_valid <= 1'b0;

      if (i_store_op && address_match) 
	reserved_valid <= 1'b0;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      o_sc_success <= 1'b0;
    end else begin
      o_sc_success <= reserved_valid && address_match && i_store_cond_op && hart_match;
    end
  end

  always_ff @(posedge clk) begin
    if (i_load_reserved_op) begin
      if (!reserved_valid ) begin
        reserved_address <= i_addr;
        reserving_hart <= i_mhartid;
      end else if (hart_match) begin
        reserved_address <= i_addr;
      end
    end
  end

endmodule

