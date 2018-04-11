#! /bin/sh
#\
exec emssh $0 $*

# read a file with module type definitions
source /usr/local/ems/share/modultypes_arr.tcl

# establish the connection
ems_connect
rename [ems_open ved] ved

# reset the ems server
ved reset

# MCST and CBLT address 
set mcst_addr 0xBB000000
set cblt_addr 0xAA000000

# create the module list (global for the ved)
set modullist {}
lappend modullist "vme $modtypearr(vme_mcst) $mcst_addr 0"
lappend modullist "vme $modtypearr(vme_cblt) $cblt_addr 0"
lappend modullist "vme $modtypearr(mesytec_mqdc32) 0x07000000 0"
lappend modullist "vme $modtypearr(mesytec_madc32) 0x09000000 0"
lappend modullist "vme $modtypearr(mesytec_mtdc32) 0x0A000000 0"
ved modullist create $modullist 

# set module name array
set modulname(2) qdc
set modulname(3) adc
set modulname(4) tdc

# Init: soft reset
puts "Soft reset first\n"
ved command1 mqdc32_init -1 0xFF 1 0 0 0
ved command1 madc32_init -1 0xFF 4 2 1 1 0 0
ved command1 mtdc32_init -1 0xFF 6 1 1 0 0 0

# setup the MCST/CBLT chain
# mxdc32_init_cblt mcst_module cblt_module
# 0 is the index of vme_mcst in the memberlist
# 1 is the index of vme_cblt in the memberlist
ved command1 mxdc32_init_cblt 0 1

proc read_timestamp {mcst_module modullist} {
    # stop the counter first
    ved command1 mxdc32_reg $mcst_module 0x60AE 0x3
    # after 1000

    upvar 1 ts ts ts_lo ts_lo ts_hi ts_hi
    upvar 1 modulname modulname
    uplevel 1 {set ts_list {}}
    # read the timestamps
    foreach module $modullist {
        set ts_lo [ved command1 mxdc32_reg $module 0x609C]
        set ts_hi [ved command1 mxdc32_reg $module 0x609E]
        set ts [expr ( $ts_hi<<16 ) + $ts_lo]
        puts "$modulname($module): $ts (lo: $ts_lo , hi: $ts_hi)"
        uplevel 1 {lappend ts_list $ts}
    }

    # start the counter again
    ved command1 mxdc32_reg $mcst_module 0x60AE 0x0
}

########### Main ####################

# read the initial timecounter:
puts "Inital timecounter:"
read_timestamp 0 {2 3 4}
puts "$ts_list\n"

# Init timestamp counter
puts "Initialize timestamp counter\n"
# stop first
ved command1 mxdc32_reg 0 0x60AE 0x3
# reset timestamp counter
ved command1 mxdc32_reg 0 0x6090 0x3
# then start again
ved command1 mxdc32_reg 0 0x60AE 0x0

# Loop
set loop_counter 100
set file [open tc_list.txt w]
puts $file "$modulname(2)\t$modulname(3)\t$modulname(4)"
for {set i 0} {$i < $loop_counter} {incr i 1} {
    puts "$i:"
    read_timestamp 0 {2 3 4}
    puts "$ts_list\n"
    puts $file "$ts_list"
    flush $file

    # interval: 1000ms
    after 1000
}

# close 
close $file
ved close
ems_disconnect
puts "End."
