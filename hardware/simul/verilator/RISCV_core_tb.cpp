#include <stdlib.h>
#include <string>
#include <fstream>
#include <iostream>
#include <iomanip>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "VRISCV_core.h"  // Verilator generated header
#include "VRISCV_core___024unit.h"

const int NUM_HARTS = 16;
// Clock and reset signals
int f=0;
#define MAX_SIMTIME 20000
vluint64_t main_time = 0;
unsigned long long simcycles=0; // amount of half clock cycles
// BRAM model for shared 4KB instr and data (1024 32-bit words with byte-wide write enable)
class BRAM {
//private:
public:
    uint32_t memory[1024];
    //std::vector<uint32_t> memory;
    uint32_t last_read_data;
    //BRAM(size_t size) : memory(size, 0){
    BRAM() {
        // Initialize BRAM from hex file
        FILE *file = fopen(TB_INIT_FILE, "r");
        if (file == NULL) {
            printf("Error opening file %s\n", TB_INIT_FILE);
            exit(1);
        }
        for (int i = 0; i < 1024; i++) {
            f=fscanf(file, "%x\n", &this->memory[i]);
        }
        fclose(file);
	this->last_read_data=0;
    }

    uint32_t fetchinstr(uint32_t addr) {
	    return (this->memory[addr & 0x3FF]);
    }

    uint32_t read(uint32_t addr) {
	//if ((addr & 0x3000)==0){  //BRAM EN
	//    this->last_read_data = this->memory[addr & 0x3FF];
	//}
	//return this->last_read_data;
	return (this->memory[addr & 0x3FF]);
    }


    void write(uint32_t addr, uint32_t data, uint8_t we) {
	if ((addr & 0x3000)==0){  //BRAM EN
            if ((we & 0x1) == 0x1) {  
                this->memory[addr & 0x3FF] = (this->memory[addr & 0x3FF] & 0xFFFFFF00) | (data & 0x000000FF);
	    }
            if ((we & 0x2) == 0x2) { 
                this->memory[addr & 0x3FF] = (this->memory[addr & 0x3FF] & 0xFFFF00FF) | (data & 0x0000FF00);
	    }
            if ((we & 0x4) == 0x4) {
                this->memory[addr & 0x3FF] = (this->memory[addr & 0x3FF] & 0xFF00FFFF) | (data & 0x00FF0000);
    }
            if ((we & 0x8) == 0x8) { 
                this->memory[addr & 0x3FF] = (this->memory[addr & 0x3FF] & 0x00FFFFFF) | (data & 0xFF000000);
	    }
	}
    }

    void dumpMemory() {
        std::cout << "Dumping Memory Contents.." << std::endl;
        //for (size_t i = 0; i < sizeof(memory)/sizeof(memory[0]); i+=4) {
        for (size_t i = 0; i < sizeof(memory); i+=4) {
            std::cout << "memory [" << std::dec << std::setw(4) << std::setfill('0') << i << "] : 0x" << std::hex << std::setw(8) << std::setfill('0') << *reinterpret_cast<uint32_t*>(&memory[i/4]) << std::endl;
        }
    }

    void dumpMemory(std::string filename) {
	std::ofstream memoryFile;
	memoryFile.open(filename);
	if (!memoryFile.is_open()) {
            std::cerr << "Error: Could not open the file for writing." << std::endl;
            return;
        }
        memoryFile << "Dumping Memory Contents.." << std::endl;
        //for (size_t i = 0; i < sizeof(memory)/sizeof(memory[0]); i+=4) {
        for (size_t i = 0; i < sizeof(memory); i+=4) {
            memoryFile << "memory [" << std::dec << std::setw(4) << std::setfill('0') << i << "] : 0x" << std::hex << std::setw(8) << std::setfill('0') << *reinterpret_cast<uint32_t*>(&memory[i/4]) << std::endl;
        }
	memoryFile.close();
    }
};


class RegFile {
//private:
public:
    static const uint32_t Harts = 16;
    uint32_t registers[Harts][32] = {};
    RegFile() {};

