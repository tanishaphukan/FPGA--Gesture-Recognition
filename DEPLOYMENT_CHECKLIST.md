# FPGA Deployment Checklist

Use this checklist to ensure successful deployment of your EMG gesture recognition system.

## Pre-Deployment

### Software Setup
- [ ] Xilinx Vivado installed (2020.1 or later)
- [ ] Python 3.7+ with required packages
- [ ] FPGA board drivers installed (Digilent Adept or Xilinx Cable Drivers)
- [ ] Git repository cloned

### Hardware Setup
- [ ] FPGA board available (Arty A7-35T or compatible)
- [ ] USB cable (Micro-B)
- [ ] Power supply (5V/2A)
- [ ] (Optional) EMG sensor/ADC board
- [ ] (Optional) Electrodes and cables

### Model Training
- [ ] Run `python ml_model/train_with_real_dataset.py`
- [ ] Verify 100% test accuracy achieved
- [ ] Check `weights_real_data_init.mem` file generated
- [ ] Model files created:
  - [ ] `model_real_data_fp32.pth`
  - [ ] `model_real_data_int8.pth`
  - [ ] `fpga_weights_real_data_int8.npz`

## FPGA Build Process

### Project Creation
- [ ] Run `create_vivado_project.tcl`
- [ ] Verify all Verilog files added
- [ ] Verify constraint files added
- [ ] Verify weight file copied to project
- [ ] Top module set correctly

### Synthesis
- [ ] Run synthesis (5-10 minutes)
- [ ] Check synthesis completed successfully
- [ ] Review utilization report:
  - [ ] LUTs < 80% of available
  - [ ] BRAMs < 70% of available
  - [ ] DSPs < 80% of available
- [ ] Check timing report:
  - [ ] WNS (Worst Negative Slack) > 0 ns
  - [ ] No critical warnings

### Implementation
- [ ] Run implementation (10-15 minutes)
- [ ] Check implementation completed successfully
- [ ] Review timing report:
  - [ ] All timing constraints met (WNS > 0)
  - [ ] Setup and hold times satisfied
- [ ] Review power report:
  - [ ] Total power < 2W
  - [ ] No thermal issues

### Bitstream Generation
- [ ] Generate bitstream (5-10 minutes)
- [ ] Verify bitstream file created
- [ ] Check file size (~1-2 MB)
- [ ] No errors in bitstream generation log

## Hardware Programming

### Board Connection
- [ ] FPGA board connected via USB
- [ ] Board powered on (LEDs lit)
- [ ] Board detected by computer
- [ ] Drivers installed and working

### Programming
- [ ] Open Hardware Manager in Vivado
- [ ] Auto-connect successful
- [ ] FPGA device detected (xc7a35t or similar)
- [ ] Program device with bitstream
- [ ] Programming completed successfully (10 seconds)
- [ ] DONE LED on board is lit

## System Testing

### Basic Functionality
- [ ] Status LED (LED0) is ON
- [ ] Press BTN0 - LEDs change (test pattern working)
- [ ] No smoke, unusual heat, or strange noises
- [ ] Board remains stable

### Serial Communication (Optional)
- [ ] Serial terminal connected (115200 baud)
- [ ] Receiving data from FPGA
- [ ] Gesture classifications displayed
- [ ] No communication errors

### EMG Hardware Integration (If Available)
- [ ] EMG sensor connected to Pmod JA
- [ ] Electrodes placed on forearm
- [ ] Ground electrode connected
- [ ] ADC receiving signals
- [ ] Real-time classification working

### Performance Verification
- [ ] Latency < 20 ms (measure with oscilloscope if available)
- [ ] Classification accuracy > 85% on live data
- [ ] No false positives during rest
- [ ] Consistent performance over 5-minute test
- [ ] All 8 gestures recognized correctly

## Troubleshooting

### Common Issues Checklist

#### "No hardware targets found"
- [ ] USB cable firmly connected
- [ ] Board power LED is on
- [ ] Drivers installed correctly
- [ ] Tried different USB port
- [ ] Board appears in Device Manager (Windows) or lsusb (Linux)

#### "Timing not met" (WNS < 0)
- [ ] Reduced clock frequency in constraints.xdc
- [ ] Added pipeline stages to critical paths
- [ ] Simplified design if necessary
- [ ] Re-ran implementation with different strategies

#### "Bitstream generation failed"
- [ ] Checked synthesis errors
- [ ] Verified all source files included
- [ ] Checked constraint file syntax
- [ ] Cleaned project and rebuilt

#### "Low accuracy on real EMG"
- [ ] Verified electrode placement
- [ ] Checked electrode contact quality
- [ ] Calibrated ADC voltage range
- [ ] Verified preprocessing parameters match training
- [ ] Collected user-specific calibration data

#### "Weight memory not initialized"
- [ ] Verified weight file path in weight_memory.v
- [ ] Checked file exists in project directory
- [ ] Used absolute path if needed
- [ ] Verified file format is correct

## Post-Deployment

### Documentation
- [ ] Record resource utilization
- [ ] Document any modifications made
- [ ] Save timing reports
- [ ] Note any issues encountered
- [ ] Update README if needed

### Optimization (Optional)
- [ ] Measure actual latency
- [ ] Profile power consumption
- [ ] Test with multiple users
- [ ] Collect accuracy statistics
- [ ] Identify improvement areas

### Next Steps
- [ ] Integrate with prosthetic controller
- [ ] Add wireless communication
- [ ] Implement user calibration mode
- [ ] Add battery power management
- [ ] Design custom PCB

## Sign-Off

**Deployment Date**: _______________

**FPGA Board**: _______________

**Vivado Version**: _______________

**Test Results**:
- Synthesis: ☐ PASS ☐ FAIL
- Implementation: ☐ PASS ☐ FAIL
- Programming: ☐ PASS ☐ FAIL
- Functionality: ☐ PASS ☐ FAIL

**Notes**:
_______________________________________
_______________________________________
_______________________________________

**Deployed By**: _______________

---

## Quick Reference

### Important Files
- Bitstream: `vivado_project/emg_gesture_fpga.runs/impl_1/emg_gesture_recognition_top.bit`
- Reports: `reports/`
- Logs: `vivado_project/emg_gesture_fpga.runs/*/runme.log`

### Key Commands
```bash
# Create project
vivado -mode batch -source create_vivado_project.tcl

# Complete build
vivado -mode batch -source run_complete_flow.tcl

# Program FPGA
vivado -mode batch -source program_fpga.tcl

# Serial monitor
screen /dev/ttyUSB1 115200  # Linux/Mac
# Use PuTTY on Windows
```

### Support
- Documentation: `FPGA_DEPLOYMENT_GUIDE.md`
- Quick Start: `QUICKSTART_FPGA.md`
- Issues: GitHub repository issues page
