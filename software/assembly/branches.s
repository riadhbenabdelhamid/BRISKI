# Test of BEQ (Branch Equal)
    li t0, 1 # test beq
beq_test:
    li a0, 5       # Load immediate values for comparison
    li a1, 5
    li a2, 3
    li a3, 4
    li a4, 5
    beq a0, a1, beq_taken   # Branch should be taken
    j end_test_nok

beq_taken:
    li a2, 1       # Set a register to 1 to indicate branch taken
    j beq_not_taken

beq_not_taken:
    li a0, 4       # Load immediate values for comparison
    li a1, 6
    beq a0, a1, end_test_nok   # Branch should not be taken
    j end_beq # should be reached

end_beq:
    li a2, 0       # Set a register to 0 to indicate branch not taken
#--------------------------------------------------------
    # Continue with the next test...
# Similar tests for BNE, BLT, BGE, BLTU, BGEU

# Test of BNE (Branch Not Equal)
    li t0, 2 # test bne 
bne_test:
    li a0, 5
    li a1, 7
    bne a0, a1, bne_taken # branch should be taken
    j end_test_nok # should not be reached

bne_taken:
    li a2, 1
    j bne_not_taken

bne_not_taken:
    li a0, 8
    li a1, 8
    bne a0, a1, end_test_nok # should not be taken
    j end_bne

end_bne:
    li a2, 0
#--------------------------------------------------------
    # Continue with the next test...

# Test of BLT (Branch Less Than)
    li t0, 3 # test blt
blt_test:
    li a0, -5      # Load immediate values for comparison
    li a1, 5
    blt a0, a1, blt_taken   # Branch should be taken
    j end_test_nok  #should not reach here

blt_taken:
    li a2, 1
    j blt_not_taken

blt_not_taken:
    li a0, 6
    li a1, 6
    blt a0, a1, end_test_nok # should not be taken
    j end_blt

end_blt:
    li a2, 0
#--------------------------------------------------------
    # Continue with the next test...

# Similar tests for BGE, BLTU, BGEU

# Test of BGE (Branch Greater or Equal)
    li t0, 4 # test bge
bge_test1:
    li a0, 3
    li a1, -10
    bge a0, a1, bge_test1_taken
    j end_test_nok #should not happen

bge_test1_taken:
    li a2, 1
    j bge_test2

bge_test2:
    li a0, 5
    li a1, 5
    bge a0, a1, bge_test2_taken
    j end_test_nok #should not happen

bge_test2_taken:
    li a2, 1
    j bge_test3

bge_test3:
    li a0, -75
    li a1, -75
    bge a0, a1, bge_test3_taken
    j end_test_nok #should not happen

bge_test3_taken:
    li a2, 1
    j bge_test1_not_taken

bge_test1_not_taken:
    li a0, -4
    li a1, 7
    bge a0, a1, end_test_nok # should not be taken
    li a2, 81
    j bge_test2_not_taken

bge_test2_not_taken:
    li a0, -6
    li a1, 3
    bge a0, a1, end_test_nok # should not be taken
    li a2, 82
    j bge_test3_not_taken

bge_test3_not_taken:
    li a0, -5
    li a1, 5
    bge a0, a1, end_test_nok # should not be taken
    li a2, 83
    j bge_test4_not_taken

bge_test4_not_taken:
    li a0, 0x80000000
    li a1, 0xEFFFFFFF
    bge a0, a1, end_test_nok # should not be taken
    li a2, 84
    j end_bge

end_bge:
    li a2, 0
#--------------------------------------------------------
    # Continue with the next test...

    li t0, 5 # test bltu
# Test of BLTU (Branch Less Than Unsigned)
bltu_test1:
    li a0, 5
    li a1, -5
    bltu a0, a1, bltu_test1_taken #branch should be taken
    j end_test_nok #should not be reached

bltu_test1_taken:
    li a2, 1
    j bltu_test2

bltu_test2:
    li a0, 0xFFFFFFFE
    li a1, 0xFFFFFFFF
    bltu a0, a1, bltu_test2_taken #branch should be taken
    j end_test_nok #should not be reached

bltu_test2_taken:
    li a2, 1
    j bltu_test3

bltu_test3:
    li a0, 0xEFFFFFFE
    li a1, 0xEFFFFFFF
    bltu a0, a1, bltu_test3_taken #branch should be taken
    j end_test_nok #should not be reached

bltu_test3_taken:
    li a2, 1
    j bltu_test1_not_taken

bltu_test1_not_taken:
    li a0, 0xFFFFFFFF
    li a1, 0xFFFFFFFE
    bltu a0, a1, end_test_nok #branch should not be taken
    j bltu_test2_not_taken 

bltu_test2_not_taken:
    li a0, 0xEFFFFFFF
    li a1, 0xEFFFFFFE
    bltu a0, a1, end_test_nok #branch should not be taken
    j end_bltu 

end_bltu:
    li a2, 0
#--------------------------------------------------------
    # Continue with the next test...

    li t0, 6 # test bgeu
# Test of BGEU (Branch Greater or Equal Unsigned)
bgeu_test1: #greater
    li a0, 0x80000000
    li a1, 0x7FFFFFFF
    bgeu a0, a1, bgeu_test1_taken # branch should be taken
    j end_test_nok #This instruction should not be reached

bgeu_test1_taken:
    li a2, 1
    j bgeu_test2

bgeu_test2: #equal
    li a0, 0xFF999999
    li a1, 0xFF999999
    bgeu a0, a1, bgeu_test2_taken # branch should be taken
    j end_test_nok #This instruction should not be reached

bgeu_test2_taken:
    li a2, 1
    j bgeu_test1_not_taken

bgeu_test1_not_taken:
    li a0, 0x7FFFFFFF
    li a1, 0x80000000
    bgeu a0, a1, end_test_nok # branch should not be taken
    j bgeu_test2_not_taken # this instruction must be executed instead

bgeu_test2_not_taken:
    li a0, -5
    li a1, -2
    bgeu a0, a1, end_test_nok # branch should not be taken
    j bgeu_test3_not_taken # this instruction must be executed instead

bgeu_test3_not_taken:
    li a0, 1
    li a1, -2
    bgeu a0, a1, end_test_nok # branch should not be taken
    j end_bgeu                # this instruction must be executed instead

end_bgeu:
    li a2, 0
    j end_test_ok
#--------------------------------------------------------
    # Tests are complete

#--------------------------------------------------------
# Evaluate all tests
end_test_ok:  #test ok A Grade or 20 score
    li a5, 0xA20
    j end_test_ok_loop

end_test_ok_loop:
    j end_test_ok_loop


end_test_nok: #test not ok F Grade or 00 score
    li a5, 0xF00
    j end_test_nok_loop

end_test_nok_loop:
    j end_test_nok_loop
