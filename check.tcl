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

# Readout type and Multievent type
set ro_type 2
set multievent 3

# create the module list (global for the ved)
set modullist {}
lappend modullist "vme $modtypearr(mesytec_madc32) 0x06000000 0"
# lappend modullist "vme $modtypearr(mesytec_mqdc32) 0x07000000 0"
lappend modullist "vme $modtypearr(mesytec_mtdc32) 0x08000000 0"
if {$ro_type>0} {
    lappend modullist "vme $modtypearr(vme_mcst) $mcst_addr 0"
}
if {$ro_type>1} {
    lappend modullist "vme $modtypearr(vme_cblt) $cblt_addr 0"
}
ved modullist create $modullist 

# setup the MCST/CBLT chain
if {$ro_type==1} {
    # mxdc32_init_cblt mcst_module
    # 2 is the index of vme_mcst in the memberlist
    ved command1 mxdc32_init_cblt 2
} elseif {$ro_type==2} {
    # mxdc32_init_cblt mcst_module cblt_module
    # 3 is the index of vme_cblt in the memberlist
    ved command1 mxdc32_init_cblt 2 3
}

# read the original module id
set moduleid [ved command1 mxdc32_reg 0 0x6004]
puts $moduleid
set moduleid [ved command1 mxdc32_reg 1 0x6004]
puts $moduleid

# setup the same module id
ved command1 mxdc32_reg 2 0x6004 30 

# read the current module id
set moduleid [ved command1 mxdc32_reg 0 0x6004]
puts $moduleid
set moduleid [ved command1 mxdc32_reg 1 0x6004]
puts $moduleid
