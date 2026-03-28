# FPGA Deployment Guide - Step by Step

## Quick Start: Deploy Your Trained Model to FPGA

This guide walks you through deploying your trained EMG gesture recognition model to an FPGA board (Arty A7-35T or similar Xilinx 7-series FPGA).

---

## Prerequisites

### Software Required:
1. **Xilinx Vivado Design Suite** (2020.1 or later)
   - Download: https://www.xilinx.com/support/download.html
   - Free WebPACK edition supports Artix-7
   - Install size: ~30 GB

2. **FPGA Board Drivers**
   - Digilent Adept (for Arty boards)
   - Or Xilinx Cable Drivers

### Hardware Required:
1. **FPGA Board**: Arty A7-35T (or compatible Xilinx 7-series)
2. **USB Cable**: USB Micro-B for programming
3. **Power Supply**: 5V/2A (usually via USB)

### Files You Already Have:
- ✅ Verilog RTL files in `fpga_rtl/`
- ✅ Trained model weights in `ml_model/weights_real_data_init.mem`
- ✅ Constraint files in `fpga_rtl/*.xdc`

---

## Step-by-Step Deployment

### Step 1: Prepare Weight Files

First, copy the trained weights to the FPGA RTL directory:

```bash
# Copy weight initialization file
cp ml_model/weights_real_data_init.mem fpga_rtl/

# Verify the file exists
ls -lh fpga_rtl/weights_real_data_init.mem
```

### Step 2: Create Vivado Project

#### Option A: Using Vivado GUI

1. **Launch Vivado**
   ```bash
   vivado &
   ```

2. **Create New Project**
   - Click "Create Project"
   - Project name: `emg_gesture_fpga`
   - Location: Choose your workspace
   - Project type: RTL Project
   - Click "Next"

3. **Add Source Files**
   - Click "Add Files"
   - Navigate to `fpga_rtl/` directory
   - Select all `.v` files:
     - `top_module.v`
     - `emg_preprocessor.v`
     - `conv1d_layer.v`
     - `dense_layer.v`
     - `mac_unit.v`
     - `weight_memory.v`
     - `argmax.v`
   - Click "OK"

4. **Add Constraint Files**
   - Click "Add Constraints"
   - Select:
     - `fpga_rtl/constraints.xdc` (timing constraints)
     - `fpga_rtl/pin_assignments_arty_a7.xdc` (pin mapping)
   - Click "OK"

5. **Select FPGA Part**
   - For Arty A7-35T: `xc7a35ticsg324-1L`
   - Or search for your specific board
   - Click "Next" → "Finish"

#### Option B: Using TCL Script (Faster)

Create a file `create_project.tcl`:

```tcl
# Create project
create_project emg_gesture_fpga ./vivado_project -part xc7a35ticsg324-1L -force

# Add RTL source files
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
add_files -fileset constrs_1 {
    fpga_rtl/constraints.xdc
    fpga_rtl/pin_assignments_arty_a7.xdc
}

# Add weight memory file
add_files fpga_rtl/weights_real_data_init.mem

# Set top module
set_property top emg_gesture_recognition_top [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

puts "Project created successfully!"
```

Run it:
```bash
vivado -mode batch -source create_project.tcl
```

### Step 3: Update Weight Memory Path

Open `fpga_rtl/weight_memory.v` and verify the memory initialization path points to your weight file:

```verilog
initial begin
    $readmemh("weights_real_data_init.mem", weight_mem);
end
```

### Step 4: Run Synthesis

#### GUI Method:
1. In Vivado, click "Run Synthesis" in Flow Navigator
2. Wait 5-10 minutes
3. Check for errors in Messages window

#### Command Line Method:
```tcl
# In Vivado TCL console
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check results
open_run synth_1
report_utilization -file reports/utilization_synth.txt
report_timing_summary -file reports/timing_synth.txt
```

**Expected Results:**
- LUTs: ~15,000 / 20,800 (72%)
- FFs: ~8,000 / 41,600 (19%)
- BRAMs: ~25 / 50 (50%)
- DSPs: ~40 / 90 (44%)
- Timing: WNS > 0 ns (positive slack)

