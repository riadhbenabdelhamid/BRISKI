`ifdef FPGA_FAMILY_VERSAL
`include "mmcm_lookup_params_VERSAL.svh"
`elsif FPGA_FAMILY_7SERIES
`include "mmcm_lookup_params_7SERIES.svh"
`elsif FPGA_FAMILY_ULTRASCALE
`include "mmcm_lookup_params_ULTRASCALE.svh"
`elsif FPGA_FAMILY_ULTRASCALEPLUS
`include "mmcm_lookup_params_ULTRASCALEPLUS.svh"
`else
`include "mmcm_lookup_params_7SERIES.svh"
`endif

module MMCM_clock_gen #(
    parameter int MMCM_OUT_FREQ = 650
) (
    input  logic CLKIN1,
    input  logic ASYNC_RESET,
    output logic CLK_OUT,
    output logic LOCKED
);
    // Function to derive Master Divider (D)
    function int DeriveMasterDiv(input int freq);
        // Default to 0 if no match found
        DeriveMasterDiv = 0;

        // Loop through the `desired_freqs` array to find a match
        for (int i = 0; i < $size(desired_freqs); i++) begin
            if (freq == desired_freqs[i]) begin
                // If a match is found, return the corresponding D_value
                $display("Dval = %d", D_values[i]);
                return D_values[i];
            end
        end
    endfunction

    // Function to derive Master Multiplier (M)
    function real DeriveMasterMult(input int freq);
        // Default to 0 if no match found
        DeriveMasterMult = 0.0;

        // Loop through the `desired_freqs` array to find a match
        for (int i = 0; i < $size(desired_freqs); i++) begin
            if (freq == desired_freqs[i]) begin
                // If a match is found, return the corresponding M_value
                $display("Mval = %f", M_values[i]);
                return M_values[i];
            end
        end
    endfunction


    // Function to derive Master Multiplier Fraction(F)
    function int DeriveMasterMultFrac(input int freq);
        // Default to 0 if no match found
        DeriveMasterMultFrac = 0;

        // Loop through the `desired_freqs` array to find a match
        for (int i = 0; i < $size(desired_freqs); i++) begin
            if (freq == desired_freqs[i]) begin
                // If a match is found, return the corresponding M_value
                $display("Fval = %d", F_values[i]);
                return F_values[i];
            end
        end
    endfunction


    // Function to derive Output Divider (O)
    function real DeriveOutDiv(input int freq);
        // Default to 0 if no match found
        DeriveOutDiv = 0.0;

        // Loop through the `desired_freqs` array to find a match
        for (int i = 0; i < $size(desired_freqs); i++) begin
            if (freq == desired_freqs[i]) begin
                // If a match is found, return the corresponding O_value
                $display("Oval = %f", O_values[i]);
                return O_values[i];
            end
        end
    endfunction

    logic CLKFBOUT;
    logic clkout0;

    localparam int Dval = DeriveMasterDiv(MMCM_OUT_FREQ);
    localparam real Mval = DeriveMasterMult(MMCM_OUT_FREQ);
    localparam real Fval = DeriveMasterMultFrac(MMCM_OUT_FREQ);
    localparam real Oval = DeriveOutDiv(MMCM_OUT_FREQ);

    generate
`ifdef FPGA_FAMILY_VERSAL

        // MMCME5: Mixed Mode Clock Manager (MMCM)
        //         Versal Prime Series
        // Xilinx HDL Language Template, version 2025.1

        MMCME5 #(
            .BANDWIDTH("OPTIMIZED"),  // HIGH, LOW, OPTIMIZED
            .CLKFBOUT_FRACT(Fval),  // 6-bit fraction M feedback divider (0-63)
            //.CLKFBOUT_FRACT(0),               // 6-bit fraction M feedback divider (0-63)
            .CLKFBOUT_MULT(Mval),  // Multiply value for all CLKOUT, (4-432)
            //.CLKFBOUT_MULT(20),               // Multiply value for all CLKOUT, (4-432)
            .CLKFBOUT_PHASE(0.0),  // Phase offset in degrees of CLKFB
            .CLKIN1_PERIOD(10.0),  // Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
            .CLKIN2_PERIOD(0.0),  // Input clock period in ns to ps resolution (i.e., 33.333 is 30 MHz).
            .CLKOUT0_DIVIDE(Oval),  // Divide amount for CLKOUT0 (2-511)
            //.CLKOUT0_DIVIDE(2),               // Divide amount for CLKOUT0 (2-511)
            .CLKOUT0_DUTY_CYCLE(0.5),  // Duty cycle for CLKOUT0
            .CLKOUT0_PHASE(0.0),  // Phase offset for CLKOUT0
            .CLKOUT0_PHASE_CTRL(2'b00),  // CLKOUT0 fine phase shift or deskew select (0-11)
            .CLKOUT1_DIVIDE(2),  // Divide amount for CLKOUT1 (2-511)
            .CLKOUT1_DUTY_CYCLE(0.5),  // Duty cycle for CLKOUT1
            .CLKOUT1_PHASE(0.0),  // Phase offset for CLKOUT1
            .CLKOUT1_PHASE_CTRL(2'b00),  // CLKOUT1 fine phase shift or deskew select (0-11)
            .CLKOUT2_DIVIDE(2),  // Divide amount for CLKOUT2 (2-511)
            .CLKOUT2_DUTY_CYCLE(0.5),  // Duty cycle for CLKOUT2
            .CLKOUT2_PHASE(0.0),  // Phase offset for CLKOUT2
            .CLKOUT2_PHASE_CTRL(2'b00),  // CLKOUT2 fine phase shift or deskew select (0-11)
            .CLKOUT3_DIVIDE(2),  // Divide amount for CLKOUT3 (2-511)
            .CLKOUT3_DUTY_CYCLE(0.5),  // Duty cycle for CLKOUT3
            .CLKOUT3_PHASE(0.0),  // Phase offset for CLKOUT3
            .CLKOUT3_PHASE_CTRL(2'b00),  // CLKOUT3 fine phase shift or deskew select (0-11)
            .CLKOUT4_DIVIDE(2),  // Divide amount for CLKOUT4 (2-511)
            .CLKOUT4_DUTY_CYCLE(0.5),  // Duty cycle for CLKOUT4
            .CLKOUT4_PHASE(0.0),  // Phase offset for CLKOUT4
            .CLKOUT4_PHASE_CTRL(2'b00),  // CLKOUT4 fine phase shift or deskew select (0-11)
            .CLKOUT5_DIVIDE(2),  // Divide amount for CLKOUT5 (2-511)
            .CLKOUT5_DUTY_CYCLE(0.5),  // Duty cycle for CLKOUT5
            .CLKOUT5_PHASE(0.0),  // Phase offset for CLKOUT5
            .CLKOUT5_PHASE_CTRL(2'b00),  // CLKOUT5 fine phase shift or deskew select (0-11)
            .CLKOUT6_DIVIDE(2),  // Divide amount for CLKOUT6 (2-511)
            .CLKOUT6_DUTY_CYCLE(0.5),  // Duty cycle for CLKOUT6
            .CLKOUT6_PHASE(0.0),  // Phase offset for CLKOUT6
            .CLKOUT6_PHASE_CTRL(2'b00),  // CLKOUT6 fine phase shift or deskew select (0-11)
            .CLKOUTFB_PHASE_CTRL(2'b00),  // CLKFBOUT fine phase shift or deskew select (0-11)
            .COMPENSATION("AUTO"),  // Clock input compensation
            //.COMPENSATION("BUF_IN"),            // Clock input compensation
            .DESKEW_DELAY1(0),  // Deskew optional programmable delay
            .DESKEW_DELAY2(0),  // Deskew optional programmable delay
            .DESKEW_DELAY_EN1("FALSE"),  // Enable deskew optional programmable delay
            .DESKEW_DELAY_EN2("FALSE"),  // Enable deskew optional programmable delay
            .DESKEW_DELAY_PATH1("FALSE"),  // Select CLKIN1_DESKEW (TRUE) or CLKFB1_DESKEW (FALSE)
            .DESKEW_DELAY_PATH2("FALSE"),  // Select CLKIN2_DESKEW (TRUE) or CLKFB2_DESKEW (FALSE)
            .DIVCLK_DIVIDE(Dval),  // Master division value
            //.DIVCLK_DIVIDE(1),                // Master division value
            .IS_CLKFB1_DESKEW_INVERTED(1'b0),  // Optional inversion for CLKFB1_DESKEW
            .IS_CLKFB2_DESKEW_INVERTED(1'b0),  // Optional inversion for CLKFB2_DESKEW
            .IS_CLKFBIN_INVERTED(1'b0),  // Optional inversion for CLKFBIN
            .IS_CLKIN1_DESKEW_INVERTED(1'b0),  // Optional inversion for CLKIN1_DESKEW
            .IS_CLKIN1_INVERTED(1'b0),  // Optional inversion for CLKIN1
            .IS_CLKIN2_DESKEW_INVERTED(1'b0),  // Optional inversion for CLKIN2_DESKEW
            .IS_CLKIN2_INVERTED(1'b0),  // Optional inversion for CLKIN2
            .IS_CLKINSEL_INVERTED(1'b0),  // Optional inversion for CLKINSEL
            .IS_PSEN_INVERTED(1'b0),  // Optional inversion for PSEN
            .IS_PSINCDEC_INVERTED(1'b0),  // Optional inversion for PSINCDEC
            .IS_PWRDWN_INVERTED(1'b0),  // Optional inversion for PWRDWN
            .IS_RST_INVERTED(1'b0),  // Optional inversion for RST
            .LOCK_WAIT("FALSE"),  // Lock wait
            .REF_JITTER1(0.0),  // Reference input jitter in UI (0.000-0.200).
            .REF_JITTER2(0.0),  // Reference input jitter in UI (0.000-0.200).
            .SS_EN("FALSE"),  // Enables spread spectrum
            .SS_MODE("CENTER_HIGH"),  // Spread spectrum frequency deviation and the spread type
            .SS_MOD_PERIOD(10000)  // Spread spectrum modulation period (ns)
        ) MMCME5_inst (
            .CLKFBOUT      (CLKFBOUT),    // 1-bit output: Feedback clock
            .CLKFBSTOPPED  (),            // 1-bit output: Feedback clock stopped
            .CLKINSTOPPED  (),            // 1-bit output: Input clock stopped
            .CLKOUT0       (clkout0),     // 1-bit output: CLKOUT0
            .CLKOUT1       (),            // 1-bit output: CLKOUT1
            .CLKOUT2       (),            // 1-bit output: CLKOUT2
            .CLKOUT3       (),            // 1-bit output: CLKOUT3
            .CLKOUT4       (),            // 1-bit output: CLKOUT4
            .CLKOUT5       (),            // 1-bit output: CLKOUT5
            .CLKOUT6       (),            // 1-bit output: CLKOUT6
            .DO            (),            // 16-bit output: DRP data output
            .DRDY          (),            // 1-bit output: DRP ready
            .LOCKED        (LOCKED),      // 1-bit output: LOCK
            .LOCKED1_DESKEW(),            // 1-bit output: LOCK DESKEW PD1
            .LOCKED2_DESKEW(),            // 1-bit output: LOCK DESKEW PD2
            .LOCKED_FB     (),            // 1-bit output: LOCK FEEDBACK
            .PSDONE        (),            // 1-bit output: Phase shift done
            .CLKFB1_DESKEW (0),           // 1-bit input: Secondary clock input to PD1
            .CLKFB2_DESKEW (0),           // 1-bit input: Secondary clock input to PD2
            .CLKFBIN       (CLKFBOUT),    // 1-bit input: Feedback clock
            .CLKIN1        (CLKIN1),      // 1-bit input: Primary clock
            .CLKIN1_DESKEW (0),           // 1-bit input: Primary clock input to PD1
            .CLKIN2        (0),           // 1-bit input: Secondary clock
            .CLKIN2_DESKEW (0),           // 1-bit input: Primary clock input to PD2
            .CLKINSEL      (1'b1),        // 1-bit input: Clock select, High=CLKIN1 Low=CLKIN2
            .DADDR         (0),           // 7-bit input: DRP address
            .DCLK          (0),           // 1-bit input: DRP clock
            .DEN           (0),           // 1-bit input: DRP enable
            .DI            (0),           // 16-bit input: DRP data input
            .DWE           (0),           // 1-bit input: DRP write enable
            .PSCLK         (0),           // 1-bit input: Phase shift clock
            .PSEN          (0),           // 1-bit input: Phase shift enable
            .PSINCDEC      (0),           // 1-bit input: Phase shift increment/decrement
            .PWRDWN        (0),           // 1-bit input: Power-down
            .RST           (ASYNC_RESET)  // 1-bit input: Reset
        );

        // End of MMCME5_inst instantiation

`elsif FPGA_FAMILY_7SERIES

        // MMCME2_BASE: Base Mixed Mode Clock Manager
        //              7 Series
        // Xilinx HDL Language Template, version 2025.1

        MMCME2_BASE #(
            .BANDWIDTH("OPTIMIZED"),  // Jitter programming (OPTIMIZED, HIGH, LOW)
            .CLKFBOUT_MULT_F(Mval),  // Multiply value for all CLKOUT (2.000-64.000).  // M
            .CLKFBOUT_PHASE(0.0),  // Phase offset in degrees of CLKFB (-360.000-360.000).
            .CLKIN1_PERIOD(10.0),  // Input clock period in ns to ps resolution (i.e. 33.333 is 30 MHz).
            // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
            .CLKOUT1_DIVIDE(1),
            .CLKOUT2_DIVIDE(1),
            .CLKOUT3_DIVIDE(1),
            .CLKOUT4_DIVIDE(1),
            .CLKOUT5_DIVIDE(1),
            .CLKOUT6_DIVIDE(1),
            .CLKOUT0_DIVIDE_F(Oval),  // Divide amount for CLKOUT0 (1.000-128.000).  // O
            // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
            .CLKOUT0_DUTY_CYCLE(0.5),
            .CLKOUT1_DUTY_CYCLE(0.5),
            .CLKOUT2_DUTY_CYCLE(0.5),
            .CLKOUT3_DUTY_CYCLE(0.5),
            .CLKOUT4_DUTY_CYCLE(0.5),
            .CLKOUT5_DUTY_CYCLE(0.5),
            .CLKOUT6_DUTY_CYCLE(0.5),
            // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
            .CLKOUT0_PHASE(0.0),
            .CLKOUT1_PHASE(0.0),
            .CLKOUT2_PHASE(0.0),
            .CLKOUT3_PHASE(0.0),
            .CLKOUT4_PHASE(0.0),
            .CLKOUT5_PHASE(0.0),
            .CLKOUT6_PHASE(0.0),
            .CLKOUT4_CASCADE("FALSE"),  // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
            .DIVCLK_DIVIDE(Dval),  // Master division value (1-106)  // D
            .REF_JITTER1(0.0),  // Reference input jitter in UI (0.000-0.999).
            .STARTUP_WAIT("FALSE")  // Delays DONE until MMCM is locked (FALSE, TRUE)
        ) MMCME2_BASE_inst (
            // Clock Outputs: 1-bit (each) output: User configurable clock outputs
            .CLKOUT0  (clkout0),      // 1-bit output: CLKOUT0
            .CLKOUT0B (),             // 1-bit output: Inverted CLKOUT0
            .CLKOUT1  (),             // 1-bit output: CLKOUT1
            .CLKOUT1B (),             // 1-bit output: Inverted CLKOUT1
            .CLKOUT2  (),             // 1-bit output: CLKOUT2
            .CLKOUT2B (),             // 1-bit output: Inverted CLKOUT2
            .CLKOUT3  (),             // 1-bit output: CLKOUT3
            .CLKOUT3B (),             // 1-bit output: Inverted CLKOUT3
            .CLKOUT4  (),             // 1-bit output: CLKOUT4
            .CLKOUT5  (),             // 1-bit output: CLKOUT5
            .CLKOUT6  (),             // 1-bit output: CLKOUT6
            // Feedback Clocks: 1-bit (each) output: Clock feedback ports
            .CLKFBOUT (CLKFBOUT),     // 1-bit output: Feedback clock
            .CLKFBOUTB(),             // 1-bit output: Inverted CLKFBOUT
            // Status Ports: 1-bit (each) output: MMCM status ports
            .LOCKED   (LOCKED),       // 1-bit output: LOCK
            // Clock Inputs: 1-bit (each) input: Clock input
            .CLKIN1   (CLKIN1),       // 1-bit input: Clock
            // Control Ports: 1-bit (each) input: MMCM control ports
            .PWRDWN   (1'b0),         // 1-bit input: Power-down
            .RST      (ASYNC_RESET),  // 1-bit input: Reset
            // Feedback Clocks: 1-bit (each) input: Clock feedback ports
            .CLKFBIN  (CLKFBOUT)      // 1-bit input: Feedback clock
        );

        // End of MMCME2_BASE_inst instantiation

`elsif FPGA_FAMILY_ULTRASCALE
        // MMCME3_BASE instantiation
        MMCME3_BASE #(
            .BANDWIDTH("OPTIMIZED"),  // Jitter programming (HIGH, LOW, OPTIMIZED)
            .CLKFBOUT_MULT_F(Mval),  // Multiply value for all CLKOUT (2.000-64.000) (M counter)
            .CLKFBOUT_PHASE(0.0),  // Phase offset in degrees of CLKFB (-360.000-360.000)
            .CLKIN1_PERIOD(8),  // Input clock period in ns units, ps resolution (i.e., 33.333 is 30 MHz).
            .CLKOUT0_DIVIDE_F(Oval),  // Divide amount for CLKOUT0 (1.000-128.000)  (O counter for clk 0)
            .CLKOUT0_DUTY_CYCLE(0.5),
            .CLKOUT1_DUTY_CYCLE(0.5),
            .CLKOUT2_DUTY_CYCLE(0.5),
            .CLKOUT3_DUTY_CYCLE(0.5),
            .CLKOUT4_DUTY_CYCLE(0.5),
            .CLKOUT5_DUTY_CYCLE(0.5),
            .CLKOUT6_DUTY_CYCLE(0.5),
            .CLKOUT0_PHASE(0.0),
            .CLKOUT1_PHASE(0.0),
            .CLKOUT2_PHASE(0.0),
            .CLKOUT3_PHASE(0.0),
            .CLKOUT4_PHASE(0.0),
            .CLKOUT5_PHASE(0.0),
            .CLKOUT6_PHASE(0.0),
            .CLKOUT1_DIVIDE(1),  // (O counter)
            .CLKOUT2_DIVIDE(1),
            .CLKOUT3_DIVIDE(1),
            .CLKOUT4_DIVIDE(1),
            .CLKOUT5_DIVIDE(1),
            .CLKOUT6_DIVIDE(1),
            .CLKOUT4_CASCADE("FALSE"),  // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
            .DIVCLK_DIVIDE(Dval),  // Master division value (1-106) (D counter)
            .IS_CLKFBIN_INVERTED(1'b0),  // Optional inversion for CLKFBIN
            .IS_CLKIN1_INVERTED(1'b0),  // Optional inversion for CLKIN1
            .IS_PWRDWN_INVERTED(1'b0),  // Optional inversion for PWRDWN
            .IS_RST_INVERTED(1'b0),  // Optional inversion for RST
            .REF_JITTER1(0.0),  // Reference input jitter in UI (0.000-0.999)
            .STARTUP_WAIT("FALSE")  // Delays DONE until MMCM is locked (FALSE, TRUE)
        ) MMCME3_BASE_inst (
            .CLKOUT0  (clkout0),      // 1-bit output: CLKOUT0
            .CLKOUT0B (),             // 1-bit output: Inverted CLKOUT0
            .CLKOUT1  (),             // 1-bit output: CLKOUT1
            .CLKOUT1B (),             // 1-bit output: Inverted CLKOUT1
            .CLKOUT2  (),             // 1-bit output: CLKOUT2
            .CLKOUT2B (),             // 1-bit output: Inverted CLKOUT2
            .CLKOUT3  (),             // 1-bit output: CLKOUT3
            .CLKOUT3B (),             // 1-bit output: Inverted CLKOUT3
            .CLKOUT4  (),             // 1-bit output: CLKOUT4
            .CLKOUT5  (),             // 1-bit output: CLKOUT5
            .CLKOUT6  (),             // 1-bit output: CLKOUT6
            .CLKFBOUT (CLKFBOUT),     // 1-bit output: Feedback clock
            .CLKFBOUTB(),             // 1-bit output: Inverted CLKFBOUT
            .LOCKED   (LOCKED),       // 1-bit output: LOCK
            .CLKIN1   (CLKIN1),       // 1-bit input: Clock
            .PWRDWN   (1'b0),         // 1-bit input: Power-down
            .RST      (ASYNC_RESET),  // 1-bit input: Reset
            .CLKFBIN  (CLKFBOUT)      // 1-bit input: Feedback clock
        );

        //ULTRASCALEPLUS
`else
        // MMCME4_BASE instantiation
        MMCME4_BASE #(
            .BANDWIDTH("OPTIMIZED"),  // Jitter programming (HIGH, LOW, OPTIMIZED)
            .CLKFBOUT_MULT_F(Mval),  // Multiply value for all CLKOUT (2.000-64.000) (M counter)
            .CLKFBOUT_PHASE(0.0),  // Phase offset in degrees of CLKFB (-360.000-360.000)
            .CLKIN1_PERIOD(8),  // Input clock period in ns units, ps resolution (i.e., 33.333 is 30 MHz).
            .CLKOUT0_DIVIDE_F(Oval),  // Divide amount for CLKOUT0 (1.000-128.000)  (O counter for clk 0)
            .CLKOUT0_DUTY_CYCLE(0.5),
            .CLKOUT1_DUTY_CYCLE(0.5),
            .CLKOUT2_DUTY_CYCLE(0.5),
            .CLKOUT3_DUTY_CYCLE(0.5),
            .CLKOUT4_DUTY_CYCLE(0.5),
            .CLKOUT5_DUTY_CYCLE(0.5),
            .CLKOUT6_DUTY_CYCLE(0.5),
            .CLKOUT0_PHASE(0.0),
            .CLKOUT1_PHASE(0.0),
            .CLKOUT2_PHASE(0.0),
            .CLKOUT3_PHASE(0.0),
            .CLKOUT4_PHASE(0.0),
            .CLKOUT5_PHASE(0.0),
            .CLKOUT6_PHASE(0.0),
            .CLKOUT1_DIVIDE(1),  // (O counter)
            .CLKOUT2_DIVIDE(1),
            .CLKOUT3_DIVIDE(1),
            .CLKOUT4_DIVIDE(1),
            .CLKOUT5_DIVIDE(1),
            .CLKOUT6_DIVIDE(1),
            .CLKOUT4_CASCADE("FALSE"),  // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
            .DIVCLK_DIVIDE(Dval),  // Master division value (1-106) (D counter)
            .IS_CLKFBIN_INVERTED(1'b0),  // Optional inversion for CLKFBIN
            .IS_CLKIN1_INVERTED(1'b0),  // Optional inversion for CLKIN1
            .IS_PWRDWN_INVERTED(1'b0),  // Optional inversion for PWRDWN
            .IS_RST_INVERTED(1'b0),  // Optional inversion for RST
            .REF_JITTER1(0.0),  // Reference input jitter in UI (0.000-0.999)
            .STARTUP_WAIT("FALSE")  // Delays DONE until MMCM is locked (FALSE, TRUE)
        ) MMCME4_BASE_inst (
            .CLKOUT0  (clkout0),      // 1-bit output: CLKOUT0
            .CLKOUT0B (),             // 1-bit output: Inverted CLKOUT0
            .CLKOUT1  (),             // 1-bit output: CLKOUT1
            .CLKOUT1B (),             // 1-bit output: Inverted CLKOUT1
            .CLKOUT2  (),             // 1-bit output: CLKOUT2
            .CLKOUT2B (),             // 1-bit output: Inverted CLKOUT2
            .CLKOUT3  (),             // 1-bit output: CLKOUT3
            .CLKOUT3B (),             // 1-bit output: Inverted CLKOUT3
            .CLKOUT4  (),             // 1-bit output: CLKOUT4
            .CLKOUT5  (),             // 1-bit output: CLKOUT5
            .CLKOUT6  (),             // 1-bit output: CLKOUT6
            .CLKFBOUT (CLKFBOUT),     // 1-bit output: Feedback clock
            .CLKFBOUTB(),             // 1-bit output: Inverted CLKFBOUT
            .LOCKED   (LOCKED),       // 1-bit output: LOCK
            .CLKIN1   (CLKIN1),       // 1-bit input: Clock
            .PWRDWN   (1'b0),         // 1-bit input: Power-down
            .RST      (ASYNC_RESET),  // 1-bit input: Reset
            .CLKFBIN  (CLKFBOUT)      // 1-bit input: Feedback clock
        );

`endif
    endgenerate

`ifdef FPGA_FAMILY_VERSAL
    BUFGCE #(
        .SIM_DEVICE("VERSAL_HBM")
    ) clkout0_gbuf (
        .O (CLK_OUT),
        .I (clkout0),
        .CE(1'b1)
    );
`elsif FPGA_FAMILY_7SERIES
    BUFG clkout0_gbuf (
        .O(CLK_OUT),
        .I(clkout0)
    );
`elsif FPGA_FAMILY_ULTRASCALE
    BUFGCE clkout0_gbuf (
        .O (CLK_OUT),
        .I (clkout0),
        .CE(1'b1)
    );
`elsif FPGA_FAMILY_ULTRASCALEPLUS
    BUFGCE clkout0_gbuf (
        .O (CLK_OUT),
        .I (clkout0),
        .CE(1'b1)
    );
`else
    BUFG clkout0_gbuf (
        .O(CLK_OUT),
        .I(clkout0)
    );
`endif




endmodule

