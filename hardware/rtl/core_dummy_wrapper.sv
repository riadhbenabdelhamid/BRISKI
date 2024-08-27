`include "riscv_pkg.sv"
module core_dummy_wrapper #(
    parameter int MMCM_OUT_FREQ = 675
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

  // Instruction mem signals
  logic [31:0] rom_data ;
  logic [ 9:0] rom_addr ;

  // Mem signals
  logic [13:0] RVcore_addr;
  logic [31:0] RVcore_wr_data;
  logic [ 3:0] RVcore_wr_en;  // One bit per byte in word
  logic [31:0] RVcore_rd_data;

  logic [ 9:0] BRAM_addr;  // 10 bit to address 1024 32-bit locations in the entire BRAM
  logic [31:0] BRAM_wr_data;
  logic [ 3:0] BRAM_wr_en;  // One bit per byte in word
  logic [31:0] BRAM_rd_data;

  //BRAM interface
  assign BRAM_addr = RVcore_addr[9:0];
  assign BRAM_wr_data = RVcore_wr_data;
  assign BRAM_wr_en = RVcore_wr_en;
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
  //================================================================================================================--
  // the RISC-V core
  //================================================================================================================--
  // Attribute to keep hierarchy
  //(* keep_hierarchy = "true" *)
  RISCV_core #(
      .IDcluster(0),
      .IDrow    (0),
      .IDminirow(0),
      .IDposx   (0)
  ) RISCV_core_inst (
      .clk                (clkout0),
      .reset              (sync_reset),
      .i_ROM_instruction  (rom_data),
      .o_ROM_addr         (rom_addr),
      .o_dmem_addr        (RVcore_addr),
      .o_dmem_write_data  (RVcore_wr_data),
      .o_dmem_write_enable(RVcore_wr_en),
      .i_dmem_read_data   (RVcore_rd_data),
      //DEBUG outputs
      .regfile_wr_addr    (),
      .regfile_wr_data    (),
      .regfile_wr_en      (),
      .thread_index_wb    (),
      .thread_index_wrmem ()
  );

  assign RVcore_rd_data = BRAM_rd_data;

  always@(posedge clkout0)
	  done <= |RVcore_wr_en;
  //================================================================================================================--
  //instr_and_data_mem : entity work.BRAM  generic map (SIZE => 1024, ADDR_WIDTH => 10, COL_WIDTH => 8, NB_COL => 4)
  //===============================================================================================================--
  BRAM #(
      .SIZE(SIZE),
      .ADDR_WIDTH(ADDR_WIDTH),
      .COL_WIDTH(COL_WIDTH),
      .NB_COL(NB_COL),
      .INIT_FILE(HEX_PROG)
  ) instr_and_data_mem (
      //--------------------------
      //port a (data part)
      //--------------------------
      .clka (clkout0),
      .ena  (1'b1),
      .wea  (BRAM_wr_en),
      .addra(BRAM_addr),
      .dia  (BRAM_wr_data),
      .doa  (BRAM_rd_data),
      //------------------------
      //port b (instrution ROM)
      //------------------------
      .clkb (clk),
      .enb  (1),
      .web  (0),
      .addrb(rom_addr),
      .dib  ('0),
      .dob  (rom_data)
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

