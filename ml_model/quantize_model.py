"""
Model Quantization for FPGA Deployment
Converts FP32 model to INT8 for hardware efficiency
"""

import numpy as np
import tensorflow as tf
from tensorflow import keras


def quantize_model(model_path, representative_dataset):
    """
    Apply post-training quantization to convert FP32 to INT8
    
    Args:
        model_path: Path to trained Keras model
        representative_dataset: Sample data for calibration
    Returns:
        Quantized TFLite model
    """
    # Load model
    model = keras.models.load_model(model_path)
    
    # Convert to TFLite with quantization
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    
    # Enable INT8 quantization
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    
    # Provide representative dataset for calibration
    def representative_data_gen():
        for sample in representative_dataset:
            yield [sample.astype(np.float32)]
    
    converter.representative_dataset = representative_data_gen
    
    # Enforce INT8 for all operations
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.int8
    converter.inference_output_type = tf.int8
    
    # Convert
    tflite_model = converter.convert()
    
    return tflite_model


def extract_quantized_weights(tflite_model):
    """
    Extract quantized weights and parameters from TFLite model
    
    Args:
        tflite_model: Quantized TFLite model
    Returns:
        Dictionary containing weights, biases, and quantization params
    """
    # Load TFLite model
    interpreter = tf.lite.Interpreter(model_content=tflite_model)
    interpreter.allocate_tensors()
    
    # Get tensor details
    tensor_details = interpreter.get_tensor_details()
    
    weights_dict = {}
    
    for tensor in tensor_details:
        tensor_name = tensor['name']
        tensor_idx = tensor['index']
        
        # Extract weights (filter for weight tensors)
        if 'kernel' in tensor_name or 'weight' in tensor_name or 'bias' in tensor_name:
            tensor_data = interpreter.get_tensor(tensor_idx)
            
            # Get quantization parameters
            quant_params = tensor['quantization_parameters']
            scale = quant_params['scales']
            zero_point = quant_params['zero_points']
            
            weights_dict[tensor_name] = {
                'data': tensor_data,
                'shape': tensor_data.shape,
                'dtype': tensor_data.dtype,
                'scale': scale,
                'zero_point': zero_point
            }
    
    return weights_dict


def export_weights_for_fpga(weights_dict, output_dir='fpga_weights'):
    """
    Export quantized weights in FPGA-compatible format
    
    Args:
        weights_dict: Dictionary of quantized weights
        output_dir: Output directory for weight files
    """
    import os
    os.makedirs(output_dir, exist_ok=True)
    
    for layer_name, weight_info in weights_dict.items():
        # Clean layer name for filename
        filename = layer_name.replace('/', '_').replace(';', '_')
        
        # Export as binary file (INT8)
        bin_path = os.path.join(output_dir, f"{filename}.bin")
        weight_info['data'].tofile(bin_path)
        
        # Export metadata as text
        meta_path = os.path.join(output_dir, f"{filename}_meta.txt")
        with open(meta_path, 'w') as f:
            f.write(f"Layer: {layer_name}\n")
            f.write(f"Shape: {weight_info['shape']}\n")
            f.write(f"Dtype: {weight_info['dtype']}\n")
            f.write(f"Scale: {weight_info['scale']}\n")
            f.write(f"Zero Point: {weight_info['zero_point']}\n")
            f.write(f"Total Elements: {weight_info['data'].size}\n")
        
        # Export as Verilog memory initialization file
        mif_path = os.path.join(output_dir, f"{filename}.mif")
        with open(mif_path, 'w') as f:
            f.write(f"// Memory Initialization File for {layer_name}\n")
            f.write(f"// Shape: {weight_info['shape']}\n")
            f.write(f"// Total: {weight_info['data'].size} elements\n\n")
            
            flat_data = weight_info['data'].flatten()
            for idx, val in enumerate(flat_data):
                # Convert INT8 to 8-bit hex
                hex_val = val & 0xFF
                f.write(f"@{idx:04X} {hex_val:02X}\n")
    
    print(f"✓ Weights exported to '{output_dir}/' directory")


