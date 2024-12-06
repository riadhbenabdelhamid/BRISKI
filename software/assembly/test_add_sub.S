    .section .data

barrier_var:
    .word 0       # Barrier counter variable

    .section .text
    .global _start
_start:
    # Get the thread ID (assumed to be in a0)
    csrr a0, 0x14
    li t0,  1024           
    addi t0, t0, 4         # Base address for thread data # barrier var stored in one word
    slli t1, a0, 6         # Shift left by 6 to multiply thread ID by 64
    add t0, t0, t1         # Calculate starting address for this thread

    # Initialize test cases
    li t2, 0               # Case index

# Loop through 30 test cases
test_loop:
    li t6, 10              # Load 10 into a register for comparison
    beq t2, t6, end_test   # Exit after 10 cases

    # Standard cases
    mv t3, t2              # Move case index to t3 as the first operand
    li t4, 5               # Load immediate 5 as the second operand
    add t5, t3, t4         # t5 = t3 + 5
    sw t5, 0(t0)           # Store result in thread-specific memory

    # Corner cases

    # 1. Test overflow: 2147483647 + 1
    lui t4, 0x7ffff        # Load upper half of 2147483647 (0x7FFFFFFF)
    addi t4, t4, 0x7FF     # Adjust lower 12 bits to complete 0x7FFFFFFF
    li t5, 0x801           # Load 1 into a register
    add t6, t4, t5         # Perform overflow addition
    sw t6, 4(t0)           # Store overflow result

    # 2. Test underflow: -2147483648 + (-1)
    lui t4, 0x80000        # Load upper half of -2147483648 (0x80000000)
    li t5, -1              # Load -1 into a register
    add t6, t4, t5         # Perform underflow addition
    sw t6, 8(t0)           # Store underflow result

    # Additional Standard Cases

    # 3. Test addition and subtraction with zero
    li t3, 0              # Load zero
    li t4, 10             # Load a positive number
    add t5, t4, t3        # t5 = 10 + 0
    sw t5, 12(t0)         # Store result in thread-specific memory

    sub t6, t4, t3        # t6 = 10 - 0
    sw t6, 16(t0)         # Store result in thread-specific memory

    # 4. Test addition and subtraction with a negative number
    li t3, -5             # Load a negative number
    add t5, t4, t3        # t5 = 10 + (-5)
    sw t5, 20(t0)         # Store result in thread-specific memory

    sub t6, t4, t3        # t6 = 10 - (-5)
    sw t6, 24(t0)         # Store result in thread-specific memory

    # Increment case index
    addi t2, t2, 1
    addi t0, t0, 28        # Move to next storage location (28 bytes for each set of test cases)

    j test_loop            # Repeat for next case

end_test:
    # Barrier synchronization
    la s1, barrier_var      # Load the address of the counter barrier variable
    li s0, NUM_THREADS      # Load total number of threads
barrier_attempt:
    lr.w s2, (s1)           # Load reserved from barrier address
    addi s3, s2, 0x01       # Increment the barrier by 1
    sc.w s4, s3, (s1)       # Store conditional to barrier address
    bnez s4, barrier_attempt # If store fails, retry

    # Check if all threads have reached the barrier
    beq s0, s3, barrier_done # If barrier equals NUM_THREADS, proceed to ecall

    # Wait in an infinite loop if not all threads reached the barrier
barrier_wait:
    j barrier_wait           # Spin-wait if not the last thread

barrier_done:
    # Call ecall to indicate completion by the last thread
    ecall

