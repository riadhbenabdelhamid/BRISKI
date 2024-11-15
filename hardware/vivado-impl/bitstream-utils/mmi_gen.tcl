#!/usr/bin/tclsh

open_checkpoint ../vivado-runs/post_route_physopt.dcp

#set_param tcl.collectionResultDisplayLimit 1024
#get a list of instance paths
#set proc_list [split [get_cells -hierarchical -filter { PRIMITIVE_TYPE=~ *bram.RAMB36* }] " "]
set proc_list [split [get_cells -hierarchical -filter { NAME=~ *instr_and_data_mem/RAM_reg }] " "]
#get a list of instance placements
set proc_placement_list [split [get_property LOC [get_cells -hierarchical -filter { PRIMITIVE_TYPE=~ *bram.RAMB36* }]] " "]

#these two lines are only used for testing purpose to avoid opening a dcp each time
#set proc_list {a0 a1 a2 a3}
#set proc_placement_list  {a0_aa a1_bb a2_cc a3_dd}


foreach proc_item $proc_list {puts $proc_item}
#foreach proc_placement_item $proc_placement_list {puts $proc_placement_item}

#open mmi generator file
set f [open "briski.mmi" w]
puts $f "\<\?xml version=\"1.0\" encoding=\"UTF-8\"\?\>"
puts $f "\<MemInfo Version=\"1\" Minor=\"0\"\>"

#populate procs
set i 0
foreach proc_item $proc_list {
puts $f "  \<Processor Endianness=\"Little\" InstPath=\"$proc_item\"\>"
append concatstring "    \<AddressSpace Name=\"core_" $i "_bram\" Begin=\"0\" End=\"4095\"\>"
puts $f $concatstring
set concatstring ""
puts $f "      \<BusBlock\>"
set coordinates [lindex $proc_placement_list $i]
set placement_parts [split $coordinates "_"]
set placement [lindex $placement_parts 1]
append concatstring "        \<BitLane MemType=\"RAMB32\" Placement=\"" $placement "\"\>"
puts $f $concatstring
set concatstring ""
puts $f "          \<DataWidth MSB=\"31\" LSB=\"0\"/\>"
puts $f "          \<AddressRange Begin=\"0\" End=\"4095\"/\>"
puts $f "          \<Parity ON=\"false\" NumBits=\"0\"/\>"
puts $f "        \</BitLane\>"
puts $f "      \</BusBlock\>"
puts $f "    \</AddressSpace\>"
puts $f "  \</Processor\>"
incr i
}

#config and drc 
puts $f "\<Config\>"
puts $f "  \<Option Name=\"Part\" Val=\"xcvu9p-flga2104-2L-e\"/\>"
puts $f "\</Config\>"
puts $f "\<DRC\>"
puts $f "  \<Rule Name=\"RDADDRCHANGE\" Val=\"false\"/\>"
puts $f "\</DRC\>"
puts $f "\</MemInfo\>"

#close mmi generator file
close $f
