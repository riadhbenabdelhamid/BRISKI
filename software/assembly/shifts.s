_start:
    # Initialize registers
    li  a0, 0x12345678   # Load a value into a0

    # Left Shift (sll)
    li  t6, 1            # test=test1
    li  t0, 0            # Load shift amount
    sll a1, a0, t0       # a1 = a0 << t0
    li  t0, 1            # Load shift amount
    sll a1, a0, t0       # a1 = a0 << t0
    li  t0, 5            # Load shift amount
    sll a1, a0, t0       # a1 = a0 << t0
    li  t0, 31           # Load shift amount
    sll a1, a0, t0       # a1 = a0 << t0

    # Left Shift (slli)
    li  t6, 2           # test=test2
    slli a1, a0, 0      # a1 = a0 << 0
    slli a1, a0, 1      # a1 = a0 << 1
    slli a1, a0, 5      # a1 = a0 << 5
    slli a1, a0, 31     # a1 = a0 << 31

    # Right Shift Logical (srl)
    li  t6, 3            # test=test3
    li  t1, 0            # Load shift amount
    srl a2, a0, t1       # a2 = a0 >> t1 (logical)
    li  t1, 1            # Load shift amount
    srl a2, a0, t1       # a2 = a0 >> t1 (logical)
    li  t1, 5            # Load shift amount
    srl a2, a0, t1       # a2 = a0 >> t1 (logical)
    li  t1, 31           # Load shift amount
    srl a2, a0, t1       # a2 = a0 >> t1 (logical)

    # Right Shift Logical (srli)
    li  t6, 4           # test=test4
    srli a2, a0, 0      # a2 = a0 >> t1 (logical)
    srli a2, a0, 1      # a2 = a0 >> t1 (logical)
    srli a2, a0, 5      # a2 = a0 >> t1 (logical)
    srli a2, a0, 31     # a2 = a0 >> t1 (logical)

    # Right Shift Arithmetic (sra)
    li  t6, 5            # test=test5
    li  t2, 0            # Load shift amount
    sra a3, a0, t2       # a3 = a0 >> t2 (arithmetic)
    li  t2, 1            # Load shift amount
    sra a3, a0, t2       # a3 = a0 >> t2 (arithmetic)
    li  t2, 5            # Load shift amount
    sra a3, a0, t2       # a3 = a0 >> t2 (arithmetic)
    li  t2, 27           # Load shift amount
    sra a3, a0, t2       # a3 = a0 >> t2 (arithmetic)
    li  t2, 31           # Load shift amount
    sra a3, a0, t2       # a3 = a0 >> t2 (arithmetic)

    li  a0, 0x82345678   # Load a value into a0
    li  t2, 0            # Load shift amount
    sra a3, a0, t2       # a3 = a0 >> t2 (arithmetic)
    li  t2, 1            # Load shift amount
    sra a3, a0, t2       # a3 = a0 >> t2 (arithmetic)
    li  t2, 5            # Load shift amount
    sra a3, a0, t2       # a3 = a0 >> t2 (arithmetic)
    li  t2, 27           # Load shift amount
    sra a3, a0, t2       # a3 = a0 >> t2 (arithmetic)
    li  t2, 31           # Load shift amount
    sra a3, a0, t2       # a3 = a0 >> t2 (arithmetic)

    # Right Shift Arithmetic (srai)
    li  t6, 6           # test=test6
    li  a0, 0x12345678   # Load a value into a0
    srai a3, a0, 0      # a3 = a0 >> 0 (arithmetic)
    srai a3, a0, 1      # a3 = a0 >> 1 (arithmetic)
    srai a3, a0, 5      # a3 = a0 >> 5 (arithmetic)
    srai a3, a0, 31     # a3 = a0 >> 31 (arithmetic)
    li  a0, 0x82345678   # Load a value into a0
    srai a3, a0, 0      # a3 = a0 >> 0 (arithmetic)
    srai a3, a0, 1      # a3 = a0 >> 1 (arithmetic)
    srai a3, a0, 5      # a3 = a0 >> 5 (arithmetic)
    srai a3, a0, 31     # a3 = a0 >> 31 (arithmetic)

    # End program
    j end_test
end_test:
    j end_test           # Make inf loop

.data
# Define your data section if needed