### Step 5: Run Implementation

#### GUI Method:
1. Click "Run Implementation"
2. Wait 10-15 minutes
3. Review timing and utilization reports

#### Command Line Method:
```tcl
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check results
open_run impl_1
report_utilization -file reports/utilization_impl.txt
report_timing_summary -file reports/timing_impl.txt
report_power -file reports/power_impl.txt
```

**Verify:**
- ✅ Timing met (WNS > 0)
- ✅ No routing congestion
- ✅ Power < 2W

### Step 6: Generate Bitstream

#### GUI Method:
1. Click "Generate Bitstream"
2. Wait 5-10 minutes
3. Bitstream saved as `vivado_project/emg_gesture_fpga.runs/impl_1/emg_gesture_recognition_top.bit`

#### Command Line Method:
```tcl
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
```

### Step 7: Connect FPGA Board

1. **Connect USB Cable**
   - Plug USB Micro-B cable into FPGA board
   - Connect other end to your computer
   - Board should power on (LEDs light up)

2. **Verify Connection**
   - In Vivado: Tools → Hardware Manager → Open Hardware Manager
   - Click "Auto Connect"
   - You should see your FPGA device (xc7a35t)

### Step 8: Program FPGA

#### GUI Method:
1. In Hardware Manager, right-click on your device
2. Select "Program Device"
3. Browse to bitstream file: `vivado_project/emg_gesture_fpga.runs/impl_1/emg_gesture_recognition_top.bit`
4. Click "Program"
5. Wait ~10 seconds
6. "Programming successful" message appears

#### Command Line Method:

Create `program_fpga.tcl`:
```tcl
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target

# Get device
set device [lindex [get_hw_devices] 0]

# Program
set_property PROGRAM.FILE {vivado_project/emg_gesture_fpga.runs/impl_1/emg_gesture_recognition_top.bit} $device
program_hw_devices $device
refresh_hw_device $device

puts "FPGA programmed successfully!"

close_hw_target
disconnect_hw_server
close_hw_manager
```

Run:
```bash
vivado -mode batch -source program_fpga.tcl
```

---

## Step 9: Test the System

### Basic Functionality Test

The FPGA is now running your gesture recognition model! Here's how to test it:

#### Without EMG Hardware (Simulation Mode):

1. **Check Status LEDs**
   - LED0: System ready (should be ON)
   - LED1: Processing active (blinks during inference)
   - LED2-3: Gesture class indicators

2. **Use Built-in Test Pattern**
   - Press BTN0 to inject test EMG pattern
   - Observe LED output changes
   - Check 7-segment display (if available) for gesture class

#### With EMG Hardware:

1. **Connect EMG Sensor**
   - Connect ADC to Pmod JA connector
   - Follow pin assignments in `pin_assignments_arty_a7.xdc`
   - Typical connections:
     - JA1-JA8: EMG channel inputs (0-3.3V)
     - JA9: ADC clock
     - JA10: ADC data ready

2. **Connect Electrodes**
   - Place electrodes on forearm
   - Ground electrode on elbow
   - Ensure good skin contact

3. **Perform Gestures**
   - Rest: No muscle activity
   - Open: Extend fingers
   - Close: Make fist
   - Flex: Bend wrist down
   - Extend: Bend wrist up
   - Pinch: Thumb to index finger
   - Point: Extend index finger
   - Thumb: Thumb up

4. **Observe Outputs**
   - LEDs show gesture class (binary)
   - UART output (115200 baud): Gesture name + confidence
   - GPIO pins: 3-bit gesture class

### Monitor UART Output

Connect a serial terminal to see real-time classifications:

```bash
# Linux/Mac
screen /dev/ttyUSB1 115200

# Windows (use PuTTY or Tera Term)
# COM port: Check Device Manager
# Baud: 115200
# Data bits: 8
# Stop bits: 1
# Parity: None
```

