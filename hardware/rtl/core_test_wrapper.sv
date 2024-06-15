`include "riscv_pkg.sv"
//import riscv_pkg::*;
module core_test_wrapper #(
    parameter int MMCM_OUT_FREQ = 650
) (
    output logic DONE_GPIO_LED_0,
    input  logic REFCLK_P,
    input  logic REFCLK_N,
    input  logic reset
);
  // Signals
  logic clkout0;  // MCM main generated clock
  logic ibuf_clk;  // buffered external input clock
  logic ibuf_reset;  // buffered external input reset
  logic sync_reset;  // synchronized reset
  logic locked;  // MMCM locked signal
  logic ibuf_reset_or_not_locked;  // synchronized reset
  logic done;  // and_reduce signal of all done signals of each cluster
  logic done_reg;  // and_reduce signal of all done signals of each cluster

  (* DONT_TOUCH = "true" *)logic proc_rst;
  (* DONT_TOUCH = "true" *)logic proc_rst_reg_1;
  (* DONT_TOUCH = "true" *)logic proc_rst_reg_2;
  logic proc_rst_reg_3;
  logic proc_rst_reg_4;
  logic proc_rst_reg_5;
  logic proc_rst_reg_6;

  //=======================================================
  //=========       CLK generate    =======================
  //=======================================================
  MMCM_clock_gen #(
      .MMCM_OUT_FREQ(MMCM_OUT_FREQ)
  ) MMCM_clock_gen_inst (
      .CLKIN1(ibuf_clk),
      .ASYNC_RESET(ibuf_reset),
      .CLK_OUT(clkout0),
      .LOCKED(locked)
  );

  IBUFDS input_buf_clock (
      .O (ibuf_clk),
      .I (REFCLK_P),
      .IB(REFCLK_N)
  );

  //=======================================================
  //=========      ASYNC RESET synchronizer    ===========
  //=======================================================
  async_reset_synchronizer sync_reset_gen_inst (
      .clk(clkout0),
      .async_reset(ibuf_reset_or_not_locked),
      .sync_reset(proc_rst)
  );

  IBUF input_buf_async_reset (
      .O(ibuf_reset),
      .I(reset)
  );

  assign ibuf_reset_or_not_locked = ibuf_reset | ~locked;

  //=======================================================
  //=========      Done                         ===========
  //=======================================================
  OBUF output_buf_done (
      .O(DONE_GPIO_LED_0),
      .I(done_reg)
  );

  RISCV_core_top #(
      .IDcluster(0),
      .IDrow(0),
      .IDminirow(0),
      .IDposx(0)
  ) RISCV_core_top_inst (
      .clk(clkout0),
      .reset(sync_reset),
      .o_URAM_en(),
      .o_URAM_addr(),
      .o_URAM_wr_data(),
      .o_URAM_wr_en(),
      .i_uram_emptied(1'b1),
      .o_core_req(),
      .o_core_locked(done),
      .i_core_grant(1'b1)
  );

  always_ff @(posedge clkout0) begin
    done_reg <= done;
    proc_rst_reg_1 <= proc_rst;
    proc_rst_reg_2 <= proc_rst_reg_1;
    proc_rst_reg_3 <= proc_rst_reg_2;
    proc_rst_reg_4 <= proc_rst_reg_3;
    proc_rst_reg_5 <= proc_rst_reg_4;
    sync_reset <= proc_rst_reg_5;
  end
endmodule

