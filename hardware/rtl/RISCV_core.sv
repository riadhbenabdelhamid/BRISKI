`include "riscv_pkg.sv"
//import riscv_pkg::*;
module RISCV_core #(
    // Generic parameters
    parameter IDcluster = 0,
    parameter IDrow = 0,
    parameter IDminirow = 0,
    parameter IDposx = 0
) (
    // Ports
    input logic clk,
    input logic reset,
    // Instruction memory signals
    input logic [31:0] i_ROM_instruction,
    output logic [9:0] o_ROM_addr,
    // Data memory signals
    output logic [13:0] o_dmem_addr,
    output logic [31:0] o_dmem_write_data,
    output logic [3:0] o_dmem_write_enable,
    input logic [31:0] i_dmem_read_data,
    // Regfile signals for debug
    output logic [4:0] regfile_wr_addr,
    output logic [31:0] regfile_wr_data,
    output logic regfile_wr_en,
    // thread index signals for debug
    output logic [$clog2(NUM_THREADS)-1:0] thread_index_wb,
    output logic [$clog2(NUM_THREADS)-1:0] thread_index_wrmem
);

  // ============================================================================================================
  // architecture
  // ============================================================================================================
  // ...
  //function logic [31-clog2(NUM_THREADS)-1:0] computeID (input int varIDcluster, varIDrow, varIDminirow, varIDposx);
  function logic [10:0] computeID(input int varIDcluster, varIDrow, varIDminirow, varIDposx);
    //logic [31-clog2(NUM_THREADS)-1:0] varID;
    logic [10:0] varID;
    //varID = 0;
    //varID[10:0] = {varIDcluster[3:0], varIDrow[1:0], {((varIDminirow * 6) + varIDposx)}[4:0]};
    varID[10:0]  = {varIDcluster[3:0], varIDrow[1:0], 5'({((varIDminirow * 6) + varIDposx)})};
    //varID[31:11] = 0;
    return varID;
  endfunction

  // Internal signals
  // ============================================================================================================
  // context
  // type thread_index_array is array(1 to NUM_THREADS-1) of logic [clog2(NUM_THREADS)-1:0];
  //type thread_index_array is array[1:9] of logic [clog2(NUM_THREADS)-1:0]; // 10 stage version
  logic [$clog2(NUM_THREADS)-1:0] thread_index_stage [1:9];  // pipelined thread counter used for pc update and writeback on the different register files
  logic [$clog2(NUM_THREADS)-1:0] thread_index_counter;  // current thread counter
  // logic [0:1] start = 0; // to delay first instruction one clock cycle after reset
  logic start;  // to delay first instruction one clock cycle after reset
  logic start_reg;  // to delay first instruction one clock cycle after reset
  // fetch signals
  logic [31:0] pc;
  logic [31:0] pcreg;
  logic [31:0] instruction;
  // decode signals
  logic [6:0] opcode;
  logic [2:0] funct3;
  logic [6:0] funct7;
  logic [4:0] rs1;
  logic [4:0] rs2;
  logic [4:0] regfile_write_addr;
  logic [31:0] regfile_write_data;
  logic [31:0] rd1;
  logic [31:0] rd2;
  logic [31:0] imm_out;
  // execute signals
  logic [1:0] ALUctrl;
  logic [ALUOP_WIDTH-1:0] ALUOp;
  logic [31:0] aluop1, aluop2;
  logic br_signed;
  logic [31:0] rd2_or_imm;
  logic is_branch;
  logic is_slt_op;
  logic is_jump;
  logic slt;
  logic is_branch_valid;
  // memory signals
  logic load;
  logic MemWr;
  logic MemWr_pipe;
  logic [3:0] dmem_write_enable_post;  // One bit per byte in word
  logic [31:0] dmem_dout_pre;
  logic [31:0] dmem_dout_post;
  // WB signals
  logic [31:0] pcplusfour;
  logic [31:0] alu_result;
  // controls
  logic PCsel;
  logic PCsel_reg;
  logic [2:0] immSel;
  logic aluop1sel;
  logic aluop2sel;
  logic brmuxsel;
  logic [1:0] WBSel;  // 00 memory dout --01 alu result --10 PC+4
  logic regfile_write_enable;
  // registers for pipeline stages
  // ============================================================================================================
  // fetch2
  logic [31:0] instruction_reg;
  // IF and IF/ID and ID/EX regs (3 stages pipe)
  logic [31:0] pcreg_pipe;
  // ID/EX registers (one stage pipe)
  logic [2:0] funct3_reg;
  logic is_branch_reg;
  logic is_slt_op_reg;
  logic is_jump_reg;
  logic br_signed_reg;
  logic load_pipe;
  logic [31:0] rd1_reg;
  logic [31:0] rd2_reg;
  logic [31:0] imm_reg;
  logic [31:0] imm_reg_f1;
  logic [31:0] imm_reg_f2;
  logic [3:0] ALUOp_reg;
  logic aluop1sel_reg;
  logic aluop2sel_reg;
  logic brmuxsel_reg;
  // EX/MEM registers (one stage pipe)
  logic [2:0] funct3_reg2;
  // logic PCsel_reg = '0';
  logic [31:0] alu_result_reg;
  logic [31:0] alu_result_reg_mem;
  logic [31:0] alu_result_reg_mem2;
  // logic slt_reg = '0';
  logic dmem_write_enable_pre;
  logic [31:0] rd2_reg2;
  // MEM/WB registers (one stage pipe)
  logic [31:0] rd2_reg2_post;
  logic [2:0] funct3_reg3;
  // logic [2:0] funct3_reg4 = '0;
  logic [31:0] alu_result_reg_wb;
  logic [1:0] WBSel_pipe;
  logic [31:0] pcplusfour_pipe;
  logic [31:0] pcplusfour_reg;
  // WB regs (three stage pipe)
  logic regfile_we_pipe;
  logic [4:0] regfile_wa_pipe;
  // 10 stage version
  logic [4:0] rs1_reg;
  logic [4:0] rs2_reg;
  logic [31:0] rd1_pipe;  // 10 stage version
  logic [31:0] rd2_pipe;  // 10 stage version
  // LR/SC
  logic sc_success;
  // logic sc_success_wb = '0;
  logic store_op;  // = '0;
  logic set_store;  // = '0;
  logic store_cond_op;
  logic load_reserved_op;
  logic store_cond_op_pipe;
  logic store_cond_op_pipe2;
  logic load_reserved_op_pipe;
  logic slt_and_not_sc_succ;  // = '0;
  logic pipe_slt_and_not_sc_succ;

  logic regfile_write_enable_reg;
  logic regfile_write_enable_post;
  logic [4:0] regfile_write_addr_reg;
  // Thread contexts management
  // =======================================================================
  always_ff @(posedge clk) begin
    thread_index_stage[1] <= thread_index_counter;
    for (int i = 2; i <= 9; i++) begin
      thread_index_stage[i] <= thread_index_stage[i-1];
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      thread_index_counter <= 0;
      start <= 0;
      start_reg <= 0;
    end else begin
      start <= 1;
      start_reg <= start;
      //thread_index_counter <= thread_index_counter + 1'b1;
      thread_index_counter <= thread_index_counter + {3'b000,start_reg};
    end
  end

  // registers and pipes for pipelined signals
  // ===================================================================================================
  // pipelined instr (IF stage)
  pipe_vec #(
      .DWIDTH(32),
      .N(1),
      .WithReset(1)
  ) instr_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(instruction),
      .o_pipelined_signal(instruction_reg)
  );
  // pipelined program counter (IF/ID stage)
  pipe_vec #(
      .DWIDTH(32),
      .N(5),
      .WithReset(1)
  ) pcreg_pipe_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(pcreg),
      .o_pipelined_signal(pcreg_pipe)
  );
  // pipelined (ID/EX stage) signals
  //---------------------------------------------------------

  pipe_vec #(
      .DWIDTH(5),
      .N(1)
  ) rs1_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(rs1),
      .o_pipelined_signal(rs1_reg)
  );
  pipe_vec #(
      .DWIDTH(5),
      .N(1)
  ) rs2_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(rs2),
      .o_pipelined_signal(rs2_reg)
  );
  pipe_vec #(
      .DWIDTH(32),
      .N(1)
  ) rd1_pipe_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(rd1),
      .o_pipelined_signal(rd1_pipe)
  );
  pipe_vec #(
      .DWIDTH(32),
      .N(1)
  ) rd2_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(rd2),
      .o_pipelined_signal(rd2_pipe)
  );
  always_comb rd1_reg = rd1_pipe;
  always_comb rd2_reg = rd2_pipe;

  //---------------------------------------------------------
  pipe_vec #(
      .DWIDTH(32),
      .N(1)
  ) imm_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(imm_out),
      .o_pipelined_signal(imm_reg)
  );
  pipe_vec #(
      .DWIDTH(32),
      .N(1)
  ) imm_reg_inst1 (
      .reset(reset),
      .clk(clk),
      .i_signal(imm_reg),
      .o_pipelined_signal(imm_reg_f1)
  );
  pipe_vec #(
      .DWIDTH(32),
      .N(1)
  ) imm_reg_inst2 (
      .reset(reset),
      .clk(clk),
      .i_signal(imm_reg),
      .o_pipelined_signal(imm_reg_f2)
  );
  pipe_sl #(
      .N(3)
  ) aluop1sel_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(aluop1sel),
      .o_pipelined_signal(aluop1sel_reg)
  );
  pipe_sl #(
      .N(3)
  ) aluop2sel_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(aluop2sel),
      .o_pipelined_signal(aluop2sel_reg)
  );
  pipe_vec #(
      .DWIDTH(4),
      .N(2)
  ) ALUOp_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(ALUOp),
      .o_pipelined_signal(ALUOp_reg)
  );
  pipe_vec #(
      .DWIDTH(3),
      .N(3)
  ) funct3_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(funct3),
      .o_pipelined_signal(funct3_reg)
  );
  pipe_sl #(
      .N(3),
      .WithReset(1)
  ) brmuxsel_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(brmuxsel),
      .o_pipelined_signal(brmuxsel_reg)
  );
  pipe_sl #(
      .N(3),
      .WithReset(1)
  ) is_branch_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(is_branch),
      .o_pipelined_signal(is_branch_reg)
  );
  pipe_sl #(
      .N(3),
      .WithReset(1)
  ) is_slt_op_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(is_slt_op),
      .o_pipelined_signal(is_slt_op_reg)
  );
  pipe_sl #(
      .N(3),
      .WithReset(1)
  ) is_jump_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(is_jump),
      .o_pipelined_signal(is_jump_reg)
  );
  pipe_sl #(
      .N(3)
  ) br_signed_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(br_signed),
      .o_pipelined_signal(br_signed_reg)
  );
  // -----------
  pipe_sl #(
      .N(7),
      .WithReset(1)
  ) load_pipe_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(load),
      .o_pipelined_signal(load_pipe)
  );
  // pipelined (EX/MEM) registers
  // PCsel_reg_inst: pipe_sl #(1) // WithReset=true
  // pipe_map (.reset=> reset, .clk => clk, .i_signal => PCsel, .o_pipelined_signal => PCsel_reg);
  // alu_result_reg_inst : pipe_vec #(32, 1)
  // pipe_map (.reset => reset, .clk => clk, .i_signal => alu_result, .o_pipelined_signal => alu_result_reg);
  pipe_vec #(
      .DWIDTH(32),
      .N(1)
  ) alu_result_reg_mem_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(alu_result_reg),
      .o_pipelined_signal(alu_result_reg_mem)
  );
  pipe_vec #(
      .DWIDTH(32),
      .N(2)
  ) rd2_reg2_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(rd2_reg),
      .o_pipelined_signal(rd2_reg2)
  );
  pipe_vec #(
      .DWIDTH(3),
      .N(2)
  ) funct3_reg2_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(funct3_reg),
      .o_pipelined_signal(funct3_reg2)
  );
  // pipelined (MEM/WB) registers
  pipe_vec #(
      .DWIDTH(32),
      .N(1)
  ) alu_result_reg_mem2_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(alu_result_reg_mem),
      .o_pipelined_signal(alu_result_reg_mem2)
  );
  pipe_vec #(
      .DWIDTH(32),
      .N(1)
  ) alu_result_reg_wb_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(alu_result_reg_mem2),
      .o_pipelined_signal(alu_result_reg_wb)
  );
  pipe_vec #(
      .DWIDTH(32),
      .N(1),
      .WithReset(1)
  ) pcplusfour_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(pcplusfour),
      .o_pipelined_signal(pcplusfour_reg)
  );
  pipe_vec #(
      .DWIDTH(32),
      .N(3)
  ) pcplusfour_pipe_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(pcplusfour_reg),
      .o_pipelined_signal(pcplusfour_pipe)
  );
  // -----------
  pipe_vec #(
      .DWIDTH(3),
      .N(2)
  ) funct3_reg3_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(funct3_reg2),
      .o_pipelined_signal(funct3_reg3)
  );
  // -----------
  pipe_vec #(
      .DWIDTH(2),
      .N(7),
      .WithReset(1)
  ) WBSel_pipe_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(WBSel),
      .o_pipelined_signal(WBSel_pipe)
  );
  // -----------
  pipe_sl #(
      .N(4),
      .WithReset(1)
  ) pre_mem_pipe_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(MemWr),
      .o_pipelined_signal(MemWr_pipe)
  );
  pipe_sl #(
      .N(1)
  ) Mem_pipe_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(MemWr_pipe),
      .o_pipelined_signal(dmem_write_enable_pre)
  );
  // -----------
  // pipelined (WB) registers
  pipe_sl #(
      .N(1),
      .WithReset(1)
  ) regfile_we_pipe_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(regfile_write_enable),
      .o_pipelined_signal(regfile_write_enable_reg)
  );
  pipe_sl #(
      .N(6),
      .WithReset(1)
  ) regfile_we_pipe_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(regfile_write_enable_post),
      .o_pipelined_signal(regfile_we_pipe)
  );
  pipe_vec #(
      .DWIDTH(5),
      .N(1)
  ) regfile_wa_pipe_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(regfile_write_addr),
      .o_pipelined_signal(regfile_write_addr_reg)
  );
  pipe_vec #(
      .DWIDTH(5),
      .N(6)
  ) regfile_wa_pipe_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(regfile_write_addr_reg),
      .o_pipelined_signal(regfile_wa_pipe)
  );
  assign regfile_write_enable_post = regfile_write_enable_reg & (|regfile_write_addr_reg);
  // component instantiations

  //-----------------------------FETCH----------------------------------------------------------------------------------
  mux2to1 PCmux_inst (
      .i_sel(PCsel_reg),
      .i_in0(pcplusfour_reg),
      .i_in1(alu_result_reg),
      .o_muxout(pc)
  );
  pcreg_vec #(DWIDTH, NUM_THREADS) reg_program_counter_inst (
      .clk(clk),
      .reset(reset),
      .i_thread_index_counter(thread_index_counter),
      .i_thread_index_execute(thread_index_stage[6]),
      .i_pc_in(pc),
      .o_pcreg_out(pcreg)
  );
  Adder32 Adder32_inst (
      .i_op1(pcreg_pipe),
      .i_op2(32'h00000004),
      .o_sum(pcplusfour)
  );
  assign o_ROM_addr = pcreg[11:2];
  always_comb instruction = (start_reg == 1'b0) ? 32'h00000000 : i_ROM_instruction;

  //-----------------------------DECODE----------------------------------------------------------------------------------
  instruction_decoder instruction_decoder_inst (
      .i_instruction(instruction_reg),
      .o_opcode(opcode),
      .o_funct3(funct3),
      .o_funct7(funct7),
      .o_rs1(rs1),
      .o_rs2(rs2),
      .o_wa(regfile_write_addr)
  );
  immsel_signext #(
      .ID(computeID(
          .varIDcluster(IDcluster), .varIDrow(IDrow), .varIDminirow(IDminirow), .varIDposx(IDposx)
      ))
  ) immsel_signext_inst (
      .clk(clk),
      .i_instruction(instruction_reg[31:7]),
      .i_imm_sel(immSel),
      .i_thread_index(thread_index_stage[2]),
      .o_imm_out(imm_out)
  );
  control_unit control_unit_inst (
      .i_opcode(opcode),
      .i_funct3(funct3),
      .i_funct7(funct7),
      .o_immSel(immSel),
      .o_brmuxsel(brmuxsel),
      .o_br_signed(br_signed),
      .o_is_branch(is_branch),
      .o_is_jump(is_jump),
      .o_aluop1sel(aluop1sel),
      .o_aluop2sel(aluop2sel),
      .o_ALUctrl(ALUctrl),
      .o_MemWr(MemWr),
      .o_regWE(regfile_write_enable),
      .o_load(load),
      .o_WBSel(WBSel),
      .o_res_station_valid(load_reserved_op),
      .o_store_cond(store_cond_op),
      .o_slt_op(is_slt_op)
  );

  // Register file
  regfile_vec register_file_vec_inst (
      .clk(clk),
      .i_thread_index_writeback(thread_index_stage[9]),
      .i_thread_index_decode(thread_index_stage[3]),
      .i_read_addr1(rs1_reg),
      .i_read_addr2(rs2_reg),
      .i_write_addr(regfile_wa_pipe),
      .i_write_data(regfile_write_data),
      .i_wr_en(regfile_we_pipe),
      .o_read_data1(rd1),
      .o_read_data2(rd2)
  );

  // ALU control unit
  alu_control alu_control_inst (
      .clk(clk),
      .i_ALUctrl(ALUctrl),
      .i_funct3(funct3),
      .i_funct7(funct7),
      .o_ALUOp(ALUOp)
  );

  //-----------------------------EXECUTE----------------------------------------------------------------------------------
  mux2to1 #(
      .MUX_DATA_WIDTH(DWIDTH)
  ) mux2to1_aluop1_inst (
      .i_sel(aluop1sel_reg),
      .i_in0(rd1_reg),
      .i_in1(pcreg_pipe),
      .o_muxout(aluop1)
  );
  mux2to1 #(
      .MUX_DATA_WIDTH(DWIDTH)
  ) mux2to1_aluop2_inst (
      .i_sel(aluop2sel_reg),
      .i_in0(rd2_reg),
      .i_in1(imm_reg_f1),
      .o_muxout(aluop2)
  );
  mux2to1 #(
      .MUX_DATA_WIDTH(DWIDTH)
  ) mux2to1_br_inputs_inst (
      .i_sel(brmuxsel_reg),
      .i_in0(rd2_reg),
      .i_in1(imm_reg_f2),
      .o_muxout(rd2_or_imm)
  );
  branch_logic branch_logic_inst (
      .i_slt_op(is_slt_op_reg),
      .i_br_signed(br_signed_reg),
      .i_is_branch(is_branch_reg),
      .i_funct3(funct3_reg),
      .i_rd1(rd1_reg),
      .i_rd2(rd2_or_imm),
      .o_slt(slt),
      .o_is_branch_valid(is_branch_valid)
  );
  always_comb PCsel = is_branch_valid | is_jump_reg;

  pipe_sl #(
      .N(1),
      .WithReset(1)
  ) PCSel_reg_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(PCsel),
      .o_pipelined_signal(PCsel_reg)
  );

  // ALU
  alu #(
      .DWIDTH(DWIDTH)
  ) ALU_inst (
      .clk(clk),
      .i_op1(aluop1),
      .i_op2(aluop2),
      .i_aluop(ALUOp_reg),
      .o_result(alu_result_reg)
  );

  //-----------------------------MEMORY----------------------------------------------------------------------------------
  reservation_set reservation_set_inst (
      .clk(clk),
      .reset(reset),
      .i_addr(alu_result_reg[13:2]),
      .i_store_op(store_op),
      .i_store_cond_op(store_cond_op_pipe),
      .i_load_reserved_op(load_reserved_op_pipe),
      .o_sc_success(sc_success)
  );

  always_comb store_op = MemWr_pipe & (~store_cond_op_pipe);
  always_comb set_store = (dmem_write_enable_pre & (~store_cond_op_pipe2)) | sc_success;

  pipe_sl #(
      .N(4),
      .WithReset(1)
  ) sc_pipe_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(store_cond_op),
      .o_pipelined_signal(store_cond_op_pipe)
  );
  pipe_sl #(
      .N(1)
  ) sc_pipe2_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(store_cond_op_pipe),
      .o_pipelined_signal(store_cond_op_pipe2)
  );
  pipe_sl #(
      .N(4),
      .WithReset(1)
  ) lr_pipe_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(load_reserved_op),
      .o_pipelined_signal(load_reserved_op_pipe)
  );

  // store_unit
  store_unit store_unit_inst (
      .i_store(set_store),
      .i_data(rd2_reg2),
      .i_addr(alu_result_reg_mem[1:0]),
      .i_funct3(funct3_reg2),
      .o_data(rd2_reg2_post),
      .o_we(dmem_write_enable_post)
  );

  // load_unit
  load_unit load_unit_inst (
      .i_load(load_pipe),
      .i_addr(alu_result_reg_wb[1:0]),
      .i_funct3(funct3_reg3),
      .i_dmem_pre(dmem_dout_pre),
      .o_dmem_post(dmem_dout_post)
  );

  assign o_dmem_addr = alu_result_reg_mem[15:2];
  assign o_dmem_write_data = rd2_reg2_post;
  assign o_dmem_write_enable = dmem_write_enable_post;

  always_ff @(posedge clk) begin
    dmem_dout_pre <= i_dmem_read_data;
  end

  always_comb slt_and_not_sc_succ = slt & (~sc_success);

  pipe_sl #(
      .N(2)
  ) pipe_slt_and_not_sc_succ_inst (
      .reset(reset),
      .clk(clk),
      .i_signal(slt_and_not_sc_succ),
      .o_pipelined_signal(pipe_slt_and_not_sc_succ)
  );

  //-------------------------------WRITE-BACK-----------------------------------
  mux4to1 #(
      .MUX_DATA_WIDTH(DWIDTH)
  ) mux4to1_WB_inst (
      .i_sel(WBSel_pipe),
      .i_in0(dmem_dout_post),
      .i_in1(alu_result_reg_wb),
      .i_in2(pcplusfour_pipe),
      .i_in3({31'b0, pipe_slt_and_not_sc_succ}),
      .o_muxout(regfile_write_data)
  );
  // Regfile signals for debug
  assign regfile_wr_addr = regfile_wa_pipe;
  assign regfile_wr_data = regfile_write_data;
  assign regfile_wr_en = regfile_we_pipe;
  assign thread_index_wb = thread_index_stage[9];
  assign thread_index_wrmem = thread_index_stage[6];

endmodule

