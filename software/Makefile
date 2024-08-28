PROG?=lower_upper_byte
RUN_DIR?=runs

hex_gen: clean compile_link objdump_elf
	python3 hexgen.py $(RUN_DIR)/$(PROG).asm $(RUN_DIR)/$(PROG).inst

all: clean compile bingen objdump format

all2: clean compile_link bingen objdump format

compile:
	mkdir -p $(RUN_DIR)
	cd $(RUN_DIR) && riscv64-unknown-elf-gcc -march=rv32ia -mabi=ilp32 -ffreestanding -nostdlib -o $(PROG).elf ../assembly/$(PROG).s

compile_link:
	mkdir -p $(RUN_DIR)
	#cd $(RUN_DIR) && riscv64-unknown-elf-gcc -march=rv32ia -mabi=ilp32 -ffreestanding -nostdlib -o $(PROG).elf -T ../assembly/$(PROG).lds ../assembly/$(PROG).s
	cd $(RUN_DIR) && riscv64-unknown-elf-gcc -march=rv32ia -mabi=ilp32 -ffreestanding -nostdlib -o $(PROG).elf -T ../assembly/sections.lds ../assembly/$(PROG).s

bingen:
	cd $(RUN_DIR) && riscv64-unknown-elf-objcopy -O binary $(PROG).elf /dev/stdout > $(PROG).bin

objdump:
	cd $(RUN_DIR) && riscv64-unknown-elf-objdump -b binary -mriscv:rv32 -D $(PROG).bin > $(PROG).inst

read_elf: compile
	cd $(RUN_DIR) && riscv64-unknown-elf-readelf -a $(PROG).elf > $(PROG).asm

objdump_elf: compile_link
	cd $(RUN_DIR) && riscv64-unknown-elf-objdump -mriscv:rv32 -d -j .text -s -j .data $(PROG).elf > $(PROG).asm
clean:
	#rm -f $(PROG).elf $(PROG).bin $(PROG).inst
	rm -rf $(RUN_DIR)
format:
	cd $(RUN_DIR) && sed -i '1,7d' $(PROG).inst
	cd $(RUN_DIR) && sed -i -E 's/^[[:space:]]+[^:]+:[[:space:]]+([^[:space:]]+)[[:space:]]+.*/\1/' $(PROG).inst


help:
	@echo "use (export PROG=your_prog_name && make all) to generate .inst file equivalent to an elf that will be used to program the core"
	@echo "If you change the dfault PROG name add the generated file name and path in the riscv_pack.vhd file" 
