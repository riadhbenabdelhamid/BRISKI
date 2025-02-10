    .section .data
    .section .text
    .globl _start
    .extern _stack_top
    # Define stack size per thread (you can adjust as needed)
    .equ STACK_SIZE, 128 # 80 bytes per thread

_start:
    # Retrieve hardware thread ID (hartid) and store it in register a0
    csrr a0, mhartid

    # Calculate stack pointer for this thread using shifts
    la t0, _stack_top        # Load address of the top of the stack

    andi t2, a0, 0xF
    andi t3, a0, 0xF
    # Decompose STACK_SIZE (80) into 64 (2^6) and 16 (2^4)
    # t2 = local hartid << 6 (hartid * 64)
    slli t2, t2, 6 # hartid * 64

    # t3 = hartid << 6 (hartid * 64) The amount can be changed to build a different stack size
    slli t3, t3, 6 #hartid * 64

    # t2 = t2 + t3 (hartid * 64 + hartid * 64 = hartid * 128) 
    add t2, t2, t3

    # Set the stack pointer for this thread
    sub sp, t0, t2           # sp = _stack_top - (hartid * STACK_SIZE)

    # Call the main function with hartid as an argument
    jal ra, main


