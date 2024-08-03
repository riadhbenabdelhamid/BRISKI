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
  // ...
  function logic [10:0] computeID(input int varIDcluster, varIDrow, varIDminirow, varIDposx);
    logic [10:0] varID;
    varID[10:0]  = {varIDcluster[3:0], varIDrow[1:0], 5'({((varIDminirow * 6) + varIDposx)})};
    return varID;
  endfunction
  //------------------- threads context
  logic [$clog2(NUM_THREADS)-1:0] thread_index_stage [1:9];  // pipelined thread counter used for pc update and writeback on the different register files
  logic [$clog2(NUM_THREADS)-1:0] thread_index_counter;  // current thread counter
  logic start;  // to delay first instruction one clock cycle after reset
  logic start_reg;  // to delay first instruction one clock cycle after reset
//=================================================================================================================
// fetch stage signals
//=================================================================================================================

    // FETCH stage 1
    //-----------------
    // PCmux for next PC signal (PCplusfour or (br, jabs, rind that are all coming from ALU result))
    //----------------------------------------------------------------------------------------------------
    logic                   PCsel_reg;
    logic [31:0]            pc;

    // Send address to instruction ROM and get back the corresponding output instruction
    logic [31:0]            pcreg;

    // FETCH stage 2
    //-----------------
    logic [31:0]            instruction;

//=================================================================================================================
// decode stage signals
//=================================================================================================================

    // DECODE STAGE 1 
    //-----------------------------------

    // Instruction decoder signals
    logic [31:0]            instruction_reg;
    logic [4:0]             rs1;
    logic [4:0]             rs2;
    logic [4:0]             regfile_write_addr;

    // Control unit signals
    logic [6:0]             opcode;
    logic [2:0]             funct3;
    logic [6:0]             funct7;
    logic [2:0]             immSel;
    logic                   brmuxsel;
    logic                   br_signed;
    logic                   is_branch;
    logic                   is_jump;
    logic                   aluop1sel;
    logic                   aluop2sel;
    logic [1:0]             ALUctrl;
    logic                   MemWr;
    logic                   regfile_write_enable;
    logic                   load;
    logic [1:0]             WBSel;  // 00 memory dout, 01 alu result, 10 PC+4
    logic                   load_reserved_op;
    logic                   store_cond_op;
    logic                   is_slt_op;

    // DECODE STAGE 2 
    //-----------------------------------
    logic [4:0]             regfile_write_addr_reg;
    logic                   regfile_write_enable_reg;
    logic                   regfile_write_enable_post;
    // Registerfile
    logic [4:0]             rs1_reg;
    logic [4:0]             rs2_reg;

    // Immediate selection (and sign extension) signals
    logic [31:0]            imm_out;

    // ALU control unit
    logic [ALUOP_WIDTH-1:0] ALUOp;

    // DECODE STAGE 3 
    //-----------------------------------
    logic [31:0]            imm_reg;

    // Registerfile
    logic [31:0]            rd1;
    logic [31:0]            rd2;

//=================================================================================================================
// execute stage signals
//=================================================================================================================

    // EX STAGE 1 
    //-----------------------------------
    logic                   is_jump_reg;
    logic                   PCsel;

    // Regfile
    // logic rs1_reg2;
    // logic rs2_reg2;

    logic [31:0]            rd1_pipe;
    logic [31:0]            rd2_pipe;

    logic [31:0]            rd1_reg;
    logic [31:0]            rd2_reg;

    // Branch logic
    logic                   is_slt_op_reg;
    logic                   br_signed_reg;
    logic                   is_branch_reg;
    logic [2:0]             funct3_reg;
    logic [31:0]            rd2_or_imm;
    logic                   slt;
    logic                   is_branch_valid;

    // First operand inputs mux
    logic                   aluop1sel_reg;
    logic [31:0]            imm_reg_f1;
    logic [31:0]            aluop1;

    // Second operand inputs mux
    logic                   aluop2sel_reg;
    logic [31:0]            imm_reg_f2;
    logic [31:0]            aluop2;

    // Second operand inputs mux (for branch logic but also for SLT and SLTU instructions. The principle is to share the logic with BLT and BLTU)
    logic                   brmuxsel_reg;

    // ALU signals
    logic [3:0]             ALUOp_reg;

    // Next pc logic (pc+4)
    logic [31:0]            pcplusfour;
    logic [31:0]            pcreg_pipe;

//=================================================================================================================
// memory stage signals
//=================================================================================================================

    // MEM stage 1
    // ---------------
    // Reservation set
    logic [31:0]            alu_result_reg;
    logic                   MemWr_pipe;
    logic                   store_cond_op_pipe;
    logic                   store_op;
    logic                   load_reserved_op_pipe;

    logic [31:0]            pcplusfour_reg;
    // MEM stage 2
    //---------------

    // Reservation set (LR/SC)
    logic                   sc_success;
    logic                   dmem_write_enable_pre;
    logic                   set_store;
    logic                   store_cond_op_pipe2;
    logic                   slt_and_not_sc_succ;

    logic                   slt_reg;

    // Store unit
    logic [31:0]            rd2_reg2;
    logic [31:0]            alu_result_reg_mem;
    logic [2:0]             funct3_reg2;
    logic [31:0]            rd2_reg2_post;
    logic [3:0]             dmem_write_enable_post;  // One bit per byte in word

    // MEM stage 3
    //---------------
    logic [31:0]            alu_result_reg_mem2;

//=================================================================================================================
// WB stage signals
//=================================================================================================================

    // WB stage 1
    //--------------

    // Load unit
    logic [2:0]             funct3_reg3;
    logic [31:0]            alu_result_reg_wb;
    logic                   load_pipe;
    logic [31:0]            dmem_dout_pre;
    logic [31:0]            dmem_dout_post;

    // LR/SC
    logic                   pipe_slt_and_not_sc_succ;

    // WB mux
    logic [1:0]             WBSel_pipe;
    logic [31:0]            pcplusfour_pipe;
    logic [31:0]            regfile_write_data;

    logic                   regfile_we_pipe;
    logic [4:0]             regfile_wa_pipe;

//=================================================================================================================

  //logic regfile_write_enable_reg;
  //logic regfile_write_enable_post;
  //logic [4:0] regfile_write_addr_reg;
  //
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
  //===================================================================
//=================================================================================================================
// --------------------------  FETCH stages components  -----------------------------------------------------------
//=================================================================================================================

//-------------------------------- FETCH stage 1 ------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------

// Multiplexer for next PC signal (PCplusfour or (br, jabs, rind that are all coming from ALU result))
//----------------------------------------------------------------------------------------------------
mux2to1 mux2to1_PCmux_inst (
    .i_sel(PCsel_reg),
    .i_in0(pcplusfour_reg),
    .i_in1(alu_result_reg),
    .o_muxout(pc)
);

// Register the PC address
//-------------------------
pcreg_vec reg_program_counter_inst (
    .clk(clk),
    .reset(reset),
    .i_thread_index_counter(thread_index_counter),
    .i_thread_index_execute(thread_index_stage[6]),
    .i_pc_in(pc),
    .o_pcreg_out(pcreg)
);

// Send address to instruction ROM and get back the corresponding output instruction
//----------------------------------------------------------------------------------
assign o_ROM_addr = pcreg[11:2];

//-------------------------------- FETCH stage 2 ------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------

assign instruction = (start_reg == 1'b0) ? 32'b0 : i_ROM_instruction;

//=================================================================================================================
// ---------------------------  DECODE stages components  ---------------------------------------------------------
//=================================================================================================================

//-------------------------------- DECODE stage 1 -----------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------

// Pipelined instruction
//--------------------------------
pipe_vec #(.DWIDTH(32), .N(1), .WithReset(true)) instr_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(instruction),
    .o_pipelined_signal(instruction_reg)
);

// Decoder for instruction fields
//--------------------------------
instruction_decoder instruction_decoder_inst (
    .i_instruction(instruction_reg),
    .o_opcode(opcode),
    .o_funct3(funct3),
    .o_funct7(funct7),
    .o_rs1(rs1),
    .o_rs2(rs2),
    .o_wa(regfile_write_addr)
);

// Select immediate and sign extend it
//-------------------------------------
immsel_signext immsel_signext_inst (
    .clk(clk),
    .i_instruction(instruction_reg[31:7]),
    .i_imm_sel(immSel),
    .i_thread_index(thread_index_stage[2]),
    .o_imm_out(imm_out)
);

// Generator for control signals
//---------------------------------
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

// Pipelined register for write enable signal
//---------------------------------------------
pipe_sl #(.N(1), .WithReset(true)) regfile_we_pipe_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(regfile_write_enable),
    .o_pipelined_signal(regfile_write_enable_reg)
);

