`include "riscv_pkg.sv"
module RISCV_core_top_tb;

    // Declarations
    logic clk ;
    logic reset ;

    parameter time CLK_period = 10ns;

    // URAM interface
    logic URAM_EN;
    logic [11:0] URAM_addr;
    logic [31:0] URAM_wr_data;
    logic URAM_wr_en;

    // Row sync interface
    logic uram_emptied;
    logic core_req;
    logic core_locked;
    logic core_grant ;
    integer counter ;
    logic core_locked_d ;
    logic core_locked_fe ;

    
    assign core_locked_fe = core_locked_d && (!core_locked);
    //core parameters
    parameter NUM_PIPE_STAGES = `NUM_PIPE_STAGES;
    parameter NUM_THREADS     = `NUM_THREADS;
    // RF parameter 
    parameter bool ENABLE_BRAM_REGFILE = `ENABLE_BRAM_REGFILE;
    // ALU parameter 
    parameter bool ENABLE_ALU_DSP = `ENABLE_ALU_DSP ;
    parameter bool ENABLE_UNIFIED_BARREL_SHIFTER = `ENABLE_UNIFIED_BARREL_SHIFTER;
    parameter HEX_PROG = "none";
    // Generic parameters
    parameter IDcluster        = 0;
    parameter IDrow            = 0;
    parameter IDminirow        = 0;
    parameter IDposx           = 0;
    // Instantiate the unit under test (UUT)
    RISCV_core_top #
    (.BRAM_DATA_INSTR_FILE (HEX_PROG),
     .NUM_PIPE_STAGES      (NUM_PIPE_STAGES),
     .NUM_THREADS          (NUM_THREADS),
    // RF parameter 
     .ENABLE_BRAM_REGFILE  (ENABLE_BRAM_REGFILE),
    // ALU parameter 
     .ENABLE_ALU_DSP       (ENABLE_ALU_DSP),
     .ENABLE_UNIFIED_BARREL_SHIFTER (ENABLE_UNIFIED_BARREL_SHIFTER),
    // Generic parameters
     .IDcluster       (IDcluster),
     .IDrow           (IDrow),
     .IDminirow       (IDminirow),
     .IDposx          (IDposx)
    ) uut (
        .clk(clk),
        .reset(reset),
        // URAM interface
        .o_URAM_en(URAM_EN),
        .o_URAM_addr(URAM_addr),
        .o_URAM_wr_data(URAM_wr_data),
        .o_URAM_wr_en(URAM_wr_en),
        // Row sync IO interface (arbiter+barriers)
        .i_uram_emptied(uram_emptied),
        .o_core_req(core_req),
        .o_core_locked(core_locked),
        .i_core_grant(core_grant)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            core_grant <= 1'b0;
        end else begin
            if (core_req) begin
                core_grant <= 1'b1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (reset) begin
            counter <= 0;
        end else begin
            if (URAM_wr_en && URAM_EN) begin
                counter <= counter + 1;
                $display("count value : [ %0d ] ------------ current time = %0t", counter, $time);
                $display("uram_data : [ %0d ] ------------ ", $unsigned(URAM_wr_data));
                $display("uram_addr : [ %0d ]", $unsigned(URAM_addr));
                assert ((counter / 16) + 8 * $unsigned(URAM_wr_data) == $unsigned(URAM_addr))
                    else $fatal("test is incorrect");
            end
        end
        core_locked_d <= core_locked;
    end

    // Clock process
    initial begin
	clk = 0;
        forever begin
            clk = ~clk;
            #(CLK_period / 2);
        end
    end

    // Reset process
    initial begin
        reset = 1'b1;
        #(200ns);
        @(posedge clk);
        reset = 1'b0;
        //#(17000ns);
        //@(posedge clk);
        //reset = 1'b1;
        //#(200ns);
        //@(posedge clk);
        //reset = 1'b0;
    end

    // Stimulus process
    initial begin
        @(posedge core_locked_fe);
        if (!reset) begin
            $display("simulation end as expected: locked is reset to zero");
            $finish;
        end
    end

  initial begin
    $dumpfile("RISCV_core_top_tb_waveform.vcd");
    $dumpvars;
  end
endmodule

