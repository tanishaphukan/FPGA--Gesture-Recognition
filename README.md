# Real-Time EMG Gesture Recognition System for Prosthetic Control

## Overview
This prototype demonstrates a complete pipeline for real-time surface EMG (sEMG) signal processing and gesture classification using FPGA-based hardware acceleration. The system achieves <20ms latency with low power consumption suitable for wearable prosthetic applications.

## System Specifications

### Hardware Requirements
- **EMG Channels**: 8-12 channels (forearm muscle array)
- **Sampling Rate**: 2000 Hz per channel
- **ADC Resolution**: 12-bit minimum
- **FPGA Platform**: 
  - Xilinx Artix-7 (XC7A35T or higher) - Recommended
  - Basys 3 (XC7A35T) - Best for students/hobbyists
  - Arty A7-35T/100T
  - Nexys A7-50T/100T
  - Spartan-6 (XC6SLX45 or higher) - Legacy support
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

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Train the Model
```bash
python ml_model/train_with_real_dataset.py
```
This generates:
- Trained CNN model (100% test accuracy)
- Quantized INT8 weights for FPGA
- Weight initialization file: `weights_real_data_init.mem`

### 3. Deploy to FPGA

#### Automated (Recommended)
**Windows:**
```bash
build_and_program.bat
```

**Linux/Mac:**
```bash
./build_and_program.sh
```

#### Manual Steps
```bash
# Create Vivado project
vivado -mode batch -source create_vivado_project.tcl

# Run complete build (synthesis + implementation + bitstream)
vivado -mode batch -source run_complete_flow.tcl

# Program FPGA board
vivado -mode batch -source program_fpga.tcl
```

### 4. Test the System
- Press BTN0 on FPGA board to inject test pattern
- Connect serial terminal (115200 baud) to monitor classifications
- Connect EMG sensor to Pmod JA for real-time gesture recognition

## Documentation

**[📚 Documentation Index](DOCUMENTATION_INDEX.md)** - Complete guide to all documentation

### Quick Start
- **[Quick Start](QUICKSTART.md)** - Get started in 5 minutes
- **[FPGA Quick Start](QUICKSTART_FPGA.md)** - Deploy to FPGA quickly
- **[Spartan Quick Start](SPARTAN_QUICKSTART.md)** - Spartan boards in 3 steps

### Deployment Guides
- **[FPGA Deployment Guide](FPGA_DEPLOYMENT_GUIDE.md)** - Complete step-by-step instructions
- **[Spartan Board Guide](SPARTAN_DEPLOYMENT.md)** - Spartan-6 and Basys 3 specific
- **[Deployment Summary](DEPLOYMENT_SUMMARY.md)** - Overview and files generated
- **[Deployment Checklist](DEPLOYMENT_CHECKLIST.md)** - Verification checklist

### Technical Documentation
- **[ML Pipeline](ml_model/README_ML_PIPELINE.md)** - Model training details
- **[System Architecture](docs/system_architecture.md)** - System design
- **[Complete Workflow](docs/COMPLETE_WORKFLOW_GUIDE.md)** - End-to-end guide
- **[Board Comparison](docs/board_comparison.txt)** - Visual board comparison

## Results

### Model Performance
- **Test Accuracy**: 100.00%
- **Model Size**: 483 KB (FP32), 146 KB (INT8)
- **Inference Time**: <10 ms on FPGA
- **Gestures**: Rest, Open, Close, Flex, Extend, Pinch, Point, Thumb

### FPGA Resource Usage (Arty A7-35T)
- **LUTs**: ~15,000 / 20,800 (72%)
- **Flip-Flops**: ~8,000 / 41,600 (19%)
- **BRAMs**: ~25 / 50 (50%)
- **DSPs**: ~40 / 90 (44%)
- **Clock**: 100 MHz
- **Power**: <2W
