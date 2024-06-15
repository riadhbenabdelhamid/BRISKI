# Code explanation
#1) the request signal is reset by any thread
#2) the locked signal is reset by any thread
#3) The thread pointer value is then computed to prepare the base address for each pack of 8 data to be sent to URAM (shared mem)
#4) request to obtain grant to shared memory is set in MMIO register by any thread.
#5) All thread will wait until grant is allocated to the core (to 16 threads) by the external memory arbiter
#6) The core lock on to the shared memory by setting its locked register in MMIO to 1 (set by any thread)
#7) Once a lock is set the request can be reset to zero
#8) start sending 8 similar data (combined x position in the row part of ID (minirowID*posx+threadID))
#9) Enter a barrier by atomically incrementing a counter in a random memory location in BRAM and the exit barrier by checking if maximum is reached
#10) reset thread count for upcoming barriers, release lock for other cores to use URAM shared mem and (extra infinite loop at the end)

    .equ mask_MMIO, 0x8000
    .equ mask_BRAM, 0x0000
    .equ mask_URAM, 0x4000
    .equ req_addr, 0x8008 #0x2002 << 2  (base addr = 0x2000 & 0b0010) # the shift is necessary because memory in RV is byte-indexed
    .equ grant_addr, 0x8000 #0x2000 << 2
    .equ locked_addr, 0x800C #0x2003 << 2
    .equ uram_emptied_addr, 0x8010 #0x2004 <<2
    .text
    .globl main

main:

_lr_sc_mem_addr:
  li t3, 1020
_set_uram_emptied_reg_init:
  li a7, 0x0
_set_iter_count_reg_init:
  li t5, 0x0

_reset_req_reg:
  li	t4, req_addr # set address of reg req
  sw	zero,0(t4) #init to 0

_reset_locked_reg:
  li	s0, locked_addr # set address of reg locked
  sw	zero,0(s0) #init to 0

_set_thread_count:
  li s5, 0x010

_set_thread_counter:
  sw x0, 1020(x0)  #address 255

_compute_tp:
  csrr	t0, 0xF14 # load complete ID in reg t0
  li	t1, 0x01FF # load mask in t1 for getting posx and hartid
  and	t2,t0,t1  # perform bitwise and and store result back in t2 (position in a row)

  slli  tp, t2, 0x02 # shift to get word addr

  add   s4, tp, x0 # s4 is the start address offset that need to be incremented by 4 after each transfer,
  slli  s4, s4, 0x03 #allocate 8 addresses for each thread

  li    t2, mask_URAM # mask to generate enable for URAM shared mem
  or    s4, s4, t2 # bitwise or to get full mask
##################
_send_data_loop:
##################
##################
#to enter the barrier just atomically incremnet a counter
_enter_barrier_iter0:
  lr.w	s1, (t3) #load reserved to random address in BRAM dmem (rd (dest), rs1(mem addr))
  addi	s2,s1,0x01 # atomic increment
  sc.w	s3,s2, (t3) # store result back in register req address  //rd(flag), rs2(data), rs1(mem addr)
  bne	s3, zero, _enter_barrier_iter0 # branch back if store fails

#to exit the barrier wait for the last thread that reach the number of threads 0x10 (16)
_exit_barrier_iter0:
  lw    s1, (t3)
  bne   s1, s5, _exit_barrier_iter0 #if all thread arrive here (counter reset to 0x0) keep spinning until all threads arrive here
##################
##################

_set_req_to_1_iter0:
  li	s9, req_addr # set address of reg req
  li	s10, 0x01 # set value of reg req
  sw	s10,0(s9) #init to 0

#set a register in RF to contain the grant reg address 
_set_grant_reg:
  li a4, 0x01 # load constant flag 1 into a4
  li a5, grant_addr

_wait_grant_iter0:
  lw a6, 0(a5)
  bne a4, a6, _wait_grant_iter0
  
_set_locked_to_1_iter0:
  li	s9, locked_addr # set address of reg req
  li	s10, 0x01 # set value of reg req
  sw	s10,0(s9) #init to 0
  
_release_req_iter0:
  li	s9, req_addr # set address of reg req
  sw	zero,0(s9) #init to 0

_send_8_data_iter0:
  sll t0, t0, t5 #shift data to be stored in URAM by the increment
  sw t0, 0(s4)
  sw t0, 4(s4)
  sw t0, 8(s4)
  sw t0, 12(s4)
  sw t0, 16(s4)
  sw t0, 20(s4)
  sw t0, 24(s4)
  sw t0, 28(s4)

#########
#########
#######
#to enter the barrier just atomically incremnet a counter
_enter_barrier_iter1:
  lr.w	s1, (t3) #load reserved to random address in BRAM dmem (rd (dest), rs1(mem addr))
  addi	s2,s1,-0x01 # atomic decrement
  sc.w	s3,s2, (t3) # store result back in register req address  //rd(flag), rs2(data), rs1(mem addr)
  bne	s3, zero, _enter_barrier_iter1 # branch back if store fails

#to exit the barrier wait for the last thread that reach the number of threads 0x10 (16)
_exit_barrier_iter1:
  lw    s1, (t3)
  #bne   s1, s5, _exit_barrier_iter1 #if all thread arrive here (counter reset to 0x0) keep spinning until all threads arrive here
  bne   s1, x0, _exit_barrier_iter1 #if all thread arrive here (counter reset to 0x0) keep spinning until all threads arrive here

#_reset_thread_count_iter1:
#  sw x0, 0(x0)
#######
#_reset_thread_count_iter0:
#  sw x0, 0(x0)
#########
#########

_release_locked_iter0:
  sw	zero,0(s0) #init to 0 (the first thread would be sufficient)

##################
_reverse_uram_emptied_reg:
  #add t6,x0, a7 
  #xori t6, t6, 0x01
  xori a7, a7, 0x01

_wait_uram_emptied_iter0:
  li t6, uram_emptied_addr
  lw t6, 0(t6)
  bne a7, t6, _wait_uram_emptied_iter0

_increment_iter_count:
  addi	t5,t5,0x01 
  li s2, 0x06 # 6 iterations
  beq t5,s2, _jump_infinite_end
  j _send_data_loop
##################

_jump_infinite_end:
  j _jump_infinite_end



   
