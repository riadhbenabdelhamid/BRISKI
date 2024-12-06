    .section .data
    .section .text
    .globl _start
    .extern _stack_top
    # Define stack size per thread (adjust as needed)
    .equ STACK_SIZE, 160  # 160 bytes per thread

_start:
    # Retrieve hardware thread ID (hartid) and store it in register a0
    csrr a0, mhartid

    # Calculate stack pointer for this thread using shifts
    la t0, _stack_top        # Load address of the top of the stack

    # Decompose STACK_SIZE (160) into 128 (2^7) and 32 (2^5)
    # t2 = hartid << 7 (hartid * 128)
    slli t2, a0, 7

    # t3 = hartid << 5 (hartid * 32)
    slli t3, a0, 5

    # t2 = t2 + t3 (hartid * 128 + hartid * 32 = hartid * 160)
    add t2, t2, t3

    # Set the stack pointer for this thread
    sub sp, t0, t2           # sp = _stack_top - (hartid * STACK_SIZE)

    # Call the main function with hartid as an argument
    jal ra, main

    # Infinite loop to prevent exit
#1:  j 1b

#    .section .bss
#    .align 4
#_stack_top:
#    .space 0  # Stack starts here and grows downwards

