`ifndef PKG_IMP_DONE // if the flag is not yet set
`define PKG_IMP_DONE // set the flag

package riscv_pkg;

  typedef enum {
    true,
    false
  } bool;
  //===========================
  // General params
  //===========================
  parameter int DWIDTH = 32;
  parameter int IWIDTH = 32;
  parameter int REGFILE_SIZE = 32;
  parameter [11:0] STARTUP_ADDR = 0;
  parameter int MEMORY_SIZE = 1024;

  `ifndef MMCM_OUT_FREQ_MHZ
    `define MMCM_OUT_FREQ_MHZ 300
  `endif

  `ifndef NUM_THREADS
    `define NUM_THREADS 16
  `endif

  `ifndef NUM_PIPE_STAGES
    `define NUM_PIPE_STAGES 16
  `endif
  //===========================
  // Pipeline depth params
  //===========================
  typedef struct packed {
    bit [4:0] fetch_stages;
    bit [4:0] decode_stages;
    bit [4:0] execute_stages;
    bit [4:0] memory_stages;
    bit [4:0] writeback_stages;
  } pipeline_config_t;

  //===========================
  // ALU specific params
  //===========================
  parameter int ALUOP_WIDTH = 4;
  parameter logic [ALUOP_WIDTH-1:0] ADD_OP = 4'b0000;
  parameter logic [ALUOP_WIDTH-1:0] SUB_OP = 4'b0001;
  parameter logic [ALUOP_WIDTH-1:0] OR_OP = 4'b1000;
  parameter logic [ALUOP_WIDTH-1:0] AND_OP = 4'b1001;
  parameter logic [ALUOP_WIDTH-1:0] XOR_OP = 4'b0101;
  parameter logic [ALUOP_WIDTH-1:0] PASS_OP = 4'b1010;
  parameter logic [ALUOP_WIDTH-1:0] SLT_OP = 4'b0011;
  parameter logic [ALUOP_WIDTH-1:0] SLTU_OP = 4'b0100;
  parameter logic [ALUOP_WIDTH-1:0] SLL_OP = 4'b0010;
  parameter logic [ALUOP_WIDTH-1:0] SRL_OP = 4'b0110;
  parameter logic [ALUOP_WIDTH-1:0] SRA_OP = 4'b0111;

  `ifndef ENABLE_ALU_DSP
    `define ENABLE_ALU_DSP true  //enables using dsp within alu to reduce LUT utilization
  `endif

  `ifndef ENABLE_UNIFIED_BARREL_SHIFTER
    `define ENABLE_UNIFIED_BARREL_SHIFTER true  // true for BRAM-based (block), false for LUT-based (distributed)
  `endif
  //===========================
  // DATA+INSTR BRAM specific params
  //===========================
  parameter int SIZE = MEMORY_SIZE;
  parameter int ADDR_WIDTH = 10;
  parameter int COL_WIDTH = 8;
  parameter int NB_COL = 4;
  //typedef logic [NB_COL * COL_WIDTH - 1:0] ram_type[SIZE-1:0];

  //===========================
  // REG FILE BRAM
  //===========================
  `ifndef ENABLE_BRAM_REGFILE 
    `define ENABLE_BRAM_REGFILE false  // true for BRAM-based (block), false for LUT-based (distributed)
  `endif

  //===========================
  // UTILITY types
  //===========================
  //localparam string HEX_PATH = "../../software/runs/";
  //parameter string HEX_NAME = "test_bitwise.inst";
  //localparam string HEX_PROG = {HEX_PATH, HEX_NAME};
  //===========================
  // UTILITY functions
  //===========================
  
  // clog2 =========================
  function int clog2(int A);
    return $clog2(A);
  endfunction

  // MAX ===========================
  function int max(int Lh, int Rh);
    return (Lh > Rh) ? Lh : Rh;
  endfunction

  // Reverse bits ===========================
  function logic [31:0] reverse_bits(input logic [31:0] in);
    logic [31:0] out;
    for (int i = 0; i < 32; i++) begin
        out[i] = in[31-i];
    end
    return out;
  endfunction


  // get_pipeline_config ===========================
  function pipeline_config_t  get_pipeline_config(input int num_pipe_stages);
	  pipeline_config_t pipeline_cfg;
	  case (num_pipe_stages)
		  4: begin  // The minimal configuration supports 4 pipeline stages
			  pipeline_cfg.fetch_stages     = 5'b00001; //fetch_stages[0] must be always 1
			  pipeline_cfg.decode_stages    = 5'b01000; //decode_stages[3] must be always 1
			  pipeline_cfg.execute_stages   = 5'b00000;
			  pipeline_cfg.memory_stages    = 5'b01000; //memory_stages[3] must be always 1
			  pipeline_cfg.writeback_stages = 5'b10000; //writeback_stages[4] must be always 1
		  end
		  5: begin
			  pipeline_cfg.fetch_stages     = 5'b00001;
			  pipeline_cfg.decode_stages    = 5'b01000;
			  pipeline_cfg.execute_stages   = 5'b10000;
			  pipeline_cfg.memory_stages    = 5'b01000;
			  pipeline_cfg.writeback_stages = 5'b10000;
		  end
		  6: begin
			  pipeline_cfg.fetch_stages     = 5'b00011;
			  pipeline_cfg.decode_stages    = 5'b01000;
			  pipeline_cfg.execute_stages   = 5'b10000;
			  pipeline_cfg.memory_stages    = 5'b01000;
			  pipeline_cfg.writeback_stages = 5'b10000;
		  end
		  7: begin
			  pipeline_cfg.fetch_stages     = 5'b00011;
			  pipeline_cfg.decode_stages    = 5'b01010;
			  pipeline_cfg.execute_stages   = 5'b10000;
			  pipeline_cfg.memory_stages    = 5'b01000;
			  pipeline_cfg.writeback_stages = 5'b10000;
		  end
		  8: begin
			  pipeline_cfg.fetch_stages     = 5'b00011;
			  pipeline_cfg.decode_stages    = 5'b01010;
			  pipeline_cfg.execute_stages   = 5'b10000;
			  pipeline_cfg.memory_stages    = 5'b11000;
			  pipeline_cfg.writeback_stages = 5'b10000;
		  end
		  9: begin
			  pipeline_cfg.fetch_stages     = 5'b00011;
			  pipeline_cfg.decode_stages    = 5'b11010;
			  pipeline_cfg.execute_stages   = 5'b10000;
			  pipeline_cfg.memory_stages    = 5'b11000;
			  pipeline_cfg.writeback_stages = 5'b10000;
		  end
		  10: begin
			  //pipeline_cfg.fetch_stages     = 5'b00011;
			  //pipeline_cfg.decode_stages    = 5'b11100;
			  //pipeline_cfg.execute_stages   = 5'b10000;
			  //pipeline_cfg.memory_stages    = 5'b11001;
			  //pipeline_cfg.writeback_stages = 5'b10000;
			  pipeline_cfg.fetch_stages     = 5'b00011;
			  pipeline_cfg.decode_stages    = 5'b11010;
			  pipeline_cfg.execute_stages   = 5'b10000;
			  pipeline_cfg.memory_stages    = 5'b11001;
			  pipeline_cfg.writeback_stages = 5'b10000;
		  end
		  11: begin
			  //pipeline_cfg.fetch_stages     = 5'b00011;
			  //pipeline_cfg.decode_stages    = 5'b01000;
			  //pipeline_cfg.execute_stages   = 5'b01101;
			  //pipeline_cfg.memory_stages    = 5'b01001;
			  //pipeline_cfg.writeback_stages = 5'b10101;
			  pipeline_cfg.fetch_stages     = 5'b00011;
			  pipeline_cfg.decode_stages    = 5'b11010;
			  pipeline_cfg.execute_stages   = 5'b10000;
			  pipeline_cfg.memory_stages    = 5'b11001;
			  pipeline_cfg.writeback_stages = 5'b10100;
		  end
		  12: begin
			  //pipeline_cfg.fetch_stages     = 5'b00011;
			  //pipeline_cfg.decode_stages    = 5'b01000;
			  //pipeline_cfg.execute_stages   = 5'b01111;
			  //pipeline_cfg.memory_stages    = 5'b01001;
			  //pipeline_cfg.writeback_stages = 5'b10101;
			  pipeline_cfg.fetch_stages     = 5'b00011;
			  pipeline_cfg.decode_stages    = 5'b11010;
			  pipeline_cfg.execute_stages   = 5'b11000;
			  pipeline_cfg.memory_stages    = 5'b11001;
			  pipeline_cfg.writeback_stages = 5'b10100;
		  end
		  13: begin
			  //pipeline_cfg.fetch_stages     = 5'b00011;
			  //pipeline_cfg.decode_stages    = 5'b11000;
			  //pipeline_cfg.execute_stages   = 5'b11000;
			  //pipeline_cfg.memory_stages    = 5'b11101;
			  //pipeline_cfg.writeback_stages = 5'b11100;
			  pipeline_cfg.fetch_stages     = 5'b00011;
			  pipeline_cfg.decode_stages    = 5'b11010;
			  pipeline_cfg.execute_stages   = 5'b11000;
			  pipeline_cfg.memory_stages    = 5'b11101;
			  pipeline_cfg.writeback_stages = 5'b10100;
		  end
		  14: begin
			  //pipeline_cfg.fetch_stages     = 5'b00011;
			  //pipeline_cfg.decode_stages    = 5'b11000;
			  //pipeline_cfg.execute_stages   = 5'b11100;
			  //pipeline_cfg.memory_stages    = 5'b11101;
			  //pipeline_cfg.writeback_stages = 5'b11100;
			  pipeline_cfg.fetch_stages     = 5'b00011;
			  pipeline_cfg.decode_stages    = 5'b11010;
			  pipeline_cfg.execute_stages   = 5'b11100;
			  pipeline_cfg.memory_stages    = 5'b11101;
			  pipeline_cfg.writeback_stages = 5'b10100;
		  end
		  15: begin
			  //pipeline_cfg.fetch_stages     = 5'b00011;
			  //pipeline_cfg.decode_stages    = 5'b11000;
			  //pipeline_cfg.execute_stages   = 5'b11110;
			  //pipeline_cfg.memory_stages    = 5'b11101;
			  //pipeline_cfg.writeback_stages = 5'b11100;
			  pipeline_cfg.fetch_stages     = 5'b00011;
			  pipeline_cfg.decode_stages    = 5'b11010;
			  pipeline_cfg.execute_stages   = 5'b11110;
			  pipeline_cfg.memory_stages    = 5'b11101;
			  pipeline_cfg.writeback_stages = 5'b10100;
		  end
		  16: begin
			  //pipeline_cfg.fetch_stages     = 5'b00011;
			  //pipeline_cfg.decode_stages    = 5'b01010;
			  //pipeline_cfg.execute_stages   = 5'b11111;
			  //pipeline_cfg.memory_stages    = 5'b11101;
			  //pipeline_cfg.writeback_stages = 5'b11100;
			  pipeline_cfg.fetch_stages     = 5'b00011;
			  pipeline_cfg.decode_stages    = 5'b11100;
			  pipeline_cfg.execute_stages   = 5'b11110;
			  pipeline_cfg.memory_stages    = 5'b11101;
			  pipeline_cfg.writeback_stages = 5'b11100;
		  end
		  default : begin
			  pipeline_cfg.fetch_stages     = 5'b00001;
			  pipeline_cfg.decode_stages    = 5'b01000;
			  pipeline_cfg.execute_stages   = 5'b00000;
			  pipeline_cfg.memory_stages    = 5'b01000;
			  pipeline_cfg.writeback_stages = 5'b10000;
		  end
	  endcase

    return pipeline_cfg;
  endfunction

endpackage

import riscv_pkg::*;

`endif
