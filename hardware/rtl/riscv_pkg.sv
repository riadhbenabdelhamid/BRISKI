
`ifndef PKG_IMP_DONE  // if the flag is not yet set
`define PKG_IMP_DONE // set the flag
//`timescale 1ns/1ps
package riscv_pkg;

    typedef enum {
        false = 0,
        true  = 1
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

`ifndef ENABLE_FETCH_ADDR_PAD
    `define ENABLE_FETCH_ADDR_PAD false
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
    `define ENABLE_ALU_DSP false  //enables using dsp within alu to reduce LUT utilization
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
    // PC Memory
    //===========================
`ifndef ENABLE_LUTRAM_PCMEM
    `define ENABLE_LUTRAM_PCMEM true  //true for LUT-based (distributed), false for reg-based (registers)
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

    // get ID     ===========================
    function logic [10:0] computeID(input int varIDcluster, varIDrow, varIDminirow, varIDposx);
        logic [10:0] varID;
        varID[10:0] = {varIDcluster[3:0], varIDrow[1:0], 5'({((varIDminirow * 6) + varIDposx)})};
        return varID;
    endfunction


    // get_pipeline_config ===========================
    function pipeline_config_t get_pipeline_config(input int num_pipe_stages, input bool enable_fetch_addr_pad);
        pipeline_config_t pipeline_cfg;
        if (enable_fetch_addr_pad == false) begin
            case (num_pipe_stages)
                4: begin  // The minimal configuration supports 4 pipeline stages
                    pipeline_cfg.fetch_stages     = 5'b00001;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b01000;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b00000;
                    pipeline_cfg.memory_stages    = 5'b01000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                5: begin
                    pipeline_cfg.fetch_stages     = 5'b00001;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b01000;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b01000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                6: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b01000;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b01000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                7: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b01010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b01000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                8: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b01010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b11000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                9: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b11000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                10: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b11001;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                11: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b11001;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10100;  //writeback_stages[4] must be always 1
                end
                12: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b11000;
                    pipeline_cfg.memory_stages    = 5'b11001;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10100;  //writeback_stages[4] must be always 1
                end
                13: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b11000;
                    pipeline_cfg.memory_stages    = 5'b11101;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10100;  //writeback_stages[4] must be always 1
                end
                14: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b11100;
                    pipeline_cfg.memory_stages    = 5'b11101;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10100;  //writeback_stages[4] must be always 1
                end
                15: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b11110;
                    pipeline_cfg.memory_stages    = 5'b11101;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10100;  //writeback_stages[4] must be always 1
                end
                16: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11100;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b11110;
                    pipeline_cfg.memory_stages    = 5'b11101;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b11100;  //writeback_stages[4] must be always 1
                end
                default: begin
                    pipeline_cfg.fetch_stages     = 5'b00001;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b01000;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b00000;
                    pipeline_cfg.memory_stages    = 5'b01000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
            endcase
        end else begin
            case (num_pipe_stages)
                //---- FETCH_ADDR_PAD enabled ----------
                5: begin  // The minimal configuration supports 4 pipeline stages
                    pipeline_cfg.fetch_stages     = 5'b00001;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b01000;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b00000;
                    pipeline_cfg.memory_stages    = 5'b01000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                6: begin
                    pipeline_cfg.fetch_stages     = 5'b00001;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b01000;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b01000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                7: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b01000;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b01000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                8: begin
                    //pipeline_cfg.fetch_stages     = 5'b00011; //fetch_stages[0] must be always 1
                    //pipeline_cfg.decode_stages    = 5'b01010; //decode_stages[3] must be always 1
                    //pipeline_cfg.execute_stages   = 5'b10000;
                    //pipeline_cfg.memory_stages    = 5'b01000; //memory_stages[3] must be always 1
                    //pipeline_cfg.writeback_stages = 5'b10000; //writeback_stages[4] must be always 1

                    pipeline_cfg.fetch_stages     = 5'b00001;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11100;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b01000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                9: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b01010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b11000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                10: begin
                    //pipeline_cfg.fetch_stages     = 5'b00011; //fetch_stages[0] must be always 1 ;
                    //pipeline_cfg.decode_stages    = 5'b11010; //decode_stages[3] must be always 1
                    //pipeline_cfg.execute_stages   = 5'b10000;
                    //pipeline_cfg.memory_stages    = 5'b11000; //memory_stages[3] must be always 1
                    //pipeline_cfg.writeback_stages = 5'b10000; //writeback_stages[4] must be always 1

                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11000;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10001;
                    pipeline_cfg.memory_stages    = 5'b11000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                11: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b11001;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                12: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b10000;
                    pipeline_cfg.memory_stages    = 5'b11001;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10100;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                13: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b11000;
                    pipeline_cfg.memory_stages    = 5'b11001;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10100;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                14: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b11000;
                    pipeline_cfg.memory_stages    = 5'b11101;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10100;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                15: begin
                    pipeline_cfg.fetch_stages     = 5'b00011;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11010;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b11100;
                    pipeline_cfg.memory_stages    = 5'b11101;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10100;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                16: begin
                    //pipeline_cfg.fetch_stages     = 5'b00111; //fetch_stages[0] must be always 1
                    //pipeline_cfg.decode_stages    = 5'b11000; //decode_stages[3] must be always 1
                    //pipeline_cfg.execute_stages   = 5'b11110;
                    //pipeline_cfg.memory_stages    = 5'b11101; //memory_stages[3] must be always 1
                    //pipeline_cfg.writeback_stages = 5'b10100; //writeback_stages[4] must be always 1
                    //
                    pipeline_cfg.fetch_stages     = 5'b00111;  //fetch_stages[0] must be always 1
                    pipeline_cfg.decode_stages    = 5'b11000;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b11110;
                    pipeline_cfg.memory_stages    = 5'b11100;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10101;  //writeback_stages[4] must be always 1
                end
                //---- FETCH_ADDR_PAD enabled ----------
                default: begin
                    pipeline_cfg.fetch_stages     = 5'b00001;  //decode_stages[3] must be always 1
                    pipeline_cfg.decode_stages    = 5'b01000;  //decode_stages[3] must be always 1
                    pipeline_cfg.execute_stages   = 5'b00000;
                    pipeline_cfg.memory_stages    = 5'b01000;  //memory_stages[3] must be always 1
                    pipeline_cfg.writeback_stages = 5'b10000;  //writeback_stages[4] must be always 1
                end
            endcase

        end

        return pipeline_cfg;
    endfunction

endpackage

import riscv_pkg::*;

`endif
