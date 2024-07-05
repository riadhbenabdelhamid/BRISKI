
module immsel_signext #(
    parameter [10:0] ID = 11'h0,
    parameter integer NUM_THREADS = 16
) (
    input  logic                           clk,             // Clock input
    input  logic [                   31:7] i_instruction,   // Input instruction
    input  logic [                    2:0] i_imm_sel,       // Immediate type selector
    input  logic [$clog2(NUM_THREADS)-1:0] i_thread_index,  // Thread index
    output logic [                   31:0] o_imm_out        // Output immediate
);
  // Signals for various immediate types
  logic [                   31:0] imm_U;  // Upper Immediate Type
  logic [                   11:0] imm_I;  // Immediate Type
  logic [                   11:0] imm_S;  // Store Type
  logic [                   12:0] imm_B;  // Branch Type
  logic [                   20:0] imm_J;  // Jump Type

  // Extended immediate signals
  logic [                   31:0] imm_I_ext;  // Extended Immediate for R-Type
  logic [                   31:0] imm_S_ext;  // Extended Immediate for store target calculation
  logic [                   31:0] imm_B_ext;  // Extended Immediate for branch target calculation
  logic [                   31:0] imm_J_ext;  // Extended Immediate for jump target calculation
  logic [$clog2(NUM_THREADS)-1:0] mhartid;  // Thread index

  always_comb begin
    // Immediate decoding
    imm_I = i_instruction[31:20];
    imm_S = {i_instruction[31:25], i_instruction[11:7]};
    imm_B = {i_instruction[31], i_instruction[7], i_instruction[30:25], i_instruction[11:8], 1'b0};
    imm_J = {
      i_instruction[31], i_instruction[19:12], i_instruction[20], i_instruction[30:21], 1'b0
    };
    imm_U = {i_instruction[31:12], 12'b0};

    // Sign extend immediates
    imm_I_ext = 32'($signed(imm_I));
    imm_S_ext = 32'($signed(imm_S));
    imm_B_ext = 32'($signed(imm_B));
    imm_J_ext = 32'($signed(imm_J));

    mhartid = i_thread_index;
  end

  always_ff @(posedge clk) begin
    // Immediate selection based on i_imm_sel
    case (i_imm_sel)
      3'b000:  o_imm_out <= imm_U;
      3'b001:  o_imm_out <= imm_I_ext;
      3'b010:  o_imm_out <= imm_S_ext;
      3'b011:  o_imm_out <= imm_B_ext;
      3'b100:  o_imm_out <= imm_J_ext;
      3'b101:  o_imm_out <= {17'b0,ID, mhartid};
      default: o_imm_out <= 32'h0;
    endcase
  end
endmodule

