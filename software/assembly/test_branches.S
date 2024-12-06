    .section .data
barrier_var:
    .word 0                   # Barrier counter

    .section .text
    .global _start
_start:
    # Calculate thread-specific memory address
    csrr a0, 0x14
    li t0,  1024           
    addi t0, t0, 4         # Base address for thread data # barrier var stored in one word
    slli t1, a0, 7         # Multiply thread ID by 128 (shift left by 7)
    add t0, t0, t1         # Calculate thread-specific starting address

    ##########################
    # BEQ (Branch if Equal) Tests
    ##########################
    
    # Case 1: BEQ with equal values
    li t2, 5                  # Load t2 with 5
    li t3, 5                  # Load t3 with 5
    beq t2, t3, beq_equal     # Branch should be taken
    li t4, 0                  # If branch not taken, store 0 (failure case)
    sw t4, 0(t0)              # Store failure case in memory
    j beq_done                # Jump to the end
beq_equal:
    li t4, 1                  # If branch taken, store 1 (success case)
    sw t4, 0(t0)              # Store success case in memory
beq_done:

    # Case 2: BEQ with unequal values
    li t2, 7                  # Load t2 with 7
    li t3, 9                  # Load t3 with 9
    beq t2, t3, beq_fail      # Branch should not be taken
    li t4, 1                  # If branch not taken, store 1 (success case)
    sw t4, 4(t0)              # Store success case in memory
    j beq_next
beq_fail:
    li t4, 0                  # If branch taken, store 0 (failure case)
    sw t4, 4(t0)              # Store failure case in memory
beq_next:

    ##########################
    # BNE (Branch if Not Equal) Tests
    ##########################

    # Case 3: BNE with unequal values
    li t2, 5                  # Load t2 with 5
    li t3, 8                  # Load t3 with 8
    bne t2, t3, bne_unequal    # Branch should be taken
    li t4, 0                  # If branch not taken, store 0 (failure case)
    sw t4, 8(t0)              # Store failure case in memory
    j bne_done
bne_unequal:
    li t4, 1                  # If branch taken, store 1 (success case)
    sw t4, 8(t0)              # Store success case in memory
bne_done:

    # Case 4: BNE with equal values
    li t2, 12                 # Load t2 with 12
    li t3, 12                 # Load t3 with 12
    bne t2, t3, bne_fail      # Branch should not be taken
    li t4, 1                  # If branch not taken, store 1 (success case)
    sw t4, 12(t0)             # Store success case in memory
    j bne_next
bne_fail:
    li t4, 0                  # If branch taken, store 0 (failure case)
    sw t4, 12(t0)             # Store failure case in memory
bne_next:

    ##########################
    # BLT (Branch if Less Than) Tests
    ##########################

    # Case 5: BLT with t2 < t3
    li t2, 3                  # Load t2 with 3
    li t3, 10                 # Load t3 with 10
    blt t2, t3, blt_less      # Branch should be taken
    li t4, 0                  # If branch not taken, store 0 (failure case)
    sw t4, 16(t0)             # Store failure case in memory
    j blt_done
blt_less:
    li t4, 1                  # If branch taken, store 1 (success case)
    sw t4, 16(t0)             # Store success case in memory
blt_done:

    # Case 6: BLT with t2 >= t3
    li t2, 15                 # Load t2 with 15
    li t3, 10                 # Load t3 with 10
    blt t2, t3, blt_fail      # Branch should not be taken
    li t4, 1                  # If branch not taken, store 1 (success case)
    sw t4, 20(t0)             # Store success case in memory
    j blt_next
blt_fail:
    li t4, 0                  # If branch taken, store 0 (failure case)
    sw t4, 20(t0)             # Store failure case in memory
blt_next:

    ##########################
    # BGE (Branch if Greater Than or Equal) Tests
    ##########################

    # Case 7: BGE with t2 >= t3
    li t2, 12                 # Load t2 with 12
    li t3, 9                  # Load t3 with 9
    bge t2, t3, bge_greater   # Branch should be taken
    li t4, 0                  # If branch not taken, store 0 (failure case)
    sw t4, 24(t0)             # Store failure case in memory
    j bge_done
