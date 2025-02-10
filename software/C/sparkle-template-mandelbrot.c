// MASKs for different memory enable signals
#define MASK_MMIO                 0x8000U   // Address Mask to set enable signal for MMIO memory
#define MASK_BRAM                 0x0000U   // Address Mask to set enable signal for BRAM (private memory) 
#define MASK_URAM                 0x4000U   // Address Mask to set enanle signal for URAM (shared per row and word-only addressable)

// Memory‑mapped control register addresses
#define REQ_ADDR                  0x8008U   // MMIO Addr for setting/unsetting shared mem access request signal to Row Arbiter
#define GRANT_ADDR                0x8000U   // MMIO Addr for reading grant signal (ReadOnly) which is set by Row Arbiter
#define LOCKED_ADDR               0x800CU   // MMIO Addr for setting/Unsetting shared mem access lock signal to Row Arbiter
#define URAM_EMPTIED_ADDR         0x8010U   // MMIO Addr for reading the state of the shared mem (empty/full) that is set by Row Synchronizer

//memory-mapped hardware barrier registers
#define REG_HART_BASE_ADDR        0x8014U  // Base address for hart registers (hart0 starts at 0b00101)
#define REG_BARRIER_STATUS_ADDR   0x8054U  // Address to read the combined barrier status

//Amount of iterations needed to fully transfer data back to host 
#define ITERMAX                   0x0008U   // The max number of iteration/chunks of data to be streamed to PCIe-connected host


//amount of frac bits for fixed shift use 
#define FIXED_SHIFT 28
typedef int fixed_t;

// Pointers to memory‑mapped registers
volatile unsigned int* const req_reg             = (unsigned int*)REQ_ADDR;
volatile unsigned int* const locked_reg          = (unsigned int*)LOCKED_ADDR;
volatile unsigned int* const uram_emptied_reg    = (unsigned int*)URAM_EMPTIED_ADDR;
volatile unsigned int* const grant_reg           = (unsigned int*)GRANT_ADDR;
volatile unsigned int* const hart_base_reg       = (unsigned int*)REG_HART_BASE_ADDR;
volatile unsigned int* const barrier_status_reg  = (unsigned int*)REG_BARRIER_STATUS_ADDR;

// Software-based fixed-point multiplication
int soft_mul(int a, int b, int shamt) {
    int sign = 1;
    if(a < 0) { a = -a; sign = -sign; }
    if(b < 0) { b = -b; sign = -sign; }

    unsigned int ua = (unsigned int)a;
    unsigned int ub = (unsigned int)b;
    unsigned long long result = 0;

    // Multiply ua by ub bit‐by‐bit.
    for (int i = 0; i < 32; i++) {
        if (ub & 1) {
            result += ((unsigned long long)ua << i);
        }
        ub >>= 1;
    }
    // Since the operands are in Qint.frac, we must shift right by frac
    int fixed_result = (int)(result >> shamt);
    return sign < 0 ? -fixed_result : fixed_result;
}

// Atomic barrier function
static void atomic_barrier(int hart_id, unsigned int * sense) {
    // Set either 1 or 0 depending on sense for the specific hart
    *(volatile unsigned int*)(hart_base_reg + hart_id) = (*sense? 1 : 0 );

    // Wait for either 0xFFFF if sense==1, or 0x0000 if sense==0
    while (*(volatile unsigned int*)barrier_status_reg != (*sense? 0xFFFFU : 0x0000)) ; // spin 

    // Flip the sense for next time
    *sense ^= 1;
}

//Thread IDs have a jump near PCIe because core count is reduced in this area
//this function re-assigns a continous count from 0 to 16384
//for easy workload assignment
unsigned int get_continuous_core_id(unsigned int complete_id) {
    unsigned int row = (complete_id >> 9) & 0x3;
    unsigned int quadrow = (complete_id >> 11) & 0xF;
    unsigned int global_row_id = (quadrow << 2) + row;
    unsigned core_id = complete_id >> 4;

    if (global_row_id <= 20) {
        return core_id;
    } else if (global_row_id <= 35) {
        // Lookup table for offsets (global_row_id 21-35)
        static const unsigned char offsets[] = {
            4, 8, 12, 16, 20, 24, 28,  // 21-27
            32, 35, 38, 41, 44, 47, 50, 53  // 28-35
        };
        return core_id - offsets[global_row_id - 21];
    } else {
        return core_id - 56;  // For global_row_id >35
    }
}

