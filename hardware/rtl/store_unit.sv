module store_unit#(parameter PIPE_STAGE =0) (
    input logic clk,
    input logic i_store,
    input logic [2:0] i_funct3,
    input logic [31:0] i_data,
    input logic [1:0] i_addr,
    output logic [31:0] o_data,
    output logic [3:0] o_we
);

  logic [3:0] sb_we;
  logic [3:0] sh_we;
  logic [4:0] sb_d;
  logic [4:0] sh_d;
  logic [1:0] shift_sh;

  if (PIPE_STAGE == 0) begin : not_registered_store_logic
  //-----------------------------------------------------
    always_comb begin
      sb_we = {3'b0, i_store};  // shift we
      sh_we = {2'b0, i_store, i_store};  // shift we
      shift_sh = {i_addr[1], 1'b0};  // shift sh

      case (i_funct3)
        3'b000:  o_we = sb_we << i_addr;  // byte store sb
        3'b001:  o_we = sh_we << shift_sh;  // half store sh
        3'b010:  o_we = {4{i_store}};  // word store sw
        default: o_we = 4'b0000;
      endcase
    end

    always_comb begin
      sb_d = {i_addr[1:0], 3'b0};  // shift data
      sh_d = {i_addr[1], 4'b0};  // shift data

      case (i_funct3)
        3'b000:  o_data = i_data << sb_d;  // byte store sb
        3'b001:  o_data = i_data << sh_d;  // half store sh
        default: o_data = i_data;
      endcase
    end

  end else begin : registered_store_logic
  //-----------------------------------------------------
    assign sb_we = {3'b0, i_store};  // shift we
    assign sh_we = {2'b0, i_store, i_store};  // shift we
    assign shift_sh = {i_addr[1], 1'b0};  // shift sh

    always_ff @(posedge clk) begin
      case (i_funct3)
        3'b000:  o_we <= sb_we << i_addr;  // byte store sb
        3'b001:  o_we <= sh_we << shift_sh;  // half store sh
        3'b010:  o_we <= {4{i_store}};  // word store sw
        default: o_we <= 4'b0000;
      endcase
    end
    //----
    assign sb_d = {i_addr[1:0], 3'b0};  // shift data
    assign sh_d = {i_addr[1], 4'b0};  // shift data

    always_ff @(posedge clk) begin
      case (i_funct3)
        3'b000:  o_data <= i_data << sb_d;  // byte store sb
        3'b001:  o_data <= i_data << sh_d;  // half store sh
        default: o_data <= i_data;
      endcase
    end

  end

endmodule

