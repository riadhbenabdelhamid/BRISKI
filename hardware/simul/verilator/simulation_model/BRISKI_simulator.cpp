#include <cstdint>
#include <vector>
#include <cstring>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <string>

#define ecall_instruction 0x00000073

const int NUM_HARTS = NUM_THREADS;
const int MEM_SIZE = 4096; // 4KB memory

class BRISKI {
public:
    BRISKI();
    void loadHex(const char* hex_file);
    void run();
    void dumpMemory();
    void dumpMemory(std::string filename);
    void dumpRegFileSet(const std::string& filename) const;

private:
    uint32_t registers[NUM_HARTS][32]; // 32 registers per hart
    uint32_t pc[NUM_HARTS];            // Program counter per hart
    uint8_t memory[MEM_SIZE];          // Shared memory
    bool valid_reserved_set = false;  //valid bit for LR/SC 
    uint32_t reserved_addr = 0;  //reserved set for LR/SC
    uint32_t reserving_hart = 0;  //reserving hart for LR/SC
    void executeInstruction(uint32_t instruction, uint32_t hart_id);
    uint32_t fetchInstruction(uint32_t hart_id);
    void reset();
};

// Constructor
BRISKI::BRISKI() {
    reset();
}

// Reset the core state
void BRISKI::reset() {
    std::memset(registers, 0, sizeof(registers));
    std::memset(pc, 0, sizeof(pc));
    std::memset(memory, 0, sizeof(memory));
}

// Load hex file into memory
void BRISKI::loadHex(const char* hex_file) {
    std::ifstream file(hex_file, std::ios::binary);
    if (!file.is_open()) {
        std::cerr << "Error opening hex file: " << hex_file << std::endl;
        return;
    }

    //file.read(reinterpret_cast<char*>(memory), MEM_SIZE);

    std::string line;
    size_t address = 0;

    while (std::getline(file, line)) {
        if (address + 4 > MEM_SIZE) {
            std::cerr << "Memory overflow. The hex file is too large to fit in memory." << std::endl;
            break;
        }

        // Convert the line from hex string to uint32_t
        uint32_t instruction = 0;
        std::stringstream ss;
        ss << std::hex << line;
        ss >> instruction;

        // Store the instruction in byte-addressable memory
        memory[address] = (instruction >> 0) & 0xFF;
        memory[address + 1] = (instruction >> 8) & 0xFF;
        memory[address + 2] = (instruction >> 16) & 0xFF;
        memory[address + 3] = (instruction >> 24) & 0xFF;

        // Move to the next memory address
        address += 4;
    }


    // Set the initial program counter for each hart
    for (int i = 0; i < NUM_HARTS; ++i) {
        pc[i] = 0;
    }

    file.close();
}

// Run the program
void BRISKI::run() {
    //for (uint64_t cycle = 0; cycle < UINT64_MAX; ++cycle) {
    // uint32_t hart_id = cycle % NUM_HARTS;
    // executeInstruction(hart_id);
        // break condition for simulation
	//if (memory[252] == 0xF)
	uint64_t cycle = 0;
        uint32_t hart_id = 0;
        uint32_t instruction;
	while (true) {
            instruction = fetchInstruction(hart_id);
	    //std::cout << "instr:" <<  std::hex << instruction << std::endl;
            if (instruction == ecall_instruction) {// custom end of program marker
		break;
	    }
            executeInstruction(instruction, hart_id);
	    ++cycle;
            hart_id = cycle % NUM_HARTS;
	}
}

