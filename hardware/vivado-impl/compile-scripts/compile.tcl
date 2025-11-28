#!/bin/bash

set MMCM_OUT_FREQ_MHZ $env(MMCM_OUT_FREQ_MHZ)
set NUM_PIPE_STAGES $env(NUM_PIPE_STAGES)
set NUM_THREADS $env(NUM_THREADS)
set ENABLE_BRAM_REGFILE $env(ENABLE_BRAM_REGFILE)
set ENABLE_ALU_DSP $env(ENABLE_ALU_DSP)
set ENABLE_UNIFIED_BARREL_SHIFTER $env(ENABLE_UNIFIED_BARREL_SHIFTER)
set ENABLE_LUTRAM_PCMEM $env(ENABLE_LUTRAM_PCMEM)
set ENABLE_FETCH_ADDR_PAD $env(ENABLE_FETCH_ADDR_PAD)
set ENABLE_ZALRSC $env(ENABLE_ZALRSC)

## FPGA board and part info
set FPGA_PART $env(FPGA_PART)
set FPGA_FAMILY $env(FPGA_FAMILY)
set PINOUT_FILE $env(PINOUT_FILE)

#Implementation parameters
set SHREG_MIN_SIZE $env(SHREG_MIN_SIZE)
set USER_REQUESTED_CLK_UNCERTAINTY $env(USER_REQUESTED_CLK_UNCERTAINTY)

# Print the variables
puts "MMCM_OUT_FREQ_MHZ: $MMCM_OUT_FREQ_MHZ"
puts "NUM_PIPE_STAGES: $NUM_PIPE_STAGES"
puts "NUM_THREADS: $NUM_THREADS"
puts "ENABLE_BRAM_REGFILE: $ENABLE_BRAM_REGFILE"
puts "ENABLE_ALU_DSP: $ENABLE_ALU_DSP"
puts "ENABLE_UNIFIED_BARREL_SHIFTER: $ENABLE_UNIFIED_BARREL_SHIFTER"
puts "ENABLE_LUTRAM_PCMEM: $ENABLE_LUTRAM_PCMEM"
puts "ENABLE_FETCH_ADDR_PAD: $ENABLE_FETCH_ADDR_PAD"
puts "ENABLE_ZALRSC: $ENABLE_ZALRSC"
puts "FPGA_PART: $FPGA_PART"
puts "FPGA_FAMILY: $FPGA_FAMILY"
puts "SHREG_MIN_SIZE: $SHREG_MIN_SIZE"
puts "USER_REQUESTED_CLK_UNCERTAINTY: $USER_REQUESTED_CLK_UNCERTAINTY"
puts "PINOUT_FILE: $PINOUT_FILE"

#set TOP_RTL "core_dummy_wrapper"
set TOP_RTL $env(TOP_RTL)

puts "TOP_RTL: $TOP_RTL"
set HEX_PROG $env(HEX_PROG)
puts "HEX_PROG: $HEX_PROG"

set INC_DIR        "../utils"
set RTL_SOURCE_DIR "../../rtl"
set COMPILE_SCRIPTS_DIR "../compile-scripts"
set USR_CONSTR_DIR "../usr-constraints"
set outputDir ../$env(RUN_DIR)


set_part $FPGA_PART
##=====================================================#
set time1 [clock seconds]
#=====================================================#
#          ------------ READ SOURCES -----------------#
#=====================================================#
if { $FPGA_FAMILY eq "VERSAL" } {
  source $COMPILE_SCRIPTS_DIR/cips_briski.tcl
}
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
##=====================================================#
set time2 [clock seconds]
puts "Total Compilation time (Opt step)= [expr [expr $time2 - $time1] / 3600] Hours : [expr [expr [expr $time2 - $time1] / 60] % 60] Minutes : [expr [expr $time2 - $time1] % 60] Seconds"

