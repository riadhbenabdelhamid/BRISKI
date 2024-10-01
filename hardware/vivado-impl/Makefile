RUN_DIR?=vivado-runs
COMPILE_SCRIPTS_DIR?=../compile-scripts
HEX_NAME?=branches.inst
#parameters
####################
MMCM_OUT_FREQ_MHZ?=650
NUM_PIPE_STAGES?=10
NUM_THREADS?=10
ENABLE_BRAM_REGFILE?=true
ENABLE_ALU_DSP?=false
ENABLE_UNIFIED_BARREL_SHIFTER?=true

ENV_VARS = RUN_DIR=$(RUN_DIR) MMCM_OUT_FREQ_MHZ=$(MMCM_OUT_FREQ_MHZ) NUM_PIPE_STAGES=$(NUM_PIPE_STAGES) NUM_THREADS=$(NUM_THREADS) ENABLE_BRAM_REGFILE=$(ENABLE_BRAM_REGFILE) ENABLE_ALU_DSP=$(ENABLE_ALU_DSP) ENABLE_UNIFIED_BARREL_SHIFTER=$(ENABLE_UNIFIED_BARREL_SHIFTER)

compile:
	mkdir -p $(RUN_DIR)
	cd $(RUN_DIR) && $(ENV_VARS) vivado -mode batch -source $(COMPILE_SCRIPTS_DIR)/compile.tcl 

clean:
	rm -rf $(RUN_DIR)

help:
	@echo "(make all) will generate the fpga bitstream for the target board" 

all: clean compile 
