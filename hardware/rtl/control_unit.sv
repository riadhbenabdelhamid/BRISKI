module control_unit (
    input logic [6:0] i_opcode,  // Opcode input from instruction_decoder
    input logic [2:0] i_funct3,  // Funct3 input from instruction_decoder
    input logic [6:0] i_funct7,  // Funct7 input from instruction_decoder
    output logic [2:0] o_immSel,  // Immediate type select signal
    output logic o_brmuxsel,  // Branch logic input mux selector
    output logic o_br_signed,  // Branch condition signed/unsigned
    output logic o_is_branch,  // Branch opcode
    output logic o_is_jump,  // Jump opcode
    output logic o_aluop1sel,  // First ALU operand multiplexer selector
    output logic o_aluop2sel,  // Second ALU operand multiplexer selector
    output logic [1:0] o_ALUctrl,  // ALU control decoder
    output logic o_MemWr,  // Data memory write enable signal
    output logic o_regWE,  // Register file write enable signal
    output logic o_load,  // Load operation
    output logic [1:0] o_WBSel,         // Write back multiplexer selector (00: memory dout, 01: ALU result, 10: PC+4)
    output logic o_slt_op,  // SLTx operation
    output logic o_res_station_valid,  // Set valid bit on reservation station
    output logic o_store_cond  // Store cond instruction
);

  always_comb begin
    // Default values
    o_immSel = 3'b000;
    o_brmuxsel = 1'b0;
    o_br_signed = 1'b0;
    o_is_branch = 1'b0;
    o_is_jump = 1'b0;
    o_aluop1sel = 1'b0;
    o_aluop2sel = 1'b0;
    o_ALUctrl = 2'b00;
    o_MemWr = 1'b0;
    o_regWE = 1'b0;
    o_load = 1'b0;
    o_WBSel = 2'b00;
    o_slt_op = 1'b0;
    o_res_station_valid = 1'b0;
    o_store_cond = 1'b0;

    // Control signals based on opcode
    case (i_opcode)
      // R-type instructions
      7'b0110011: begin
        o_WBSel = 2'b01;
        o_regWE = 1'b1;

        if ((i_funct7 == 7'b0100000) && (i_funct3 == 3'b000)) begin
          o_ALUctrl = 2'b01;  // Subtraction
        end else begin
          o_ALUctrl = 2'b10;
        end

        if (i_funct3 == 3'b010) begin
          o_slt_op = 1'b1;
          o_br_signed = 1'b1;
          o_WBSel = 2'b11;
        end else if (i_funct3 == 3'b011) begin
          o_slt_op = 1'b1;
          o_WBSel  = 2'b11;
        end
      end

      // I-type instructions
      7'b0010011: begin
        o_immSel = 3'b001;
        o_aluop2sel = 1'b1;
        o_WBSel = 2'b01;
        o_regWE = 1'b1;
        o_ALUctrl = 2'b10;
        o_brmuxsel = 1'b1;

        if (i_funct3 == 3'b010) begin
          o_slt_op = 1'b1;
          o_br_signed = 1'b1;
          o_WBSel = 2'b11;
        end else if (i_funct3 == 3'b011) begin
          o_slt_op = 1'b1;
          o_WBSel  = 2'b11;
        end
      end

      // Load instructions
      7'b0000011: begin
        o_load = 1'b1;
        o_immSel = 3'b001;
        o_aluop2sel = 1'b1;
        o_regWE = 1'b1;
      end

      // Store instructions
      7'b0100011: begin
        o_immSel = 3'b010;
        o_aluop2sel = 1'b1;
        o_MemWr = 1'b1;
      end

      // Branch instructions
      7'b1100011: begin
        o_immSel = 3'b011;
        o_aluop1sel = 1'b1;
        o_aluop2sel = 1'b1;
        o_is_branch = 1'b1;

        case (i_funct3)
          3'b100, 3'b101: o_br_signed = 1'b1;
          default: o_br_signed = 1'b0;
        endcase
      end

      // JAL instruction
      7'b1101111: begin
        o_is_jump = 1'b1;
        o_immSel = 3'b100;
        o_aluop1sel = 1'b1;
        o_aluop2sel = 1'b1;
        o_WBSel = 2'b10;
        o_regWE = 1'b1;
      end

      // JALR instruction
      7'b1100111: begin
        o_is_jump = 1'b1;
        o_immSel = 3'b001;
        o_aluop2sel = 1'b1;
        o_WBSel = 2'b10;
        o_regWE = 1'b1;
      end

      // LUI instruction
      7'b0110111: begin
        o_aluop2sel = 1'b1;
        o_ALUctrl = 2'b11;
        o_WBSel = 2'b01;
        o_regWE = 1'b1;
      end

      // AUIPC instruction
      7'b0010111: begin
        o_aluop1sel = 1'b1;
        o_aluop2sel = 1'b1;
        o_WBSel = 2'b01;
        o_regWE = 1'b1;
      end

      // CSR instruction
      7'b1110011: begin
        o_WBSel = 2'b01;
        o_regWE = 1'b1;
        o_immSel = 3'b101;
        o_aluop2sel = 1'b1;
        o_ALUctrl = 2'b11;
      end

      // ATOMIC: LR/SC
      7'b0101111: begin
        // Load Reserved
        if (i_funct7[3:2] == 2'b10) begin  // LR
          o_res_station_valid = 1'b1;
          o_load = 1'b1;
          o_aluop1sel = 1'b0;
          o_immSel = 3'b110;
          o_aluop2sel = 1'b1;
          o_regWE = 1'b1;
          // Store Conditional
        end else if (i_funct7[3:2] == 2'b11) begin  // SC
          o_WBSel = 2'b11;
          o_res_station_valid = 1'b0;
          o_aluop1sel = 1'b0;
          o_immSel = 3'b110;
          o_aluop2sel = 1'b1;
          o_regWE = 1'b1;
          o_store_cond = 1'b1;
        end
      end
      default: begin
      end
    endcase
  end

endmodule

