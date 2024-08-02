RTL_SRC_PATH?= ../../rtl
HEX_SRC_PATH?= ../../../software/runs
RTL_TOP?= RISCV_core
FLAGS = -Wall --trace
HEX_PROG?=lower_upper_byte
CXXFLAGS= -DTB_INIT_FILE='\"$(HEX_SRC_PATH)/$(HEX_PROG).inst\"'

all: clean compile build run

check_all: clean check_mem_dump compare_files

check_mem_dump: clean hex_gen compile build run
	cd simulation_model && g++ -DTB_INIT_FILE=\"../$(HEX_SRC_PATH)/$(HEX_PROG).inst\" -o prog BRISKI_simulator.cpp 
	cd simulation_model && ./prog

compare_files:
	diff rtl_memory.txt simulation_model/memory.txt
	@if [ $$? -eq 0 ]; then \
		echo "OK: Contents of RTL Memory and Software model Memory Files are identical."; \
	elif [ $$? -eq 1 ]; then \
		echo "ERROR: Contents of RTL Memory and Software model Memory Files are different. use vimdiff to check differences"; \
	else \
		echo "FATAL: An error occurred while comparing files."; \
	fi

hex_gen:
	cd $(HEX_SRC_PATH) && cd ../ && PROG=$(HEX_PROG) $(MAKE) hex_gen 
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
	rm -rf obj_dir rtl_memory.txt *.vcd
	rm -f simulation_model/prog simulation_model/memory.txt