// Pipelined register for write address
//---------------------------------------
pipe_vec #(.DWIDTH(5), .N(1)) regfile_wa_pipe_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(regfile_write_addr),
    .o_pipelined_signal(regfile_write_addr_reg)
);

// Determine final write enable signal
assign regfile_write_enable_post = regfile_write_enable_reg && |regfile_write_addr_reg;
//=================================================================================================================
// ---------------------------  DECODE stages components  ---------------------------------------------------------
//=================================================================================================================

//-------------------------------- DECODE stage 2 -----------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------

// Pipelined register for rs1
pipe_vec #(.DWIDTH(5), .N(1)) rs1_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(rs1),
    .o_pipelined_signal(rs1_reg)
);

// Pipelined register for rs2
pipe_vec #(.DWIDTH(5), .N(1)) rs2_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(rs2),
    .o_pipelined_signal(rs2_reg)
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

//-------------------------------- DECODE stage 3 -----------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------

// Pipelined register for imm_out
pipe_vec #(.DWIDTH(32), .N(1)) imm_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(imm_out),
    .o_pipelined_signal(imm_reg)
);
//=================================================================================================================
// ----------------------------  EXECUTE stages components  -------------------------------------------------------
//=================================================================================================================

//-------------------------------- EXECUTE stage 1 ----------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------

