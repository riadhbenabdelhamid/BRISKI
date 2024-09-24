module load_unit (
    input  logic        i_load,      // Load signal
    input  logic [ 1:0] i_addr,      // Address for byte/half selection
    input  logic [ 2:0] i_funct3,    // Function code for load operation
    input  logic [31:0] i_dmem_pre,  // Data memory input
    output logic [31:0] o_dmem_post  // Data memory output
);
  // Signals for byte and half-word selection
  logic [ 7:0] dmem_byte;
  logic [15:0] dmem_half;

  always_comb begin
    // Byte selection based on address
    case (i_addr)
      2'b00:   dmem_byte = i_dmem_pre[7:0];
      2'b01:   dmem_byte = i_dmem_pre[15:8];
      2'b10:   dmem_byte = i_dmem_pre[23:16];
      2'b11:   dmem_byte = i_dmem_pre[31:24];
      default: dmem_byte = i_dmem_pre[7:0];
    endcase
  end

  always_comb begin
    // Half-word selection based on address
    case (i_addr[1])
      1'b0: dmem_half = i_dmem_pre[15:0];
      1'b1: dmem_half = i_dmem_pre[31:16];
      default: dmem_half = i_dmem_pre[15:0];
    endcase
  end

  always_comb begin
    // Default value for LW
    o_dmem_post = i_dmem_pre;
    if (i_load) begin
      // Load operation based on funct3
      case (i_funct3[1:0])
        2'b00:
        o_dmem_post = {
          {24{(~i_funct3[2] & dmem_byte[7])}}, dmem_byte
        };  // LB/LBU //000 LB (byte is sign extended) //100 LBU (zero extend)
        2'b01:
        o_dmem_post = {
          {16{(~i_funct3[2] & dmem_half[15])}}, dmem_half
        };  // LH/LHU //001 LH (Half is sign extended) //101 LHU (zero extend)
        default: o_dmem_post = i_dmem_pre;  // LW
      endcase
    end
  end
endmodule

