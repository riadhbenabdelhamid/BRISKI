

    .text
    .globl main
main:
    #csrr a0, 0xF14       => 0xf1402573
    # Store byte
    li t0, 0xF2     # Load immediate value into t0
    sb t0, 0(x0) # Store byte from t0 at memLocation 0
    
    # Store halfword
    li t1, 0x3456   # Load another immediate value into t1
    sh t1, 2(x0) # Store halfword from t1 at memLocation + 2

    # Store word
    li t2, 0xF89ABCDE   # Load another immediate value into t2
    sw t2, 4(x0) # Store word from t2 at memLocation + 4

    # Load byte
    lb a0, 0(x0) # Load byte from memLocation into a0

    # Load halfword
    lh a0, 2(x0) # Load halfword from memLocation + 2 into a0

    # Load word
    lw a0, 4(x0) # Load word from memLocation + 4 into a0

    # Load byte unsigned
    lbu a0, 0(x0) # Load byte unsigned from memLocation into a0

    # Load halfword unsigned
    lhu a0, 2(x0) # Load halfword unsigned from memLocation + 2 into a0

infinite_loop:
    j infinite_loop    # Jump to itself, creating an infinite loop