// Pipelined registers for imm_reg signals
pipe_vec #(.DWIDTH(32), .N(1)) imm_reg_inst1 (
    .reset(reset),
    .clk(clk),
    .i_signal(imm_reg),
    .o_pipelined_signal(imm_reg_f1)
);

pipe_vec #(.DWIDTH(32), .N(1)) imm_reg_inst2 (
    .reset(reset),
    .clk(clk),
    .i_signal(imm_reg),
    .o_pipelined_signal(imm_reg_f2)
);

// Generate block for register file with conditional BRAM or distributed memory
        // Pipelined registers for rd1 and rd2 when using BRAM
        pipe_vec #(.DWIDTH(32), .N(1)) rd1_pipe_inst (
            .reset(reset),
            .clk(clk),
            .i_signal(rd1),
            .o_pipelined_signal(rd1_pipe)
        );

        pipe_vec #(.DWIDTH(32), .N(1)) rd2_reg_inst (
            .reset(reset),
            .clk(clk),
            .i_signal(rd2),
            .o_pipelined_signal(rd2_pipe)
        );

        // Assignments for registered outputs with BRAM
        assign rd1_reg = rd1_pipe; // Conditional assignment commented out as per VHDL source
        assign rd2_reg = rd2_pipe; // Conditional assignment commented out as per VHDL source
//---------------------------------------------------------
// ----------------------------  EXECUTE stages components  -------------------------------
//---------------------------------------------------------

//-------------------------------- EXECUTE stage 2 ----------------------------------------
//-----------------------------------------------------------------------------------------

// Pipelined program counter for pc+4 computation in EXE stage
pipe_vec #(.DWIDTH(32), .N(5), .WithReset(1)) pcreg_pipe_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(pcreg),
    .o_pipelined_signal(pcreg_pipe)
);

pipe_sl #(.N(3)) aluop1sel_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(aluop1sel),
    .o_pipelined_signal(aluop1sel_reg)
);

mux2to1 #(.MUX_DATA_WIDTH(DWIDTH)) mux2to1_aluop1_inst (
    .i_sel(aluop1sel_reg),
    .i_in0(rd1_reg),
    .i_in1(pcreg_pipe),
    .o_muxout(aluop1)
);

// Second operand inputs mux
pipe_sl #(.N(3)) aluop2sel_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(aluop2sel),
    .o_pipelined_signal(aluop2sel_reg)
);

mux2to1 #(.MUX_DATA_WIDTH(DWIDTH)) mux2to1_aluop2_inst (
    .i_sel(aluop2sel_reg),
    .i_in0(rd2_reg),
    .i_in1(imm_reg_f1),
    .o_muxout(aluop2)
);

// Mux for branch logic and SLT/SLTU instructions
pipe_sl #(.N(3), .WithReset(1)) brmuxsel_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(brmuxsel),
    .o_pipelined_signal(brmuxsel_reg)
);

mux2to1 #(.MUX_DATA_WIDTH(DWIDTH)) mux2to1_br_inputs_inst (
    .i_sel(brmuxsel_reg),
    .i_in0(rd2_reg),
    .i_in1(imm_reg_f2),
    .o_muxout(rd2_or_imm)
);

// Branch logic
pipe_sl #(.N(3), .WithReset(1)) is_slt_op_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(is_slt_op),
    .o_pipelined_signal(is_slt_op_reg)
);

pipe_sl #(.N(3), .WithReset(1)) is_jump_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(is_jump),
    .o_pipelined_signal(is_jump_reg)
);

