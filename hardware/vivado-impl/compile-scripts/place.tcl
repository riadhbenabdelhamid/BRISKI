open_checkpoint $outputDir/post_opt.dcp
set place_directive ExtraPostPlacementOpt
set time_1 [clock seconds]
#place_design -directive ${place_directive} -verbose
place_design
set time_2 [clock seconds]
puts "Elapsed time (Place step)= [expr [expr $time_2 - $time_1] / 3600] : [expr [expr [expr $time_2 - $time_1] / 60] % 3600] : [expr [expr $time_2 - $time_1] % 60]"
write_checkpoint -force $outputDir/post_place.dcp
