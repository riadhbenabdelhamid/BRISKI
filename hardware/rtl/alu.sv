`include "riscv_pkg.sv"
module alu #(
    parameter bool ENABLE_UNIFIED_BARREL_SHIFTER = true,
    parameter ALUOP_WIDTH = 4,
    DWIDTH = 32,
    PIPE_STAGE0 = 0,
    PIPE_STAGE1 =0,
    PIPE_STAGE2 =1
) (
    input logic clk,
    input logic [DWIDTH-1:0] i_op1,
    input logic [DWIDTH-1:0] i_op2,
    input logic [ALUOP_WIDTH-1:0] i_aluop,
    output logic [DWIDTH-1:0] o_result
);

  logic [DWIDTH-1:0] op1;
  logic [DWIDTH-1:0] op2;
  logic [ALUOP_WIDTH-1:0] aluop;

  logic [DWIDTH-1:0] result_add;
  logic [DWIDTH-1:0] result_sll;
  logic [DWIDTH-1:0] result_xor;
  logic [DWIDTH-1:0] result_or;
  logic [DWIDTH-1:0] result_and;
  logic [DWIDTH-1:0] result_pass;

  logic [DWIDTH-1:0] result_srl_sra;
  logic [4:0] shamt;
  logic [DWIDTH:0] temp;
  logic [DWIDTH-1:0] mask;

  logic [DWIDTH-1:0] op2_negated_or_not; // negate second operand when aluop is sub

  logic [DWIDTH-1:0] swapped_op1;
  logic [DWIDTH-1:0] reswapped_op1;
  logic [DWIDTH-1:0] temp_trim;
//-----------------------------------------------------------------------
//   FIRST PIPE STAGE 
//-----------------------------------------------------------------------
  if (PIPE_STAGE0 == 1) begin : first_stage_registered
  //-------------------------------------------------
    always_ff @(posedge clk) begin
      op2_negated_or_not <= i_op2 ^ {DWIDTH{i_aluop[0]}};  // xored with zeros when aluop is add (aluop[0]=0) else xored with ones
      shamt <= i_op2[4:0];
      op1 <= i_op1;
      op2 <= i_op2;
      aluop <= i_aluop;
    end 

    if (ENABLE_UNIFIED_BARREL_SHIFTER == true) begin : first_registered_left_right_shifts_shared_logic
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      always_ff @(posedge clk) begin
        swapped_op1 <= (i_aluop == SLL_OP)? reverse_bits(i_op1) : i_op1;
      end 
    end

  end else begin : first_stage_not_registered
  //-------------------------------------------------
    assign op2_negated_or_not = i_op2 ^ {DWIDTH{i_aluop[0]}};  // xored with zeros when aluop is add (aluop[0]=0) else xored with ones
    assign shamt = i_op2[4:0];
    assign op1 = i_op1;
    assign op2 = i_op2;
    assign aluop = i_aluop;

    if (ENABLE_UNIFIED_BARREL_SHIFTER == true) begin : first_not_registered_left_right_shifts_shared_logic
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      assign swapped_op1 = (i_aluop == SLL_OP)? reverse_bits(i_op1) : i_op1;
    end

  end


//-----------------------------------------------------------------------
//   SECOND PIPE STAGE 
//-----------------------------------------------------------------------
  if (PIPE_STAGE1 == 1) begin : second_stage_registered
  //-------------------------------------------------
    always_ff @(posedge clk) begin
      result_add <= (aluop == ADD_OP || aluop == SUB_OP) ? op1 + op2_negated_or_not + {{(DWIDTH-1){1'b0}},aluop[0]} : 0;   //i_aluop[0] is 1 for sub and 0 for add
      result_xor <= (aluop == XOR_OP) ? op1 ^ op2 : 0;
      result_or <= (aluop == OR_OP) ? op1 | op2 : 0;
      result_and <= (aluop == AND_OP) ? op1 & op2 : 0;
      result_pass <= (aluop == PASS_OP) ? op2 : 0;
    end


    if (ENABLE_UNIFIED_BARREL_SHIFTER == true) begin : second_registered_left_right_shifts_shared_logic
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      assign temp = ($signed({(aluop[0] & swapped_op1[DWIDTH-1]),swapped_op1}) >>> shamt);
      assign temp_trim = temp [DWIDTH-1:0];
      always_ff @(posedge clk) begin
        result_srl_sra <= (aluop == SRL_OP || aluop == SRA_OP ) ? temp_trim : 0;
        result_sll <= (aluop == SLL_OP) ? reverse_bits(temp_trim) : 0;
      end

    end else begin : second_registered_separate_left_right_shifters
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      assign temp = ($signed({(aluop[0] & op1[DWIDTH-1]),op1}) >>> shamt);
      assign temp_trim = temp [DWIDTH-1:0];
      always_ff @(posedge clk) begin
        result_srl_sra <= (aluop == SRL_OP || aluop == SRA_OP) ? temp_trim : 0;
        result_sll <= (aluop == SLL_OP) ? op1 << shamt : 0;
      end
    end

  end else begin : second_stage_not_registered
  //-------------------------------------------------
    always_comb begin
      result_add = (aluop == ADD_OP || aluop == SUB_OP) ? op1 + op2_negated_or_not + {{(DWIDTH-1){1'b0}},aluop[0]} : 0;   //i_aluop[0] is 1 for sub and 0 for add
      result_xor = (aluop == XOR_OP) ? op1 ^ op2 : 0;
      result_or = (aluop == OR_OP) ? op1 | op2 : 0;
      result_and = (aluop == AND_OP) ? op1 & op2 : 0;
      result_pass = (aluop == PASS_OP) ? op2 : 0;
    end


    if (ENABLE_UNIFIED_BARREL_SHIFTER == true) begin : second_not_registered_left_right_shifts_shared_logic
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      always_comb begin
        temp = ($signed({(aluop[0] & swapped_op1[DWIDTH-1]),swapped_op1}) >>> shamt);
        temp_trim = temp [DWIDTH-1:0];
        result_srl_sra = (aluop == SRL_OP || aluop == SRA_OP ) ? temp_trim : 0;
        result_sll = (aluop == SLL_OP) ? reverse_bits(temp_trim) : 0;
      end

    end else begin : second_not_registered_separate_left_right_shifters
    //++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      always_comb begin
        temp = ($signed({(aluop[0] & op1[DWIDTH-1]),op1}) >>> shamt);
        temp_trim = temp [DWIDTH-1:0];
        result_srl_sra = (aluop == SRL_OP || aluop == SRA_OP) ? temp_trim : 0;
        result_sll = (aluop == SLL_OP) ? op1 << shamt : 0;
      end
    end

  end
//-----------------------------------------------------------------------
//   THIRD PIPE STAGE 
//-----------------------------------------------------------------------
  if (PIPE_STAGE2 == 1) begin : third_stage_registered
  //-------------------------------------------------
    always_ff @(posedge clk) 
         //o_result <= result_add ^ result_sll ^ result_xor ^ result_srl_sra ^ result_or ^ result_and ^ result_pass;
         o_result <= result_add | result_sll | result_xor | result_srl_sra | result_or | result_and | result_pass;

  end else begin : third_stage_not_registered
  //-------------------------------------------------
    always_comb 
         //o_result = result_add ^ result_sll ^ result_xor ^ result_srl_sra ^ result_or ^ result_and ^ result_pass;
         o_result = result_add | result_sll | result_xor | result_srl_sra | result_or | result_and | result_pass;

  end

endmodule

