.text
.globl main
main:
    # Test LUI (Load Upper Immediate)
    lui t0, 0x12345   # Load 0x12345000 into t0

    # Test AUIPC (Add Upper Immediate to PC)
    # This is trickier to demonstrate, because it involves the program counter
    # We can try to use it to create a relative jump
    auipc t1, 1       # t1 = pc + 0x1000 (roughly speaking, not exact because of pc's value at the moment of execution)
    addi t2, t1, -4  # t2 = t1 - 4, creating a backwards loop
    jalr zero, t2, 0 # Jump to the address in t2 (creating an infinite loop)

infinite_loop:
    j infinite_loop  # If the AUIPC instruction did not work, we still have a fallback infinite loop here

