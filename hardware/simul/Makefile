SRC_PATH=../rtl
HEX_SRC_PATH?=../../software
FULL_HEX_SRC_PATH?= $(HEX_SRC_PATH)/runs
TESTBENCH_NAME=RISCV_core_top_extended_tb
#TESTBENCH_NAME=RISCV_core_top_tb
#PROG?=branches
PROG?=sparkle-template-mandelbrot
INCLUDES?=-i ../vivado-impl/utils 

NUM_THREADS?=16
NUM_PIPE_STAGES?=8
ENABLE_BRAM_REGFILE?=true
ENABLE_ALU_DSP?=false
ENABLE_UNIFIED_BARREL_SHIFTER?=true
XPROG?=$(FULL_HEX_SRC_PATH)/$(PROG).inst

DEFS = --generic_top HEX_PROG=$(XPROG) -d NUM_PIPE_STAGES=$(NUM_PIPE_STAGES) -d NUM_THREADS=$(NUM_THREADS) -d ENABLE_BRAM_REGFILE=$(ENABLE_BRAM_REGFILE) -d ENABLE_ALU_DSP=$(ENABLE_ALU_DSP) -d ENABLE_UNIFIED_BARREL_SHIFTER=$(ENABLE_UNIFIED_BARREL_SHIFTER)  --O3


all: clean c_hex_gen simulate

c_hex_gen:
	cd $(HEX_SRC_PATH) && CPROG=$(PROG) NUM_THREADS=$(NUM_THREADS) $(MAKE) c_hex_gen 

sv_compile:
	xvlog -sv $(SRC_PATH)/*.sv $(INCLUDES)

elaborate: sv_compile
	xelab -debug typical -top $(TESTBENCH_NAME) -snapshot $(TESTBENCH_NAME)_snapshot $(DEFS)

simulate: elaborate
	xsim $(TESTBENCH_NAME)_snapshot -R 

simulate_dump: elaborate
	xsim $(TESTBENCH_NAME)_snapshot -tclbatch Makefile_cfg_sim.tcl
	xsim --gui $(TESTBENCH_NAME)_snapshot.wdb

simulate: elaborate

clean:
	find . -maxdepth 1 -type f ! -name 'Makefile*' -execdir rm {} +
	rm -rf xsim.dir
