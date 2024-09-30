    .section .data
barrier_var:
    .word 0       # Barrier counter variable

    .section .text
    .global _start
_start:
    # Get the thread ID (assumed to be in a0)
    li t0, 512             # Base address for thread data
    slli t1, a0, 6         # Shift left by 6 to multiply thread ID by 64
    add t0, t0, t1         # Calculate starting address for this thread

    ##########################
    # ADDI Tests
    ##########################

    # Case 1: ADDI - Basic positive addition
    li t1, 10              # Load 10 into t1
    addi t2, t1, 5         # t2 = t1 + 5
    sw t2, 0(t0)           # Store result (expected 15)

    # Case 2: ADDI - Adding zero
    li t1, 20              # Load 20 into t1
    addi t2, t1, 0         # t2 = t1 + 0
    sw t2, 4(t0)           # Store result (expected 20)

    # Case 3: ADDI - Negative immediate
    li t1, 15              # Load 15 into t1
    addi t2, t1, -10       # t2 = t1 - 10
    sw t2, 8(t0)           # Store result (expected 5)

    # Case 4: ADDI - Overflow case
    li t1, 2147483647      # Load max signed int into t1
    addi t2, t1, 1         # t2 = t1 + 1 (should overflow)
    sw t2, 12(t0)          # Store result (expected -2147483648)

    # Case 5: ADDI - Underflow case
    li t1, -2147483648     # Load min signed int into t1
    addi t2, t1, -1        # t2 = t1 - 1 (should underflow)
    sw t2, 16(t0)          # Store result (expected 2147483647)

    ##########################
    # SLTI Tests
    ##########################

    # Case 6: SLTI - Less than positive
    li t1, 5                # Load 5 into t1
    slti t2, t1, 10         # t2 = (t1 < 10)
    sw t2, 20(t0)           # Store result (expected 1)

    # Case 7: SLTI - Equal case
    li t1, 10               # Load 10 into t1
    slti t2, t1, 10         # t2 = (t1 < 10)
    sw t2, 24(t0)           # Store result (expected 0)

    # Case 8: SLTI - Greater than
    li t1, 15               # Load 15 into t1
    slti t2, t1, 10         # t2 = (t1 < 10)
    sw t2, 28(t0)           # Store result (expected 0)

    # Case 9: SLTI - Negative comparison
    li t1, -5               # Load -5 into t1
    slti t2, t1, 0          # t2 = (t1 < 0)
    sw t2, 32(t0)           # Store result (expected 1)

    ##########################
    # SLTIU Tests
    ##########################

    # Case 10: SLTIU - Less than unsigned
    li t1, 5                # Load 5 into t1
    sltiu t2, t1, 10        # t2 = (t1 < 10)
    sw t2, 36(t0)           # Store result (expected 1)

    # Case 11: SLTIU - Equal case
    li t1, 10               # Load 10 into t1
    sltiu t2, t1, 10        # t2 = (t1 < 10)
    sw t2, 40(t0)           # Store result (expected 0)

    # Case 12: SLTIU - Greater than
    li t1, 15               # Load 15 into t1
    sltiu t2, t1, 10        # t2 = (t1 < 10)
    sw t2, 44(t0)           # Store result (expected 0)

    # Case 13: SLTIU - Maximum unsigned comparison
    li t1, 0xFFFFFFFF       # Load max unsigned int into t1
    sltiu t2, t1, 0        # t2 = (t1 < 0) (should be 0)
    sw t2, 48(t0)           # Store result (expected 0)

    ##########################
    # XORI Tests
    ##########################

    # Case 14: XORI - Basic positive number
    li t1, 0b10101010       # Load binary 10101010 into t1
    xori t2, t1, 0b11111111 # t2 = t1 XOR 0b11111111
    sw t2, 52(t0)           # Store result (expected 0b01010101)

    # Case 15: XORI - Zero immediate
    li t1, 0b11001100       # Load binary 11001100 into t1
    xori t2, t1, 0          # t2 = t1 XOR 0
    sw t2, 56(t0)           # Store result (expected 0b11001100)

    # Case 16: XORI - Negative number
    li t1, -1               # Load -1 into t1
    xori t2, t1, 0b11111111 # t2 = t1 XOR 0b11111111
    sw t2, 60(t0)           # Store result (expected 0)

    # Case 17: XORI - Edge case max signed int
    li t1, 0x7FFFFFFF       # Load max signed int into t1
    xori t2, t1, 0xFFFFFFFF  # t2 = t1 XOR 0xFFFFFFFF
    sw t2, 64(t0)           # Store result (expected 0x80000000)

    ###########################
    # Barrier synchronization
    ###########################
    la s1, barrier_var        # Load the address of the counter barrier variable
    li s0, NUM_THREADS        # Load total number of threads
barrier_attempt:
    lr.w s2, (s1)             # Load reserved from barrier address
    addi s3, s2, 0x01         # Increment the barrier by 1
    sc.w s4, s3, (s1)         # Store conditional to barrier address
    bnez s4, barrier_attempt  # If store fails, retry

    # Check if all threads have reached the barrier
    beq s0, s3, barrier_done  # If barrier equals NUM_THREADS, proceed to ecall

    # Wait in an infinite loop if not all threads reached the barrier
barrier_wait:
    j barrier_wait            # Spin-wait if not the last thread

barrier_done:
    # Call ecall to indicate completion by the last thread
    ecall

