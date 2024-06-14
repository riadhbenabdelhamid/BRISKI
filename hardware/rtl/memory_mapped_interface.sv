module memory_mapped_interface (
    input logic clk,
    input logic reset,
    //RVcore interface
    input logic i_mmio_enable,  // MMIO address range enable
    input logic [3:0] i_mmio_addr,  // Address bus (4 bits)
    input logic i_mmio_wen,  // Write enable signal
    input logic i_mmio_data_in,
    output logic o_mmio_data_out,  // Data output (32 bits)
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
      o_mmio_data_out <= 0;
    end else begin
      if (i_mmio_enable == 1) begin
        if (i_mmio_wen == 1) begin
          // Write operation
          case (i_mmio_addr)
            4'b0001: reg2_rw <= i_mmio_data_in;  //read-write address
            4'b0010: reg3_rw <= i_mmio_data_in;  //read-write address // req
            4'b0011: reg4_rw <= i_mmio_data_in;  //read-write address // locked
            default: begin
              // Ignore writes to read-only registers
            end
          endcase
        end else begin
          // Read operation
          case (i_mmio_addr)
            4'b0000: o_mmio_data_out <= reg1_ro;  // read-only addr    // grant register
            4'b0001: o_mmio_data_out <= reg2_rw;  // read-write addr
            4'b0010: o_mmio_data_out <= reg3_rw;  // read-write addr  // req
            4'b0011: o_mmio_data_out <= reg4_rw;  // read-write addr  // locked
            4'b0100: o_mmio_data_out <= reg5_ro;  // read-only addr  // uram emptied register
            default: o_mmio_data_out <= 0;  // Default value for unknown address
          endcase
        end
      end
    end
  end
endmodule
