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
    # LUI Tests
    ##########################

    # Case 1: LUI - Load basic upper immediate value
    lui t1, 0x12345         # Load upper immediate value into t1
    sw t1, 0(t0)            # Store result (expected 0x12345000)

    # Case 2: LUI - Loading maximum unsigned value
    lui t1, 0xFFFFF         # Load max upper immediate
    sw t1, 4(t0)            # Store result (expected 0xFFFFF000)

    # Case 3: LUI - Load 0
    lui t1, 0x0             # Load 0 into upper part
    sw t1, 8(t0)            # Store result (expected 0x00000000)

    # Case 4: LUI - Load upper with negative equivalent
    lui t1, 0x80000         # Load upper immediate that leads to negative
    sw t1, 12(t0)           # Store result (expected 0x80000000)

    # Case 5: LUI - Upper immediate with large offset
    lui t1, 0xFFFF          # Load upper immediate with large value
    sw t1, 16(t0)           # Store result (expected 0xFFFF0000)

    ##########################
    # AUIPC Tests
    ##########################

    # Case 6: AUIPC - Add upper immediate to PC (current PC + 0)
    auipc t1, 0             # Load current PC into t1
    sw t1, 20(t0)           # Store PC (address of this instruction)

    # Case 7: AUIPC - Add upper immediate with a positive offset
    auipc t1, 1             # PC + 0x1000
    sw t1, 24(t0)           # Store result (expected PC + 0x1000)

    # Case 8: AUIPC - Add upper immediate with a large offset
    auipc t1, 0xFFF         # PC + 0xFFF000
    sw t1, 28(t0)           # Store result (expected PC + 0xFFF000)

    # Case 9: AUIPC - Add upper immediate with negative equivalent
    auipc t1, 0x800         # PC + 0x80000
    sw t1, 32(t0)           # Store result (expected PC + 0x80000)

    # Case 10: AUIPC - Testing with boundary case
    auipc t1, 0xFFFFF       # PC + 0xFFFFF000
    sw t1, 36(t0)           # Store result (expected PC + 0xFFFFF000)

    ###########################
    # Barrier synchronization
    ###########################
    la s1, barrier_var        # Load the address of the counter barrier variable
    li s0, NUM_THREADS        # Load total number of threads
barrier_attempt:
    lr.w s2, (s1)             # Load reserved from barrier address
    addi s3, s2, 0x01         # Increment the barrier by 1
    sc.w s4, s3, (s1)         # Store conditional to barrier address
    bnez s4, barrier_attempt   # If store fails, retry

    # Check if all threads have reached the barrier
    beq s0, s3, barrier_done   # If barrier equals NUM_THREADS, proceed to ecall

    # Wait in an infinite loop if not all threads reached the barrier
barrier_wait:
    j barrier_wait             # Spin-wait if not the last thread

barrier_done:
    # Call ecall to indicate completion by the last thread
    ecall

