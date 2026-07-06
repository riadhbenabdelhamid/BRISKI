`include "riscv_pkg.sv"
module pcreg_vec #(
    parameter DWIDTH = 32,
    parameter NUM_THREADS = 16,
    parameter EXE_STAGE = 7,
    parameter PC_WIDTH = 12,  // stored PC bits (byte address): instruction address bus width + 2
    parameter bool ENABLE_LUTRAM_PCMEM = true
) (
    input  logic                           reset,
    input  logic                           clk,
    input  logic [$clog2(NUM_THREADS)-1:0] i_thread_index_counter,
    input  logic [$clog2(NUM_THREADS)-1:0] i_thread_index_execute,
    input  logic [             DWIDTH-1:0] i_pc_in,
    output logic [             DWIDTH-1:0] o_pcreg_out
);

    logic [$clog2(NUM_THREADS)-1:0] counter;
    logic                           we;
    logic [$clog2(NUM_THREADS)-1:0] pcaddrin;
    logic [           PC_WIDTH-1:0] pcdatain;
    logic [           PC_WIDTH-1:0] pcdataout;

    always_ff @(posedge clk) begin
        if (reset) begin
            counter  <= 0;
            we       <= 1;
            pcaddrin <= pcaddrin + 1;
            pcdatain <= PC_WIDTH'({STARTUP_ADDR});
        end else begin
            pcaddrin <= i_thread_index_execute;
            pcdatain <= i_pc_in[PC_WIDTH-1:0];
            if (counter == EXE_STAGE[$clog2(NUM_THREADS)-1:0] + 1) begin
                we <= 1;
            end else begin
                we      <= 0;
                counter <= counter + 1;
            end
        end
    end

    LUT_RAM #(
        .SIZE(NUM_THREADS),
        .ADDR_WIDTH($clog2(NUM_THREADS)),
        .DATA_WIDTH(PC_WIDTH),
        .ENABLE_LUTRAM_PCMEM(ENABLE_LUTRAM_PCMEM)
    ) PC_MEM_INST (
        .clka (clk),
        .ena  (1'b1),
        .wea  (we),
        .addra(pcaddrin),
        .dia  (pcdatain),
        .addrb(i_thread_index_counter),
        .dob  (pcdataout)
    );

    assign o_pcreg_out = {{($bits(o_pcreg_out) - $bits(pcdataout)) {1'b0}}, pcdataout};  // zero-extend to match the bit widths

endmodule

