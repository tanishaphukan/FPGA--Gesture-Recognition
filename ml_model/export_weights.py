"""
Export Model Weights for FPGA Integration
Generates Verilog-compatible memory initialization files
"""

import numpy as np
import tensorflow as tf
from pathlib import Path


def export_layer_weights_to_verilog(layer_name, weights, biases, output_dir):
    """
    Export layer weights as Verilog memory initialization file
    
    Args:
        layer_name: Name of the layer
        weights: Weight array
        biases: Bias array (optional)
        output_dir: Output directory path
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(exist_ok=True)
    
    # Flatten weights
    weights_flat = weights.flatten()
    
    # Export weights
    weight_file = output_dir / f"{layer_name}_weights.mif"
    with open(weight_file, 'w') as f:
        f.write(f"// Weight Memory Initialization File\n")
        f.write(f"// Layer: {layer_name}\n")
        f.write(f"// Shape: {weights.shape}\n")
        f.write(f"// Total elements: {weights_flat.size}\n\n")
        
        for idx, val in enumerate(weights_flat):
            # Convert to 8-bit signed integer
            int_val = int(np.clip(val, -128, 127))
            hex_val = int_val & 0xFF
            f.write(f"@{idx:04X} {hex_val:02X}\n")
    
    print(f"  ✓ Exported {layer_name} weights: {weights_flat.size} elements")
    
    # Export biases if present
    if biases is not None:
        bias_file = output_dir / f"{layer_name}_biases.mif"
        with open(bias_file, 'w') as f:
            f.write(f"// Bias Memory Initialization File\n")
            f.write(f"// Layer: {layer_name}\n")
            f.write(f"// Elements: {biases.size}\n\n")
            
            for idx, val in enumerate(biases):
                # Biases use 32-bit representation
                int_val = int(np.clip(val, -2147483648, 2147483647))
                hex_val = int_val & 0xFFFFFFFF
                f.write(f"@{idx:04X} {hex_val:08X}\n")
        
        print(f"  ✓ Exported {layer_name} biases: {biases.size} elements")


def generate_verilog_header(weights_dict, output_file):
    """
    Generate Verilog header file with weight memory addresses
    
    Args:
        weights_dict: Dictionary of layer weights
        output_file: Output header file path
    """
    with open(output_file, 'w') as f:
        f.write("// Auto-generated weight memory map\n")
        f.write("// DO NOT EDIT MANUALLY\n\n")
        
        current_addr = 0
        
        for layer_name, info in weights_dict.items():
            weight_size = info['weights'].size
            bias_size = info['biases'].size if info['biases'] is not None else 0
            
            f.write(f"// {layer_name}\n")
            f.write(f"localparam [{15}:0] {layer_name.upper()}_WEIGHT_ADDR = 16'h{current_addr:04X};\n")
            f.write(f"localparam [{15}:0] {layer_name.upper()}_WEIGHT_SIZE = 16'd{weight_size};\n")
            
            current_addr += weight_size
            
            if bias_size > 0:
                f.write(f"localparam [{15}:0] {layer_name.upper()}_BIAS_ADDR = 16'h{current_addr:04X};\n")
                f.write(f"localparam [{15}:0] {layer_name.upper()}_BIAS_SIZE = 16'd{bias_size};\n")
                current_addr += bias_size
            
            f.write("\n")
        
        f.write(f"// Total memory required: {current_addr} bytes\n")
    
    print(f"\n✓ Generated Verilog header: {output_file}")


def export_model_for_fpga(model_path, output_dir='fpga_weights'):
    """
    Complete export pipeline for FPGA deployment
    
    Args:
        model_path: Path to trained Keras model
        output_dir: Output directory for weight files
    """
    print("="*60)
    print("Exporting Model for FPGA Deployment")
    print("="*60)
    
    # Load model
    print("\n[1/3] Loading model...")
    model = tf.keras.models.load_model(model_path)
    print(f"  ✓ Loaded {model_path}")
    
    # Extract weights from each layer
    print("\n[2/3] Extracting layer weights...")
    weights_dict = {}
    
    for layer in model.layers:
        if len(layer.get_weights()) > 0:
            layer_weights = layer.get_weights()
            
            # Get weights and biases
            weights = layer_weights[0]
            biases = layer_weights[1] if len(layer_weights) > 1 else None
            
            weights_dict[layer.name] = {
                'weights': weights,
                'biases': biases,
                'shape': weights.shape
            }
            
            # Export to files
            export_layer_weights_to_verilog(
                layer.name, weights, biases, output_dir
            )
    
    # Generate header file
    print("\n[3/3] Generating Verilog header...")
    header_file = Path(output_dir) / "weight_memory_map.vh"
    generate_verilog_header(weights_dict, header_file)
    
    # Summary
    total_weights = sum(info['weights'].size for info in weights_dict.values())
    total_biases = sum(info['biases'].size if info['biases'] is not None else 0 
                       for info in weights_dict.values())
    total_params = total_weights + total_biases
    
    print("\n" + "="*60)
    print("Export Summary")
    print("="*60)
    print(f"Total layers: {len(weights_dict)}")
    print(f"Total weights: {total_weights:,}")
    print(f"Total biases: {total_biases:,}")
    print(f"Total parameters: {total_params:,}")
    print(f"Memory required: {total_params} bytes ({total_params/1024:.1f} KB)")
    print(f"\nOutput directory: {output_dir}/")
    print("="*60)


if __name__ == "__main__":
    import sys
    
    # Check if model exists
    model_path = 'emg_gesture_model.h5'
    
    if not Path(model_path).exists():
        print(f"Error: Model file '{model_path}' not found.")
        print("Please run train_cnn.py first to train the model.")
        sys.exit(1)
    
    # Export weights
    export_model_for_fpga(model_path, output_dir='fpga_weights')
    
    print("\n✓ Ready for FPGA synthesis")
    print("  Next: Import .mif files into Vivado project")
