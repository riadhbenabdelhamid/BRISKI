RTL_SRC_PATH?= ../../rtl
HEX_SRC_PATH?= ../../../software
FULL_HEX_SRC_PATH?= $(HEX_SRC_PATH)/runs
RTL_TOP?= RISCV_core
FLAGS = -Wall --trace
HEX_PROG?=lower_upper_byte
#HEX_PROG?=loads_stores
CXXFLAGS= -DTB_INIT_FILE='\"$(FULL_HEX_SRC_PATH)/$(HEX_PROG).inst\"'

all: clean compile build run

check_all: clean check_mem_dump compare_mem_files compare_registerfiles_files

check_mem_dump: clean hex_gen compile build run
	cd simulation_model && g++ -DTB_INIT_FILE=\"../$(FULL_HEX_SRC_PATH)/$(HEX_PROG).inst\" -o prog BRISKI_simulator.cpp 
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
	cd $(HEX_SRC_PATH) && PROG=$(HEX_PROG) $(MAKE) hex_gen 
compile:
	#verilator -cc $(TOP) +incdir+$(SRC)
	# Verilate the design
	verilator $(FLAGS) --cc $(RTL_SRC_PATH)/$(RTL_TOP).sv --exe $(RTL_TOP)_tb.cpp -I$(RTL_SRC_PATH) -Wno-VARHIDDEN -Wno-IMPORTSTAR -Wno-UNUSEDSIGNAL -Wno-UNUSEDPARAM  -CFLAGS "$(CXXFLAGS)"

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