bge_greater:
    li t4, 1                  # If branch taken, store 1 (success case)
    sw t4, 24(t0)             # Store success case in memory
bge_done:

    # Case 8: BGE with t2 < t3
    li t2, 7                  # Load t2 with 7
    li t3, 9                  # Load t3 with 9
    bge t2, t3, bge_fail      # Branch should not be taken
    li t4, 1                  # If branch not taken, store 1 (success case)
    sw t4, 28(t0)             # Store success case in memory
    j bge_next
bge_fail:
    li t4, 0                  # If branch taken, store 0 (failure case)
    sw t4, 28(t0)             # Store failure case in memory
bge_next:

    ##########################
    # BLTU (Branch if Less Than Unsigned) Tests
    ##########################

    # Case 9: BLTU with t2 < t3 (unsigned)
    li t2, 2                  # Load t2 with 2
    li t3, 10                 # Load t3 with 10
    bltu t2, t3, bltu_less    # Branch should be taken
    li t4, 0                  # If branch not taken, store 0 (failure case)
    sw t4, 32(t0)             # Store failure case in memory
    j bltu_done
bltu_less:
    li t4, 1                  # If branch taken, store 1 (success case)
    sw t4, 32(t0)             # Store success case in memory
bltu_done:

    # Case 10: BLTU with t2 >= t3 (unsigned)
    li t2, 15                 # Load t2 with 15
    li t3, 10                 # Load t3 with 10
    bltu t2, t3, bltu_fail    # Branch should not be taken
    li t4, 1                  # If branch not taken, store 1 (success case)
    sw t4, 36(t0)             # Store success case in memory
    j bltu_next
bltu_fail:
    li t4, 0                  # If branch taken, store 0 (failure case)
    sw t4, 36(t0)             # Store failure case in memory
bltu_next:

    ##########################
    # BGEU (Branch if Greater Than or Equal Unsigned) Tests
    ##########################

    # Case 11: BGEU with t2 >= t3 (unsigned)
    li t2, 10                 # Load t2 with 10
    li t3, 5                  # Load t3 with 5
    bgeu t2, t3, bgeu_greater # Branch should be taken
    li t4, 0                  # If branch not taken, store 0 (failure case)
    sw t4, 40(t0)             # Store failure case in memory
    j bgeu_done
bgeu_greater:
    li t4, 1                  # If branch taken, store 1 (success case)
    sw t4, 40(t0)             # Store success case in memory
bgeu_done:

    # Case 12: BGEU with t2 < t3 (unsigned)
    li t2, 7                  # Load t2 with 7
    li t3, 12                 # Load t3 with 12
    bgeu t2, t3, bgeu_fail    # Branch should not be taken
    li t4, 1                  # If branch not taken, store 1 (success case)
    sw t4, 44(t0)             # Store success case in memory
    j bgeu_next
bgeu_fail:
    li t4, 0                  # If branch taken, store 0 (failure case)
    sw t4, 44(t0)             # Store failure case in memory
bgeu_next:

    ##########################
    # Barrier Synchronization
    ##########################

    la      s1, barrier_var       # Load the address of the counter barrier value
    li      s0, NUM_THREADS       # Load total number of threads

barrier_attempt:
    lr.w    s2, (s1)              # Load reserved from barrier address
    addi    s3, s2, 0x01          # Increment the barrier by 1
    sc.w    s4, s3, (s1)          # Store conditional to barrier address
    bnez    s4, barrier_attempt   # If store fails, retry

    # Check if all threads have reached the barrier
    beq     s0, s3, barrier_done  # If barrier equals NUM_THREADS, proceed to ECALL

barrier_wait:
    j barrier_wait                # Spin-wait if not the last thread

barrier_done:
    ecall                          # Last thread performs ECALL to terminate


