.section .data
#.org 512                   # Start the data section at address 512
.align 4
# Data sections for each hart, each containing an array of 32 ASCII characters
hart0_data: .ascii "AbcDefGhijKlmNop@#%$&*!()_-+=012345"
hart1_data: .ascii "zXyWVutsrQpOnMLkjihgfEDCBA9876543210"
hart2_data: .ascii "PqRsTuvWXYzabcdefghij!@#$%^&*()_+[]"
hart3_data: .ascii "lmnOpQrStUvWxYzABCDEFGHIJ{}|;:<>,.?/"
hart4_data: .ascii "KLMNoPQrStUVWXyz0123456789~`-=_+|\\"
hart5_data: .ascii "abcdefghijKLMNOPQR2345678901*&^%$#@"
hart6_data: .ascii "1234567890abcdefGHIJKLMnoPQRSTuvWX"
hart7_data: .ascii "yzABCDEFghijKLMNOpqrst0123456789!@"
hart8_data: .ascii "ghijKLMNOPQRSTuvwxyZ!@#$%^&*()1234"
hart9_data: .ascii "ABCDefghijklmnopQRSTuvWXYZ01234567"
hart10_data: .ascii "mnopQRSTUVWXyzab@#%$&*!()_-+=01234"
hart11_data: .ascii "xyz1234567890ABCD%$&*(!)_+=-{}|[]\\"
hart12_data: .ascii "wxyZABCDEfghijklmnopQRSTuvWXYZ1234"
hart13_data: .ascii "abcdefghijklmNOPQRSTUVWXyz01234567"
hart14_data: .ascii "PQRSTuvWXYzabcdefghijklmnop!@#$%^&"
hart15_data: .ascii "1234567890ABCDXYZefghijklmnopQRST"

.align 4
shared_counter: .word 0  # Shared counter for barrier synchronization
.section .text
.globl _start

_start:
    li t0, 32              # Length of the ASCII array (32 characters)
    la t1, hart0_data      # Load address of hart0 data
    la t2, shared_counter  # Load address of shared counter

    # Determine hart id (for simplicity, using a fixed base register)
    csrr a0, mhartid       # Read the hart ID
    slli a0, a0, 6         # Each hart's data starts 64 bytes apart
    add t1, t1, a0         # Calculate start of this hart's data section

    # Character Conversion Loop
convert_loop:
    lb a1, 0(t1)           # Load character from array
    beqz a1, finish        # End of string (null character), exit loop
    #li a2, 'a'             # Load 'a'
    #li a3, 'z'             # Load 'z'
    #blt a1, a2, next_char  # If char < 'a', not a lowercase letter
    #bgt a1, a3, next_char  # If char > 'z', not a lowercase letter

    # Convert to uppercase
    #li a4, 32              # ASCII difference between upper and lower case
    #sub a1, a1, a4         # Convert to uppercase
    lotoupcase a1, a1      # Custom instruction: a1 = lotoupcase(a1)
    sb a1, 0(t1)           # Store back converted character

next_char:
    addi t1, t1, 1         # Move to next character
    addi t0, t0, -1        # Decrease character count
    bnez t0, convert_loop  # Continue loop if more characters

    # Barrier Synchronization
finish:
    li t6, 16              # Total number of harts
    li t3, 1               # Atomic increment value
barrier:
    lr.w t4, 0(t2)         # Load current counter value
    add t4, t4, t3         # Increment counter
    sc.w t5, t4, 0(t2)     # Store conditionally
    bnez t5, barrier       # Retry if SC failed
exit_barrier:
    lw t4, 0(t2)                # Total number of harts
    bne t4, t6, exit_barrier    # Wait until all harts have reached this point

    # Termination
    ecall                  # End program (simulated halt for each hart)

