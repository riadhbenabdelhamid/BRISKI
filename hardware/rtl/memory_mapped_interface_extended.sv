module memory_mapped_interface_extended (
    input logic clk,
    input logic reset,
    //RVcore interface
    input logic i_mmio_enable,  // MMIO address range enable
    input logic [4:0] i_mmio_addr,  // Address bus (4 bits)
    input logic i_mmio_wen,  // Write enable signal
    input logic i_mmio_data_in,
    output logic [31:0] o_mmio_data_out,  // Data output (32 bits)
    //row sync IO interface (arbiter+barriers)
    input logic i_uram_emptied,
    output logic o_core_req,
    output logic o_core_locked,
    input logic i_core_grant
);

  logic reg1_ro ;  // Read-only register 1 (grant)
  logic reg2_rw ;  // Read-only register 2
  logic reg3_rw ;  // read-write register 3 (request)
  logic reg4_rw ;  // read_write register 4 (locked)
  logic reg5_ro ;  // Read-only register 5 (uram emptied barrier)

  logic [15:0] reg_hart; //registers for hart locks

  assign reg1_ro = i_core_grant;  // zero extend 1 bit signal to 4 bit signal
  assign reg5_ro = i_uram_emptied;  // zero extend 1 bit signal to 4 bit signal

  assign o_core_req = reg3_rw;  // req is set when any threads in a core set their own req
  assign o_core_locked = reg4_rw;  // locked is set when all threads in a core set their own locked

  always_ff @(posedge clk) begin
    if (reset == 1) begin
      // Reset registers to default values when reset is active
      reg2_rw <= 0;
      reg3_rw <= 0;
      reg4_rw <= 0;
      reg_hart <= 0;
      o_mmio_data_out <= 0;
    end else begin
      if (i_mmio_enable == 1) begin
        if (i_mmio_wen == 1) begin
          // Write operation
          case (i_mmio_addr)
            5'b00001: reg2_rw <= i_mmio_data_in;  //read-write address
            5'b00010: reg3_rw <= i_mmio_data_in;  //read-write address // req
            5'b00011: reg4_rw <= i_mmio_data_in;  //read-write address // locked
	    //
            5'b00101: reg_hart[0] <= i_mmio_data_in;  //read-write address // hart0
            5'b00110: reg_hart[1] <= i_mmio_data_in;  //read-write address // hart1
            5'b00111: reg_hart[2] <= i_mmio_data_in;  //read-write address // hart2
            5'b01000: reg_hart[3] <= i_mmio_data_in;  //read-write address // hart3
            5'b01001: reg_hart[4] <= i_mmio_data_in;  //read-write address // hart4
            5'b01010: reg_hart[5] <= i_mmio_data_in;  //read-write address // hart5
            5'b01011: reg_hart[6] <= i_mmio_data_in;  //read-write address // hart6
            5'b01100: reg_hart[7] <= i_mmio_data_in;  //read-write address // hart7
            5'b01101: reg_hart[8] <= i_mmio_data_in;  //read-write address // hart8
            5'b01110: reg_hart[9] <= i_mmio_data_in;  //read-write address // hart9
            5'b01111: reg_hart[10] <= i_mmio_data_in;  //read-write address // hart10
            5'b10000: reg_hart[11] <= i_mmio_data_in;  //read-write address // hart11
            5'b10001: reg_hart[12] <= i_mmio_data_in;  //read-write address // hart12
            5'b10010: reg_hart[13] <= i_mmio_data_in;  //read-write address // hart13
            5'b10011: reg_hart[14] <= i_mmio_data_in;  //read-write address // hart14
            5'b10100: reg_hart[15] <= i_mmio_data_in;  //read-write address // hart15
            default: begin
              // Ignore writes to read-only registers
            end
          endcase
        end else begin
          // Read operation
          case (i_mmio_addr)
            5'b00000: o_mmio_data_out <= {31'b0,reg1_ro};  // read-only addr    // grant register
            5'b00001: o_mmio_data_out <= {31'b0,reg2_rw};  // read-write addr
            5'b00010: o_mmio_data_out <= {31'b0,reg3_rw};  // read-write addr  // req
            5'b00011: o_mmio_data_out <= {31'b0,reg4_rw};  // read-write addr  // locked
            5'b00100: o_mmio_data_out <= {31'b0,reg5_ro};  // read-only addr  // uram emptied register
	    //
	    5'b10101: o_mmio_data_out <= {16'b0,reg_hart}; //32bits barrier values
            default: o_mmio_data_out <= 32'b0;  // Default value for unknown address
          endcase
        end
      end
    end
  end
endmodule
