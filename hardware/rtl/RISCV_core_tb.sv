`include "riscv_pkg.sv"
//import riscv_pkg::*;

module RISCV_core_tb;

  parameter TB_INIT_FILE_NAME = "branches.inst";
  localparam TB_INIT_FILE_PATH = "../../software/runs/";
  localparam TB_INIT_FILE = {TB_INIT_FILE_PATH, TB_INIT_FILE_NAME};
  logic [31:0] tb_ROM_instruction;
  logic [9:0] tb_ROM_addr;
  // Data memory signals
  logic [13:0] tb_dmem_addr;
  logic [31:0] tb_dmem_write_data;
  logic [3:0] tb_dmem_write_enable;
  logic [31:0] tb_dmem_read_data;
  // Regfile signals for debug
  logic [4:0] tb_regfile_wr_addr;
  logic [31:0] tb_regfile_wr_data;
  logic tb_regfile_wr_en;
  // thread index signals for debug
  logic [3:0] tb_thread_index_wb;
  logic [3:0] tb_thread_index_wrmem;

  bit clk;
  bit reset;

  int fd_regs;
  int fd_mem;
  logic BRAM_EN;

  task dump_registers();
     forever begin
     fd_regs = $fopen("./dumped_regs.txt", "a");
     repeat(1) @(posedge clk);
	     if (tb_regfile_wr_en == 1'b1) begin
		     $fdisplay(fd_regs, "Thread = %0d, addr = %0d, data = %0d", tb_thread_index_wb, tb_regfile_wr_addr, tb_regfile_wr_data);
		     $fdisplay(fd_regs, "==========================================");
	     end
      $fclose(fd_regs);
      end
   endtask

  task dump_memory();
     forever begin
     fd_mem = $fopen("./dumped_mem.txt", "a");
     repeat(1) @(posedge clk);
	     if (tb_dmem_write_enable == 1'b1) begin
		     $fdisplay(fd_mem, "Thread = %0d, addr = %0d, data = %0d", tb_thread_index_wrmem, tb_dmem_addr, tb_dmem_write_data);
		     $fdisplay(fd_mem, "==========================================");
	     end
      $fclose(fd_mem);
      end
  endtask

  initial begin
	  //fork
            dump_registers();
	  //join_none;
  end
  initial begin
	  //fork
            dump_memory();
	  //join_none;
  end
  initial begin
    clk = 0;
  end
  always #10 clk = ~clk;

  initial begin
    reset = 1;
    #200;
    reset = 0;
    #16000;
    $finish;
  end

  initial begin
    $dumpfile("RISCV_core_tb_waveform.vcd");
    $dumpvars;
  end

  RISCV_core #(
      // Generic parameters
      .IDcluster(0),
      .IDrow(0),
      .IDminirow(0),
      .IDposx(0)
  ) RISCV_core_inst (
      .clk(clk),
      .reset(reset),
      .i_ROM_instruction(tb_ROM_instruction),
      .o_ROM_addr(tb_ROM_addr),
      .o_dmem_addr(tb_dmem_addr),
      .o_dmem_write_data(tb_dmem_write_data),
      .o_dmem_write_enable(tb_dmem_write_enable),
      .i_dmem_read_data(tb_dmem_read_data),
      .regfile_wr_addr(tb_regfile_wr_addr),
      .regfile_wr_data(tb_regfile_wr_data),
      .regfile_wr_en(tb_regfile_wr_en),
      .thread_index_wb(tb_thread_index_wb),
      .thread_index_wrmem(tb_thread_index_wrmem)
  );
  memory_map_decoder memory_map_decoder_inst (
      .clk                (clk),
      .reset              (reset),
      .i_address_lines    (tb_dmem_addr[13:12]),
      .o_dmem_enable      (BRAM_EN),
      .o_shared_mem_enable(),
      .o_MMIO_enable      (),
      .o_readmem_mux_sel  ()
  );

  BRAM #(
      .SIZE(SIZE),
      .ADDR_WIDTH(ADDR_WIDTH),
      .COL_WIDTH(COL_WIDTH),
      .NB_COL(NB_COL),
      .INIT_FILE(TB_INIT_FILE)
  ) instr_and_data_mem (
      //--------------------------
      //port a (data part)
      //--------------------------
      .clka (clk),
      .ena  (BRAM_EN),
      .wea  (tb_dmem_write_enable),
      .addra(tb_dmem_addr[9:0]),
      .dia  (tb_dmem_write_data),
      .doa  (tb_dmem_read_data),
      //------------------------
      //port b (instrution ROM)
      //------------------------
      .clkb (clk),
      .enb  (1),
      .web  (0),
      .addrb(tb_ROM_addr),
      .dib  ('0),
      .dob  (tb_ROM_instruction)
  );

endmodule
