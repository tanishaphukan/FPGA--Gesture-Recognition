# Vivado Project Creation Script
# EMG Gesture Recognition FPGA Implementation

# Project settings
set project_name "emg_gesture_fpga"
set project_dir "./vivado_project"

# FPGA part number (Arty A7-35T)
# Change this if using a different board
set fpga_part "xc7a35ticsg324-1L"

# Alternative parts (uncomment the one you're using):
# Arty A7-100T: xc7a100tcsg324-1
# Basys 3: xc7a35tcpg236-1
# Nexys A7-50T: xc7a50ticsg324-1L
# Nexys A7-100T: xc7a100ticsg324-1L
# Spartan-6 LX9: xc6slx9csg324-2
# Spartan-6 LX16 (Nexys 3): xc6slx16csg324-2
# Spartan-6 LX45 (Atlys): xc6slx45csg324-2

# Pin assignment file selection
# Will be auto-selected based on FPGA part
set pin_file ""
if {[string match "*xc7a35t*cpg236*" $fpga_part]} {
    set pin_file "fpga_rtl/pin_assignments_basys3.xdc"
    puts "Detected: Basys 3 board"
} elseif {[string match "*xc7a35t*csg324*" $fpga_part] || [string match "*xc7a100t*csg324*" $fpga_part]} {
    set pin_file "fpga_rtl/pin_assignments_arty_a7.xdc"
    puts "Detected: Arty A7 or Nexys A7 board"
} elseif {[string match "*xc6slx*" $fpga_part]} {
    set pin_file "fpga_rtl/pin_assignments_spartan6.xdc"
    puts "Detected: Spartan-6 board"
} else {
    set pin_file "fpga_rtl/pin_assignments_arty_a7.xdc"
    puts "Using default: Arty A7 pin assignments"
}

puts "=========================================="
puts "Creating Vivado Project for EMG Gesture Recognition"
puts "=========================================="

# Create project
puts "\n[1/6] Creating project..."
create_project $project_name $project_dir -part $fpga_part -force

# Add RTL source files
puts "\n[2/6] Adding RTL source files..."
add_files {
    fpga_rtl/top_module.v
    fpga_rtl/emg_preprocessor.v
    fpga_rtl/conv1d_layer.v
    fpga_rtl/dense_layer.v
    fpga_rtl/mac_unit.v
    fpga_rtl/weight_memory.v
    fpga_rtl/argmax.v
}

# Add constraint files
puts "\n[3/6] Adding constraint files..."
add_files -fileset constrs_1 fpga_rtl/constraints.xdc

# Add board-specific pin assignments
if {[file exists $pin_file]} {
    add_files -fileset constrs_1 $pin_file
    puts "  ✓ Added pin assignments: $pin_file"
} else {
    puts "  ⚠ WARNING: Pin assignment file not found: $pin_file"
    puts "  Please create pin assignments for your board"
}

# Add weight memory initialization file
puts "\n[4/6] Adding weight memory file..."
if {[file exists "ml_model/weights_real_data_init.mem"]} {
    file copy -force ml_model/weights_real_data_init.mem fpga_rtl/
    add_files fpga_rtl/weights_real_data_init.mem
    puts "  ✓ Weight file added successfully"
} else {
    puts "  ⚠ WARNING: Weight file not found!"
    puts "  Please run: python ml_model/train_with_real_dataset.py"
}

# Set top module
puts "\n[5/6] Setting top module..."
set_property top emg_gesture_recognition_top [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

# Create reports directory
file mkdir reports

# Project summary
puts "\n[6/6] Project Summary:"
puts "  Project name: $project_name"
puts "  Location: $project_dir"
puts "  FPGA part: $fpga_part"
puts "  Top module: emg_gesture_recognition_top"
puts "  Source files: [llength [get_files -filter {FILE_TYPE == Verilog}]]"
puts "  Constraint files: [llength [get_files -of_objects [get_filesets constrs_1]]]"

puts "\n=========================================="
puts "Project created successfully!"
puts "=========================================="
puts "\nNext steps:"
puts "  1. Open project: vivado $project_dir/$project_name.xpr"
puts "  2. Run synthesis: source run_synthesis.tcl"
puts "  3. Run implementation: source run_implementation.tcl"
puts "  4. Program FPGA: source program_fpga.tcl"
puts "\nOr run complete flow: source run_complete_flow.tcl"
