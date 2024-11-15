#!/bin/bash

set MMCM_OUT_FREQ_MHZ $env(MMCM_OUT_FREQ_MHZ)
set NUM_PIPE_STAGES $env(NUM_PIPE_STAGES)
set NUM_THREADS $env(NUM_THREADS)
set ENABLE_BRAM_REGFILE $env(ENABLE_BRAM_REGFILE)
set ENABLE_ALU_DSP $env(ENABLE_ALU_DSP)
set ENABLE_UNIFIED_BARREL_SHIFTER $env(ENABLE_UNIFIED_BARREL_SHIFTER)

# Print the variables
puts " MMCM_OUT_FREQ_MHZ: $MMCM_OUT_FREQ_MHZ"
puts "NUM_PIPE_STAGES: $NUM_PIPE_STAGES"
puts "NUM_THREADS: $NUM_THREADS"
puts "ENABLE_BRAM_REGFILE: $ENABLE_BRAM_REGFILE"
puts "ENABLE_ALU_DSP: $ENABLE_ALU_DSP"
puts "ENABLE_UNIFIED_BARREL_SHIFTER: $ENABLE_UNIFIED_BARREL_SHIFTER"
## FPGA part number
#set FPGA_PART "xc7a100tcsg324-1"
#set FPGA_PART "xcvu9p-flga2104-2L-e"
#set FPGA_PART "xcvu9p-flga2104-3-e"
set FPGA_PART $env(FPGA_PART)

#set TOP_RTL "core_dummy_wrapper"
set TOP_RTL $env(TOP_RTL)

puts "TOP_RTL: $TOP_RTL"
set HEX_PROG $env(HEX_PROG)
puts "HEX_PROG: $HEX_PROG"
set RTL_SOURCE_DIR "../../rtl"
set COMPILE_SCRIPTS_DIR "../compile-scripts"
set USR_CONSTR_DIR "../usr-constraints"
set outputDir ../$env(RUN_DIR)

set_part $FPGA_PART
#=====================================================#
#          ------------ READ SOURCES -----------------#
#=====================================================#
source $COMPILE_SCRIPTS_DIR/read_sources.tcl

#=====================================================#
#          ------------ SYNTHESIS --------------------#
#=====================================================#
source $COMPILE_SCRIPTS_DIR/synth.tcl
#=====================================================#
#          ------------ OPT --------------------------#
#=====================================================#
source $COMPILE_SCRIPTS_DIR/opt.tcl
#=====================================================#
#          ------------ PLACE ------------------------#
#=====================================================#
source $COMPILE_SCRIPTS_DIR/place.tcl
##--------------post place phys_opt--------------------#
source $COMPILE_SCRIPTS_DIR/post_place_physopt.tcl
##=====================================================#
##          ------------ ROUTE ------------------------#
##=====================================================#
source $COMPILE_SCRIPTS_DIR/route.tcl
##--------------post route phys_opt--------------------#
source $COMPILE_SCRIPTS_DIR/post_route.tcl
##=====================================================#
##          ------------ BITSTREAM --------------------#
##=====================================================#
source $COMPILE_SCRIPTS_DIR/bitstream.tcl

