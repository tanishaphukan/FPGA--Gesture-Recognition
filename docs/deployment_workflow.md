# Deployment Workflow

## Complete Pipeline: From Data to Hardware

### Phase 1: Data Collection and Model Training

#### Step 1: Collect EMG Data
```bash
# Install dependencies
pip install -r requirements.txt

# Collect training data (if hardware available)
# Otherwise, use synthetic data for prototyping
python signal_processing/preprocessing.py
```

**Data Requirements**:
- 50-100 trials per gesture per subject
- 8 gesture classes
- 2-3 second duration per trial
- Multiple subjects for generalization (5-10 subjects)

#### Step 2: Train CNN Model
```bash
# Train model with collected data
python ml_model/train_cnn.py

# Expected output:
# - emg_gesture_model.h5 (trained model)
# - Training accuracy: >95%
# - Validation accuracy: >90%
```

**Training Time**: ~10-20 minutes on CPU, ~2-5 minutes on GPU

#### Step 3: Quantize Model
```bash
# Convert FP32 to INT8 for FPGA
python ml_model/quantize_model.py

# Expected output:
# - emg_gesture_model_int8.tflite (quantized model)
# - fpga_weights/ directory (weight files for RTL)
# - Accuracy drop: <2%
# - Model size: ~50 KB
```

### Phase 2: RTL Development and Simulation

#### Step 4: Verify RTL Modules
```bash
# Using Icarus Verilog (open-source)
iverilog -o mac_unit.vvp testbenches/tb_mac_unit.v fpga_rtl/mac_unit.v
vvp mac_unit.vvp

# Or using Vivado Simulator
xvlog fpga_rtl/mac_unit.v testbenches/tb_mac_unit.v
xelab tb_mac_unit -debug typical
xsim tb_mac_unit -gui
```

**Verification Checklist**:
- [ ] MAC unit produces correct products
- [ ] Accumulator handles overflow
- [ ] Clear signal resets accumulator
- [ ] Timing meets 100 MHz constraint

#### Step 5: Integrate Weight Files
```bash
# Copy generated weight files to FPGA project
cp fpga_weights/*.mif vivado_project/emg_gesture.srcs/sources_1/

# Update weight_memory.v INIT_FILE parameter
# Point to correct .mif files for each layer
```

### Phase 3: FPGA Synthesis and Implementation

#### Step 6: Synthesize Design (Vivado)

**Create Vivado Project**:
```tcl
# In Vivado TCL console
create_project emg_gesture ./vivado_project -part xc7a35tcpg236-1
add_files {fpga_rtl/top_module.v fpga_rtl/emg_preprocessor.v fpga_rtl/conv1d_layer.v fpga_rtl/dense_layer.v fpga_rtl/mac_unit.v fpga_rtl/weight_memory.v fpga_rtl/argmax.v}
add_files -fileset constrs_1 constraints/timing_constraints.xdc
set_property top emg_gesture_recognition_top [current_fileset]
```

**Run Synthesis**:
```tcl
launch_runs synth_1
wait_on_run synth_1
open_run synth_1
report_utilization -file utilization_synth.txt
report_timing_summary -file timing_synth.txt
```

**Check Results**:
- Utilization: <80% of available resources
- Timing: WNS (Worst Negative Slack) > 0
- No critical warnings

#### Step 7: Implementation
```tcl
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
open_run impl_1
report_utilization -file utilization_impl.txt
report_timing_summary -file timing_impl.txt
report_power -file power_impl.txt
```

**Verify**:
- Timing closure (all paths meet constraints)
- Power estimate <500 mW
- No routing congestion

#### Step 8: Generate Bitstream
```tcl
# Bitstream generation
write_bitstream -force emg_gesture.bit

# Generate memory configuration file (for flash)
write_cfgmem -format mcs -interface spix4 -size 16 \
  -loadbit "up 0x0 emg_gesture.bit" -file emg_gesture.mcs
```

### Phase 4: Hardware Programming and Testing

#### Step 9: Program FPGA
```bash
# Using Vivado Hardware Manager
# 1. Connect Arty A7 via USB
# 2. Open Hardware Manager
# 3. Auto-connect to target
# 4. Program device with emg_gesture.bit

# Or using command line:
vivado -mode batch -source program_fpga.tcl
```

**program_fpga.tcl**:
```tcl
open_hw_manager
connect_hw_server
open_hw_target
set_property PROGRAM.FILE {emg_gesture.bit} [get_hw_devices xc7a35t_0]
program_hw_devices [get_hw_devices xc7a35t_0]
close_hw_target
disconnect_hw_server
close_hw_manager
```

#### Step 10: System Integration Test