pipe_sl #(.N(3)) br_signed_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(br_signed),
    .o_pipelined_signal(br_signed_reg)
);

pipe_sl #(.N(3), .WithReset(1)) is_branch_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(is_branch),
    .o_pipelined_signal(is_branch_reg)
);

pipe_vec #(.DWIDTH(3), .N(3)) funct3_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(funct3),
    .o_pipelined_signal(funct3_reg)
);

//branch_logic #(.DWIDTH(DWIDTH)) branch_logic_inst (
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

assign PCsel = is_branch_valid | is_jump_reg;

// ALU
pipe_vec #(.DWIDTH(4), .N(2)) ALUOp_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(ALUOp),
    .o_pipelined_signal(ALUOp_reg)
);

alu #(.ALUOP_WIDTH(ALUOP_WIDTH), .DWIDTH(DWIDTH)) ALU_inst (
    .clk(clk),
    .i_op1(aluop1),
    .i_op2(aluop2),
    .i_aluop(ALUOp_reg),
    .o_result(alu_result_reg)
);

// Next PC address (pc+4)
Adder32 Adder32_inst (
    .i_op1(pcreg_pipe),
    .i_op2(32'h00000004),  // The +4 is delayed until EX stage to save registers
    .o_sum(pcplusfour)     // The pc will be written before its thread is accessed again
);
//=================================================================================================================
// --------------------------------  MEMORY stages components  ----------------------------------------------------
//=================================================================================================================

//----------------------------- MEMORY stage 1 --------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------

// PC mux selector
pipe_sl #(.N(1), .WithReset(1)) PCSel_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(PCsel),
    .o_pipelined_signal(PCsel_reg)
);

pipe_vec #(.DWIDTH(32), .N(1), .WithReset(1)) pcplusfour_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(pcplusfour),
    .o_pipelined_signal(pcplusfour_reg)
);

// Reservation set for ATOMIC LR/SC
// LR Load Reserved : Register a reservation set RESERV_SET (1 bit valid + 32-bit address of the word being loaded)
// SC Store Conditional: 
//  1) Try to write the word in rs2 to the memory address in rs1 (when RESERV_SET.valid is 1 and RESERV_SET.lraddr is same as rs2)
//  2) Invalidates the reservation set (valid bit reset to '0')
//  3) Successful SC write will do 1) and write 0 to rd, UNSUCCESSFUL SC does not do 1) but writes 1 to rd.
pipe_sl #(.N(4), .WithReset(1)) sc_pipe_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(store_cond_op),
    .o_pipelined_signal(store_cond_op_pipe)
);

pipe_sl #(.N(4), .WithReset(1)) lr_pipe_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(load_reserved_op),
    .o_pipelined_signal(load_reserved_op_pipe)
);

reservation_set reservation_set_inst (
    .clk(clk),
    .reset(reset),
    .i_addr(alu_result_reg[13:2]),
    .i_store_op(store_op),
    .i_store_cond_op(store_cond_op_pipe),
    .i_load_reserved_op(load_reserved_op_pipe),
    .i_mhartid(thread_index_stage[6]),
    .o_sc_success(sc_success)
);

pipe_sl #(.N(2)) slt_reg_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(slt),
    .o_pipelined_signal(slt_reg)
);

assign slt_and_not_sc_succ = slt_reg & (~sc_success);

// Pre-data memory write
pipe_sl #(.N(4), .WithReset(1)) pre_mem_pipe_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(MemWr),
    .o_pipelined_signal(MemWr_pipe)
);

assign store_op = MemWr_pipe & (~store_cond_op_pipe);
//=================================================================================================================
// --------------------------------  MEMORY stages components  ----------------------------------------------------
//=================================================================================================================

//----------------------------- MEMORY stage 2 --------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------

pipe_vec #(.DWIDTH(32), .N(1)) alu_result_reg_mem_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(alu_result_reg),
    .o_pipelined_signal(alu_result_reg_mem)
);

pipe_sl #(.N(1)) sc_pipe2_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(store_cond_op_pipe),
    .o_pipelined_signal(store_cond_op_pipe2)
);

pipe_vec #(.DWIDTH(32), .N(2)) rd2_reg2_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(rd2_reg),
    .o_pipelined_signal(rd2_reg2)
);

// Data memory write
pipe_sl #(.N(1), .WithReset(0)) Mem_pipe_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(MemWr_pipe),
    .o_pipelined_signal(dmem_write_enable_pre)
);

assign set_store = (dmem_write_enable_pre & (~store_cond_op_pipe2)) | sc_success;