    void writeback(uint8_t thread_index, uint8_t reg_index, uint32_t data, bool we) {
	if (we & (reg_index!=0)){  //BRAM EN
              this->registers[thread_index][reg_index] = data;
	}
    }
    void dumpRegFile(const std::string& filename = "") const {
        std::ostream* os = nullptr;
        std::ofstream outfile;

        if (filename.empty()) {
            // If no filename is provided, dump to screen
            os = &std::cout;
        } else {
            // If a filename is provided, open the file
            outfile.open(filename);
            if (outfile.is_open()) {
                os = &outfile;
            } else {
                std::cerr << "Error: Unable to open file " << filename << " for writing." << std::endl;
                return;
            }
        }

	// ABI register names as per RISC-V standard
        const char* abi_names[32] = {
            "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2",
            "s0/fp", " s1", "a0", "a1", "a2", "a3", "a4", "a5",
            "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7",
            "s8", "s9", "s10", "s11", "t3", "t4", "t5", "t6"
        };

        // header line with thread IDs
        *os << "+-------------+";
        for (uint32_t hart = 0; hart < Harts; ++hart) {
            *os << " Hart  " << std::setw(2) << hart << " |";
        }
        *os << std::endl;

        // separator line
        *os << "+-------------+";
        for (uint32_t hart = 0; hart < Harts; ++hart) {
            *os << "----------+";
        }
        *os << std::endl;

        // Loop over each register index (0-31)
        for (uint32_t reg_idx = 0; reg_idx < 32; ++reg_idx) {
            // Print the register label (x0, x1, x2, ...)
	    *os << "| " << std::setw(5) << std::setfill(' ') << abi_names[reg_idx] << " (x" << std::setw(2) << std::dec << reg_idx << ") |";
            // Print each hart's register value in hex format
            for (uint32_t hart = 0; hart < Harts; ++hart) {
                *os << " " << std::setw(8) << std::hex << std::setfill('0') << registers[hart][reg_idx] << " |";
            }
            *os << std::endl;

            // the separator line after each row
            *os << "+-------------+";
            for (uint32_t hart = 0; hart < Harts; ++hart) {
                *os << "----------+";
            }
            *os << std::endl;
        }

        // Close the file if it was opened
        if (outfile.is_open()) {
            outfile.close();
            std::cout << "Dumped to " << filename << std::endl;
        }
    }
};

int main(int argc, char **argv, char **env) {

    VRISCV_core *top = new VRISCV_core;
    VerilatedVcdC *tfp = new VerilatedVcdC;
    Verilated::traceEverOn(true);
    top->trace(tfp, 5);
    tfp->open("waveform.vcd");

    BRAM *bram=new BRAM();
    RegFile *regfile= new RegFile();
    static uint32_t ram_addr = 0;
    static uint32_t rom_addr = 0;

    top->reset = 0;
    top->clk = 0;

    top->i_dmem_read_data = 0;
    top->i_ROM_instruction = 0;

    while (!Verilated::gotFinish()) {

	++main_time;

        if (simcycles < 25) {
            top->reset = 1;  // assert reset
	} else {
            top->reset = 0;  // Deassert reset
        }

	if (main_time < MAX_SIMTIME && top->i_ROM_instruction!=0x00000073){
            if (top->clk == 0) {
	      rom_addr = top->o_ROM_addr;
	      ram_addr = top->o_dmem_addr;
	    } else {
              bram->write(top->o_dmem_addr, top->o_dmem_write_data, top->o_dmem_write_enable);
              top->i_ROM_instruction = bram->fetchinstr(rom_addr);
              top->i_dmem_read_data = bram->read(ram_addr);
	      regfile->writeback(top->thread_index_wb, top->regfile_wr_addr, top->regfile_wr_data, top->regfile_wr_en);
	    }
            //toggle clock
	    top->clk = !top->clk;
	    top->eval();

	    simcycles++;
            tfp->dump(main_time);
	} else {
	    for (int k=0; k < 2*NUM_HARTS; k++){
            if (top->clk == 0) {
	      rom_addr = top->o_ROM_addr;
	      ram_addr = top->o_dmem_addr;
	    } else {
              bram->write(top->o_dmem_addr, top->o_dmem_write_data, top->o_dmem_write_enable);
              top->i_ROM_instruction = bram->fetchinstr(rom_addr);
              top->i_dmem_read_data = bram->read(ram_addr);
	      regfile->writeback(top->thread_index_wb, top->regfile_wr_addr, top->regfile_wr_data, top->regfile_wr_en);
	    }
	      top->clk = !top->clk;
	      top->eval();
	      simcycles++;
	    }
	    std::cout << std::dec << "simcycle :" << simcycles/2 << std::endl;
	    break;
        }
    }

    tfp->close();
    bram->dumpMemory("rtl_memory.txt");
    regfile->dumpRegFile("rtl_regfiles.txt");
    delete bram;
    delete top;
    return 0;
}

