    .section .data
thread_data:
    .space 2048  # Space for NUM_THREADS threads (2KB)

barrier_var:
    .word 0       # Barrier counter variable

    .section .text
    .global _start
_start:
    # Get the thread ID (assumed to be in a0)
    li t0, 512             # Base address for thread data
    slli t1, a0, 11        # Shift left by 11 to multiply thread ID by 2048 (2KB)
    add t0, t0, t1         # Calculate starting address for this thread

    ##########################
    # Byte Load and Store Tests
    ##########################

    # Case 1: Store a byte and then load it back (unsigned)
    li t2, 0xAB            # Load immediate byte value
    sb t2, 0(t0)           # Store byte at address 0
    lb t3, 0(t0)           # Load byte back
    sb t3, 4(t0)           # Store loaded byte to check (expected 0xAB)

    # Case 2: Store and load a signed byte
    li t4, -5              # Load a negative byte value
    sb t4, 8(t0)           # Store byte at offset 8
    lb t5, 8(t0)           # Load it back (should read as signed)
    sb t5, 12(t0)          # Store loaded byte to check (expected -5)

    # Case 3: Store the maximum unsigned byte
    li t6, 0xFF            # Load maximum unsigned byte value
    sb t6, 16(t0)          # Store byte at offset 16
    lb t2, 16(t0)          # Load it back
    sb t2, 20(t0)          # Store loaded byte to check (expected 0xFF)

    # Case 4: Load unsigned byte (LBU)
    li t3, 0x7F            # Store a positive value to check LBU
    sb t3, 24(t0)          # Store byte at offset 24
    lbu t4, 24(t0)         # Load unsigned byte
    sb t4, 28(t0)          # Store loaded byte to check (expected 0x7F)

    # Case 5: Load unsigned byte (LBU) with negative value
    li t5, -1              # Store a negative value to check LBU
    sb t5, 32(t0)          # Store byte at offset 32
    lbu t6, 32(t0)         # Load unsigned byte (should be 0xFF)
    sb t6, 36(t0)          # Store loaded byte to check (expected 0xFF)

    ##########################
    # Half-Word Load and Store Tests
    ##########################

    # Case 6: Store a half-word and then load it back (unsigned)
    li t2, 0x1234          # Load immediate half-word value
    sh t2, 40(t0)          # Store half-word at offset 40
    lw t3, 40(t0)          # Load it back (should read as unsigned)
    sh t3, 44(t0)          # Store loaded half-word to check (expected 0x1234)

    # Case 7: Store and load a signed half-word
    li t4, -32768          # Load a negative half-word value
    sh t4, 48(t0)         # Store half-word at offset 48
    lw t5, 48(t0)         # Load it back (should read as signed)
    sh t5, 52(t0)         # Store loaded half-word to check (expected -32768)

    # Case 8: Load unsigned half-word (LHU)
    li t6, 0x00FF          # Store value to check LHU
    sh t6, 56(t0)         # Store half-word at offset 56
    lhu t2, 56(t0)       # Load unsigned half-word
    sh t2, 60(t0)        # Store loaded half-word to check (expected 0x00FF)

    # Case 9: Load unsigned half-word (LHU) with negative value
    li t3, -1              # Store negative value as half-word
    sh t3, 64(t0)         # Store half-word at offset 64
    lhu t4, 64(t0)        # Load unsigned half-word (should be 0xFFFF)
    sh t4, 68(t0)         # Store loaded half-word to check (expected 0xFFFF)

    ##########################
    # Word Load and Store Tests
    ##########################

    # Case 10: Store a word and then load it back
    li t5, 0xDEADBEEF     # Load a word value
    sw t5, 72(t0)         # Store word at offset 72
    lw t6, 72(t0)         # Load it back
    sw t6, 76(t0)         # Store loaded value to check (expected 0xDEADBEEF)

    ###########################
    # Boundary and Special Case Loads
    ###########################

    # Case 11: Load and store at the edge of memory
    li t2, 0xCAFECAFE     # Load a value
    sw t2, 2040(t0)       # Store at the last byte (2048-8)
    lw t3, 2040(t0)       # Load it back
    sw t3, 80(t0)         # Store loaded value to check (expected 0xCAFECAFE)

    ###########################
    # Sign and Zero Extension Tests
    ###########################

    # Test zero extension with LBU
    li t4, 0xFE           # Store a negative byte
    sb t4, 88(t0)         # Store byte at offset 88
    lbu t5, 88(t0)        # Load byte unsigned
    sb t5, 92(t0)         # Store loaded byte to check (expected 0xFE)

    # Test sign extension with LB
    li t6, -5              # Store negative value
    sb t6, 96(t0)         # Store byte at offset 96
    lb t2, 96(t0)         # Load it back (should read as signed)
    sb t2, 100(t0)        # Store loaded byte to check (expected -5)

    # Test zero extension with LHU
    li t3, 0xF00F         # Store value for half-word
    sh t3, 104(t0)        # Store half-word at offset 104
    lhu t4, 104(t0)       # Load half-word unsigned
    sh t4, 108(t0)        # Store loaded half-word to check (expected 0xF00F)

    # Test sign extension with LH
    li t5, -32768         # Store negative value for half-word
    sh t5, 112(t0)       # Store half-word at offset 112
    lh t6, 112(t0)       # Load it back (should read as signed)
    sh t6, 116(t0)       # Store loaded half-word to check (expected -32768)

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

