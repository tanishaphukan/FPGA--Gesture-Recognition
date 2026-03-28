# FPGA Programming Script
# Programs the Arty A7 board with generated bitstream

puts "=========================================="
puts "Programming FPGA Board"
puts "=========================================="

# Check if bitstream exists
set bitstream_file "vivado_project/emg_gesture_fpga.runs/impl_1/emg_gesture_recognition_top.bit"

if {![file exists $bitstream_file]} {
    puts "\n❌ ERROR: Bitstream file not found!"
    puts "Expected location: $bitstream_file"
    puts "\nPlease run synthesis and implementation first:"
    puts "  vivado -mode batch -source run_complete_flow.tcl"
    exit 1
}

puts "\n✓ Bitstream found: $bitstream_file"
puts "  Size: [expr [file size $bitstream_file] / 1024] KB"

# Open Hardware Manager
puts "\n[1/5] Opening Hardware Manager..."
open_hw_manager

# Connect to hardware server
puts "\n[2/5] Connecting to hardware server..."
connect_hw_server -allow_non_jtag -url localhost:3121

# Open hardware target
puts "\n[3/5] Scanning for FPGA boards..."
if {[catch {open_hw_target} result]} {
    puts "\n❌ ERROR: No FPGA board detected!"
    puts "\nTroubleshooting:"
    puts "  1. Check USB cable connection"
    puts "  2. Verify board is powered on"
    puts "  3. Install Digilent Adept or Xilinx Cable Drivers"
    puts "  4. Try a different USB port"
    puts "  5. Check Device Manager (Windows) or lsusb (Linux)"
    close_hw_manager
    exit 1
}

# Get hardware device
set hw_devices [get_hw_devices]
if {[llength $hw_devices] == 0} {
    puts "\n❌ ERROR: No FPGA devices found in JTAG chain!"
    close_hw_target
    disconnect_hw_server
    close_hw_manager
    exit 1
}

set device [lindex $hw_devices 0]
puts "\n✓ Found FPGA device: $device"

# Get device properties
set part [get_property PART $device]
puts "  Part: $part"

# Verify correct device
if {![string match "*xc7a35t*" $part] && ![string match "*xc7a100t*" $part]} {
    puts "\n⚠ WARNING: Unexpected FPGA part!"
    puts "  Expected: xc7a35t or xc7a100t (Arty A7)"
    puts "  Found: $part"
    puts "\nContinuing anyway..."
}

# Program device
puts "\n[4/5] Programming FPGA..."
puts "  This will take about 10 seconds..."

current_hw_device $device
set_property PROGRAM.FILE $bitstream_file $device

if {[catch {program_hw_devices $device} result]} {
    puts "\n❌ ERROR: Programming failed!"
    puts "Error message: $result"
    close_hw_target
    disconnect_hw_server
    close_hw_manager
    exit 1
}

# Refresh device
refresh_hw_device $device

puts "\n✓ Programming completed successfully!"

# Verify programming
puts "\n[5/5] Verifying configuration..."
set done_status [get_property REGISTER.BOOTSTS.DONE $device]
if {$done_status == 1} {
    puts "✓ FPGA configuration verified - DONE pin is HIGH"
} else {
    puts "⚠ WARNING: DONE pin is not HIGH"
    puts "  The FPGA may not be configured correctly"
}

# Close connections
close_hw_target
disconnect_hw_server
close_hw_manager

puts "\n=========================================="
puts "FPGA Programming Complete!"
puts "=========================================="

puts "\nYour EMG gesture recognition system is now running on the FPGA!"

puts "\nNext steps:"
puts "  1. Check status LEDs on the board"
puts "  2. Connect EMG sensor to Pmod connector"
puts "  3. Connect serial terminal (115200 baud) to monitor output"
puts "  4. Test with gestures!"

puts "\nSerial Terminal Commands:"
puts "  Linux/Mac: screen /dev/ttyUSB1 115200"
puts "  Windows: Use PuTTY or Tera Term"
puts "    - Baud: 115200"
puts "    - Data bits: 8"
puts "    - Stop bits: 1"
puts "    - Parity: None"

puts "\nFor testing without hardware:"
puts "  - Press BTN0 to inject test pattern"
puts "  - Observe LED outputs for gesture classification"

puts "\n=========================================="
