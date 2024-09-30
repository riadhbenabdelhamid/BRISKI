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
    # SLT (Set Less Than) Tests
    ##########################

    # Case 1: slt - Positive numbers
    li t2, 10              # Load 10 into t2
    li t3, 20              # Load 20 into t3
    slt t4, t2, t3         # t4 = (10 < 20) ? 1 : 0
    sw t4, 0(t0)           # Store result (expected 1)

    li t2, 30              # Load 30 into t2
    slt t4, t3, t2         # t4 = (20 < 30) ? 1 : 0
    sw t4, 4(t0)           # Store result (expected 1)

    # Case 2: slt - Negative and positive comparison (signed)
    li t2, -10             # Load -10 into t2
    li t3, 10              # Load 10 into t3
    slt t4, t2, t3         # t4 = (-10 < 10) ? 1 : 0
    sw t4, 8(t0)           # Store result (expected 1)

    li t2, 10              # Load 10 into t2
    slt t4, t3, t2         # t4 = (10 < -10) ? 1 : 0
    sw t4, 12(t0)          # Store result (expected 0)

    # Case 3: slt - Zero comparison
    li t2, 0               # Load 0 into t2
    li t3, 1               # Load 1 into t3
    slt t4, t2, t3         # t4 = (0 < 1) ? 1 : 0
    sw t4, 16(t0)          # Store result (expected 1)

    li t2, 1               # Load 1 into t2
    slt t4, t2, t2         # t4 = (1 < 1) ? 1 : 0
    sw t4, 20(t0)          # Store result (expected 0)

    # Case 4: slt - Negative number comparison
    li t2, -10             # Load -10 into t2
    li t3, -20             # Load -20 into t3
    slt t4, t2, t3         # t4 = (-10 < -20) ? 1 : 0
    sw t4, 24(t0)          # Store result (expected 0)

    slt t4, t3, t2         # t4 = (-20 < -10) ? 1 : 0
    sw t4, 28(t0)          # Store result (expected 1)

    ##########################
    # SLTU (Set Less Than Unsigned) Tests
    ##########################

    # Case 5: sltu - Basic unsigned comparison
    li t2, 10              # Load 10 into t2
    li t3, 20              # Load 20 into t3
    sltu t4, t2, t3        # t4 = (10 < 20) ? 1 : 0 (unsigned)
    sw t4, 32(t0)          # Store result (expected 1)

    li t2, 30              # Load 30 into t2
    sltu t4, t3, t2        # t4 = (20 < 30) ? 1 : 0 (unsigned)
    sw t4, 36(t0)          # Store result (expected 1)

    # Case 6: sltu - Zero and unsigned comparison
    li t2, 0               # Load 0 into t2
    li t3, 1               # Load 1 into t3
    sltu t4, t2, t3        # t4 = (0 < 1) ? 1 : 0 (unsigned)
    sw t4, 40(t0)          # Store result (expected 1)

    li t2, 1               # Load 1 into t2
    sltu t4, t2, t2        # t4 = (1 < 1) ? 1 : 0 (unsigned)
    sw t4, 44(t0)          # Store result (expected 0)

    # Case 7: sltu - Comparison with large unsigned numbers
    li t2, 0xFFFFFFFE      # Load large unsigned number (max-1) into t2
    li t3, 0xFFFFFFFF      # Load max unsigned number into t3
    sltu t4, t2, t3        # t4 = (0xFFFFFFFE < 0xFFFFFFFF) ? 1 : 0 (unsigned)
    sw t4, 48(t0)          # Store result (expected 1)

    li t2, 0xFFFFFFFF      # Load max unsigned number into t2
    sltu t4, t2, t2        # t4 = (0xFFFFFFFF < 0xFFFFFFFF) ? 1 : 0 (unsigned)
    sw t4, 52(t0)          # Store result (expected 0)

    ##########################
    # Edge Case Comparisons
    ##########################

    # Case 8: slt - Max and min signed integers
    li t2, 0x7FFFFFFF      # Load max positive signed int
    li t3, 0x80000000      # Load min negative signed int
    slt t4, t3, t2         # t4 = (-2147483648 < 2147483647) ? 1 : 0
    sw t4, 56(t0)          # Store result (expected 1)

    slt t4, t2, t3         # t4 = (2147483647 < -2147483648) ? 1 : 0
    sw t4, 60(t0)          # Store result (expected 0)

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

