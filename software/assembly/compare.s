_start:
    # Set Less Than (slt)
    li  a0, 5     # Load a value into a0
    li  a1, 10      # Load another value into a1
    slt t1, a0, a1     # t1 = (a0 < a1)
    li  a0, 11     # Load a value into a0
    li  a1, 11     # Load another value into a1
    slt t1, a0, a1     # t1 = (a0 < a1)
    li  a0, -5     # Load a value into a0
    li  a1, -6     # Load another value into a1
    slt t1, a0, a1     # t1 = (a0 < a1)
    li  a0, -7     # Load a value into a0
    li  a1, -7     # Load another value into a1
    slt t1, a0, a1     # t1 = (a0 < a1)

    # Set Less Than Immediate (slti)
    li  a0, 10     # Load a value into a0
    slti t2, a0, 15    # t2 = (a0 < 15)
    li  a0, 15     # Load a value into a0
    slti t2, a0, 15    # t2 = (a0 < 15)
    li  a0, -6     # Load a value into a0
    slti t2, a0, -5    # t2 = (a0 < -5)
    li  a0, -7     # Load a value into a0
    slti t2, a0, -7    # t2 = (a0 < -7)

    # Set Less Than Unsigned (sltu)
    li  a0, 5     # Load a value into a0
    li  a1, 10      # Load another value into a1
    sltu t3, a0, a1    # t3 = (a0 < a1) using unsigned comparison
    li  a0, 15     # Load a value into a0
    li  a1, 15      # Load another value into a1
    sltu t3, a0, a1    # t3 = (a0 < a1) using unsigned comparison
    li  a0, -5     # Load a value into a0
    li  a1, -6      # Load another value into a1
    sltu t3, a0, a1    # t3 = (a0 < a1) using unsigned comparison
    li  a0, -7     # Load a value into a0
    li  a1, -7      # Load another value into a1
    sltu t3, a0, a1    # t3 = (a0 < a1) using unsigned comparison

    # Set Less Than Immediate Unsigned (sltiu)
    li  a1, 1     # Load a value into a0
    sltiu t4, a1, 3    # t4 = (a1 < 3) using unsigned comparison
    li  a1, 12     # Load a value into a0
    sltiu t4, a1, 12   # t4 = (a1 < 12) using unsigned comparison
    li  a1, -5     # Load a value into a0
    sltiu t4, a1, 1   # t4 = (a1 < 1) using unsigned comparison
    li  a1, -6     # Load a value into a0
    sltiu t4, a1, -6   # t4 = (a1 < -6) using unsigned comparison

    # Your preferred method of output, e.g., printing registers or storing results

    # End program
    li  a7, 10          # Load system call code for exit
end_test:
    j end_test          # Make system call

.data
# Define your data section if needed

