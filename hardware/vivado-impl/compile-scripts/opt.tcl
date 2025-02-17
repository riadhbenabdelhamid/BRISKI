set time_1 [clock seconds]
#opt_design -resynth_remap
opt_design -directive ExploreWithRemap -debug_log -verbose
#opt_design -aggressive_remap  -muxf_remap -carry_remap -control_set_merge -merge_equivalent_drivers
#opt_design -directive ExploreSequentialArea
#opt_design -directive ExploreArea
set time_2 [clock seconds]
puts "Elapsed time (Opt step)= [expr [expr $time_2 - $time_1] / 3600] Hours : [expr [expr [expr $time_2 - $time_1] / 60] % 60] Minutes : [expr [expr $time_2 - $time_1] % 60] Seconds"
write_checkpoint -force $outputDir/post_opt
