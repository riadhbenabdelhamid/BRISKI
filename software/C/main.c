#ifndef NUM_THREADS
#define NUM_THREADS 16
#endif

#define ARRAY_SIZE 4

// Shared barrier variable for synchronization
volatile int barrier_var = 0;

// Data arrays for each thread (starting at address 1024)
int data[NUM_THREADS][ARRAY_SIZE] __attribute__((section(".data"))) = {
    /* Always-present first 4 rows */
    {34, 23, 12, 45},     // Thread 0
    { 7,  2, 19, 25},     // Thread 1
    {15, 22,  8, 16},     // Thread 2
    {21, 13, 17, 29}      // Thread 3
#if NUM_THREADS > 4
  , { 5, 12,  9,  8}     // Thread 4
#endif
#if NUM_THREADS > 5
  , {18, 24,  7,  5}     // Thread 5
#endif
#if NUM_THREADS > 6
  , { 9,  3, 12,  7}     // Thread 6
#endif
#if NUM_THREADS > 7
  , {10, 20, 30, 40}     // Thread 7
#endif
#if NUM_THREADS > 8
  , {80, 70, 60, 50}     // Thread 8
#endif
#if NUM_THREADS > 9
  , { 2,  3,  5,  7}     // Thread 9
#endif
#if NUM_THREADS > 10
  , {19, 17, 13, 0}      // Thread 10 (last value zero-filled explicitly)
#endif
#if NUM_THREADS > 11
  , { 1,  2,  3,  4}     // Thread 11
#endif
#if NUM_THREADS > 12
  , { 8,  7,  6,  5}     // Thread 12
#endif
#if NUM_THREADS > 13
  , {14, 28, 42, 84}     // Thread 13
#endif
#if NUM_THREADS > 14
  , {112, 98, 84, 70}    // Thread 14
#endif
#if NUM_THREADS > 15
  , {12,  7, 18, 24}     // Thread 15
#endif
};


#ifdef ENABLE_ZALRSC
// Atomic increment function using lr.w and sc.w
static inline void atomic_increment(volatile int *addr) {
    int tmp, new_tmp, status;
    do {
        __asm__ volatile (
            "lr.w %0, (%2)      \n"
            "addi %1, %0, 1     \n"
            "sc.w %3, %1, (%2)  \n"
            : "=&r"(tmp), "=&r"(new_tmp), "+r"(addr), "=&r"(status)
            :
            : "memory"
        );
    } while (status != 0);
}
#endif

void main() {

    int mhartid;
    __asm__ volatile ("csrr %0, mhartid" : "=r"(mhartid));
    int i, j, temp;
    int *my_data = data[mhartid];  // Access data for this thread

    //Bubble sort algorithm
    for (i = 0; i < ARRAY_SIZE - 1; i++) {
        for (j = 0; j < ARRAY_SIZE - i - 1; j++) {
            if (my_data[j] > my_data[j + 1]) {
               // Swap elements
                temp = my_data[j];
                my_data[j] = my_data[j + 1];
                my_data[j + 1] = temp;
            }
        }
   }

#ifdef ENABLE_ZALRSC
    // Atomically increment the barrier variable
    atomic_increment(&barrier_var);

    // Wait until all threads have incremented the barrier variable
    while (barrier_var != NUM_THREADS);
#endif
}

