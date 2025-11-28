set time_1 [clock seconds]

set vdefs [list \
    "MMCM_OUT_FREQ_MHZ=$MMCM_OUT_FREQ_MHZ" \
    "NUM_PIPE_STAGES=$NUM_PIPE_STAGES" \
    "NUM_THREADS=$NUM_THREADS" \
    "ENABLE_BRAM_REGFILE=$ENABLE_BRAM_REGFILE" \
    "ENABLE_ALU_DSP=$ENABLE_ALU_DSP" \
    "ENABLE_UNIFIED_BARREL_SHIFTER=$ENABLE_UNIFIED_BARREL_SHIFTER" \
    "ENABLE_FETCH_ADDR_PAD=$ENABLE_FETCH_ADDR_PAD" \
    "ENABLE_LUTRAM_PCMEM=$ENABLE_LUTRAM_PCMEM" \
    "HEX_PROG=$HEX_PROG" \
    "FPGA_FAMILY_$FPGA_FAMILY" \
]


# Only add the bare macro when set to 1
if {[info exists ENABLE_ZALRSC] && [string equal $ENABLE_ZALRSC "true"]} {
    lappend vdefs ENABLE_ZALRSC
}

if { $FPGA_FAMILY eq "VERSAL" } {
#  generate_target all [get_ips]
#  synth_ip [get_ips]
  generate_target all [get_files cips_briski.bd]
}

synth_design \
             -top ${TOP_RTL} \
	     -part $FPGA_PART \
             -include_dirs ${INC_DIR}\
	     -directive AreaOptimized_High \
	     -gated_clock_conversion auto \
	     -resource_sharing off \
	     -fsm_extraction one_hot \
	     -flatten_hierarchy rebuilt \
	     -retiming \
	     -shreg_min_size ${SHREG_MIN_SIZE} \
	     -verilog_define $vdefs
	     #-resource_sharing on \
	     #-directive AreaOptimized_High \
	     #-flatten_hierarchy rebuilt \
	     #-directive PerformanceOptimized \
	     -global_retiming on \
             #-control_set_opt_threshold 12

#synth_design -help
#synth_design -top core_dummy_wrapper -part $FPGA_PART -flatten_hierarchy none -gated_clock_conversion on -directive AreaMultThresholdDSP -global_retiming off -fsm_extraction off -keep_equivalent_registers on -resource_sharing auto -control_set_opt_threshold 8 -no_lc on -no_srlextract off -shreg_min_size 6
#synth_design -top core_dummy_wrapper -part $FPGA_PART -flatten_hierarchy none -gated_clock_conversion on -directive AreaMultThresholdDSP -global_retiming off -fsm_extraction off 

set time_2 [clock seconds]
puts "Elapsed time (Synth step)= [expr [expr $time_2 - $time_1] / 3600] Hours : [expr [expr [expr $time_2 - $time_1] / 60] % 60] Minutes : [expr [expr $time_2 - $time_1] % 60] Seconds"
write_checkpoint -force $outputDir/post_synth
report_clocks -file $outputDir/clocks.rpt
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_utilization -file $outputDir/post_synth_util.rpt
