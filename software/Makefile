PROG?=branches
RUN_DIR?=runs

compile:
	mkdir -p $(RUN_DIR)
	cd $(RUN_DIR) && riscv64-unknown-elf-gcc -march=rv32ia -mabi=ilp32 -ffreestanding -nostdlib -o $(PROG).elf ../assembly/$(PROG).s

bingen:
	cd $(RUN_DIR) && riscv64-unknown-elf-objcopy -O binary $(PROG).elf /dev/stdout > $(PROG).bin
objdump:
	cd $(RUN_DIR) && riscv64-unknown-elf-objdump -b binary -mriscv:rv32 -D $(PROG).bin > $(PROG).inst
clean:
	#rm -f $(PROG).elf $(PROG).bin $(PROG).inst
	rm -rf $(RUN_DIR)
format:
	cd $(RUN_DIR) && sed -i '1,7d' $(PROG).inst
	cd $(RUN_DIR) && sed -i -E 's/^[[:space:]]+[^:]+:[[:space:]]+([^[:space:]]+)[[:space:]]+.*/\1/' $(PROG).inst
	

all: clean compile bingen objdump format

help:
	@echo "use (export PROG=your_prog_name && make all) to generate .inst file equivalent to an elf that will be used to program the core"
	@echo "If you change the dfault PROG name add the generated file name and path in the riscv_pack.vhd file" 