//compute data_stream is the template function that do real work and streams data back to host
//here we implement a mandelbrot computation
//COMPUTING KERNEL CONSTANTS
//--------------------------
#define MAX_ESCAPE_ITER 100
#define RESOLUTION 32 // 32x32
#define RESOLUTION_LOG 5
#define NUM_HARTS 16
#define CHUNK_SIZE (RESOLUTION * RESOLUTION / NUM_HARTS)
#define CHUNK_LOG 6 // for 64
#define x_step ((2 << FIXED_SHIFT) / RESOLUTION) //  divide by RESOLUTION=32
#define y_step ((2 << FIXED_SHIFT) / RESOLUTION)
#define x_base  -(3 << (FIXED_SHIFT-1)) //(x from -1.5 to 0.5)
#define y_base  -(1 << FIXED_SHIFT)      //(y from -1 to 1 )

//COMPUTING KERNEL TASK
//--------------------------
	//start: chunk start, iter:chunk ID, datastreamptr : pointer to a unsigned int array[8] for results 
	//produced by the relative thread for this round (iter)
void compute_datastream(unsigned int start, unsigned int iter, unsigned int* datastreamptr) { 
    for (int p = 0; p < 8; p++) { 
        // Calculate index as per original code (includes potential bug)
        unsigned int idx = (start + p + (iter<<3)); //start of thread chunk + p in (8 pt per iter) + offset in chunk (iter*8)
        int i = (idx & (RESOLUTION - 1)); // idx % RESOLUTION
        int j = (idx >> RESOLUTION_LOG);  // idx / RESOLUTION

        // Calculate coordinates using fixed-point arithmetic
        fixed_t x0 = x_base + soft_mul(i , x_step, 0);
        fixed_t y0 = y_base + soft_mul(j , y_step, 0);

        //fixed_t zr = 0, zi = 0;
        fixed_t zr = x0, zi = y0;
        int count = 0;

        // Mandelbrot iteration
        while (count < MAX_ESCAPE_ITER) {
            fixed_t zr_sq = soft_mul(zr, zr, FIXED_SHIFT);
            fixed_t zi_sq = soft_mul(zi, zi, FIXED_SHIFT);

            if (zr_sq + zi_sq > (4 << FIXED_SHIFT)) break;

            fixed_t new_zr = zr_sq - zi_sq + x0;
            fixed_t new_zi = (soft_mul(zr, zi, FIXED_SHIFT) << 1) + y0;

            zr = new_zr;
            zi = new_zi;
            count++;
        }
        datastreamptr[p] = count;
    }
}

/* ---- Execution timeline (Algo)----- */

    //1. Initialize arrays, registers and counters
    //2. get Row-level thread ID and get core-local thread ID
    //3. compute ultraram allocated space based on Row-level ID
    //4. get new continous (no gap) global core IDs and global thread IDs
    //5. /* ////////////  Main computation /////////////// */
    //------------------------------------------------------
        //5.1 assign chunks to threads by assigning start point for each thread
        //5.2. Main computation loop (generic compute problem)
        //------------------------------------------------------
	    //5.2.1 synchronize by waiting for atomic barrier (hardware supported)
            //5.2.2 compute chunk of 8 data words and store them in address pointed by datastream 
            //5.2.3 Data is rady so Request access to shared memory to start streaming results
            //5.2.4 wait for grant signal to be asserted by shared memory arbiter (Row Arbiter)
            //5.2.5 set the locked signal after acquiring grant to lock shared mem for this core
            //5.2.6 Release request once lock is set
            //5.2.7 start sending data to the allocated thread space in ultra ram
	    //5.2.8 synchronize by waiting for atomic barrier (hardware supported)
            //5.2.9 release (unset) lock reg
            //5.2.10 reverse uram_emptied flag (reverse sense hardware barrier)
            //5.2.11 make sure memory is emptied from previous steps before moving to next iter
            //5.2.12 increment iter count and loop back to 5.2.1 or 6 if iter count reach limit
        //------------------------------------------------------
    //------------------------------------------------------
    //6 Optional (necessary with verilator testbench in verilator dir to match the end of test condition)
    //----------------------------------------------------------------------------------
    //6.1 Atomically increment or decrement the barrier variable
    //6.2 inline "ecall" with verilator testbench for example 
    
