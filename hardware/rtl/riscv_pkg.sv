package riscv_pkg;
  //===========================
  // Manycore array params
  //===========================
  parameter int array_len = 45;

  //===========================
  // Cluster params
  //===========================
  //parameter int x_cluster = 4;
  //parameter int y_cluster = 6;

  //===========================
  // General params
  //===========================
  parameter int DWIDTH = 32;
  parameter int IWIDTH = 32;
  parameter int NUM_THREADS = 16;
  parameter int REGFILE_SIZE = 32;
  parameter [11:0] STARTUP_ADDR = 0;
  parameter int MEMORY_SIZE = 1024;

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

  //===========================
  // BRAM specific params
  //===========================
  parameter int SIZE = MEMORY_SIZE;
  parameter int ADDR_WIDTH = 10;
  parameter int COL_WIDTH = 8;
  parameter int NB_COL = 4;
  typedef logic [NB_COL * COL_WIDTH - 1:0] ram_type[SIZE-1:0];

  //===========================
  // REG FILE BRAM
  //===========================
  typedef enum {
    true,
    false
  } bool;
  parameter bool RF_USE_BRAM = true;
  parameter int RF_SIZE = REGFILE_SIZE * NUM_THREADS;
  typedef logic [DWIDTH-1:0] regfile_ram_type[RF_SIZE-1:0];

  //===========================
  // UTILITY types
  //===========================
  parameter HEX_PROG = "../../programs/hex/bubble_sort.inst";
  //===========================
  // UTILITY functions
  //===========================
  // clog2
  function int clog2(int A);
    return $clog2(A);
  endfunction

  function int max(int Lh, int Rh);
    return (Lh > Rh) ? Lh : Rh;
  endfunction

endpackage

