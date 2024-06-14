//`include "riscv_pkg.sv"
import riscv_pkg::*;
module regfile_vec #(
    parameter DWIDTH = 32
) (
    input logic clk,
    input logic [$clog2(NUM_THREADS)-1:0] i_thread_index_writeback,
    input logic [$clog2(NUM_THREADS)-1:0] i_thread_index_decode,
    input logic [4:0] i_read_addr1,
    input logic [4:0] i_read_addr2,
    input logic [4:0] i_write_addr,
    input logic [31:0] i_write_data,
    input logic i_wr_en,
    output logic [31:0] o_read_data1,
    output logic [31:0] o_read_data2
);

  BRAM_SDP #(
      .SIZE(RF_SIZE),
      .ADDR_WIDTH($clog2(RF_SIZE)),
      .DATA_WIDTH(DWIDTH)
  ) regfile_top_inst (
      .clka (clk),
      .ena  (1'b1),
      .wea  (i_wr_en),
      .addra({i_thread_index_writeback, i_write_addr}),
      .dia  (i_write_data),
      .clkb (clk),
      .enb  (1'b1),
      .addrb({i_thread_index_decode, i_read_addr1}),
      .dob  (o_read_data1)
  );

  BRAM_SDP #(
      .SIZE(RF_SIZE),
      .ADDR_WIDTH($clog2(RF_SIZE)),
      .DATA_WIDTH(DWIDTH)
  ) regfile_bot_inst (
      .clka (clk),
      .ena  (1'b1),
      .wea  (i_wr_en),
      .addra({i_thread_index_writeback, i_write_addr}),
      .dia  (i_write_data),
      .clkb (clk),
      .enb  (1'b1),
      .addrb({i_thread_index_decode, i_read_addr2}),
      .dob  (o_read_data2)
  );

endmodule