/* ----------------------------- */

void main(unsigned int complete_id) {
    unsigned int sense = 1;
    //1. Initialize arrays, registers and counters
    *req_reg = 0;
    *locked_reg = 0;
    unsigned int iter = 0;
    unsigned int uram_empty_flag = 0;
    //temporary storage for results produced by this thread in current 'iter' round
    int datastream[8] ={0,0,0,0,0,0,0,0};  

    //2. get Row-level thread ID and get core-local thread ID
    unsigned int row_level_id = complete_id & 0x01FF;
    unsigned int core_local_thread_id = complete_id & 0x000F;

    //3. compute ultraram allocated space based on Row-level ID
    // Compute base address for URAM data (<<2 : word align, <<3 space with 8 words in between thread slots)
    unsigned int base_uram_addr = ((row_level_id << 2U) << 3U) | MASK_URAM;
    volatile unsigned int* datastream_uram_ptr = (volatile unsigned int*) base_uram_addr;

    //4. get new continous (no gap) global core IDs and global thread IDs
    unsigned int new_core_id = get_continuous_core_id(complete_id);
    unsigned int new_thread_id = (new_core_id << 4) | core_local_thread_id;

    //5. /* ////////////  Main computation /////////////// */
    //compute chunk of 8*iter data words (call compute kernel task 'iter' times)
    
    //5.1 assign chunks to threads by assigning start point for each thread
    //new_thread_id * CHUNK_SIZE;
    unsigned int start = new_thread_id << CHUNK_LOG; // 6 for  64 8-word chunk (log(64)) 

    //5.2. Main computation loop (generic compute problem)
    //------------------------------------------------------
    //iterate and produce 8 words per thread for 'iter' iterations.
    do {
	//5.2.1 synchronize by waiting for atomic barrier (hardware supported)
        atomic_barrier(core_local_thread_id, &sense);

        //5.2.2 compute chunk of 8 data words and store them in address pointed by datastream 
	/* ////////////  Main computation /////////////// */
        compute_datastream(start, iter, datastream);  

	/* ////////////////////////////////////////////// */    
        //5.2.3 Data is rady so Request access to shared memory to start streaming results
        *req_reg = 1; 

        //5.2.4 wait for grant signal to be asserted by shared memory arbiter (Row Arbiter)
        while (*grant_reg == 0) { } ; /* spin-wait until grant is received */

        //5.2.5 set the locked signal after acquiring grant to lock shared mem for this core
        *locked_reg = 1;

        //5.2.6 Release request once lock is set
        *req_reg = 0;
    
        //5.2.7 start sending data to the allocated thread space in ultra ram
        // Loop for sending data until max iterations reached
        for (int k = 0; k < 8; k+=1) {
            /**** Here goes the 8 data words to be sent in this current iteration  ****/
	    *( datastream_uram_ptr + k ) = datastream[k]; 
	}
	//5.2.8 synchronize by waiting for atomic barrier (hardware supported)
        atomic_barrier(core_local_thread_id, &sense);
	
        //5.2.9 release (unset) lock reg
        *locked_reg = 0;

        //5.2.10 reverse uram_emptied flag (reverse sense hardware barrier)
        uram_empty_flag ^= 0x01U;  // Toggle flag value

        //5.2.11 make sure memory is emptied from previous steps before moving to next iter
        while (*uram_emptied_reg != uram_empty_flag) { }; // spin-wait until URAM emptied signal matches flag 

        //5.2.12 increment iter count and loop back to 5.2.1 or 6 if iter count reach limit
        iter++;
    } while (iter < ITERMAX);
    //------------------------------------------------------

    //6 Optional (necessary with verilator testbench in verilator dir to match the end of test condition)
    //----------------------------------------------------------------------------------
    //6.1 Atomically increment or decrement the barrier variable
    //atomic_barrier(core_local_thread_id, &sense);
    //6.2 inline "ecall" with verilator testbench for example 
    __asm__ volatile ("ecall");
}

