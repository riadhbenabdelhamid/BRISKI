.text
.globl main
main:
    # Load a value into a register
    li t0, 5     # Load 5 into t0

    # Test ADDI (add immediate)
    addi t1, t0, 10   # Add 10 to t0, store result in t1

    # Test SLTI (set less than immediate)
    slti t2, t0, 4    # If t0 is less than 4, set t2 to 1

    # Test SLTIU (set less than immediate, unsigned)
    sltiu t3, t0, 6   # If t0 is less than 6 (unsigned comparison), set t3 to 1

    # Test XORI (exclusive OR immediate)
    xori t4, t0, 3    # Perform bitwise XOR on t0 and 3, store result in t4

    # Test ORI (bitwise OR immediate)
    ori t5, t0, 2     # Perform bitwise OR on t0 and 2, store result in t5

    # Test ANDI (bitwise AND immediate)
    andi t6, t0, 7    # Perform bitwise AND on t0 and 7, store result in t6

    # Test SLLI (shift left logical immediate)
    slli t1, t0, 1    # Shift t0 left by 1 bit, store result in t1

    # Load a value into a register
    li t0, 5     # Load 5 into t0
    
    # Test SRLI (shift right logical immediate)
    srli t1, t0, 1    # Shift t0 right by 1 bit, store result in t1

    # Load a value into a register
    lui t0, 0xF0000     # Load upper immediate 0xF0000 into t0
    
    # Test SRLI (shift right logical immediate)
    srli t1, t0, 1    # Shift t0 right by 1 bit, store result in t1

    # Load a value into a register
    li t0, 5     # Load upper immediate 0xF0000 into t0
    
    # Test SRAI (shift right arithmetic immediate)
    srai t1, t0, 1    # Shift t0 right by 1 bit (sign-extended), store result in t0

    # Load a value into a register
    lui t0, 0xF0000     # Load upper immediate 0xF0000 into t0
    
    # Test SRAI (shift right arithmetic immediate)
    srai t1, t0, 1    # Shift t0 right by 1 bit (sign-extended), store result in t0

    # Infinite loop to terminate the program
    infinite_loop:
        j infinite_loop    # Jump to itself, creating an infinite loop

