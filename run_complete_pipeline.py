#!/usr/bin/env python3
"""
Quick Start Script for EMG Gesture Recognition Pipeline
Runs the complete ML workflow and generates all outputs
"""

import os
import sys
import subprocess

def print_header(text):
    print("\n" + "="*70)
    print(text.center(70))
    print("="*70 + "\n")

def check_dependencies():
    """Check if required packages are installed"""
    print_header("CHECKING DEPENDENCIES")
    
    required_packages = [
        'numpy', 'scipy', 'torch', 'sklearn', 
        'matplotlib', 'seaborn', 'onnx'
    ]
    
    missing = []
    for package in required_packages:
        try:
            __import__(package)
            print(f"✓ {package}")
        except ImportError:
            print(f"✗ {package} - MISSING")
            missing.append(package)
    
    if missing:
        print(f"\n⚠ Missing packages: {', '.join(missing)}")
        print(f"\nInstall with: pip install -r requirements.txt")
        return False
    
    print(f"\n✓ All dependencies installed!")
    return True

def run_pipeline():
    """Run the complete ML pipeline"""
    print_header("RUNNING COMPLETE ML PIPELINE")
    
    script_path = os.path.join('ml_model', 'complete_emg_pipeline.py')
    
    if not os.path.exists(script_path):
        print(f"✗ Script not found: {script_path}")
        return False
    
    print(f"Executing: {script_path}\n")
    
    try:
        result = subprocess.run(
            [sys.executable, script_path],
            check=True,
            capture_output=False
        )
        print(f"\n✓ Pipeline completed successfully!")
        return True
    except subprocess.CalledProcessError as e:
        print(f"\n✗ Pipeline failed with error code {e.returncode}")
        return False

def list_generated_files():
    """List all generated files"""
    print_header("GENERATED FILES")
    
    files = [
        ('model_fp32.pth', 'Original PyTorch model (FP32)'),
        ('model_int8.pth', 'Quantized model (INT8)'),
        ('emg_gesture_model.onnx', 'ONNX format for deployment'),
        ('fpga_weights_int8.npz', 'INT8 weights for FPGA'),
        ('weights_init.mem', 'Verilog memory initialization'),
    ]
    
    print("Files ready for FPGA deployment:\n")
    
    for filename, description in files:
        if os.path.exists(filename):
            size = os.path.getsize(filename) / 1024  # KB
            print(f"✓ {filename:30s} ({size:6.1f} KB) - {description}")
        else:
            print(f"✗ {filename:30s} - NOT FOUND")
    
    print(f"\nThese files are ready to be used with the FPGA implementation.")

def show_next_steps():
    """Show next steps for FPGA deployment"""
    print_header("NEXT STEPS - FPGA DEPLOYMENT")
    
    print("""
1. LOAD WEIGHTS TO FPGA
   - Copy weights_init.mem to your Vivado project
   - Update weight_memory.v to load this file
   
2. SYNTHESIZE VERILOG DESIGN
   cd fpga_rtl
   vivado -mode batch -source synthesize.tcl
   
3. PROGRAM FPGA BOARD
   - Connect Arty A7 board via USB
   - Program with generated bitstream
   
4. CONNECT HARDWARE
   - Connect ADC (ADS1298) to Pmod connectors
   - Attach EMG electrodes to forearm
   - Connect motor controller to output pins
   
5. TEST SYSTEM
   - Apply EMG electrodes
   - Perform gestures
   - Verify LED output shows correct gesture class
   
6. CALIBRATE (Optional)
   - Collect user-specific training data
   - Retrain model with new data
   - Update FPGA weights

For detailed instructions, see:
- docs/fpga_implementation_guide.md
- docs/deployment_workflow.md
- ml_model/README_ML_PIPELINE.md
""")

def main():
    """Main execution"""
    print_header("EMG GESTURE RECOGNITION - QUICK START")
    
    print("""
This script will:
1. Check dependencies
2. Run the complete ML pipeline
3. Generate all necessary files for FPGA deployment
4. Show next steps

Estimated time: 5-10 minutes
""")
    
    input("Press Enter to continue...")
    
    # Step 1: Check dependencies
    if not check_dependencies():
        print("\n⚠ Please install missing dependencies first.")
        return 1
    
    # Step 2: Run pipeline
    if not run_pipeline():
        print("\n⚠ Pipeline execution failed.")
        return 1
    
    # Step 3: List generated files
    list_generated_files()
    
    # Step 4: Show next steps
    show_next_steps()
    
    print_header("QUICK START COMPLETE")
    print("✓ All files generated successfully!")
    print("✓ Ready for FPGA deployment!")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
