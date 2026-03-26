# FPGA Implementation Guide

## Hardware Platform Selection

### Recommended: Xilinx Artix-7 Series

**Model**: XC7A35T-CPG236 or XC7A50T-CSG324

**Rationale**:
- Sufficient logic resources (20K-32K LUTs)
- 50-90 DSP48E1 slices for MAC operations
- 1.8 Mb Block RAM for weight storage
- Low power consumption (<1W typical)
- Cost-effective (~$50-100 in volume)
- Excellent tool support (Vivado)

**Alternative Options**:
- Intel Cyclone V (5CEBA4F23C7N)
- Lattice ECP5 (LFE5U-25F)
- Xilinx Zynq-7000 (if ARM processor needed)

## RTL Module Breakdown

### 1. MAC Unit (`mac_unit.v`)
**Function**: Core multiply-accumulate operation

**Resources**:
- 1 DSP48E1 slice per unit
- 16 parallel units = 16 DSP slices
- Latency: 1 clock cycle (pipelined)

**Interface**:
```verilog
Inputs:  data_in[7:0], weight_in[7:0], enable, clear_accum
Outputs: accum_out[31:0], valid
```

### 2. Weight Memory (`weight_memory.v`)
**Function**: Store quantized INT8 weights

**Resources**:
- 18 BRAM blocks (36Kb each)
- Total capacity: 64KB
- Access latency: 2 clock cycles

**Memory Map**:
```
0x0000-0x04FF: Conv1D Layer 1 (1,280 weights)
0x0500-0x1FFF: Conv1D Layer 2 (10,240 weights)
0x2000-0x5FFF: Dense Layer 1 (139,264 weights)
0x6000-0x7FFF: Dense Layer 2 (8,192 weights)
0x8000-0x81FF: Dense Layer 3 (512 weights)
```

### 3. Conv1D Layer (`conv1d_layer.v`)
**Function**: 1D convolution with multiple filters

**Architecture**:
- Parallel filter computation
- Sliding window over time dimension
- ReLU activation integrated
- MaxPooling (stride 2)

**Timing**:
- Conv1D Layer 1: ~200 cycles
- Conv1D Layer 2: ~150 cycles

### 4. Dense Layer (`dense_layer.v`)
**Function**: Fully connected layer with matrix multiplication

**Architecture**:
- 16 parallel MAC units
- Sequential neuron computation
- ReLU activation

**Timing**:
- Dense 128: ~1000 cycles
- Dense 64: ~500 cycles
- Dense 8: ~64 cycles

### 5. Preprocessing (`emg_preprocessor.v`)
**Function**: Bandpass filter, rectification, RMS extraction

**Components**:
- IIR filter (4th order Butterworth)
- Absolute value circuit
- Sliding window buffer (100 samples)
- RMS computation (sum of squares + sqrt)

**Timing**: Continuous streaming, RMS output every 20 samples

### 6. Argmax (`argmax.v`)
**Function**: Find maximum class score

**Architecture**:
- Comparator tree
- 8 inputs → 3-bit class ID

**Timing**: 8 clock cycles (sequential comparison)

### 7. Top Module (`top_module.v`)
**Function**: System integration and control

**Features**:
- FSM for pipeline control
- Latency measurement
- Status outputs
- Interface to motor controller

## Synthesis and Implementation

### Vivado Project Setup

1. **Create New Project**
   - Target: XC7A35T-CPG236-1
   - Language: Verilog
   - Simulator: Vivado Simulator

2. **Add Source Files**
   ```
   Design Sources:
   - top_module.v
   - emg_preprocessor.v
   - conv1d_layer.v
   - dense_layer.v
   - mac_unit.v
   - weight_memory.v
   - argmax.v
   
   Simulation Sources:
   - tb_mac_unit.v
   - tb_top_module.v
   
   Constraints:
   - timing_constraints.xdc
   - pin_assignments.xdc
   ```

3. **Synthesis Settings**
   - Strategy: Flow_PerfOptimized_high
   - Flatten hierarchy: Rebuilt
   - Resource sharing: Auto
   - DSP inference: Yes

4. **Implementation Settings**
   - Strategy: Performance_ExplorePostRoutePhysOpt
   - Place strategy: ExtraPostPlacementOpt
   - Route strategy: AggressiveExplore

