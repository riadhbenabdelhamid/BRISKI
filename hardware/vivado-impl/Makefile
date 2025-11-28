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

# configuration parameters
#############################################################
#MMCM_OUT_FREQ_MHZ?=1000 #VU80 (VERSAL) speedgrade -3
MMCM_OUT_FREQ_MHZ?=850 #VU80 (VERSAL) speedgrade -2
#MMCM_OUT_FREQ_MHZ?=737 #vu9p (USP : ULTRASCALEPLUS)
#MMCM_OUT_FREQ_MHZ?=125 #nexys_a7_100 (7SERIES)
#MMCM_OUT_FREQ_MHZ?=300 #nexys_Video (7SERIES)
#MMCM_OUT_FREQ_MHZ?=300 #vu9p (USP : ULTRASCALEPLUS)

NUM_PIPE_STAGES?= 16			# Amount of physical pipeline stages (4 to 16)
NUM_THREADS?= 16 			# Amount of Hardware Threads (Harts) (4 to 16) (NUM_THREAD should always be greater or equal to NUM_PIPE_STAGES)

ENABLE_ALU_DSP?=true 			# Packs ADD/SUB/OR/XOR/AND in a DSP primitivefor a compact ALU (fewer LUTs)
ENABLE_BRAM_REGFILE?= true 		# Implements RegisterFile as BlockRAM (true) or "distributed" LUTRAM (false)
ENABLE_UNIFIED_BARREL_SHIFTER?= false  	# Uses a logical barrel shifter with a fixed direction and adds logic around it for handling SRA and SLL
ENABLE_LUTRAM_PCMEM?= false  		# RAM_STYLE for storing program counters (true : "distributed", false : "registers")
ENABLE_FETCH_ADDR_PAD?= true 		# Additional prefetch stage to register ROM Addr input

# ISA EXTENSIONS
########################
ENABLE_ZALRSC?= false			# Enable Zalrsc extension  (false: disabled, true : enabled)

#Implementation parameters
##########################

#vivado synthesis parameter
#SHREG_MIN_SIZE?= 17 # should be greater to NUM_PIPE_STAGES if no shift register wanted
SHREG_MIN_SIZE?= 17 # should be greater to NUM_PIPE_STAGES if no shift register wanted

#Vivado post_placement
USER_REQUESTED_CLK_UNCERTAINTY?= 0.12 # 0.12 
#USER_REQUESTED_CLK_UNCERTAINTY?= 0.06 #  

#TOP LEVEL RTL
##############
#TOP_RTL?=core_dummy_wrapper
TOP_RTL?=core_dummy_wrapper_versal
#TOP_RTL?=RISCV_core_top
#TOP_RTL?=RISCV_core_top_extended

# Define the board you want to use (add board config if not listed below)
###########################################################
#BOARD ?= Nexys_a7_100T
#BOARD ?= Nexys_Video
#BOARD ?= VCU118
BOARD ?= V80
#BOARD?= None  # e.g: to experiment with versal speed grade -3

# Conditional configuration based on the BOARD
ifeq ($(BOARD), Nexys_a7_100T)
    FPGA_PART = xc7a100tcsg324-1
    FPGA_FAMILY = 7SERIES
    PINOUT_FILE = $(BOARD).xdc
else ifeq ($(BOARD), Nexys_Video)
    FPGA_PART = xc7a200tsbg484-1
    FPGA_FAMILY = 7SERIES
    PINOUT_FILE = $(BOARD).xdc
else ifeq ($(BOARD), VCU118)
    FPGA_PART = xcvu9p-flga2104-2L-e
    FPGA_FAMILY = ULTRASCALEPLUS
    PINOUT_FILE = $(BOARD).xdc
else ifeq ($(BOARD), V80)
    FPGA_PART?= xcv80-lsva4737-2MHP-e-S
    FPGA_FAMILY = VERSAL
    PINOUT_FILE = $(BOARD).xdc
else
    #Default VERSAL HBM (speed grade -3)
    ##############
    FPGA_PART = xcvh1782-lsva4737-3HP-e-S
    FPGA_FAMILY = VERSAL
    PINOUT_FILE = V80.xdc #PINOUT is similar to XC80 FPGA
endif




ENV_VARS = RUN_DIR=$(RUN_DIR) \
           MMCM_OUT_FREQ_MHZ=$(MMCM_OUT_FREQ_MHZ) \
           NUM_PIPE_STAGES=$(NUM_PIPE_STAGES) \
           NUM_THREADS=$(NUM_THREADS) \
           ENABLE_BRAM_REGFILE=$(ENABLE_BRAM_REGFILE) \
           ENABLE_ALU_DSP=$(ENABLE_ALU_DSP) \
           ENABLE_UNIFIED_BARREL_SHIFTER=$(ENABLE_UNIFIED_BARREL_SHIFTER) \
           ENABLE_LUTRAM_PCMEM=$(ENABLE_LUTRAM_PCMEM) \
           ENABLE_ZALRSC=$(ENABLE_ZALRSC) \
           ENABLE_FETCH_ADDR_PAD=$(ENABLE_FETCH_ADDR_PAD) \
           FPGA_PART=$(FPGA_PART) \
	   FPGA_FAMILY=$(FPGA_FAMILY) \
	   SHREG_MIN_SIZE=$(SHREG_MIN_SIZE)\
	   USER_REQUESTED_CLK_UNCERTAINTY=$(USER_REQUESTED_CLK_UNCERTAINTY)\
           PINOUT_FILE=$(PINOUT_FILE) \
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
