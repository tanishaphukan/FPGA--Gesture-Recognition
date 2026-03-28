# Complete FPGA Build Flow
# Runs synthesis, implementation, and bitstream generation

puts "=========================================="
puts "EMG Gesture Recognition - Complete Build Flow"
puts "=========================================="

# Check if project exists
if {![file exists "vivado_project/emg_gesture_fpga.xpr"]} {
    puts "\n⚠ Project not found. Creating project first..."
    source create_vivado_project.tcl
    puts "\nProject created. Continuing with build flow..."
}

# Open project
puts "\n[1/5] Opening project..."
open_project vivado_project/emg_gesture_fpga.xpr

# Run Synthesis
puts "\n[2/5] Running Synthesis..."
puts "  This may take 5-10 minutes..."
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis results
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "\n❌ ERROR: Synthesis failed!"
    puts "Check logs: vivado_project/emg_gesture_fpga.runs/synth_1/runme.log"
    exit 1
}

puts "\n✓ Synthesis completed successfully"

# Open synthesis run and generate reports
open_run synth_1
report_utilization -file reports/utilization_synth.txt
report_timing_summary -file reports/timing_synth.txt

# Display synthesis results
puts "\n--- Synthesis Results ---"
puts "Utilization:"
set util [report_utilization -return_string]
if {[regexp {Slice LUTs.*?(\d+)} $util -> luts]} {
    puts "  LUTs: $luts"
}
if {[regexp {Slice Registers.*?(\d+)} $util -> regs]} {
    puts "  Registers: $regs"
}
if {[regexp {Block RAM Tile.*?(\d+)} $util -> brams]} {
    puts "  BRAMs: $brams"
}
if {[regexp {DSPs.*?(\d+)} $util -> dsps]} {
    puts "  DSPs: $dsps"
}

# Check timing
set timing [report_timing_summary -return_string]
if {[regexp {WNS\(ns\).*?([-\d.]+)} $timing -> wns]} {
    puts "Timing:"
    puts "  WNS: $wns ns"
    if {$wns < 0} {
        puts "  ⚠ WARNING: Timing not met!"
    } else {
        puts "  ✓ Timing constraints met"
    }
}

# Run Implementation
puts "\n[3/5] Running Implementation..."
puts "  This may take 10-15 minutes..."
reset_run impl_1
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check implementation results
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "\n❌ ERROR: Implementation failed!"
    puts "Check logs: vivado_project/emg_gesture_fpga.runs/impl_1/runme.log"
    exit 1
}

puts "\n✓ Implementation completed successfully"

# Open implementation run and generate reports
open_run impl_1
report_utilization -file reports/utilization_impl.txt
report_timing_summary -file reports/timing_impl.txt
report_power -file reports/power_impl.txt

# Display implementation results
puts "\n--- Implementation Results ---"
set util [report_utilization -return_string]
if {[regexp {Slice LUTs.*?(\d+)} $util -> luts]} {
    puts "  LUTs: $luts"
}
if {[regexp {Slice Registers.*?(\d+)} $util -> regs]} {
    puts "  Registers: $regs"
}

set timing [report_timing_summary -return_string]
if {[regexp {WNS\(ns\).*?([-\d.]+)} $timing -> wns]} {
    puts "  WNS: $wns ns"
    if {$wns < 0} {
        puts "  ❌ ERROR: Timing not met! Cannot generate bitstream."
        exit 1
    }
}

set power [report_power -return_string]
if {[regexp {Total On-Chip Power \(W\).*?([\d.]+)} $power -> total_power]} {
    puts "  Power: $total_power W"
}

# Generate Bitstream
puts "\n[4/5] Generating Bitstream..."
puts "  This may take 5-10 minutes..."
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Check bitstream generation
set bitstream_file "vivado_project/emg_gesture_fpga.runs/impl_1/emg_gesture_recognition_top.bit"
if {[file exists $bitstream_file]} {
    puts "\n✓ Bitstream generated successfully"
    puts "  Location: $bitstream_file"
    set size [file size $bitstream_file]
    puts "  Size: [expr $size / 1024] KB"
} else {
    puts "\n❌ ERROR: Bitstream generation failed!"
    exit 1
}

# Summary
puts "\n[5/5] Build Summary"
puts "=========================================="
puts "✓ Synthesis: PASSED"
puts "✓ Implementation: PASSED"
puts "✓ Bitstream: GENERATED"
puts "=========================================="

puts "\nNext step: Program FPGA"
puts "  1. Connect your FPGA board via USB"
puts "  2. Run: vivado -mode batch -source program_fpga.tcl"
puts "  Or open Hardware Manager in Vivado GUI"

puts "\nReports saved in: reports/"
puts "  - utilization_synth.txt"
puts "  - timing_synth.txt"
puts "  - utilization_impl.txt"
puts "  - timing_impl.txt"
puts "  - power_impl.txt"

close_project
