`include "riscv_pkg.sv"
module pcreg_vec #(
    parameter DWIDTH = 32,
    NUM_THREADS = 16,
    EXE_STAGE = 7,
    MEM_ADDR_WIDTH = 10
) (
    input logic reset,
    input logic clk,
    input logic [$clog2(NUM_THREADS)-1:0] i_thread_index_counter,
    input logic [$clog2(NUM_THREADS)-1:0] i_thread_index_execute,
    input logic [DWIDTH-1:0] i_pc_in,
    output logic [DWIDTH-1:0] o_pcreg_out
);

  localparam MEM_BYTE_ADDR = MEM_ADDR_WIDTH+2;
  logic [$clog2(NUM_THREADS)-1:0] counter;
  logic we;
  logic [$clog2(NUM_THREADS)-1:0] pcaddrin;
  logic [MEM_BYTE_ADDR-1:0] pcdatain;
  logic [MEM_BYTE_ADDR-1:0] pcdataout;

  always_ff @(posedge clk) begin
    if (reset) begin
      counter <= 0;
      we <= 1;
      pcaddrin <= pcaddrin + 1;
      pcdatain <= (MEM_BYTE_ADDR'({STARTUP_ADDR}));
    end else begin
      pcaddrin <= i_thread_index_execute;
      pcdatain <= i_pc_in[MEM_BYTE_ADDR-1:0];
      if (counter == EXE_STAGE[$clog2(NUM_THREADS)-1:0]+1) begin
        we <= 1;
      end else begin
        we <= 0;
        counter <= counter + 1;
      end
    end
  end

  LUT_RAM #(NUM_THREADS, $clog2(NUM_THREADS), MEM_BYTE_ADDR,(MEM_BYTE_ADDR'({STARTUP_ADDR}))) PC_MEM_INST (
      .clka (clk),
      .ena  (1),
      .wea  (we),
      .addra(pcaddrin),
      .dia  (pcdatain),
      .addrb(i_thread_index_counter),
      .dob  (pcdataout)
  );

  assign o_pcreg_out = {{($bits(o_pcreg_out)-$bits(pcdataout)){1'b0}}, pcdataout}; // zero-extend to match the bit widths

endmodule