pipe_vec #(.DWIDTH(3), .N(2)) funct3_reg2_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(funct3_reg),
    .o_pipelined_signal(funct3_reg2)
);

// Store unit
store_unit store_unit_inst (
    .i_store(set_store),
    .i_data(rd2_reg2),
    .i_addr(alu_result_reg_mem[1:0]),
    .i_funct3(funct3_reg2),
    .o_data(rd2_reg2_post),
    .o_we(dmem_write_enable_post)
);

assign o_dmem_addr = alu_result_reg_mem[15:2]; // 2 LSB bits ignored, next 14 bits address data memory/MMIO/URAM
assign o_dmem_write_data = rd2_reg2_post;
assign o_dmem_write_enable = dmem_write_enable_post;

//----------------------------- MEMORY stage 3 --------------------------------------------------------------------
//-----------------------------------------------------------------------------------------------------------------

pipe_vec #(.DWIDTH(32), .N(1)) alu_result_reg_mem2_inst (
    .reset(reset),
    .clk(clk),
    .i_signal(alu_result_reg_mem),
    .o_pipelined_signal(alu_result_reg_mem2)
);
//=================================================================================================================
// ------------------     WRITE-BACK stage components -------------------------------------------------------------
//=================================================================================================================

    // Data Memory Read Data Register
    always_ff @(posedge clk) begin
        if (reset) begin
            dmem_dout_pre <= 32'b0;
        end else begin
            dmem_dout_pre <= i_dmem_read_data;
        end
    end

    // Pipeline Registers
    pipe_sl #(.N(7), .WithReset(1)) load_pipe_inst (
        .reset(reset),
        .clk(clk),
        .i_signal(load),
        .o_pipelined_signal(load_pipe)
    );

    pipe_vec #(.DWIDTH(3), .N(2)) funt3_reg3_inst (
        .reset(reset),
        .clk(clk),
        .i_signal(funct3_reg2),
        .o_pipelined_signal(funct3_reg3)
    );

    pipe_vec #(.DWIDTH(32), .N(1)) alu_result_reg_wb_inst (
        .reset(reset),
        .clk(clk),
        .i_signal(alu_result_reg_mem2),
        .o_pipelined_signal(alu_result_reg_wb)
    );

    pipe_sl #(.N(6), .WithReset(1)) regfile_we_pipe_inst (
        .reset(reset),
        .clk(clk),
        .i_signal(regfile_write_enable_post),
        .o_pipelined_signal(regfile_we_pipe)
    );

    pipe_vec #(.DWIDTH(5), .N(6)) regfile_wa_pipe_inst (
        .reset(reset),
        .clk(clk),
        .i_signal(regfile_write_addr_reg),
        .o_pipelined_signal(regfile_wa_pipe)
    );

    pipe_vec #(.DWIDTH(2), .N(7), .WithReset(1)) WBSel_pipe_inst (
        .reset(reset),
        .clk(clk),
        .i_signal(WBSel),
        .o_pipelined_signal(WBSel_pipe)
    );

    pipe_vec #(.DWIDTH(32), .N(3), .WithReset(0)) pcplusfour_pipe_inst (
        .reset(reset),
        .clk(clk),
        .i_signal(pcplusfour_reg),
        .o_pipelined_signal(pcplusfour_pipe)
    );

    pipe_sl #(.N(2)) pipe_slt_and_not_sc_succ_inst (
        .reset(reset),
        .clk(clk),
        .i_signal(slt_and_not_sc_succ),
        .o_pipelined_signal(pipe_slt_and_not_sc_succ)
    );

    // Load Unit
    load_unit load_unit_inst (
        .i_load(load_pipe),
        .i_addr(alu_result_reg_wb[1:0]),
        .i_funct3(funct3_reg3),
        .i_dmem_pre(dmem_dout_pre),
        .o_dmem_post(dmem_dout_post)
    );

    // WB MUX
    mux4to1 #(.MUX_DATA_WIDTH(32)) mux4to1_WB_inst (
        .i_sel(WBSel_pipe),
        .i_in0(dmem_dout_post),
        .i_in1(alu_result_reg_wb),
        .i_in2(pcplusfour_pipe),
        .i_in3({pipe_slt_and_not_sc_succ, 31'b0}),
        .o_muxout(regfile_write_data)
    );

  //===================================================================
  // Regfile signals for debug
  assign regfile_wr_addr = regfile_wa_pipe;
  assign regfile_wr_data = regfile_write_data;
  assign regfile_wr_en = regfile_we_pipe;
  assign thread_index_wb = thread_index_stage[9];
  assign thread_index_wrmem = thread_index_stage[6];

endmodule
