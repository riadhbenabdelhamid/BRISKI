SRC_PATH=../rtl
TESTBENCH_NAME=RISCV_core_top_tb
#PROG?=branches
PROG?=row_test3

all: clean simulate

sv_compile:
	xvlog -sv $(SRC_PATH)/*.sv --define HEX_PROG=$(PROG).inst

elaborate: sv_compile
	xelab -debug typical -top $(TESTBENCH_NAME) -snapshot $(TESTBENCH_NAME)_snapshot

simulate: elaborate
	xsim $(TESTBENCH_NAME)_snapshot -R 

simulate_dump: elaborate
	xsim $(TESTBENCH_NAME)_snapshot -tclbatch Makefile_cfg_xsim.tcl
	xsim --gui $(TESTBENCH_NAME)_snapshot.wdb

simulate: elaborate

clean:
	find . -type f ! -name 'Makefile*' -execdir rm {} +
	rm -rf xsim.dir