// Dump Mem
    void BRISKI::dumpMemory() {
        std::cout << "Dumping Memory Contents.." << std::endl;
        for (size_t i = 0; i < sizeof(memory); i+=4) {
            std::cout << "memory [" << std::dec << std::setw(4) << std::setfill('0') << i << "] : 0x" << std::hex << std::setw(8) << std::setfill('0') << *reinterpret_cast<uint32_t*>(&memory[i]) << std::endl;
            //std::cout << "memory [" << std::dec << std::setw(4) << std::setfill('0') << i/4 << "] : 0x" << std::hex << std::setw(8) << std::setfill('0') << *reinterpret_cast<uint32_t*>(&memory[i]) << std::endl;
        }
    }

    void BRISKI::dumpMemory(std::string filename) {
	std::ofstream memoryFile;
	memoryFile.open(filename);
	if (!memoryFile.is_open()) {
            std::cerr << "Error: Could not open the file for writing." << std::endl;
            return;
        }
        memoryFile << "Dumping Memory Contents.." << std::endl;
        for (size_t i = 0; i < sizeof(memory); i+=4) {
            memoryFile << "memory [" << std::dec << std::setw(4) << std::setfill('0') << i << "] : 0x" << std::hex << std::setw(8) << std::setfill('0') << *reinterpret_cast<uint32_t*>(&memory[i]) << std::endl;
            //memoryFile << "memory [" << std::dec << std::setw(4) << std::setfill('0') << i/4 << "] : 0x" << std::hex << std::setw(8) << std::setfill('0') << *reinterpret_cast<uint32_t*>(&memory[i]) << std::endl;
        }
	memoryFile.close();
    }
    void BRISKI::dumpRegFileSet(const std::string& filename = "") const {
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
        for (uint32_t hart = 0; hart < NUM_HARTS; ++hart) {
            *os << " Hart  " << std::setw(2) << hart << " |";
        }
        *os << std::endl;

        // separator line
        *os << "+-------------+";
        for (uint32_t hart = 0; hart < NUM_HARTS; ++hart) {
            *os << "----------+";
        }
        *os << std::endl;

        // Loop over each register index (0-31)
        for (uint32_t reg_idx = 0; reg_idx < 32; ++reg_idx) {
            // Print the register label (x0, x1, x2, ...)
           // *os << "|   x" << std::dec << std::setw(2) << std::setfill(' ') <<  reg_idx << "   |";
	    *os << "| " << std::setw(5) << std::setfill(' ') << abi_names[reg_idx] << " (x" << std::setw(2) << std::dec << reg_idx << ") |";
            // Print each hart's register value in hex format
            for (uint32_t hart = 0; hart < NUM_HARTS; ++hart) {
                *os << " " << std::setw(8) << std::hex << std::setfill('0') << registers[hart][reg_idx] << " |";
            }
            *os << std::endl;

            // the separator line after each row
            *os << "+-------------+";
            for (uint32_t hart = 0; hart < NUM_HARTS; ++hart) {
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
// Fetch instruction for a hart
uint32_t BRISKI::fetchInstruction(uint32_t hart_id) {
    uint32_t address = pc[hart_id];
    if (address < MEM_SIZE - 4) {
        //std::cout << std::hex << address << std::endl;
        return *reinterpret_cast<uint32_t*>(&memory[address]);
    }
    return 0;
}

// Execute instruction for a hart
void BRISKI::executeInstruction(uint32_t instruction, uint32_t hart_id) {

    uint32_t opcode = instruction & 0x7F;
    uint32_t rd = (instruction >> 7) & 0x1F;
    uint32_t rs1 = (instruction >> 15) & 0x1F;
    uint32_t rs2 = (instruction >> 20) & 0x1F;
    uint32_t funct3 = (instruction >> 12) & 0x07;
    uint32_t funct7 = (instruction >> 25) & 0x7F;
    int32_t imm;
    bool branch_taken = false ;
    switch (opcode) {
        case 0x33: // R-type
            switch (funct3) {
                case 0x0:
                    if (funct7 == 0x00) // ADD
                        registers[hart_id][rd] = registers[hart_id][rs1] + registers[hart_id][rs2];
                    else if (funct7 == 0x20) // SUB
                        registers[hart_id][rd] = registers[hart_id][rs1] - registers[hart_id][rs2];
                    break;
                case 0x1: // SLL
                    registers[hart_id][rd] = registers[hart_id][rs1] << (registers[hart_id][rs2] & 0x1F);
                    break;
                case 0x2: // SLT
                    registers[hart_id][rd] = (int32_t)registers[hart_id][rs1] < (int32_t)registers[hart_id][rs2];
                    break;
                case 0x3: // SLTU
                    registers[hart_id][rd] = registers[hart_id][rs1] < registers[hart_id][rs2];
                    break;
                case 0x4: // XOR
                    registers[hart_id][rd] = registers[hart_id][rs1] ^ registers[hart_id][rs2];
                    break;
                case 0x5:
                    if (funct7 == 0x00) // SRL
                        registers[hart_id][rd] = registers[hart_id][rs1] >> (registers[hart_id][rs2] & 0x1F);
                    else if (funct7 == 0x20) // SRA
                        registers[hart_id][rd] = (int32_t)registers[hart_id][rs1] >> (registers[hart_id][rs2] & 0x1F);
                    break;
                case 0x6: // OR
                    registers[hart_id][rd] = registers[hart_id][rs1] | registers[hart_id][rs2];
                    break;
                case 0x7: // AND
                    registers[hart_id][rd] = registers[hart_id][rs1] & registers[hart_id][rs2];
                    break;
            }
	    pc[hart_id]+=4;
            break;
        case 0x13: // I-type
            imm = (int32_t)instruction >> 20;
            switch (funct3) {
                case 0x0: // ADDI
                    registers[hart_id][rd] = registers[hart_id][rs1] + imm;
                    break;
                case 0x2: // SLTI
                    registers[hart_id][rd] = (int32_t)registers[hart_id][rs1] < imm;
                    break;
                case 0x3: // SLTIU
                    registers[hart_id][rd] = registers[hart_id][rs1] < (uint32_t)imm;
                    break;
                case 0x4: // XORI
                    registers[hart_id][rd] = registers[hart_id][rs1] ^ imm;
                    break;
                case 0x6: // ORI
                    registers[hart_id][rd] = registers[hart_id][rs1] | imm;
                    break;
                case 0x7: // ANDI
                    registers[hart_id][rd] = registers[hart_id][rs1] & imm;
                    break;
                case 0x1: // SLLI
                    registers[hart_id][rd] = registers[hart_id][rs1] << (imm & 0x1F);
                    break;
                case 0x5:
                    if ((imm & 0x400) == 0x000) // SRLI
                        registers[hart_id][rd] = registers[hart_id][rs1] >> (imm & 0x1F);
                    else // SRAI
                        registers[hart_id][rd] = (int32_t)registers[hart_id][rs1] >> (imm & 0x1F);
                    break;
            }
	    pc[hart_id]+=4;
            break;
        case 0x03: // Load
            imm = (int32_t)instruction >> 20;
            switch (funct3) {
                case 0x0: // LB
                    registers[hart_id][rd] = *reinterpret_cast<int8_t*>(&memory[registers[hart_id][rs1] + imm]);
                    break;
                case 0x1: // LH
                    registers[hart_id][rd] = *reinterpret_cast<int16_t*>(&memory[registers[hart_id][rs1] + imm]);
		    //std::cout << "half signed = " << std::hex << registers[hart_id][rd] << std::endl;
                    break;
                case 0x2: // LW
                    registers[hart_id][rd] = *reinterpret_cast<int32_t*>(&memory[registers[hart_id][rs1] + imm]);
		    //std::cout << "load word" << std::endl;
                    break;
                case 0x4: // LBU
                    registers[hart_id][rd] = memory[registers[hart_id][rs1] + imm];
                    break;
                case 0x5: // LHU
                    registers[hart_id][rd] = *reinterpret_cast<uint16_t*>(&memory[registers[hart_id][rs1] + imm]);
                    break;
            }
	    pc[hart_id]+=4;
            break;
        case 0x23: // S-type (Store)
            imm = ((instruction >> 7) & 0x1F) | ((instruction >> 25) << 5);
            switch (funct3) {
                case 0x0: // SB
                    memory[registers[hart_id][rs1] + imm] = registers[hart_id][rs2] & 0xFF;
		    if (reserved_addr == (registers[hart_id][rs1] + imm)) {
			    valid_reserved_set = false;
		    }
                    break;
                case 0x1: // SH
                    *reinterpret_cast<uint16_t*>(&memory[registers[hart_id][rs1] + imm]) = registers[hart_id][rs2] & 0xFFFF;
		    if (reserved_addr == (registers[hart_id][rs1] + imm)) {
			    valid_reserved_set = false;
		    }
                    break;
                case 0x2: // SW
                    *reinterpret_cast<uint32_t*>(&memory[registers[hart_id][rs1] + imm]) = registers[hart_id][rs2];
		    if (reserved_addr == (registers[hart_id][rs1] + imm)) {
			    valid_reserved_set = false;
		    }
                    break;
            }
	    pc[hart_id]+=4;
            break;
        case 0x63: // B-type (Branch)
            imm = (((instruction >> 31) & 0x1) << 12) | (((instruction >> 25) & 0x3F) << 5) | (((instruction >> 8) & 0xF) << 1) | (((instruction >> 7) & 0x1) << 11);
	    if ( ( ( (instruction >> 31) & 0x1) << 12) ) imm |=0xFFFFE000;
            branch_taken = false ;
            switch (funct3) {
                case 0x0: // BEQ
                    if (registers[hart_id][rs1] == registers[hart_id][rs2])
                        branch_taken = true ;
                    break;
                case 0x1: // BNE
                    if (registers[hart_id][rs1] != registers[hart_id][rs2])
                        branch_taken = true ;
                    break;
                case 0x4: // BLT
                    if ((int32_t)registers[hart_id][rs1] < (int32_t)registers[hart_id][rs2])
                        branch_taken = true ;
                    break;
                case 0x5: // BGE
                    if ((int32_t)registers[hart_id][rs1] >= (int32_t)registers[hart_id][rs2])
                        branch_taken = true ;
                    break;
                case 0x6: // BLTU
                    if (registers[hart_id][rs1] < registers[hart_id][rs2])
                        branch_taken = true ;
                    break;
                case 0x7: // BGEU
                    if (registers[hart_id][rs1] >= registers[hart_id][rs2])
                        branch_taken = true ;
                    break;
		default : ; break;
            }
	    if (branch_taken == true) pc[hart_id]+= imm;
	    else pc[hart_id]+=4; 
	    // [DEBUG]
            // std::cout << "pc [ " << hart_id << " BNE ] : " << pc[hart_id] << std::endl;
            break;
	case 0x37: // LUI
            registers[hart_id][rd] = instruction & 0xFFFFF000;
	    pc[hart_id]+=4;
            break;
        case 0x17: // AUIPC
            registers[hart_id][rd] = pc[hart_id] + (instruction & 0xFFFFF000);
	    pc[hart_id]+=4;
            break;
        case 0x6F: // JAL
            imm = ((instruction >> 31) << 20) | (((instruction >> 21) & 0x3FF) << 1) | (((instruction >> 20) & 0x1) << 11) | (((instruction >> 12) & 0xFF) << 12);
            registers[hart_id][rd] = pc[hart_id] + 4;
            pc[hart_id] += (int32_t(imm<<11))>>11 ;
            break;
        case 0x67: // JALR
            imm = (int32_t)instruction >> 20;
            {
                uint32_t temp = pc[hart_id] + 4;
                pc[hart_id] = (registers[hart_id][rs1] + imm) & ~1;  //(ensure LSB is 0)
                registers[hart_id][rd] = temp;
		//std::cout<< "next_pc: " << std::hex << pc[hart_id] <<std::endl;
            }
            break;
        case 0x0F: // FENCE
            // No operation required for FENCE in this simple model
            pc[hart_id] += 4;
            break;
        case 0x73: // SYSTEM
            switch (funct3) {
                case 0x0: // ECALL, EBREAK
                    if (imm == 0) { // ECALL
                        // Handle system call (not implemented in this model / just checked for termionation )
                    } else if (imm == 1) { // EBREAK
                        // Handle breakpoint (not implemented in this model)
                    }
                    pc[hart_id] += 4;
                    break;
                case 0x2: // CSRRS
                    // Placeholder for CSRRS instruction (not fully implemented)
                    {
                        uint32_t csr_address = (instruction >> 20) & 0xFFF;
                        uint32_t csr_value = hart_id; // Simulated CSR value (replace with actual CSR handling)
                        //uint32_t old_value = csr_value;
                        //csr_value |= registers[hart_id][rs1];
                        //registers[hart_id][rd] = old_value;
                        registers[hart_id][rd] = csr_value;
                    }
                    pc[hart_id] += 4;
                    break;
                // Other CSR instructions can be implemented here
            }
            break;
	// --------------------
        // R-type Instructions (RV32A)
	// --------------------
	case 0x2F :
	    if (funct3==0x2)  { 
                int funct5 = (instruction >> 27) & 0x1F;
	        switch (funct5) {
                    case 0x02 : // LR
			    if (!valid_reserved_set) {
                                registers[hart_id][rd] = *reinterpret_cast<uint32_t*>(&memory[registers[hart_id][rs1]]);
			        reserved_addr = registers[hart_id][rs1]; 
				reserving_hart = hart_id;
			    } else if (reserving_hart == hart_id) {
                                registers[hart_id][rd] = *reinterpret_cast<uint32_t*>(&memory[registers[hart_id][rs1]]);
			        reserved_addr = registers[hart_id][rs1]; 
			    }
			    valid_reserved_set = true; 
			    // [DEBUG]
			    // std::cout << "LR " << hart_id << std::endl;
			    break;
                    case 0x03 :  // SC
                            registers[hart_id][rd] = 1;
		            if ((reserved_addr == (registers[hart_id][rs1])) && valid_reserved_set == true && reserving_hart == hart_id) {
				    memory[registers[hart_id][rs1]+0] = (uint8_t)((registers[hart_id][rs2] >> 0)  & 0xFF);
				    memory[registers[hart_id][rs1]+1] = (uint8_t)((registers[hart_id][rs2] >> 8)  & 0xFF);
				    memory[registers[hart_id][rs1]+2] = (uint8_t)((registers[hart_id][rs2] >> 16)  & 0xFF);
				    memory[registers[hart_id][rs1]+3] = (uint8_t)((registers[hart_id][rs2] >> 24)  & 0xFF);

				    registers[hart_id][rd] = 0;
			            valid_reserved_set = false;
			    }
			    if (reserving_hart == hart_id) {
			            valid_reserved_set = false;
			    }
			    // [DEBUG]
			    // std::cout << "mem[" << registers[hart_id][rs1] + 0 << "] : " << ((memory[registers[hart_id][rs1]] >> 0) & 0xFF) << std::endl;
			    // std::cout << "mem[" << registers[hart_id][rs1] + 1 << "] : " << ((memory[registers[hart_id][rs1]] >> 8) & 0xFF) << std::endl;
			    // std::cout << "mem[" << registers[hart_id][rs1] + 2 << "] : " << ((memory[registers[hart_id][rs1]] >> 16) & 0xFF) << std::endl;
			    // std::cout << "mem[" << registers[hart_id][rs1] + 3 << "] : " << ((memory[registers[hart_id][rs1]] >> 24) & 0xFF) << std::endl;
			    break;
                    case 0x01 :  ; break; // AMOSWAP.W  TBD
                    case 0x00 :  ; break; // AMOADD.W  TBD
                    case 0x0C :  ; break; // AMOAND.W TBD
                    case 0x0A :  ; break; // AMOOR.W TBD
                    case 0x04 :  ; break; // AMOXOR.W TBD
                    case 0x14 :  ; break; // AMOMAX.W TBD
                    case 0x10 :  ; break;// AMOMIN.W TBD
                    default  : ; break;
	        } 
	    }
	    // [DEBUG]
            // std::cout << "pc [ " << hart_id << " ] : " << pc[hart_id] << std::endl;
	    pc[hart_id]+=4;
	    break;
	//-------------------------
        // Other instructions TBD ..
    }
    //force x0 to remain 0
    registers[hart_id][0] = 0;
    //std::cout << "pc [ " << hart_id << " ] : " << pc[hart_id] << std::endl;

}

// Example program
int main() {

    // Initialize BRISKI model
    BRISKI briski;
    // load program
    //briski.loadHex("../../../../software/runs/lower_upper_byte.inst");
    briski.loadHex(TB_INIT_FILE);
    // run the program
    briski.run();
    // dump memory contents
    briski.dumpMemory("memory.txt");
    //briski.dumpMemory();
    briski.dumpRegFileSet("regfiles.txt");

    return 0;
}

