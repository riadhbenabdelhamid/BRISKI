#!/bin/bash

## FPGA part number
#set FPGA_PART "xc7a100tcsg324-1"
set FPGA_PART "xcvu9p-flga2104-2L-e"

set TOP_RTL "core_dummy_wrapper"
set RTL_SOURCE_DIR "../../rtl"
set COMPILE_SCRIPTS_DIR "../compile-scripts"
set USR_CONSTR_DIR "../usr-constraints"
set outputDir "../vivado-runs"

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

