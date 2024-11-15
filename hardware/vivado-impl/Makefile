RUN_DIR?=vivado-runs
COMPILE_SCRIPTS_DIR?=../compile-scripts
HEX_NAME?=test_branches
HEX_SRC_PATH?= ../../software
HEX_PROG?=$(HEX_SRC_PATH)/$(HEX_NAME).inst

#parameters
####################
MMCM_OUT_FREQ_MHZ?=350
NUM_PIPE_STAGES?=12
NUM_THREADS?=14
ENABLE_ALU_DSP?=false
ENABLE_BRAM_REGFILE?=true
ENABLE_UNIFIED_BARREL_SHIFTER?=true

FPGA_PART?=xcvu9p-flga2104-2L-e
TOP_RTL?=core_dummy_wrapper

ENV_VARS = RUN_DIR=$(RUN_DIR) MMCM_OUT_FREQ_MHZ=$(MMCM_OUT_FREQ_MHZ) NUM_PIPE_STAGES=$(NUM_PIPE_STAGES) NUM_THREADS=$(NUM_THREADS) ENABLE_BRAM_REGFILE=$(ENABLE_BRAM_REGFILE) ENABLE_ALU_DSP=$(ENABLE_ALU_DSP) ENABLE_UNIFIED_BARREL_SHIFTER=$(ENABLE_UNIFIED_BARREL_SHIFTER) FPGA_PART=$(FPGA_PART) TOP_RTL=$(TOP_RTL) HEX_PROG=$(HEX_PROG)

#run fpga compilation to generate bitstream
compile: hex_gen
	mkdir -p $(RUN_DIR)
	cd $(RUN_DIR) && $(ENV_VARS) vivado -mode batch -source $(COMPILE_SCRIPTS_DIR)/compile.tcl 

#removes run directory
clean:
	rm -rf $(RUN_DIR)

help:
	@echo "(make all) will generate the fpga bitstream for the target board" 
#generate new memory map info file
generat_mmi:
	cp -f bitstream-utils/mmi_gen.tcl $(RUN_DIR)/mmi_gen.tcl
	cd $(RUN_DIR) && vivado -mode batch -source mmi_gen.tcl

#modify .inst file to .mem format that update the contents of BRAM and consequently the bitstream 
update_mem: hex_gen
	cp -f bitstream-utils/briski.mmi $(RUN_DIR)/briski.mmi
	cp -f $(HEX_SRC_PATH)/runs/$(HEX_NAME).inst $(RUN_DIR)/
	cd $(RUN_DIR) && sed '1s/^/@0 /' $(HEX_NAME).inst > $(HEX_NAME).mem
	cd $(RUN_DIR) && updatemem -meminfo briski.mmi -data $(HEX_NAME).mem -bit fpga_bitstream.bit -proc instr_and_data_mem/RAM_reg -force -out updated_fpga_bitstream.bit

#prepare .inst file that pre-fills the BRAM to be used in bitstream generation
hex_gen:
	cd $(HEX_SRC_PATH) && PROG=$(HEX_NAME) NUM_THREADS=$(NUM_THREADS) $(MAKE) hex_gen 

all: clean compile 
