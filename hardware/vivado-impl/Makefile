RUN_DIR?=vivado-runs
COMPILE_SCRIPTS_DIR?=../compile-scripts

compile:
	mkdir -p $(RUN_DIR)
	cd $(RUN_DIR) && vivado -mode batch -source $(COMPILE_SCRIPTS_DIR)/compile.tcl

clean:
	rm -rf $(RUN_DIR)

help:
	@echo "(make all) will generate the fpga bitstream for the target board" 

all: clean compile 
