set time_1 [clock seconds]
opt_design -directive ExploreWithRemap
set time_2 [clock seconds]
puts "Elapsed time (Opt step)= [expr [expr $time_2 - $time_1] / 3600] : [expr [expr [expr $time_2 - $time_1] / 60] % 3600] : [expr [expr $time_2 - $time_1] % 60]"
write_checkpoint -force $outputDir/post_opt
