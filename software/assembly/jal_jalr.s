
    _start:
        # JAL example
        addi x5, x0, 0      # Initialize x5 to 0
        addi x7, x0, 13      # Initialize x7 to 0
        jal x6, label1      # Jump to label1 and save return address in x6


    continue:
        # JALR example
        addi x8, x0, 4      # Initialize x8 to 4
        jalr x9, x8, 0      # Jump to address (x8 + 0) and save return address in x9
        # Next instruction is unreachable as it's a direct jump to _end

    _end:
        # End of program, loop indefinitely
        j _end

    label1:
        beq  x5, x7, _end
        addi x5, x5, 1      # Increment x5
        jalr x0, x6, 0      # Return to the address saved in x6
