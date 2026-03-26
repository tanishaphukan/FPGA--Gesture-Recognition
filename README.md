# Real-Time EMG Gesture Recognition System for Prosthetic Control

## Overview
This prototype demonstrates a complete pipeline for real-time surface EMG (sEMG) signal processing and gesture classification using FPGA-based hardware acceleration. The system achieves <20ms latency with low power consumption suitable for wearable prosthetic applications.

## System Specifications

### Hardware Requirements
- **EMG Channels**: 8-12 channels (forearm muscle array)
- **Sampling Rate**: 2000 Hz per channel
- **ADC Resolution**: 12-bit minimum
- **FPGA Platform**: Xilinx Artix-7 (XC7A35T or higher)
- **Target Latency**: <20 ms end-to-end
- **Power Budget**: <500 mW for FPGA processing

### Performance Targets
- **Classification Accuracy**: ≥90%
- **Gesture Classes**: 6-8 hand gestures (open, close, pinch, point, etc.)
- **Inference Time**: <10 ms on FPGA
- **Preprocessing Time**: <5 ms

## Project Structure

```
emg-gesture-fpga/
├── docs/
│   ├── system_architecture.md
│   └── block_diagram.svg
├── signal_processing/
│   ├── preprocessing.py
│   └── feature_extraction.py
├── ml_model/
│   ├── train_cnn.py
│   ├── quantize_model.py
│   └── export_weights.py
├── fpga_rtl/
│   ├── emg_preprocessor.v
│   ├── mac_unit.v
│   ├── conv1d_layer.v
│   ├── dense_layer.v
│   ├── argmax.v
│   ├── weight_memory.v
│   └── top_module.v
├── testbenches/
│   ├── tb_mac_unit.v
│   └── tb_top_module.v
├── simulation/
│   └── system_simulator.py
└── requirements.txt
```

## Quick Start

1. Train and quantize the ML model
2. Generate RTL-compatible weight files
3. Synthesize FPGA design
4. Deploy and test with real EMG data

See individual module documentation for detailed instructions.
