set bitfile "bitstream/morse.bit"

open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target [lindex [get_hw_targets] 0]
set_property PROGRAM.FILE $bitfile [get_hw_devices xc7a100t_0]
program_hw_devices [get_hw_devices xc7a100t_0]
close_hw_manager
puts "Programming complete!"