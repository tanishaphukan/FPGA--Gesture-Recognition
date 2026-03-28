#!/bin/bash
# Linux/Mac Shell Script for FPGA Build and Programming
# EMG Gesture Recognition System

set -e  # Exit on error

echo "=========================================="
echo "EMG Gesture Recognition - FPGA Deployment"
echo "=========================================="
echo ""

# Check if Vivado is available
if ! command -v vivado &> /dev/null; then
    echo "❌ ERROR: Vivado not found in PATH!"
    echo ""
    echo "Please source Vivado settings first:"
    echo "  source /tools/Xilinx/Vivado/2020.1/settings64.sh"
    echo "Or add Vivado to your PATH"
    exit 1
fi

echo "[1/4] Checking prerequisites..."
echo ""

# Check if weight file exists
if [ ! -f "ml_model/weights_real_data_init.mem" ]; then
    echo "⚠ WARNING: Weight file not found!"
    echo "Running training script first..."
    echo ""
    python ml_model/train_with_real_dataset.py
    if [ $? -ne 0 ]; then
        echo "❌ ERROR: Training failed!"
        exit 1
    fi
fi

echo "✓ Prerequisites checked"
echo ""

echo "[2/4] Creating Vivado project..."
echo ""
vivado -mode batch -source create_vivado_project.tcl
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Project creation failed!"
    exit 1
fi

echo ""
echo "[3/4] Running complete build flow..."
echo "⏱️  This will take 20-30 minutes. Please be patient..."
echo ""
vivado -mode batch -source run_complete_flow.tcl
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Build failed!"
    echo "Check logs in: vivado_project/emg_gesture_fpga.runs/"
    exit 1
fi

echo ""
echo "[4/4] Programming FPGA..."
echo ""
echo "Please ensure your FPGA board is connected via USB."
echo ""
read -p "Press Enter to continue..."

vivado -mode batch -source program_fpga.tcl
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Programming failed!"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check USB cable connection"
    echo "  2. Verify board is powered on"
    echo "  3. Install Digilent Adept drivers"
    echo "  4. Check USB permissions: sudo usermod -a -G dialout $USER"
    echo "  5. Try: sudo chmod 666 /dev/ttyUSB*"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ SUCCESS! FPGA is programmed and running!"
echo "=========================================="
echo ""
echo "Your EMG gesture recognition system is now active."
echo ""
echo "Next steps:"
echo "  1. Check status LEDs on the board"
echo "  2. Press BTN0 to test with built-in pattern"
echo "  3. Connect EMG sensor to Pmod JA"
echo "  4. Open serial terminal to monitor output"
echo ""
echo "Serial Terminal Commands:"
echo "  screen /dev/ttyUSB1 115200"
echo "  or"
echo "  minicom -D /dev/ttyUSB1 -b 115200"
echo ""
echo "To exit screen: Ctrl+A, then K, then Y"
echo ""
