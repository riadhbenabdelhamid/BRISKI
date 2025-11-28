open_checkpoint $outputDir/post_opt.dcp
set time_1 [clock seconds]

    #Optional
    #DPlace.ReducePinDensity.high
if { $FPGA_FAMILY eq "VERSAL" } {

  place_design -directive AggressiveExplore -subdirective { 
	  Floorplan.WLDrivenBlockPlacement 
	  GPlace.ExtraTimingOpt.high 
	  GPlace.ExtraTimingUpdate 
	  GPlace.ReduceCongestion.med 
	  DPlace.ExtraTimingOpt.high 
	  DPlace.ExtraTimingUpdate 
    }

} else {

  set place_directive ExtraPostPlacementOpt
  place_design -directive $place_directive -verbose

}


set time_2 [clock seconds]
puts "Elapsed time (Place step)= [expr [expr $time_2 - $time_1] / 3600] Hours : [expr [expr [expr $time_2 - $time_1] / 60] % 60] Minutes : [expr [expr $time_2 - $time_1] % 60] Seconds"
write_checkpoint -force $outputDir/post_place.dcp