def compare_accuracy(original_model, tflite_model, test_data, test_labels):
    """
    Compare accuracy between original and quantized models
    
    Args:
        original_model: Original Keras model
        tflite_model: Quantized TFLite model
        test_data: Test dataset
        test_labels: Test labels
    Returns:
        Dictionary with comparison metrics
    """
    # Original model predictions
    orig_pred = original_model.predict(test_data)
    orig_accuracy = np.mean(np.argmax(orig_pred, axis=1) == test_labels)
    
    # Quantized model predictions
    interpreter = tf.lite.Interpreter(model_content=tflite_model)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    quant_predictions = []
    for sample in test_data:
        # Quantize input
        input_scale, input_zero_point = input_details[0]['quantization']
        quantized_input = (sample / input_scale + input_zero_point).astype(np.int8)
        
        # Run inference
        interpreter.set_tensor(input_details[0]['index'], [quantized_input])
        interpreter.invoke()
        
        # Dequantize output
        output = interpreter.get_tensor(output_details[0]['index'])[0]
        output_scale, output_zero_point = output_details[0]['quantization']
        dequantized_output = (output.astype(np.float32) - output_zero_point) * output_scale
        
        quant_predictions.append(np.argmax(dequantized_output))
    
    quant_accuracy = np.mean(np.array(quant_predictions) == test_labels)
    
    # Model sizes
    import sys
    orig_size = sys.getsizeof(original_model.to_json()) / 1024  # Approximate
    quant_size = len(tflite_model) / 1024  # KB
    
    return {
        'original_accuracy': orig_accuracy,
        'quantized_accuracy': quant_accuracy,
        'accuracy_drop': orig_accuracy - quant_accuracy,
        'original_size_kb': orig_size,
        'quantized_size_kb': quant_size,
        'compression_ratio': orig_size / quant_size
    }


if __name__ == "__main__":
    print("=" * 60)
    print("Model Quantization for FPGA Deployment")
    print("=" * 60)
    
    # Load trained model
    print("\n[1/5] Loading trained model...")
    try:
        model = keras.models.load_model('emg_gesture_model.h5')
        print("  ✓ Model loaded successfully")
    except:
        print("  ✗ Model not found. Run train_cnn.py first.")
        exit(1)
    
    # Generate representative dataset
    print("\n[2/5] Generating representative dataset for calibration...")
    from train_cnn import generate_synthetic_dataset
    X_train, y_train, X_test, y_test = generate_synthetic_dataset(n_samples=500)
    representative_data = X_train[:100]  # Use subset for calibration
    print(f"  Using {len(representative_data)} samples for calibration")
    
    # Quantize model
    print("\n[3/5] Applying INT8 quantization...")
    tflite_model = quantize_model('emg_gesture_model.h5', representative_data)
    print(f"  ✓ Quantization complete")
    
    # Save quantized model
    print("\n[4/5] Saving quantized model...")
    with open('emg_gesture_model_int8.tflite', 'wb') as f:
        f.write(tflite_model)
    print("  ✓ Saved to 'emg_gesture_model_int8.tflite'")
    
    # Extract and export weights
    print("\n[5/5] Extracting weights for FPGA...")
    weights_dict = extract_quantized_weights(tflite_model)
    export_weights_for_fpga(weights_dict, output_dir='fpga_weights')
    
    # Compare accuracy
    print("\n" + "=" * 60)
    print("Model Comparison")
    print("=" * 60)
    comparison = compare_accuracy(model, tflite_model, X_test, y_test)
    print(f"\nOriginal Model Accuracy:  {comparison['original_accuracy']*100:.2f}%")
    print(f"Quantized Model Accuracy: {comparison['quantized_accuracy']*100:.2f}%")
    print(f"Accuracy Drop:            {comparison['accuracy_drop']*100:.2f}%")
    print(f"\nOriginal Size:  {comparison['original_size_kb']:.1f} KB")
    print(f"Quantized Size: {comparison['quantized_size_kb']:.1f} KB")
    print(f"Compression:    {comparison['compression_ratio']:.1f}×")
    
    print("\n" + "=" * 60)
    print("✓ Ready for FPGA deployment")
    print("=" * 60)
