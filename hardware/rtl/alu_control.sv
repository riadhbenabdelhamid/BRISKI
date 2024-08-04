`include "riscv_pkg.sv"
//import riscv_pkg::*;
module alu_control (
    input logic clk,
    input logic [2:0] i_ALUctrl,
    input logic [2:0] i_funct3,
    input logic [6:0] i_funct7,
    output logic [ALUOP_WIDTH-1:0] o_ALUOp
);
  always_ff @(posedge clk) begin
    case (i_ALUctrl)
      3'b000: o_ALUOp <= ADD_OP;  // Addition
      3'b001: o_ALUOp <= SUB_OP;  // SUB
      3'b010:
      case (i_funct3)
        3'b000:
	case (i_funct7) 
		7'b0000000: o_ALUOp <= ADD_OP;  // ADD 
                //7'b0100000: o_ALUOp <= SUB_OP;  // SUB
		default: o_ALUOp <= '0;
	endcase
        3'b001: o_ALUOp <= SLL_OP;  // SLL
        3'b010: o_ALUOp <= SLT_OP;  // SLT
        3'b011: o_ALUOp <= SLTU_OP;  // SLTU
        3'b100: o_ALUOp <= XOR_OP;  // XOR
        3'b101:
	case (i_funct7) 
		7'b0000000: o_ALUOp <= SRL_OP;  // SRL
                7'b0100000: o_ALUOp <= SRA_OP;  // SRA
		default: o_ALUOp <= '0;
	endcase

        3'b110: o_ALUOp <= OR_OP;  // OR
        3'b111: o_ALUOp <= AND_OP;  // AND
        default: o_ALUOp <= '0;  // Undefined operation
      endcase
      3'b011: o_ALUOp <= PASS_OP;  // output second operand
      3'b100: //custom-0
      case (i_funct3)
        3'b000:
	case (i_funct7) 
		7'b0000001: o_ALUOp <= LOTOUPC_OP;  //  lotoupcase
		default: o_ALUOp <= '0;
	endcase
        default: o_ALUOp <= '0;  // Undefined operation
      endcase
      default: o_ALUOp <= '0;  // Undefined operation
    endcase
  end
endmodule

