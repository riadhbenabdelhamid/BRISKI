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

    ##########################
    # AND Tests
    ##########################

    # Case 1: AND - Basic positive numbers
    li t1, 0b11001100      # Load binary 11001100 into t1
    li t2, 0b10101010      # Load binary 10101010 into t2
    and t3, t1, t2         # t3 = t1 AND t2
    sw t3, 0(t0)           # Store result (expected 0b10001000)

    # Case 2: AND - Zero operand
    li t1, 0b11111111      # Load binary 11111111 into t1
    li t2, 0               # Load 0 into t2
    and t3, t1, t2         # t3 = t1 AND t2
    sw t3, 4(t0)           # Store result (expected 0)

    # Case 3: AND - Negative number
    li t1, -5               # Load -5 into t1
    li t2, 0b10101010      # Load binary 10101010 into t2
    and t3, t1, t2         # t3 = t1 AND t2
    sw t3, 8(t0)           # Store result

    # Case 4: AND - Edge case max and min signed integers
    li t1, 0x7FFFFFFF      # Load max positive signed int
    li t2, 0x80000000      # Load min negative signed int
    and t3, t1, t2         # t3 = t1 AND t2
    sw t3, 12(t0)          # Store result (expected 0)

    ##########################
    # OR Tests
    ##########################

    # Case 5: OR - Basic positive numbers
    li t1, 0b11001100      # Load binary 11001100 into t1
    li t2, 0b10101010      # Load binary 10101010 into t2
    or t3, t1, t2          # t3 = t1 OR t2
    sw t3, 16(t0)          # Store result (expected 0b11101110)

    # Case 6: OR - Zero operand
    li t1, 0b11111111      # Load binary 11111111 into t1
    li t2, 0               # Load 0 into t2
    or t3, t1, t2          # t3 = t1 OR t2
    sw t3, 20(t0)          # Store result (expected 0b11111111)

    # Case 7: OR - Negative number
    li t1, -5              # Load -5 into t1
    li t2, 0b10101010      # Load binary 10101010 into t2
    or t3, t1, t2          # t3 = t1 OR t2
    sw t3, 24(t0)          # Store result

    # Case 8: OR - Edge case max and min signed integers
    li t1, 0x7FFFFFFF      # Load max positive signed int
    li t2, 0x80000000      # Load min negative signed int
    or t3, t1, t2          # t3 = t1 OR t2
    sw t3, 28(t0)          # Store result (expected 0xFFFFFFFF)

    ##########################
    # XOR Tests
    ##########################

    # Case 9: XOR - Basic positive numbers
    li t1, 0b11001100      # Load binary 11001100 into t1
    li t2, 0b10101010      # Load binary 10101010 into t2
    xor t3, t1, t2         # t3 = t1 XOR t2
    sw t3, 32(t0)          # Store result (expected 0b01100110)

    # Case 10: XOR - Zero operand
    li t1, 0b11111111      # Load binary 11111111 into t1
    li t2, 0               # Load 0 into t2
    xor t3, t1, t2         # t3 = t1 XOR t2
    sw t3, 36(t0)          # Store result (expected 0b11111111)

    # Case 11: XOR - Negative number
    li t1, -5              # Load -5 into t1
    li t2, 0b10101010      # Load binary 10101010 into t2
    xor t3, t1, t2         # t3 = t1 XOR t2
    sw t3, 40(t0)          # Store result

    # Case 12: XOR - Edge case max and min signed integers
    li t1, 0x7FFFFFFF      # Load max positive signed int
    li t2, 0x80000000      # Load min negative signed int
    xor t3, t1, t2         # t3 = t1 XOR t2
    sw t3, 44(t0)          # Store result (expected 0xFFFFFFFF)

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

