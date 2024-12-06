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
    # SLL - Logical Left Shift
    ##########################

    # Case 1: Shift small positive number (5 << 1)
    li t2, 5               # Load the number 5
    li t3, 1               # Shift by 1
    sll t4, t2, t3         # Perform logical left shift
    sw t4, 0(t0)           # Store result (5 << 1 = 10)

    # Case 2: Shift large positive number (0x7FFFFFFF << 2)
    li t2, 0x7FFFFFFF      # Load the large positive number
    li t3, 2               # Shift by 2
    sll t4, t2, t3         # Perform logical left shift
    sw t4, 4(t0)           # Store result (shift 0x7FFFFFFF by 2)

    # Case 3: Shift negative number (-1 << 3)
    li t2, -1              # Load -1 (0xFFFFFFFF)
    li t3, 3               # Shift by 3
    sll t4, t2, t3         # Perform logical left shift
    sw t4, 8(t0)           # Store result (-1 << 3 = 0xFFFFFFF8)

    # Case 4: Shift by 0 (5 << 0)
    li t2, 5               # Load the number 5
    li t3, 0               # Shift by 0
    sll t4, t2, t3         # Perform logical left shift
    sw t4, 12(t0)          # Store result (5 << 0 = 5)

    # Case 5: Maximum shift (1 << 31)
    li t2, 1               # Load 1
    li t3, 31              # Shift by 31
    sll t4, t2, t3         # Perform logical left shift
    sw t4, 16(t0)          # Store result (1 << 31 = 0x80000000)

    ##########################
    # SRL - Logical Right Shift
    ##########################

    # Case 6: Shift small positive number (10 >> 1)
    li t2, 10              # Load the number 10
    li t3, 1               # Shift by 1
    srl t4, t2, t3         # Perform logical right shift
    sw t4, 20(t0)          # Store result (10 >> 1 = 5)

    # Case 7: Shift large positive number (0x7FFFFFFF >> 2)
    li t2, 0x7FFFFFFF      # Load the large positive number
    li t3, 2               # Shift by 2
    srl t4, t2, t3         # Perform logical right shift
    sw t4, 24(t0)          # Store result (shift 0x7FFFFFFF by 2)

    # Case 8: Shift by 0 (5 >> 0)
    li t2, 5               # Load the number 5
    li t3, 0               # Shift by 0
    srl t4, t2, t3         # Perform logical right shift
    sw t4, 28(t0)          # Store result (5 >> 0 = 5)

    # Case 9: Maximum shift (1 >> 31)
    li t2, 1               # Load 1
    li t3, 31              # Shift by 31
    srl t4, t2, t3         # Perform logical right shift
    sw t4, 32(t0)          # Store result (1 >> 31 = 0)

    ##########################
    # SRA - Arithmetic Right Shift
    ##########################

    # Case 10: Shift small positive number (10 >> 1)
    li t2, 10              # Load the number 10
    li t3, 1               # Shift by 1
    sra t4, t2, t3         # Perform arithmetic right shift
    sw t4, 36(t0)          # Store result (10 >> 1 = 5)

    # Case 11: Shift large positive number (0x7FFFFFFF >> 2)
    li t2, 0x7FFFFFFF      # Load the large positive number
    li t3, 2               # Shift by 2
    sra t4, t2, t3         # Perform arithmetic right shift
    sw t4, 40(t0)          # Store result (shift 0x7FFFFFFF by 2)

    # Case 12: Shift negative number (-1 >> 1)
    li t2, -1              # Load -1 (0xFFFFFFFF)
    li t3, 1               # Shift by 1
    sra t4, t2, t3         # Perform arithmetic right shift
    sw t4, 44(t0)          # Store result (-1 >> 1 = -1)

    # Case 13: Shift by 0 (-5 >> 0)
    li t2, -5              # Load -5
    li t3, 0               # Shift by 0
    sra t4, t2, t3         # Perform arithmetic right shift
    sw t4, 48(t0)          # Store result (-5 >> 0 = -5)

    # Case 14: Maximum shift (-1 >> 31)
    li t2, -1              # Load -1 (0xFFFFFFFF)
    li t3, 31              # Shift by 31
    sra t4, t2, t3         # Perform arithmetic right shift
    sw t4, 52(t0)          # Store result (-1 >> 31 = -1)

    ############################
    # Barrier synchronization
    ############################
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

