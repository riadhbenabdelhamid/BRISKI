RUN_DIR?=vivado-runs
COMPILE_SCRIPTS_DIR?=../compile-scripts
#HEX_NAME?=test_branches
HEX_NAME?=sparkle-template-mandelbrot
HEX_SRC_PATH?=../../software
HEX_PROG?=\"$(HEX_SRC_PATH)/runs/$(HEX_NAME).inst\"

HEX_C_PATH := $(HEX_SRC_PATH)/C/$(HEX_NAME).c
HEX_ASM_PATH := $(HEX_SRC_PATH)/assembly/$(HEX_NAME).S

# Determine generator based on path
ifeq ($(wildcard $(HEX_C_PATH)), $(HEX_C_PATH))
  HEX_GEN_TARGET = c_hex_gen
else ifeq ($(wildcard $(HEX_ASM_PATH)), $(HEX_ASM_PATH))
  HEX_GEN_TARGET = hex_gen
else
  $(error HEX_NAME '$(HEX_NAME)' not found in either C/ or Assembly/ under '$(HEX_SRC_PATH)')
endif

# parameters
####################
MMCM_OUT_FREQ_MHZ?=500
NUM_PIPE_STAGES?=16
NUM_THREADS?=16
ENABLE_ALU_DSP?=true
ENABLE_BRAM_REGFILE?=true
ENABLE_UNIFIED_BARREL_SHIFTER?=true

FPGA_PART?=xcvu9p-flga2104-2L-e

TOP_RTL?=core_dummy_wrapper
#TOP_RTL?=RISCV_core_top
#TOP_RTL?=RISCV_core_top_extended

ENV_VARS = RUN_DIR=$(RUN_DIR) \
           MMCM_OUT_FREQ_MHZ=$(MMCM_OUT_FREQ_MHZ) \
           NUM_PIPE_STAGES=$(NUM_PIPE_STAGES) \
           NUM_THREADS=$(NUM_THREADS) \
           ENABLE_BRAM_REGFILE=$(ENABLE_BRAM_REGFILE) \
           ENABLE_ALU_DSP=$(ENABLE_ALU_DSP) \
           ENABLE_UNIFIED_BARREL_SHIFTER=$(ENABLE_UNIFIED_BARREL_SHIFTER) \
           FPGA_PART=$(FPGA_PART) \
           TOP_RTL=$(TOP_RTL) \
           HEX_PROG=$(HEX_PROG)

# run fpga compilation to generate bitstream
compile: hex_gen
	mkdir -p $(RUN_DIR)
	cd $(RUN_DIR) && $(ENV_VARS) vivado -mode batch -source $(COMPILE_SCRIPTS_DIR)/compile.tcl

# removes run directory
clean:
	rm -rf $(RUN_DIR)

help:
	@echo "(make all) will generate the fpga bitstream for the target board"

# generate new memory map info file
generat_mmi:
	cp -f bitstream-utils/mmi_gen.tcl $(RUN_DIR)/mmi_gen.tcl
	cd $(RUN_DIR) && vivado -mode batch -source mmi_gen.tcl

# modify .inst file to .mem format that updates the contents of BRAM and the bitstream
update_mem: hex_gen
	cp -f bitstream-utils/briski.mmi $(RUN_DIR)/briski.mmi
	cp -f $(HEX_SRC_PATH)/runs/$(HEX_NAME).inst $(RUN_DIR)/
	cd $(RUN_DIR) && sed '1s/^/@0 /' $(HEX_NAME).inst > $(HEX_NAME).mem
	cd $(RUN_DIR) && updatemem -meminfo briski.mmi -data $(HEX_NAME).mem -bit fpga_bitstream.bit -proc instr_and_data_mem/RAM_reg -force -out updated_fpga_bitstream.bit

# generate .inst file
hex_gen:
	cd $(HEX_SRC_PATH) && CPROG=$(HEX_NAME) PROG=$(HEX_NAME) NUM_THREADS=$(NUM_THREADS) $(MAKE) $(HEX_GEN_TARGET)

all: clean compile
