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

# Multievent type
set multievent 3

# create the module list (global for the ved)
set modullist {}
lappend modullist "vme $modtypearr(mesytec_madc32) 0x06000000 0"
# lappend modullist "vme $modtypearr(mesytec_mqdc32) 0x07000000 0"
lappend modullist "vme $modtypearr(mesytec_mtdc32) 0x08000000 0"
lappend modullist "vme $modtypearr(vme_mcst) $mcst_addr 0"
lappend modullist "vme $modtypearr(vme_cblt) $cblt_addr 0"

ved modullist create $modullist 

# setup the MCST/CBLT chain
# mxdc32_init_cblt mcst_module cblt_module
# 2 is the index of vme_mcst in the memberlist
# 3 is the index of vme_cblt in the memberlist
ved command1 mxdc32_init_cblt 2 3

# read the initial timecounter:
puts "Inital timecounter:"

puts "ADC:"
set ts_lo [ved command1 mxdc32_reg 0 0x609C]
set ts_hi [ved command1 mxdc32_reg 0 0x609E]
puts "ts_lo: $ts_lo    ts_hi: $ts_hi"

puts "TDC:"
set ts_lo [ved command1 mxdc32_reg 1 0x609C]
set ts_hi [ved command1 mxdc32_reg 1 0x609E]
puts "ts_lo: $ts_lo    ts_hi: $ts_hi"

# stop first
ved command1 mxdc32_reg 2 0x60AE 0x3
# reset timestamp counter
ved command1 mxdc32_reg 2 0x6090 0x3
# then start again
ved command1 mxdc32_reg 2 0x60AE 0x0

# After some time, stop the counter
puts ""
puts ""
after 1000
ved command1 mxdc32_reg 2 0x60AE 0x3

# read the final  timecounter:
puts "Afterchange timecounter:"

puts "ADC:"
set ts_lo [ved command1 mxdc32_reg 0 0x609C]
set ts_hi [ved command1 mxdc32_reg 0 0x609E]
puts "ts_lo: $ts_lo    ts_hi: $ts_hi"

puts "TDC:"
set ts_lo [ved command1 mxdc32_reg 1 0x609C]
set ts_hi [ved command1 mxdc32_reg 1 0x609E]
puts "ts_lo: $ts_lo    ts_hi: $ts_hi"
