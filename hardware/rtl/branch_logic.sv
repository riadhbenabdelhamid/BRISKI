module branch_logic (
    input  logic        i_slt_op,          // SLTx operation
    input  logic        i_br_signed,       // Branch condition signed/unsigned
    input  logic        i_is_branch,       // Branch opcode
    input  logic [ 2:0] i_funct3,          // Funct3 input
    input  logic [31:0] i_rd1,             // Register file data 1
    input  logic [31:0] i_rd2,             // Register file data 2
    output logic        o_slt,             // Set less than result
    output logic        o_is_branch_valid  // Branch validity signal
);
  // Signals for sign extension and branch conditions
  logic bit_ext1, bit_ext2;
  logic br_eq, br_lt;

  // Sign extension conditions
  assign bit_ext1 = (i_br_signed == 1) ? i_rd1[31] : 1'b0;
  assign bit_ext2 = (i_br_signed == 1) ? i_rd2[31] : 1'b0;

  // Branch condition checks
  assign br_eq = (i_rd1 == i_rd2) ? 1'b1 : 1'b0;
  assign br_lt = ($signed({bit_ext1, i_rd1}) < $signed({bit_ext2, i_rd2})) ? 1'b1 : 1'b0;
  assign o_slt = (i_slt_op == 1) ? br_lt : 1'b1;  // Facilitate combined use with SC result with a simple OR

  // Process for determining branch validity
  always_comb begin
    o_is_branch_valid = 1'b0;

    if (i_is_branch == 1'b1) begin
      case (i_funct3)
        // beq branch
        // Example: beq rs1, rs2, offset if (rs1 == rs2) pc += sext(offset)
        3'b000:  o_is_branch_valid = br_eq;
        // bne branch
        // Example: bne rs1, rs2, offset if (rs1 != rs2) pc += sext(offset)
        3'b001:  o_is_branch_valid = ~br_eq;
        // blt branch
        // Example: blt rs1, rs2, offset if (rs1 <(s) rs2) pc += sext(offset)
        3'b100:  o_is_branch_valid = br_lt;
        // bge branch
        // Example: bge rs1, rs2, offset if (rs1 >=(s) rs2) pc += sext(offset)
        3'b101:  o_is_branch_valid = ~br_lt;
        // bltu branch
        // Example: bltu rs1, rs2, offset <=> if (rs1 <(u) rs2) pc += sext(offset)
        3'b110:  o_is_branch_valid = br_lt;
        // bgeu branch
        // Example: bgeu rs1, rs2, offset if (rs1 >=(u) rs2) pc += sext(offset)
        3'b111:  o_is_branch_valid = ~br_lt;
        default: o_is_branch_valid = 1'b0;
      endcase
    end
  end

endmodule