Expected output:
```
EMG Gesture Recognition System
Model: CNN (100% accuracy)
Ready...

Gesture: Rest (Class 0) - Confidence: 98%
Gesture: Open (Class 1) - Confidence: 95%
Gesture: Close (Class 2) - Confidence: 97%
...
```

---

## Step 10: Performance Verification

### Measure Latency

Use an oscilloscope or logic analyzer:

1. **Trigger**: ADC data ready signal (JA10)
2. **Measure**: Time to output valid (GPIO output change)
3. **Expected**: < 20 ms end-to-end latency

### Measure Accuracy

Run 100 test gestures:

```python
# Use the system simulator
python simulation/system_simulator.py --fpga-test

# Expected output:
# Accuracy: >90%
# Latency: <20 ms
# False positive rate: <5%
```

### Check Resource Usage

In Vivado, view utilization report:
- LUTs: Should be < 80% of available
- BRAMs: Should be < 70% of available
- Power: Should be < 2W

---

## Troubleshooting

### Issue: "No hardware targets found"

**Solution:**
1. Check USB cable connection
2. Install Digilent Adept or Xilinx Cable Drivers
3. Try different USB port
4. Restart Vivado Hardware Manager

### Issue: "Timing constraints not met" (WNS < 0)

**Solution:**
1. Reduce clock frequency in `constraints.xdc`:
   ```tcl
   create_clock -period 20.000 [get_ports clk]  # 50 MHz instead of 100 MHz
   ```
2. Re-run implementation
3. Or add pipeline stages to critical paths

### Issue: "Bitstream generation failed"

**Solution:**
1. Check for synthesis/implementation errors
2. Verify all source files are included
3. Check constraint file syntax
4. Try cleaning project: Tools → Clean Project

### Issue: "Weight memory not initialized"

**Solution:**
1. Verify `weights_real_data_init.mem` is in project directory
2. Check file path in `weight_memory.v`
3. Use absolute path if needed:
   ```verilog
   $readmemh("/full/path/to/weights_real_data_init.mem", weight_mem);
   ```

### Issue: "Low accuracy on real EMG data"

**Solution:**
1. Check electrode placement and contact
2. Verify ADC voltage range (0-3.3V)
3. Calibrate preprocessing parameters
4. Collect user-specific training data
5. Check for 50/60 Hz noise (add notch filter)

---

## Next Steps

### 1. Optimize Performance
- Increase parallelism (more MAC units)
- Add pipeline stages for higher clock frequency
- Optimize memory access patterns

### 2. Add Features
- UART communication for real-time monitoring
- Bluetooth module for wireless operation
- Battery power management
- User calibration mode

### 3. Integration
- Connect to prosthetic hand controller
- Add motor driver interface
- Implement gesture sequences
- Add force/speed control

### 4. Production
- Flash bitstream to non-volatile memory
- Create standalone system (no PC needed)
- Design custom PCB
- Add enclosure

---

## Quick Reference Commands

### Vivado TCL Commands
```tcl
# Create project
create_project <name> <path> -part <part_number>

# Add files
add_files {file1.v file2.v}

# Run synthesis
launch_runs synth_1
wait_on_run synth_1

# Run implementation
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Program FPGA
open_hw_manager
connect_hw_server
open_hw_target
program_hw_devices [get_hw_devices]
```

### File Locations
- Bitstream: `vivado_project/emg_gesture_fpga.runs/impl_1/*.bit`
- Reports: `vivado_project/emg_gesture_fpga.runs/impl_1/reports/`
- Logs: `vivado_project/emg_gesture_fpga.runs/*/runme.log`

---

## Support Resources

- **Vivado Documentation**: https://www.xilinx.com/support/documentation/
- **Arty A7 Reference**: https://digilent.com/reference/programmable-logic/arty-a7/start
- **Project Repository**: Your GitHub repo
- **Issues**: Open an issue on GitHub for help

---

**Congratulations!** Your EMG gesture recognition model is now running on FPGA hardware! 🎉
