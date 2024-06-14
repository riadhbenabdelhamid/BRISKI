module async_reset_synchronizer (
    input  logic clk,
    input  logic async_reset,
    output logic sync_reset
);

  logic reset_sync1, reset_sync2, reset_sync3;

  always_ff @(posedge clk) begin
    reset_sync1 <= async_reset;
  end

  always_ff @(posedge clk) begin
    reset_sync2 <= reset_sync1;
  end

  always_ff @(posedge clk) begin
    reset_sync3 <= reset_sync2;
  end

  BUFG glob_buf_sync_reset (
      .O(sync_reset),
      .I(reset_sync3)
  );

endmodule
