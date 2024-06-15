module pipe_vec #(
    parameter DWIDTH = 8,
    N = 1,
    WithReset = 0
) (
    input logic reset,
    input logic clk,
    input logic [DWIDTH-1:0] i_signal,
    output logic [DWIDTH-1:0] o_pipelined_signal
);

  logic [N-1:0][DWIDTH-1:0] pipeline_stages;


  if (WithReset == 0) begin : without_reset

    if (N == 1) begin : n_is_1
      always_ff @(posedge clk) begin
        pipeline_stages[0] <= i_signal;
      end
      assign o_pipelined_signal = pipeline_stages[0];
    end else if (N == 2) begin : n_is_2
      always_ff @(posedge clk) begin
        pipeline_stages[0] <= i_signal;
        pipeline_stages[1] <= pipeline_stages[0];
      end
      assign o_pipelined_signal = pipeline_stages[1];
    end else begin : n_is_greater_than_2
      always_ff @(posedge clk) begin
        pipeline_stages[0] <= i_signal;
        for (int i = 1; i < N; i++) begin
          pipeline_stages[i] <= pipeline_stages[i-1];
        end
      end
      assign o_pipelined_signal = pipeline_stages[N-1];
    end

  end else begin : with_reset

    if (N == 1) begin : n_is_1_reset
      always_ff @(posedge clk) begin
        if (reset) begin
          pipeline_stages[0] <= 0;
        end else begin
          pipeline_stages[0] <= i_signal;
        end
      end
      assign o_pipelined_signal = pipeline_stages[0];
    end else if (N == 2) begin : n_is_2_reset
      always_ff @(posedge clk) begin
        if (reset) begin
          pipeline_stages[0] <= 0;
        end else begin
          pipeline_stages[0] <= i_signal;
        end
        pipeline_stages[1] <= pipeline_stages[0];
      end
      assign o_pipelined_signal = pipeline_stages[1];
    end else begin : n_is_greater_than_2_reset
      always_ff @(posedge clk) begin
        if (reset) begin
          pipeline_stages[0] <= 0;
        end else begin
          pipeline_stages[0] <= i_signal;
        end
        for (int i = 1; i < N; i++) begin
          pipeline_stages[i] <= pipeline_stages[i-1];
        end
      end
      assign o_pipelined_signal = pipeline_stages[N-1];
    end

  end

endmodule

