RTL_SRC_PATH?= ../../rtl
HEX_SRC_PATH?= ../../../software
FULL_HEX_SRC_PATH?= $(HEX_SRC_PATH)/runs
RTL_TOP?= RISCV_core
##################################
#HEX_PROG?=test_lui_auipc
#HEX_PROG?=test_add_sub
#HEX_PROG?=test_shift
#HEX_PROG?=test_jal_jalr
#HEX_PROG?=test_slt
#HEX_PROG?=test_bitwise
#HEX_PROG?=test_branches
#HEX_PROG?=test_immediate_arith
#HEX_PROG?=test_load_store
#HEX_PROG?=main-no-atomics
HEX_PROG?=main

NUM_THREADS?=10
NUM_PIPE_STAGES?=6
ENABLE_BRAM_REGFILE?=false
ENABLE_ALU_DSP?=true
ENABLE_UNIFIED_BARREL_SHIFTER?=false
ENABLE_LUTRAM_PCMEM?=false
ENABLE_FETCH_ADDR_PAD?=false

#FPGA_FAMILY?=ULTRASCALEPLUS # VERSAL: DSP58; ULTRASCALE, ULTRASCALEPLUS=DSP48E2; 7SERIES=DSP48E1
FPGA_FAMILY?=VERSAL # VERSAL: DSP58; ULTRASCALE, ULTRASCALEPLUS=DSP48E2; 7SERIES=DSP48E1
#FPGA_FAMILY?=7SERIES # VERSAL: DSP58; ULTRASCALE, ULTRASCALEPLUS=DSP48E2; 7SERIES=DSP48E1

##Extensions
ENABLE_ZALRSC?= false # extension zalrsc -> true: supported, false: not supported 

FLAGS = -Wall --trace +define+NUM_PIPE_STAGES=$(NUM_PIPE_STAGES) +define+NUM_THREADS=$(NUM_THREADS) +define+ENABLE_BRAM_REGFILE=$(ENABLE_BRAM_REGFILE) +define+ENABLE_ALU_DSP=$(ENABLE_ALU_DSP) +define+ENABLE_UNIFIED_BARREL_SHIFTER=$(ENABLE_UNIFIED_BARREL_SHIFTER) +define+ENABLE_LUTRAM_PCMEM=$(ENABLE_LUTRAM_PCMEM) +define+ENABLE_FETCH_ADDR_PAD=$(ENABLE_FETCH_ADDR_PAD) +define+FPGA_FAMILY_$(FPGA_FAMILY)

CXXFLAGS= -DTB_INIT_FILE='\"$(FULL_HEX_SRC_PATH)/$(HEX_PROG).inst\"' -DNUM_THREADS=$(NUM_THREADS) 

#used in preprocessor
ifeq ($(strip $(ENABLE_ZALRSC)),true)
FLAGS += +define+ENABLE_ZALRSC
CXXFLAGS += -DENABLE_ZALRSC=$(ENABLE_ZALRSC)
endif


all: clean compile build run


check_all: clean check_mem_dump compare_mem_files compare_registerfiles_files 
check_all_c: clean check_mem_dump_c compare_mem_files compare_registerfiles_files 

check_mem_dump: clean hex_gen compile build run
	cd simulation_model && g++ -DTB_INIT_FILE=\"../$(FULL_HEX_SRC_PATH)/$(HEX_PROG).inst\" -DNUM_THREADS=$(NUM_THREADS) -o prog BRISKI_simulator.cpp 
	cd simulation_model && ./prog

check_mem_dump_c: clean c_hex_gen compile build run
	cd simulation_model && g++ -DTB_INIT_FILE=\"../$(FULL_HEX_SRC_PATH)/$(HEX_PROG).inst\" -DNUM_THREADS=$(NUM_THREADS) -o prog BRISKI_simulator.cpp 
	cd simulation_model && ./prog

compare_mem_files:
	diff rtl_memory.txt simulation_model/memory.txt
	@if [ $$? -eq 0 ]; then \
		echo "OK: Contents of RTL Memory and Software model Memory Files are identical."; \
	elif [ $$? -eq 1 ]; then \
		echo "ERROR: Contents of RTL Memory and Software model Memory Files are different. use diff or vimdiff to check differences"; \
	else \
		echo "FATAL: An error occurred while comparing files."; \
	fi
compare_registerfiles_files:
	diff rtl_regfiles.txt simulation_model/regfiles.txt
	@if [ $$? -eq 0 ]; then \
		echo "OK: Contents of RTL RegFiles and Software model RegisterFiles Files are identical."; \
	elif [ $$? -eq 1 ]; then \
		echo "ERROR: Contents of RTL RegFiles and Software model RegisterFiles Files are different. use diff or vimdiff to check differences"; \
	else \
		echo "FATAL: An error occurred while comparing files."; \
	fi

hex_gen:
	cd $(HEX_SRC_PATH) && PROG=$(HEX_PROG) NUM_THREADS=$(NUM_THREADS) ENABLE_ZALRSC=$(ENABLE_ZALRSC) $(MAKE) hex_gen 

c_hex_gen:
	cd $(HEX_SRC_PATH) && CPROG=$(HEX_PROG) NUM_THREADS=$(NUM_THREADS) ENABLE_ZALRSC=$(ENABLE_ZALRSC) $(MAKE) c_hex_gen 

compile:
	#verilator -cc $(TOP) +incdir+$(SRC)
	# Verilate the design
	verilator $(FLAGS) --cc $(RTL_SRC_PATH)/$(RTL_TOP).sv --no-timing -exe $(RTL_TOP)_tb.cpp -I$(RTL_SRC_PATH) -Wno-VARHIDDEN -Wno-IMPORTSTAR -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM  -Wno-GENUNNAMED -CFLAGS "$(CXXFLAGS)"

build:
	# Build the simulation executable
	make -C obj_dir -f V$(RTL_TOP).mk V$(RTL_TOP) 

run:
	# Run the simulation
	obj_dir/V$(RTL_TOP)


.phony: clean

clean:
	rm -rf obj_dir rtl_memory.txt *.vcd rtl_regfiles.txt
	rm -f simulation_model/prog simulation_model/memory.txt simulation_model/regfiles.txt

