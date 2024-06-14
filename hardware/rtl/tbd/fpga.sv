module fpga
  import riscv_pkg::*;
(
    BTNC,
    CLK100MHZ,
    LED,
    SW
);

  input logic BTNC;  //reset button
  input logic CLK100MHZ;  //system clock
  output logic [15:0] LED;
  input logic [15:0] SW;

  logic main_clk;  //MCM main generated clock
  logic ibuf_clk;  //buffered external input clock
  logic ibuf_reset;  //buffered external input reset
  logic sync_reset;  //synchronized reset
  logic locked;  //MMCM locked signal
  logic ibuf_reset_or_not_locked;  //synchronized reset

  //instruction mem signals
  logic [31:0] rom_data;
  logic [9:0] rom_addr;

  //mem signals
  logic [13:0] RVcore_addr;
  logic [31:0] RVcore_wr_data;
  logic [3:0] RVcore_wr_en;  // One bit per byte in word
  logic [31:0] RVcore_rd_data;

  logic [9:0] BRAM_addr;  //10 bit to address 1024 32-bit loations in the entire BRAM
  logic [31:0] BRAM_wr_data;
  logic [3:0] BRAM_wr_en;  // One bit per byte in word
  logic [31:0] BRAM_rd_data;

  logic [7:0] MMIO_addr;  // 16 registers at most but more can be added
  logic [31:0] MMIO_wr_data;
  logic MMIO_wr_en;
  logic [31:0] MMIO_rd_data;
  logic [31:0] MMIO_rd_data_reg;


  //memory enable control signals
  logic BRAM_EN;
  logic URAM_EN;
  logic MMIO_EN;

  //mux read back:
  logic readmem_mux_sel;

  //manually replicating signals
  //=====================================================================================--

  //BRAM interface
  assign BRAM_addr = RVcore_addr[9:0];
  assign BRAM_wr_data = RVcore_wr_data;
  assign BRAM_wr_en = RVcore_wr_en;

  //MMIO interface
  assign MMIO_addr = RVcore_addr[7:0];
  assign MMIO_wr_data = RVcore_wr_data;
  assign MMIO_wr_en   = &RVcore_wr_en;       //uses only write word but stores a chunk of the word (AND reduce)

  pipe_vec #(
      .DWIDTH(32),
      .N(1),
      .WithReset(true)
  )  //used to delay read data to match latency with BRAM
      MMIO_rd_data_pipe_inst (
      .reset(sync_reset),
      .clk(main_clk),
      .i_signal(MMIO_rd_data),
      .o_pipelined_signal(MMIO_rd_data_reg)
  );
  //----------------------------
  MMCM_clock_gen #(150) MMCM_clock_gen_inst (
      .clock_in(ibuf_clk),
      .async_reset(ibuf_reset),
      .clock_out(main_clk),
      .locked(locked)
  );

  IBUF input_buf_clock (
      .O(ibuf_clk),
      .I(CLK100MHZ)
  );

  //=======================================================
  //=========      ASYNC RESET synchronizer    ===========
  //=======================================================
  async_reset_synchronizer reset_gen (
      .clk(main_clk),
      .async_reset(ibuf_reset_or_not_locked),
      .sync_reset(sync_reset)
  );

  IBUF reset_buf (
      .O(ibuf_reset),
      .I(BTNC)
  );

  assign ibuf_reset_or_not_locked = ibuf_reset | (!locked);

  //=======================================================
  //=========      Done                         ===========
  //=======================================================
  //OBUF led_buf
  //    ( O => DONE_GPIO_LED_0,
  //       I => done
  //    );

  //=====================================================================================--
  //multiplexing the read data
  //=====================================================================================--
  mux2to1 mem_read_data_mux_inst (
      .i_sel(readmem_mux_sel),
      .i_in0(BRAM_rd_data),
      .i_in1(MMIO_rd_data_reg),
      .o_muxout(RVcore_rd_data)
  );
  //=====================================================================================--
  // memory map decoder that activate eithr BRAM (local mem)
  // or MMIO mem (used for synchronization between cores)
  //=====================================================================================--
  memory_map_decoder memory_map_decoder_inst (
      .clk(main_clk),
      .reset(sync_reset),
      .i_address_lines(RVcore_addr[13]),
      .o_dmem_enable(BRAM_EN),
      .o_MMIO_enable(MMIO_EN),
      .o_readmem_mux_sel(readmem_mux_sel)
  );


  //================================================================================================================--
  // the RISC-V core
  //================================================================================================================--
  RISCV_core #(
      .IDcluster(0),
      .IDrow(0),
      .IDminirow(0),
      .IDposx(0)
  ) RISCV_core_inst (
      .clk                (main_clk),
      .reset              (sync_reset),
      //instr mem signal
      .i_ROM_instruction  (rom_data),
      .o_ROM_addr         (rom_addr),
      //data mem signals
      .o_dmem_addr        (RVcore_addr),
      .o_dmem_write_data  (RVcore_wr_data),
      .o_dmem_write_enable(RVcore_wr_en),
      .i_dmem_read_data   (RVcore_rd_data)
  );


  //================================================================================================================--
  //instr_and_data_mem : entity work.BRAM  generic map (SIZE => 1024, ADDR_WIDTH => 10, COL_WIDTH => 8, NB_COL => 4)
  //===============================================================================================================--
  BRAM #(
      .SIZE(SIZE),
      .ADDR_WIDTH(ADDR_WIDTH),
      .COL_WIDTH(COL_WIDTH),
      .NB_COL(NB_COL),
      .INIT_FILE(HEX_PROG),
      .RAM_STYLE_ATTR("block")
  ) instr_and_data_mem (
      //--------------------------
      //port a (data part)
      //------------------------
      .clka (main_clk),
      .ena  (BRAM_EN),
      .wea  (BRAM_wr_en),
      .addra(BRAM_addr),
      .dia  (BRAM_wr_data),
      .doa  (BRAM_rd_data),
      //------------------------
      //port b (instrution ROM)
      //------------------------
      .clkb (main_clk),
      .enb  (1'b1),
      .web  (1'b0),
      .addrb(rom_addr),
      .dib  (0),
      .dob  (rom_data)
  );


  //=====================================================================================--
  // memory_mapped_interface
  //=====================================================================================--
  nexys_a7_mem_map memory_mapped_interface_inst (
      .clk(main_clk),
      .reset(sync_reset),
      .gpio_led(LED),
      .gpio_sw(SW),
      //RVcore interface
      .i_mmio_enable(MMIO_EN),
      .i_mmio_addr(MMIO_addr),
      .i_mmio_wen(MMIO_wr_en),
      //i_mmio_data_in => MMIO_wr_data(DWIDTH-1 downto 0),
      .i_mmio_data_in(MMIO_wr_data),
      .o_mmio_data_out(MMIO_rd_data)
  );

endmodule
