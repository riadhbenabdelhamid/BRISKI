open_checkpoint $outputDir/post_place_physopt.dcp
set time_1 [clock seconds]
route_design -directive AggressiveExplore -tns_cleanup 
#route_design 
set time_2 [clock seconds]
puts "Elapsed time (Route step)= [expr [expr $time_2 - $time_1] / 3600] Hours : [expr [expr [expr $time_2 - $time_1] / 60] % 60] Minutes : [expr [expr $time_2 - $time_1] % 60] Seconds"
write_checkpoint -force $outputDir/post_route.dcp
