SRC?= ../rtl
TOP?= RISCV_core_top.sv

compile:
	verilator -cc $(TOP) +incdir+$(SRC)

.phony: clean

clean:
	rm -rf obj_dir

all: clean compile
