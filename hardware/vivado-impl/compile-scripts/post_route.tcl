# This script is a slightly modified version based on the one in the following web link : 
# https://hwjedi.wordpress.com/2017/02/09/vivado-non-project-mode-part-iii-phys-opt-looping/
# The current script targets a routed dcp instead of a placed one and therefore drop constraining the clock 
open_checkpoint $outputDir/post_route.dcp
set time_1 [clock seconds]

set WNS [ get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup] ]

if {$WNS < 0.000} {
  phys_opt_design -directive AggressiveExplore
  phys_opt_design -directive AlternateReplication
  phys_opt_design -directive Explore 
  phys_opt_design -directive AggressiveFanoutOpt
}

set WNS [ get_property SLACK [get_timing_paths -max_paths 1 -nworst 1 -setup] ]
# Post Place PhysOpt Looping
#set NLOOPS 8 
set NLOOPS 12
set TNS_PREV 0
set WNS_SRCH_STR "WNS="
set TNS_SRCH_STR "TNS="

if {$WNS < 0.000} {

    set TNS [ exec grep $TNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$TNS_SRCH_STR//p" | cut -d\  -f 1]
    set TNS_ITER_PREV $TNS

    for {set i 0} {$i < $NLOOPS} {incr i} {
        phys_opt_design -directive AlternateReplication
        set WNS [ exec grep $WNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$WNS_SRCH_STR//p" | cut -d\  -f 1]
        set TNS [ exec grep $TNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$TNS_SRCH_STR//p" | cut -d\  -f 1]
        if {($TNS == $TNS_PREV && $i > 0) || $WNS >= 0.000} {
            break
        }
        set TNS_PREV $TNS

        phys_opt_design -directive AggressiveFanoutOpt
        set WNS [ exec grep $WNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$WNS_SRCH_STR//p" | cut -d\  -f 1]
        set TNS [ exec grep $TNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$TNS_SRCH_STR//p" | cut -d\  -f 1]
        if {($TNS == $TNS_PREV && $i > 0) || $WNS >= 0.000} {
            break
        }
        set TNS_PREV $TNS

        phys_opt_design -directive AggressiveExplore
        set WNS [ exec grep $WNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$WNS_SRCH_STR//p" | cut -d\  -f 1]
        set TNS [ exec grep $TNS_SRCH_STR vivado.log | tail -1 | sed -n -e "s/^.*$TNS_SRCH_STR//p" | cut -d\  -f 1]
        if {($TNS == $TNS_PREV) || $WNS >= 0.000} {
            break
        }
        set TNS_PREV $TNS

        if {($TNS_PREV == $TNS_ITER_PREV) || $WNS >= 0.000} {
            break
        }
    }

}
set time_2 [clock seconds]
puts "Elapsed time (Post Route step)= [expr [expr $time_2 - $time_1] / 3600] : [expr [expr [expr $time_2 - $time_1] / 60] % 3600] : [expr [expr $time_2 - $time_1] % 60]"
write_checkpoint -force $outputDir/post_route_physopt
#--------------reports--------------------------------#
report_timing_summary -file $outputDir/post_route_timing_summary.rpt
#-----------------report------------------------------#
report_timing_summary -file $outputDir/post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $outputDir/post_route_timing.rpt
report_pulse_width -file $outputDir/post_route_pulse_width.rpt
report_clock_utilization -file $outputDir/clock_util.rpt
report_utilization -hierarchical -file $outputDir/post_route_util.rpt
report_power -file $outputDir/post_route_power.rpt
report_drc -file $outputDir/post_imp_drc.rpt
