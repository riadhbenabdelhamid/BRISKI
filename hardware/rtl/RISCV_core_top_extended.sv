`include "riscv_pkg.sv"
//import riscv_pkg::*;
module RISCV_core_top_extended #(
    //main parameters
    parameter NUM_PIPE_STAGES  = `NUM_PIPE_STAGES,
    parameter NUM_THREADS      = `NUM_THREADS,
    // RF parameter 
    parameter bool ENABLE_BRAM_REGFILE = `ENABLE_BRAM_REGFILE,
    // ALU parameter 
    parameter bool ENABLE_ALU_DSP = `ENABLE_ALU_DSP ,
    parameter bool ENABLE_UNIFIED_BARREL_SHIFTER = `ENABLE_UNIFIED_BARREL_SHIFTER,
    //parameter string HEX_PROG = "../../software/runs/sparkle-template-mandelbrot.inst",
    parameter BRAM_DATA_INSTR_FILE = "none",
    // Generic parameters
    parameter int IDcluster = 0,
    parameter int IDrow = 0,
    parameter int IDminirow = 0,
    parameter int IDposx = 0
) (
    input logic clk,
    input logic reset,
    // URAM interface
    output logic o_URAM_en,
    output logic [11:0] o_URAM_addr,
    output logic [31:0] o_URAM_wr_data,
    output logic o_URAM_wr_en,
    // row sync IO interface (arbiter+barriers)
    input logic i_uram_emptied,
    output logic o_core_req,
    output logic o_core_locked,
    input logic i_core_grant
);
  // Attribute to keep hierarchy
  (* keep_hierarchy = "true" *)

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

  // Replaced by external interface signals
  // logic [11:0] URAM_addr;
  // logic [31:0] URAM_wr_data;
  // logic URAM_wr_en;  // One bit per word
  // logic [31:0] URAM_rd_data;

  logic [ 4:0] MMIO_addr;  // 32 registers at most but more can be added
  logic        MMIO_wr_data;
  logic        MMIO_wr_en;
  logic [31:0] MMIO_rd_data;
  logic [31:0] MMIO_rd_data_reg;

  // Memory enable control signals
  logic        BRAM_EN;
  logic        URAM_EN;
  logic        MMIO_EN;

  // Mux read back:
  logic [ 1:0] readmem_mux_sel;

  logic [ 4:0] DEBUG_regfile_wr_addr;
  logic [31:0] DEBUG_regfile_wr_data;
  logic        DEBUG_regfile_wr_en;
  logic [ $clog2(NUM_THREADS)-1:0] DEBUG_thread_index_wb;
  logic [ $clog2(NUM_THREADS)-1:0] DEBUG_thread_index_wrmem;
  //manually replicating signals
  //=====================================================================================--

  //BRAM interface
  assign BRAM_addr = RVcore_addr[9:0];
  assign BRAM_wr_data = RVcore_wr_data;
  assign BRAM_wr_en = RVcore_wr_en;

  //URAM interface
  assign o_URAM_addr = (i_core_grant == 0) ? 0 : RVcore_addr[11:0];
  assign o_URAM_wr_data = (i_core_grant==0) ? 0 : RVcore_wr_data;  // Later need to extend to fit URAM input (64 bit)
  assign o_URAM_wr_en   = (i_core_grant==0) ? 0 : (&RVcore_wr_en);  //only write word is supported (1bit we, and-reduce original we)
  assign o_URAM_en = (i_core_grant == 0) ? 0 : URAM_EN;

  //MMIO interface
  assign MMIO_addr = RVcore_addr[4:0];
  assign MMIO_wr_data = RVcore_wr_data[0];
  assign MMIO_wr_en = &RVcore_wr_en;  //uses only write word but stores a chunk of the word


  //pipe_vec #(
  //    .N(32),
  //    .WithReset(1)
  //) MMIO_rd_data_pipe_inst (
  //    .reset(reset),
  //    .clk(clk),
  //    .i_signal(MMIO_rd_data),
  //    .o_pipelined_signal(MMIO_rd_data_reg)
  //);

  //=====================================================================================--
  //multiplexing the read data
  //=====================================================================================--
  mux3to1 mem_read_data_mux_inst (
      .i_sel   (readmem_mux_sel),
      .i_in0   (BRAM_rd_data),
      .i_in1   (0),
      //.i_in2   (MMIO_rd_data_reg),
      .i_in2   (MMIO_rd_data),
      .o_muxout(RVcore_rd_data)
  );

  //=====================================================================================--
  // memory map decoder that activate eithr BRAM (local mem), URAM (shared mem)
  // or MMIO mem (used for synchronization between cores)
  //=====================================================================================--
  memory_map_decoder memory_map_decoder_inst (
      .clk                (clk),
      .reset              (reset),
      .i_address_lines    (RVcore_addr[13:12]),
      .o_dmem_enable      (BRAM_EN),
      .o_shared_mem_enable(URAM_EN),
      .o_MMIO_enable      (MMIO_EN),
      .o_readmem_mux_sel  (readmem_mux_sel)
  );


  //================================================================================================================--
  // the RISC-V core
  //================================================================================================================--
  RISCV_core #(
      .IDcluster(IDcluster),
      .IDrow    (IDrow),
      .IDminirow(IDminirow),
      .IDposx   (IDposx)
  ) RISCV_core_inst (
      .clk                (clk),
      .reset              (reset),
      .i_ROM_instruction  (rom_data),
      .o_ROM_addr         (rom_addr),
      .o_dmem_addr        (RVcore_addr),
      .o_dmem_write_data  (RVcore_wr_data),
      .o_dmem_write_enable(RVcore_wr_en),
      .i_dmem_read_data   (RVcore_rd_data),
      //DEBUG outputs
      .regfile_wr_addr    (DEBUG_regfile_wr_addr),
      .regfile_wr_data    (DEBUG_regfile_wr_data),
      .regfile_wr_en      (DEBUG_regfile_wr_en),
      .thread_index_wb    (DEBUG_thread_index_wb),
      .thread_index_wrmem (DEBUG_thread_index_wrmem)
  );

  //================================================================================================================--
  //instr_and_data_mem : entity work.BRAM  generic map (SIZE => 1024, ADDR_WIDTH => 10, COL_WIDTH => 8, NB_COL => 4)
  //===============================================================================================================--
  BRAM #(
      .SIZE(SIZE),
      .ADDR_WIDTH(ADDR_WIDTH),
      .COL_WIDTH(COL_WIDTH),
      .NB_COL(NB_COL),
      //.INIT_FILE(HEX_PROG)
      .INIT_FILE(BRAM_DATA_INSTR_FILE)
  ) instr_and_data_mem (
      //--------------------------
      //port a (data part)
      //--------------------------
      .clka (clk),
      .ena  (BRAM_EN),
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

  //=====================================================================================--
  // memory_mapped_interface
  //=====================================================================================--
  memory_mapped_interface_extended memory_mapped_interface_inst (
      .clk(clk),
      .reset(reset),
      // RVcore interface
      .i_mmio_enable(MMIO_EN),
      .i_mmio_addr(MMIO_addr),
      .i_mmio_wen(MMIO_wr_en),
      .i_mmio_data_in(MMIO_wr_data),
      .o_mmio_data_out(MMIO_rd_data),
      // row sync IO interface (arbiter+barriers)
      .i_uram_emptied(i_uram_emptied),
      .o_core_req(o_core_req),
      .o_core_locked(o_core_locked),
      .i_core_grant(i_core_grant)
  );

endmodule
