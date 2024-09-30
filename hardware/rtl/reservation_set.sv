module reservation_set #(
    parameter integer NUM_THREADS = 16,
    parameter PIPE_STAGE = 1
) (
    input logic clk,
    input logic reset,
    input logic [11:0] i_addr,
    input logic i_store_op,
    input logic i_store_cond_op,
    input logic i_load_reserved_op,
    input logic [$clog2(NUM_THREADS)-1:0] i_mhartid,
    output logic o_sc_success
);

  logic [11:0] reserved_address ;
  logic [$clog2(NUM_THREADS)-1:0] reserving_hart ;
  logic reserved_valid;
  logic address_match ;
  logic hart_match ;

  if (PIPE_STAGE == 1) begin : registered_reservation_set 
  //-----------------------------------------------------
    assign address_match = (i_addr == reserved_address) ;
    assign hart_match = (i_mhartid == reserving_hart) ;
   
    always_ff @(posedge clk) begin
      if (reset) begin
        reserved_valid <= 1'b0;
      end else begin
        if (i_load_reserved_op) 
          reserved_valid <= 1'b1;

        if ((i_store_cond_op && hart_match) || (i_store_op && address_match))
          reserved_valid <= 1'b0;

      end
    end

    always_ff @(posedge clk) begin
      if (reset) begin
        o_sc_success <= 1'b0;
      end else begin
        o_sc_success <= reserved_valid && address_match && i_store_cond_op && hart_match;
      end
    end

    always_ff @(posedge clk) begin

        if (i_load_reserved_op) begin
          if (!reserved_valid ) begin
            reserving_hart <= i_mhartid;
          end 
	  if ((!reserved_valid) || (reserved_valid && hart_match)) begin
            reserved_address <= i_addr;
          end
        end

    end

  end else begin : not_registered_reservation_set
  //-----------------------------------------------------

    always_latch begin
      if (reset) begin
        reserved_valid = 1'b0;
	reserved_address = 0;
	reserving_hart = 0;
	o_sc_success = 0;
      end else begin
       // Compare the current address and the reserved address
        address_match = (i_addr == reserved_address);
        // Compare the current hart ID and the reserving hart ID
        hart_match = (i_mhartid == reserving_hart);


        if (i_load_reserved_op) begin
          if (!reserved_valid ) begin
            reserving_hart = i_mhartid;
          end 
	  
	  if ((!reserved_valid) || (reserved_valid && hart_match)) begin
            reserved_address = i_addr;
          end
          
	  reserved_valid = 1'b1;
        end
        
	if (reserved_valid)
          o_sc_success = address_match && i_store_cond_op && hart_match;

	if (!hart_match)  // this will maintain the sc_success pulse for a clock period until the next hart context change
          o_sc_success = 0;


        if ((i_store_cond_op && hart_match) || (i_store_op && address_match))
          reserved_valid = 1'b0;
      
      end

    end
  end 

endmodule

