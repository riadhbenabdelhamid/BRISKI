set time_1 [clock seconds]
write_bitstream -force $outputDir/fpga_bitstream
set time_2 [clock seconds]
puts "Elapsed time (Bitstream step)= [expr [expr $time_2 - $time_1] / 3600] Hours : [expr [expr [expr $time_2 - $time_1] / 60] % 60] Minutes : [expr [expr $time_2 - $time_1] % 60] Seconds"
