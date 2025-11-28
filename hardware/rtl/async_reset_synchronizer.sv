module async_reset_synchronizer #(ext_reset_polarity = 0) (
    input  logic clk,
    input  logic async_reset,
    output logic sync_reset
);

    (* ASYNC_REG = "TRUE" *) reg [1:0] rst_sync;

    if (ext_reset_polarity == 0) begin  // neg polarity (default)
        //external active-high reset , internal active high reset
        // Async assert, sync deassert 
        always @(posedge clk or posedge async_reset) begin
            if (async_reset) rst_sync <= 2'b11;  // assert immediately
            else rst_sync <= {1'b0, rst_sync[1]};  // deassert synced
        end
        assign sync_reset = rst_sync[0];  // synchronous reset 

    end else begin
        //external active-low reset , internal active high reset
        // Async assert, sync deassert 
        always @(posedge clk or negedge async_reset) begin
          if (!async_reset) rst_sync <= 2'b00;     // assert immediately
          else      rst_sync <= {rst_sync[0], 1'b1}; // deassert synced
        end
        assign sync_reset = ~rst_sync[1]; // synchronous reset 
    end
endmodule