**Hardware Setup**:
1. Connect ADC board to FPGA via Pmod connector
2. Attach EMG electrodes to forearm
3. Connect motor controller to FPGA output pins
4. Power on system

**Functional Test**:
```python
# Run system simulator to verify
python simulation/system_simulator.py

# Expected output:
# - Gesture classification at 100 Hz
# - Latency <20 ms
# - Accuracy >90%
```

**Live Test Protocol**:
1. Perform "Rest" gesture → Verify class 0 output
2. Perform "Hand Open" → Verify class 1 output
3. Perform "Hand Close" → Verify class 2 output
4. Repeat for all 8 gestures
5. Measure latency with oscilloscope (trigger on ADC DRDY, measure to output valid)

### Phase 5: Optimization and Tuning

#### Step 11: Performance Optimization

**If latency too high**:
- Increase parallelism (more MAC units)
- Pipeline critical paths
- Reduce model complexity

**If accuracy too low**:
- Collect more training data
- Retrain with data augmentation
- Adjust preprocessing parameters
- User-specific calibration

**If power too high**:
- Enable clock gating
- Reduce clock frequency (if latency allows)
- Optimize weight memory access patterns

#### Step 12: User Calibration

**Calibration Procedure**:
1. User performs each gesture 5 times
2. System records EMG patterns
3. Compute user-specific normalization parameters
4. Update preprocessing coefficients
5. Test accuracy improvement

**Adaptive Threshold**:
- Adjust RMS threshold for gesture detection
- Account for electrode placement variation
- Compensate for muscle fatigue

## Deployment Checklist

### Pre-Deployment
- [ ] Model accuracy ≥90% on test set
- [ ] Quantized model accuracy drop <2%
- [ ] All RTL modules pass testbenches
- [ ] Synthesis meets timing constraints
- [ ] Implementation utilization <80%
- [ ] Power consumption <500 mW

### Hardware Validation
- [ ] ADC noise floor <5 μV RMS
- [ ] FPGA programming successful
- [ ] Weight memory initialized correctly
- [ ] All I/O pins functional
- [ ] Power supply stable under load

### System Testing
- [ ] End-to-end latency <20 ms
- [ ] Gesture recognition accuracy >85% (live)
- [ ] No false positives during rest
- [ ] Consistent performance over 1-hour session
- [ ] Battery life >4 hours

### User Acceptance
- [ ] Comfortable electrode placement
- [ ] Intuitive gesture mapping
- [ ] Responsive prosthetic control
- [ ] Minimal training time (<30 min)

## Troubleshooting Guide

### Issue: Low Accuracy

**Possible Causes**:
- Poor electrode contact
- Incorrect electrode placement
- Insufficient training data
- Model-hardware mismatch

**Solutions**:
- Clean skin, apply conductive gel
- Follow anatomical landmarks for placement
- Collect more diverse training data
- Verify weight quantization didn't corrupt model

### Issue: High Latency

**Possible Causes**:
- Inefficient RTL implementation
- Clock frequency too low
- Memory bottleneck

**Solutions**:
- Profile pipeline stages
- Increase parallelism
- Optimize memory access patterns
- Use faster clock (if timing allows)

### Issue: FPGA Won't Program

**Possible Causes**:
- USB connection issue
- Bitstream corruption
- JTAG configuration error

**Solutions**:
- Check USB cable and drivers
- Regenerate bitstream
- Verify JTAG chain in Hardware Manager

### Issue: Incorrect Classifications

**Possible Causes**:
- Weight loading error
- Quantization mismatch
- Preprocessing parameter mismatch

**Solutions**:
- Verify weight memory initialization
- Check quantization scale factors
- Ensure preprocessing matches training

## Continuous Improvement

### Model Updates
- Collect user feedback on misclassifications
- Retrain model with additional data
- Deploy updated weights via USB/Bluetooth
- No FPGA reprogramming needed (weights in RAM)

### Feature Additions
- Add new gestures (retrain with 9-10 classes)
- Implement gesture sequences
- Add force/speed control
- Multi-user profiles

### Performance Monitoring
- Log classification accuracy over time
- Track battery life
- Monitor electrode impedance
- Detect electrode degradation

## Production Scaling

### For Volume Manufacturing
1. **ASIC Development**: Convert FPGA to custom chip
   - 10× power reduction
   - 5× cost reduction at scale
   - Smaller form factor

2. **PCB Optimization**: 
   - Integrate FPGA, ADC, AFE on single board
   - Reduce to 2-layer PCB
   - Automated assembly

3. **Software Tools**:
   - Mobile app for calibration
   - Cloud-based model updates
   - Usage analytics dashboard

4. **Certification**:
   - FDA 510(k) clearance
   - CE marking (Europe)
   - ISO 13485 quality management
