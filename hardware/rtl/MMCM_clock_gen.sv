module MMCM_clock_gen #(
    parameter int MMCM_OUT_FREQ = 650
) (
    input logic CLKIN1,
    input logic ASYNC_RESET,
    output logic CLK_OUT,
    output logic LOCKED
);
    // Function to derive Master Divider (D)
    function int DeriveMasterDiv (input int freq);
        case (freq)
            100, 150, 200, 250, 300, 350, 360, 370, 380, 390, 
            400, 420, 450, 500, 550, 600, 635, 650, 665, 670, 675, 
	    700, 720, 735, 750, 765, 770, 780, 790,
	    800 : return 5;
            660, 670, 680, 710, 730 : return 4;
            default: return 0;
        endcase
    endfunction

    // Function to derive Master Multiplier (M)
    function real DeriveMasterMult (input int freq);
        case (freq)
            100: return 64.0;
            150, 350, 360: return 63.75;
            200, 400, 500: return 64.0;
            250: return 63.75;
            300, 450: return 63.0;
            370: return 55.5;
            380: return 57.0;
            390: return 58.5;
            420, 550: return 63.25;
            600: return 63.0;
            635: return 63.5;
            650: return 61.75;
            660: return 44.875;
            665: return 63.125;
            670: return 63.625;
            675: return 60.75;
            680: return 46.25;
            700: return 63.0;
	    710: return 51.125;
	    720: return 57.625;
	    730: return 49.625;
	    735: return 62.5;
	    750: return 63.75;
	    765: return 61.25;
	    770: return 61.625;
	    780: return 62.375;
	    790: return 63.25;
	    800: return 64.0;
            default: return 0.0;
        endcase
    endfunction

    // Function to derive Output Divider (O)
    function real DeriveOutDiv (input int freq);
        case (freq)
            100: return 16.0;
            150: return 10.625;
            200: return 8.0;
            250: return 6.375;
            300: return 5.25;
            350: return 4.5;
            360: return 4.375;
            370, 380, 390: return 3.75;
            400: return 4.0;
            420: return 3.75;
            450: return 3.5;
            500: return 3.125;
            550: return 2.875;
            600: return 2.625;
            635: return 2.5;
            650: return 2.375;
            660, 680, 730, 735, 750: return 2.125;
	    665, 670: return 2.375;
            720: return 2.0;
            675, 700, 710: return 2.25;
	    765: return 2.0;
	    770: return 2.0;
	    780: return 2.0;
	    790: return 2.0;
	    800: return 2.0;
            default: return 0.0;
        endcase
    endfunction

    logic CLKFBOUT;
    logic clkout0;

    // MMCME4_BASE instantiation
    MMCME4_BASE #(
        .BANDWIDTH("OPTIMIZED"),   // Jitter programming (HIGH, LOW, OPTIMIZED)
        .CLKFBOUT_MULT_F(DeriveMasterMult(MMCM_OUT_FREQ)),     // Multiply value for all CLKOUT (2.000-64.000) (M counter)
        .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000)
        .CLKIN1_PERIOD(8),         // Input clock period in ns units, ps resolution (i.e., 33.333 is 30 MHz).
        .CLKOUT0_DIVIDE_F(DeriveOutDiv(MMCM_OUT_FREQ)),    // Divide amount for CLKOUT0 (1.000-128.000)  (O counter for clk 0)
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
        .CLKOUT1_DIVIDE(1),    // (O counter)
        .CLKOUT2_DIVIDE(1),
        .CLKOUT3_DIVIDE(1),
        .CLKOUT4_DIVIDE(1),
        .CLKOUT5_DIVIDE(1),
        .CLKOUT6_DIVIDE(1),
        .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
        .DIVCLK_DIVIDE(DeriveMasterDiv(MMCM_OUT_FREQ)),    // Master division value (1-106) (D counter)
        .IS_CLKFBIN_INVERTED(1'b0), // Optional inversion for CLKFBIN
        .IS_CLKIN1_INVERTED(1'b0),  // Optional inversion for CLKIN1
        .IS_PWRDWN_INVERTED(1'b0),  // Optional inversion for PWRDWN
        .IS_RST_INVERTED(1'b0),     // Optional inversion for RST
        .REF_JITTER1(0.0),          // Reference input jitter in UI (0.000-0.999)
        .STARTUP_WAIT("FALSE")      // Delays DONE until MMCM is locked (FALSE, TRUE)
    ) MMCME4_BASE_inst (
        .CLKOUT0(clkout0),     // 1-bit output: CLKOUT0
        .CLKOUT0B(),           // 1-bit output: Inverted CLKOUT0
        .CLKOUT1(),            // 1-bit output: CLKOUT1
        .CLKOUT1B(),           // 1-bit output: Inverted CLKOUT1
        .CLKOUT2(),            // 1-bit output: CLKOUT2
        .CLKOUT2B(),           // 1-bit output: Inverted CLKOUT2
        .CLKOUT3(),            // 1-bit output: CLKOUT3
        .CLKOUT3B(),           // 1-bit output: Inverted CLKOUT3
        .CLKOUT4(),            // 1-bit output: CLKOUT4
        .CLKOUT5(),            // 1-bit output: CLKOUT5
        .CLKOUT6(),            // 1-bit output: CLKOUT6
        .CLKFBOUT(CLKFBOUT),   // 1-bit output: Feedback clock
        .CLKFBOUTB(),          // 1-bit output: Inverted CLKFBOUT
        .LOCKED(LOCKED),       // 1-bit output: LOCK
        .CLKIN1(CLKIN1),       // 1-bit input: Clock
        .PWRDWN(1'b0),         // 1-bit input: Power-down
        .RST(ASYNC_RESET),     // 1-bit input: Reset
        .CLKFBIN(CLKFBOUT)     // 1-bit input: Feedback clock
    );

    BUFG clkout0_gbuf (
        .O(CLK_OUT),
        .I(clkout0)
    );

endmodule

