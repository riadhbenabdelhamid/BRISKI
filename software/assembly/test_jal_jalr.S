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

    ########################
    # JAL - Jump and Link
    ########################

    # Case 1: Jump forward by small offset (+4)
    jal t2, forward_jump_1    # Jump forward by 4 bytes
    sw t1, 0(t0)              # This instruction should not be executed

forward_jump_1:
    li t3, 1                  # Mark the jump was successful
    sw t3, 0(t0)              # Store success in memory (indicates jump executed)

    # Case 2: Jump forward by large offset (+20)
    jal t2, forward_jump_2
    sw t3, 4(t0)              # This instruction should not be executed

forward_jump_2:
    li t3, 2
    sw t3, 4(t0)              # Store success in memory (indicates jump executed)

    # Case 3: Jump backward by small offset (-12)
    jal t2, backward_jump_1
    sw t3, 8(t0)              # This instruction should not be executed

backward_jump_1:
    li t3, 3
    sw t3, 8(t0)              # Store success in memory (indicates jump executed)

    # Case 4: Jump backward by large offset (-24)
    jal t2, backward_jump_2
    sw t3, 12(t0)             # This instruction should not be executed

backward_jump_2:
    li t3, 4
    sw t3, 12(t0)             # Store success in memory (indicates jump executed)

    ##########################
    # JALR - Jump and Link Register
    ##########################

    # Case 5: JALR with base register set to a label (jump forward by offset 0)
    la t4, jalr_forward_jump
    jalr t2, 0(t4)            # Jump to the address in t4
    sw t3, 16(t0)             # This instruction should not be executed

jalr_forward_jump:
    li t3, 5
    sw t3, 16(t0)             # Store success in memory (JALR jump forward executed)

    j jalr_test_done          # Jump to avoid falling into the next test case

    # Case 6: JALR with offset (jump forward with offset 8)
    la t4, jalr_forward_jump_offset
    jalr t2, 8(t4)            # Jump to address + offset 8
    sw t3, 20(t0)             # This instruction should not be executed

jalr_forward_jump_offset:
    li t3, 6
    sw t3, 20(t0)             # Store success in memory (JALR jump with offset executed)

    j jalr_test_done          # Jump to avoid falling into the next test case

    # Case 7: JALR with base register and negative offset (jump backward)
    la t4, jalr_backward_jump
    jalr t2, -8(t4)           # Jump to address - 8
    sw t3, 24(t0)             # This instruction should not be executed

jalr_backward_jump:
    li t3, 7
    sw t3, 24(t0)             # Store success in memory (JALR jump backward executed)

jalr_test_done:
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

