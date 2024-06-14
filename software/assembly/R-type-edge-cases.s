.text
.globl main
main:
    # Load edge case values into registers
    li t0, -1    # Load -1 into t0
    li t1, 1     # Load 0 into t1

    # Test ADD (add)
    add t2, t0, t1   # Add t0 and t1, store result in t2

    # Test SUB (subtract)
    sub t2, t0, t1   # Subtract t1 from t0, store result in t2

    # Test SLL (shift left logical)
    sll t2, t0, t1   # Shift t0 left by t1, store result in t2

    # Test SLT (set less than)
    slt t2, t0, t1   # If t0 is less than t1, set t2 to 1

    # Test SLTU (set less than, unsigned)
    sltu t2, t0, t1  # If t0 is less than t1 (unsigned comparison), set t2 to 1

    # Test XOR (exclusive OR)
    xor t2, t0, t1   # Perform bitwise XOR on t0 and t1, store result in t2

    # Test SRL (shift right logical)
    srl t2, t0, t1   # Shift t0 right by t1, store result in t2

    # Test SRA (shift right arithmetic)
    sra t2, t0, t1   # Shift t0 right by t1 (sign-extended), store result in t2

    # Test OR (bitwise OR)
    or t2, t0, t1    # Perform bitwise OR on t0 and t1, store result in t2

    # Test AND (bitwise AND)
    and t2, t0, t1   # Perform bitwise AND on t0 and t1, store result in t2

    # Infinite loop to terminate the program
    infinite_loop:
        j infinite_loop    # Jump to itself, creating an infinite loop

