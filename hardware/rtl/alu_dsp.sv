/* verilator lint_off PINCONNECTEMPTY */

`include "riscv_pkg.sv"
module alu_dsp #(
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

  logic [DWIDTH-1:0] result_sll;
  logic [DWIDTH-1:0] result_srl_sra;
  logic [4:0] shamt;
  logic [DWIDTH:0] temp;
  // DSP48E2 signals
  logic [29:0] A;            // 30 bits
  logic [17:0] B;            // 18 bits
  logic [47:0] C;            // 48 bits
  logic [26:0] D;            // 27 bits
  logic [47:0] P;            // 48 bits
  logic [4:0]  INMODE;       // 5 bits
  logic [8:0]  OPMODE;       // 9 bits
  logic [3:0]  ALUMODE;      // 4 bits
  logic [DWIDTH-1:0] result_dsp; // DWIDTH bits (user-defined width)


  logic [DWIDTH-1:0] swapped_op1;
  logic [DWIDTH-1:0] temp_trim;
   //-----------------------------------------------------------------------
  //   Barrel Shifter Path 
  //-----------------------------------------------------------------------
//-----------------------------------------------------------------------
//   FIRST PIPE STAGE 
//-----------------------------------------------------------------------
  if (PIPE_STAGE0 == 1) begin : first_stage_registered
  //-------------------------------------------------
    always_ff @(posedge clk) begin
      shamt <= i_op2[4:0];
      op1 <= i_op1;
      op2 <= i_op2;
      aluop <= i_aluop;
    end 

    if (ENABLE_UNIFIED_BARREL_SHIFTER == true) begin : first_registered_left_right_shifts_shared_logic
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      always_ff @(posedge clk) begin
        //swapped_op1 <= (i_aluop == SLL_OP)? reverse_bits(i_op1) : i_op1;
        swapped_op1 <= (~i_aluop[2])? reverse_bits(i_op1) : i_op1;
      end 
    end

  end else begin : first_stage_not_registered
  //-------------------------------------------------
    assign shamt = i_op2[4:0];
    assign op1 = i_op1;
    assign op2 = i_op2;
    assign aluop = i_aluop;

    if (ENABLE_UNIFIED_BARREL_SHIFTER == true) begin : first_not_registered_left_right_shifts_shared_logic
    //+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
      //assign swapped_op1 = (i_aluop == SLL_OP)? reverse_bits(i_op1) : i_op1;
      assign swapped_op1 = (~i_aluop[2])? reverse_bits(i_op1) : i_op1;
    end

  end


//-----------------------------------------------------------------------
//   SECOND PIPE STAGE 
//-----------------------------------------------------------------------
  if (PIPE_STAGE1 == 1) begin : second_stage_registered
  //-------------------------------------------------

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
         o_result <= result_sll | result_dsp | result_srl_sra;

  end else begin : third_stage_not_registered
  //-------------------------------------------------
    always_comb 
         o_result = result_sll | result_dsp | result_srl_sra;

  end

   //-----------------------------------------------------------------------
  //   DSP Path : OPMODE and ALUMODE control
  //-----------------------------------------------------------------------
  always_comb begin
    // OPMODE[8:7] must be set to "00" for default all 0s values at W mux out
    // OPMODE[6:4] selects Z mux out
    // OPMODE[3:2] must be set to "00" for default all 0s values at Y mux out
    // OPMODE[3:2] must be set to "10" for default all 1s values at Y mux out
    // OPMODE[1:0] selects X mux out

    case (i_aluop)
      ADD_OP: begin
        ALUMODE = 4'b0000;        // Z+(W+X+Y+CIN)
        OPMODE  = 9'b000110011;   // X=A:B , Z=C
      end
      SUB_OP: begin
        ALUMODE = 4'b0011;        // Z-(W+X+Y+CIN)
        OPMODE  = 9'b000110011;   // X=A:B , Z=C
      end
      XOR_OP: begin
        ALUMODE = 4'b0100;
        OPMODE  = 9'b000110011;   // X=A:B , Z=C
      end
      OR_OP: begin
        ALUMODE = 4'b1100;
        OPMODE  = 9'b000111011;   // X=A:B , Z=C
      end
      AND_OP: begin
        ALUMODE = 4'b1100;
        OPMODE  = 9'b000110011;   // X=A:B , Z=C
      end
      PASS_OP: begin
        ALUMODE = 4'b0000;        // or instr
        OPMODE  = 9'b000000011;   // X=A:B and Z=0 => will pass X (i_op2)
      end
      default: begin
        ALUMODE = 4'b1100;        // or instr
        OPMODE  = 9'b000000000;   // X=0, Z=0 => should pass a 0 as default
      end
    endcase
  end

  //-----------------------------------------------------------------------
  //   DSP inputs
  //-----------------------------------------------------------------------
  // A <= (A'high downto 15=>'0', i_op2(31 downto 18)); -- unsigned
  assign A[29:14] = {16{i_op2[31]}}; // sign extend
  assign A[13:0]  = i_op2[31:18];
  assign B        = i_op2[17:0];

  // C <= (C'high downto 32=>'0',i_op1(31 downto 0); -- unsigned
  assign C[47:32] = {16{i_op1[31]}}; // sign extend
  assign C[31:0]  = i_op1[31:0];
  assign D        = 27'b0;
  //assign D        = i_op1[26:0];
  assign INMODE   = 5'b0;            // internal pipeline registers A2 and B2
  //assign INMODE   = {PIPE_STAGE0, 3'b0, PIPE_STAGE0};            // internal pipeline registers for A1 and B1
  assign result_dsp = P[31:0];

 // logic [31:0] result_dsp0;
  //always_ff @(posedge clk)  begin
    //  result_dsp <= P[31:0];
      //result_dsp0 <= P[31:0];
      //result_dsp <= result_dsp0;
  //end

//   DSP48E2   : In order to incorporate this function into the design,
//   Verilog   : the following instance declaration needs to be placed
//  instance   : in the body of the design code.  The instance name
// declaration : (DSP48E2_inst) and/or the port declarations within the
//    code     : parenthesis may be changed to properly reference and
//             : connect this function to the design.  All inputs
//             : and outputs must be connected.

//  <-----Cut code below this line---->

   // DSP48E2: 48-bit Multi-Functional Arithmetic Block
   //          Virtex UltraScale+
   // Xilinx HDL Language Template, version 2022.1

DSP48E2 #(
      // Feature Control Attributes: Data Path Selection
      .AMULTSEL("A"),                    // Selects A input to multiplier (A, AD)
      .A_INPUT("DIRECT"),                // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
      .BMULTSEL("B"),                    // Selects B input to multiplier (AD, B)
      .B_INPUT("DIRECT"),                // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
      .PREADDINSEL("A"),                 // Selects input to pre-adder (A, B)
      .RND(48'h000000000000),            // Rounding Constant
      //.USE_MULT("MULTIPLY"),             // Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
      .USE_MULT("NONE"),             // Select multiplier usage (DYNAMIC, MULTIPLY, NONE)
      .USE_SIMD("ONE48"),                // SIMD selection (FOUR12, ONE48, TWO24)
      .USE_WIDEXOR("FALSE"),             // Use the Wide XOR function (FALSE, TRUE)
      .XORSIMD("XOR24_48_96"),           // Mode of operation for the Wide XOR (XOR12, XOR24_48_96)
      // Pattern Detector Attributes: Pattern Detection Configuration
      .AUTORESET_PATDET("NO_RESET"),     // NO_RESET, RESET_MATCH, RESET_NOT_MATCH
      .AUTORESET_PRIORITY("RESET"),      // Priority of AUTORESET vs. CEP (CEP, RESET).
      .MASK(48'h3fffffffffff),           // 48-bit mask value for pattern detect (1=ignore)
      .PATTERN(48'h000000000000),        // 48-bit pattern match for pattern detect
      .SEL_MASK("MASK"),                 // C, MASK, ROUNDING_MODE1, ROUNDING_MODE2
      .SEL_PATTERN("PATTERN"),           // Select pattern value (C, PATTERN)
      .USE_PATTERN_DETECT("NO_PATDET"),  // Enable pattern detect (NO_PATDET, PATDET)
      // Programmable Inversion Attributes: Specifies built-in programmable inversion on specific pins
      .IS_ALUMODE_INVERTED(4'b0000),     // Optional inversion for ALUMODE
      .IS_CARRYIN_INVERTED(1'b0),        // Optional inversion for CARRYIN
      .IS_CLK_INVERTED(1'b0),            // Optional inversion for CLK
      .IS_INMODE_INVERTED(5'b00000),     // Optional inversion for INMODE
      .IS_OPMODE_INVERTED(9'b000000000), // Optional inversion for OPMODE
      .IS_RSTALLCARRYIN_INVERTED(1'b0),  // Optional inversion for RSTALLCARRYIN
      .IS_RSTALUMODE_INVERTED(1'b0),     // Optional inversion for RSTALUMODE
      .IS_RSTA_INVERTED(1'b0),           // Optional inversion for RSTA
      .IS_RSTB_INVERTED(1'b0),           // Optional inversion for RSTB
      .IS_RSTCTRL_INVERTED(1'b0),        // Optional inversion for RSTCTRL
      .IS_RSTC_INVERTED(1'b0),           // Optional inversion for RSTC
      .IS_RSTD_INVERTED(1'b0),           // Optional inversion for RSTD
      .IS_RSTINMODE_INVERTED(1'b0),      // Optional inversion for RSTINMODE
      .IS_RSTM_INVERTED(1'b0),           // Optional inversion for RSTM
      .IS_RSTP_INVERTED(1'b0),           // Optional inversion for RSTP
      // Register Control Attributes: Pipeline Register Configuration
      .ACASCREG(PIPE_STAGE0),                      // Number of pipeline stages between A/ACIN and ACOUT (0-2)
      .ADREG(0),                         // Pipeline stages for pre-adder (0-1)
      .ALUMODEREG(PIPE_STAGE0),                    // Pipeline stages for ALUMODE (0-1)
      .AREG(PIPE_STAGE0),                          // Pipeline stages for A (0-2)
      .BCASCREG(PIPE_STAGE0),                      // Number of pipeline stages between B/BCIN and BCOUT (0-2)
      .BREG(PIPE_STAGE0),                          // Pipeline stages for B (0-2)
      .CARRYINREG(PIPE_STAGE0),                    // Pipeline stages for CARRYIN (0-1)
      .CARRYINSELREG(PIPE_STAGE0),                 // Pipeline stages for CARRYINSEL (0-1)
      .CREG(PIPE_STAGE0),                          // Pipeline stages for C (0-1)
      .DREG(0),                          // Pipeline stages for D (0-1)
      .INMODEREG(0),                     // Pipeline stages for INMODE (0-1)
      .MREG(0),                          // Multiplier pipeline stages (0-1)
      .OPMODEREG(PIPE_STAGE0),                     // Pipeline stages for OPMODE (0-1)
      .PREG(PIPE_STAGE1)                           // Number of pipeline stages for P (0-1)
   )
   DSP48E2_inst (
      // Cascade outputs: Cascade Ports
      .ACOUT(),                   // 30-bit output: A port cascade
      .BCOUT(),                   // 18-bit output: B cascade
      .CARRYCASCOUT(),     // 1-bit output: Cascade carry
      .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade
      .PCOUT(),                   // 48-bit output: Cascade output
      // Control outputs: Control Inputs/Status Bits
      .OVERFLOW(),             // 1-bit output: Overflow in add/acc
      .PATTERNBDETECT(), // 1-bit output: Pattern bar detect
      .PATTERNDETECT(),   // 1-bit output: Pattern detect
      .UNDERFLOW(),           // 1-bit output: Underflow in add/acc
      // Data outputs: Data Ports
      .CARRYOUT(),             // 4-bit output: Carry
      .P(P),                           // 48-bit output: Primary data
      .XOROUT(),                 // 8-bit output: XOR data
      // Cascade inputs: Cascade Ports
      .ACIN(0),                     // 30-bit input: A cascade data
      .BCIN(0),                     // 18-bit input: B cascade
      .CARRYCASCIN(0),       // 1-bit input: Cascade carry
      .MULTSIGNIN(0),         // 1-bit input: Multiplier sign cascade
      .PCIN(0),                     // 48-bit input: P cascade
      // Control inputs: Control Inputs/Status Bits
      .ALUMODE(ALUMODE),               // 4-bit input: ALU control
      .CARRYINSEL(0),         // 3-bit input: Carry select
      .CLK(clk),                       // 1-bit input: Clock
      .INMODE(INMODE),                 // 5-bit input: INMODE control
      .OPMODE(OPMODE),                 // 9-bit input: Operation mode
      // Data inputs: Data Ports
      .A(A),                           // 30-bit input: A data
      .B(B),                           // 18-bit input: B data
      .C(C),                           // 48-bit input: C data
      .CARRYIN(0),               // 1-bit input: Carry-in
      .D(D),                           // 27-bit input: D data
      // Reset/Clock Enable inputs: Reset/Clock Enable Inputs
      .CEA1(0),                     // 1-bit input: Clock enable for 1st stage AREG
      .CEA2(PIPE_STAGE0),                     // 1-bit input: Clock enable for 2nd stage AREG
      .CEAD(0),                     // 1-bit input: Clock enable for ADREG
      .CEALUMODE(PIPE_STAGE0),           // 1-bit input: Clock enable for ALUMODE
      .CEB1(0),// 1-bit input: Clock enable for 1st stage BREG
      .CEB2(PIPE_STAGE0),                     // 1-bit input: Clock enable for 2nd stage BREG
      .CEC(PIPE_STAGE0),                       // 1-bit input: Clock enable for CREG
      .CECARRYIN(PIPE_STAGE0),           // 1-bit input: Clock enable for CARRYINREG
      .CECTRL(PIPE_STAGE0),                 // 1-bit input: Clock enable for OPMODEREG and CARRYINSELREG
      .CED(0),                       // 1-bit input: Clock enable for DREG
      .CEINMODE(0),             // 1-bit input: Clock enable for INMODEREG
      .CEM(0),                       // 1-bit input: Clock enable for MREG
      .CEP(PIPE_STAGE1),                       // 1-bit input: Clock enable for PREG
      .RSTA(0),                     // 1-bit input: Reset for AREG
      .RSTALLCARRYIN(0),   // 1-bit input: Reset for CARRYINREG
      .RSTALUMODE(0),         // 1-bit input: Reset for ALUMODEREG
      .RSTB(0),                     // 1-bit input: Reset for BREG
      .RSTC(0),                     // 1-bit input: Reset for CREG
      .RSTCTRL(0),               // 1-bit input: Reset for OPMODEREG and CARRYINSELREG
      .RSTD(0),                     // 1-bit input: Reset for DREG and ADREG
      .RSTINMODE(0),           // 1-bit input: Reset for INMODEREG
      .RSTM(0),                     // 1-bit input: Reset for MREG
      .RSTP(0)                      // 1-bit input: Reset for PREG
   );

   // End of DSP48E2_inst instantiation
					
endmodule

/* verilator lint_on PINCONNECTEMPTY */
