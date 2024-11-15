set time_1 [clock seconds]
#synth_design -top ${TOP_RTL} -part $FPGA_PART -directive PerformanceOptimized -retiming -shreg_min_size 10 -flatten_hierarchy rebuilt 
#synth_design -top ${TOP_RTL} -part $FPGA_PART -directive AreaOptimized_High -retiming -shreg_min_size 3 -flatten_hierarchy rebuilt 
synth_design \
             -top ${TOP_RTL} \
	     -part $FPGA_PART \
	     -directive AreaOptimized_High \
	     -retiming \
	     -shreg_min_size 5 \
	     -flatten_hierarchy rebuilt \
	     -verilog_define MMCM_OUT_FREQ_MHZ=$MMCM_OUT_FREQ_MHZ \
	     -verilog_define NUM_PIPE_STAGES=$NUM_PIPE_STAGES \
	     -verilog_define NUM_THREADS=$NUM_THREADS \
	     -verilog_define ENABLE_BRAM_REGFILE=$ENABLE_BRAM_REGFILE \
	     -verilog_define ENABLE_ALU_DSP=$ENABLE_ALU_DSP \
	     -verilog_define ENABLE_UNIFIED_BARREL_SHIFTER=$ENABLE_UNIFIED_BARREL_SHIFTER \
	     -verilog_define HEX_PROG=$HEX_PROG 
	     #-resource_sharing on \
             #-control_set_opt_threshold 12


#synth_design -top ${TOP_RTL} -part $FPGA_PART -directive AreaOptimized_High -retiming -shreg_min_size 5 -flatten_hierarchy full
#synth_design -top ${TOP_RTL} -part $FPGA_PART -directive AreaOptimized_High -retiming -shreg_min_size 10 -flatten_hierarchy full
#synth_design -top ${TOP_RTL} -part $FPGA_PART -directive AreaOptimized_High -retiming -shreg_min_size 10 -flatten_hierarchy none
set time_2 [clock seconds]
puts "Elapsed time (Synth step)= [expr [expr $time_2 - $time_1] / 3600] : [expr [expr [expr $time_2 - $time_1] / 60] % 3600] : [expr [expr $time_2 - $time_1] % 60]"
write_checkpoint -force $outputDir/post_synth
report_clocks -file $outputDir/clocks.rpt
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_utilization -file $outputDir/post_synth_util.rpt