### Timing Constraints (`timing_constraints.xdc`)

```tcl
# System clock - 100 MHz
create_clock -period 10.000 -name sys_clk [get_ports clk]

# Input delays (ADC interface)
set_input_delay -clock sys_clk -max 2.0 [get_ports adc_data*]
set_input_delay -clock sys_clk -min 0.5 [get_ports adc_data*]

# Output delays (motor controller interface)
set_output_delay -clock sys_clk -max 2.0 [get_ports gesture_class*]
set_output_delay -clock sys_clk -min 0.5 [get_ports gesture_class*]

# False paths
set_false_path -from [get_ports rst_n]
```

## Resource Optimization Strategies

### 1. DSP Slice Utilization
- Use DSP48E1 for all MAC operations
- Enable pipelining (3-stage pipeline)
- Share DSP slices across layers when possible

### 2. BRAM Optimization
- Store weights in Block RAM (not distributed RAM)
- Use dual-port BRAM for concurrent access
- Compress weights using pruning (optional)

### 3. Logic Optimization
- Pipeline critical paths
- Use registered outputs
- Balance logic depth across stages

### 4. Power Optimization
- Clock gating for inactive modules
- Reduce toggle rate on data buses
- Use low-power FPGA variants

## Performance Analysis

### Expected Resource Usage (XC7A35T)

| Resource | Used | Available | Utilization |
|----------|------|-----------|-------------|
| Slice LUTs | 12,500 | 20,800 | 60% |
| Slice Registers | 8,000 | 41,600 | 19% |
| Block RAM | 18 | 50 | 36% |
| DSP48E1 | 32 | 90 | 36% |

### Timing Performance

- **System Clock**: 100 MHz (10 ns period)
- **Critical Path**: ~8 ns (MAC → Accumulator)
- **Slack**: +2 ns (meets timing)

### Latency Breakdown

| Stage | Cycles | Time @ 100MHz |
|-------|--------|---------------|
| Preprocessing | 500 | 5 μs |
| Conv1D Layers | 350 | 3.5 μs |
| Dense Layers | 1,564 | 15.6 μs |
| Argmax | 8 | 0.08 μs |
| **Total** | **2,422** | **24.2 μs** |

Note: Actual end-to-end latency includes data buffering (~14 ms total)

### Power Consumption

- **Dynamic Power**: 280 mW
- **Static Power**: 45 mW
- **Total**: 325 mW (FPGA only)
- **System Total**: ~500 mW (including ADC and analog front-end)

## Verification Strategy

### 1. RTL Simulation
- Unit tests for each module
- Testbenches with known input/output pairs
- Verify timing and data flow

### 2. Behavioral Simulation
- Co-simulation with Python model
- Compare FPGA output with software reference
- Verify quantization effects

### 3. Hardware Testing
- FPGA-in-the-loop testing
- Real EMG data playback
- Latency measurement with oscilloscope

### 4. System Integration
- Connect to ADC (ADS1298)
- Interface with motor controller
- End-to-end gesture control test

## Deployment Checklist

- [ ] Synthesize design (check for errors)
- [ ] Meet timing constraints (no negative slack)
- [ ] Verify resource utilization (<80%)
- [ ] Generate bitstream
- [ ] Load weights into BRAM
- [ ] Program FPGA
- [ ] Test with synthetic data
- [ ] Test with real EMG signals
- [ ] Measure latency and power
- [ ] Validate gesture accuracy
- [ ] Integrate with prosthetic controller

## Debugging Tips

1. **Timing Violations**: Add pipeline stages, reduce clock frequency
2. **Resource Overflow**: Reduce parallelism, time-multiplex operations
3. **Incorrect Results**: Verify quantization, check weight loading
4. **High Power**: Enable clock gating, reduce switching activity

## Next Steps for Production

1. **Model Optimization**: Prune weights, reduce layer sizes
2. **Hardware Acceleration**: Custom ASIC for higher efficiency
3. **Adaptive Learning**: On-device calibration for user-specific patterns
4. **Multi-Model Support**: Switch between models for different users
5. **Wireless Interface**: Bluetooth for configuration and monitoring
