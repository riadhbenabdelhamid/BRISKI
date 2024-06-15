set time_1 [clock seconds]
#synth_design -top ${TOP_RTL} -part $FPGA_PART -directive PerformanceOptimized -retiming -shreg_min_size 10 -flatten_hierarchy rebuilt 
synth_design -top ${TOP_RTL} -part $FPGA_PART -directive AreaOptimized_High -retiming -shreg_min_size 10 -flatten_hierarchy rebuilt 
set time_2 [clock seconds]
puts "Elapsed time (Synth step)= [expr [expr $time_2 - $time_1] / 3600] : [expr [expr [expr $time_2 - $time_1] / 60] % 3600] : [expr [expr $time_2 - $time_1] % 60]"
write_checkpoint -force $outputDir/post_synth
report_clocks -file $outputDir/clocks.rpt
report_timing_summary -file $outputDir/post_synth_timing_summary.rpt
report_utilization -file $outputDir/post_synth_util.rpt
