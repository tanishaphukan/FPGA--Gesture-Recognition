# Complete EMG Gesture Recognition ML Pipeline

## Overview

This directory contains a complete end-to-end machine learning pipeline for EMG-based gesture recognition, specifically designed for FPGA deployment. The implementation uses PyTorch and includes all stages from data generation to hardware-ready model export.

## Pipeline Architecture

```
Raw EMG Signal (12 channels, 2000 Hz)
    ↓
[1] Signal Preprocessing
    - Bandpass Filter (20-450 Hz)
    - Full-Wave Rectification
    - RMS Feature Extraction (50ms window, 10ms step)
    ↓
Feature Tensor (12 channels, ~95 time steps)
    ↓
[2] 1D CNN Model
    - Conv1D: 12→32 filters (kernel=5)
    - ReLU + MaxPool
    - Conv1D: 32→64 filters (kernel=3)
    - ReLU + MaxPool
    - Dense: 128 neurons
    - Dropout: 0.4
    - Output: 8 classes
    ↓
Gesture Classification (0-7)
    ↓
[3] Post-Training Quantization
    - FP32 → INT8
    - 4x size reduction
    - Minimal accuracy loss
    ↓
[4] Hardware Export
    - ONNX format
    - INT8 weights for FPGA
    - Verilog memory initialization
```

## Files

### Main Scripts

- **`complete_emg_pipeline.py`** - Complete end-to-end pipeline (run this first)
- **`visualize_results.py`** - Generate plots and analysis
- **`train_cnn.py`** - Standalone training script (legacy)
- **`quantize_model.py`** - Model quantization utilities (legacy)
- **`export_weights.py`** - Weight export for hardware (legacy)

### Generated Files

After running the pipeline, the following files are created:

- `model_fp32.pth` - Original PyTorch model (FP32)
- `model_int8.pth` - Quantized model (INT8)
- `emg_gesture_model.onnx` - ONNX format for deployment
- `fpga_weights_int8.npz` - INT8 weights in NumPy format
- `weights_init.mem` - Verilog memory initialization file

## Installation

### Requirements

```bash
pip install -r ../requirements.txt
```

Key dependencies:
- PyTorch >= 1.10.0
- NumPy >= 1.21.0
- SciPy >= 1.7.0
- scikit-learn >= 1.0.0
- ONNX >= 1.10.0

### Quick Start

```bash
# Run complete pipeline
python complete_emg_pipeline.py

# Generate visualizations (optional)
python visualize_results.py
```

## Pipeline Details

### 1. Data Generation

The pipeline includes a synthetic EMG data generator that creates realistic gesture signals:

```python
generator = EMGDataGenerator(
    num_samples=1000,      # Total samples
    num_channels=12,       # EMG channels
    sampling_rate=2000,    # Hz
    duration=1.0,          # seconds
    num_classes=8          # Gesture types
)
```

**Gesture Classes:**
0. Rest (neutral)
1. Hand Open
2. Hand Close (fist)
3. Wrist Flexion
4. Wrist Extension
5. Pinch Grip
6. Point (index extension)
7. Thumb Up

**Note:** For real-world deployment, replace with actual EMG dataset (e.g., NinaPro DB2).

### 2. Signal Preprocessing

Implements the same preprocessing as the FPGA module:

```python
preprocessor = EMGPreprocessor(
    sampling_rate=2000,
    lowcut=20,           # Hz
    highcut=450,         # Hz
    window_size_ms=50,   # RMS window
    step_size_ms=10      # RMS step
)
```

**Stages:**
1. **Bandpass Filter** - 4th order Butterworth (20-450 Hz)
   - Removes DC offset and high-frequency noise
   - FPGA: IIR filter in fixed-point arithmetic

2. **Rectification** - Absolute value
   - Converts bipolar signal to unipolar
   - FPGA: Simple comparator + negation

3. **RMS Extraction** - Sliding window
   - Window: 50ms (100 samples at 2kHz)
   - Step: 10ms (20 samples)
   - FPGA: Circular buffer + accumulator + sqrt approximation

### 3. CNN Model Architecture

Lightweight 1D CNN optimized for FPGA implementation:

```
Input: (batch, 12, 95)
    ↓
Conv1D(12→32, k=5) + ReLU + MaxPool(2)
    ↓ (batch, 32, 47)
Conv1D(32→64, k=3) + ReLU + MaxPool(2)
    ↓ (batch, 64, 23)
Flatten → (batch, 1472)
    ↓
Dense(1472→128) + ReLU + Dropout(0.4)
    ↓
Dense(128→8)
    ↓
Output: (batch, 8) [gesture scores]
```

**Hardware Mapping:**

| Layer | Operation | FPGA Implementation | MAC Ops |
|-------|-----------|---------------------|---------|
| Conv1D-1 | 12×32×5 convolution | Parallel MAC units (DSP48) | 90,240 |
| Conv1D-2 | 32×64×3 convolution | Parallel MAC units (DSP48) | 144,384 |
| Dense-1 | 1472×128 matrix-vector | Sequential MAC operations | 188,416 |
| Dense-2 | 128×8 matrix-vector | Sequential MAC operations | 1,024 |
| **Total** | | | **424,064** |

At 100 MHz clock: ~4.2 ms theoretical inference time

### 4. Training Configuration

```python
optimizer = Adam(lr=0.001)
loss = CrossEntropyLoss()
epochs = 50
batch_size = 32
train_split = 0.66
test_split = 0.33
```

**Expected Performance:**
- Training accuracy: >95%
- Test accuracy: >90%
- Training time: ~5-10 minutes (CPU)

### 5. Quantization (FP32 → INT8)

Post-training dynamic quantization:

```python
quantized_model = torch.quantization.quantize_dynamic(
    model, 
    {nn.Linear, nn.Conv1d}, 
    dtype=torch.qint8
)
```

**Benefits:**
- 4× model size reduction
- 2-3× inference speedup
- <2% accuracy drop
- Hardware-friendly (integer arithmetic)

**Quantization Process:**
1. Analyze activation ranges during inference
2. Compute scale factors for each layer
3. Convert FP32 weights to INT8
4. Maintain accuracy through careful scaling

### 6. Hardware Export

Three export formats for different use cases:

#### ONNX Format
```python
torch.onnx.export(model, dummy_input, "emg_gesture_model.onnx")
```
- Standard format for deployment
- Compatible with ONNX Runtime
- Can be converted to other frameworks

#### INT8 Weights (NumPy)
```python
np.savez('fpga_weights_int8.npz', **weights_dict)
```
- Quantized weights with scale factors
- Easy to load in Python/C++
- Suitable for embedded systems

#### Verilog Memory File
```verilog
// weights_init.mem
@0000 1a
@0001 f3
@0002 2c
...
```
- Hexadecimal INT8 values
- Direct initialization of FPGA Block RAM
- Used in `weight_memory.v` module

## Usage Examples

### Basic Training

```python
from complete_emg_pipeline import EMGDataGenerator, EMGPreprocessor, EMGGestureCNN

# Generate data
generator = EMGDataGenerator()
raw_data, labels = generator.generate_dataset()

# Preprocess
preprocessor = EMGPreprocessor()
features = preprocessor.process(raw_data[0])

# Create and train model
model = EMGGestureCNN()
# ... training code ...
```

### Real-Time Inference

```python
# Load trained model
model = EMGGestureCNN()
model.load_state_dict(torch.load('model_fp32.pth'))
model.eval()

# Process new EMG signal
raw_signal = acquire_emg_signal()  # Your acquisition function
features = preprocessor.process(raw_signal)
features_tensor = torch.FloatTensor(features).unsqueeze(0)

# Predict gesture
with torch.no_grad():
    output = model(features_tensor)
    predicted_class = torch.argmax(output, dim=1).item()
    
print(f"Predicted gesture: {predicted_class}")
```

### Load Quantized Model

```python
quantized_model = torch.jit.load('model_int8.pth')
quantized_model.eval()

# Inference (same as FP32)
output = quantized_model(features_tensor)
```

## Hardware Integration

### FPGA Deployment Workflow

1. **Generate Weights**
   ```bash
   python complete_emg_pipeline.py
   ```
   This creates `weights_init.mem`

2. **Update Verilog**
   ```verilog
   // In weight_memory.v
   initial begin
       $readmemh("weights_init.mem", weight_mem);
   end
   ```

3. **Synthesize Design**
   ```bash
   vivado -mode batch -source synthesize.tcl
   ```

4. **Program FPGA**
   ```bash
   vivado -mode batch -source program.tcl
   ```

5. **Test Hardware**
   - Connect ADC (ADS1298) to FPGA
   - Apply EMG electrodes
   - Verify gesture recognition

### Memory Requirements

| Component | Size | FPGA Resource |
|-----------|------|---------------|
| Conv1D-1 weights | 1.5 KB | BRAM |
| Conv1D-2 weights | 6 KB | BRAM |
| Dense-1 weights | 184 KB | BRAM |
| Dense-2 weights | 1 KB | BRAM |
| Activation buffers | 10 KB | BRAM |
| **Total** | **~200 KB** | **11 BRAM blocks** |

Artix-7 XC7A35T has 50 BRAM blocks (1.8 Mb) - plenty of capacity!

### Performance Estimates

| Metric | Value | Notes |
|--------|-------|-------|
| Inference latency | 5-10 ms | At 100 MHz clock |
| Preprocessing latency | 3-5 ms | Includes filtering + RMS |
| Total latency | 8-15 ms | Well under 20 ms target |
| Power consumption | 300-500 mW | FPGA + ADC |
| Throughput | 60-120 Hz | Real-time capable |

## Troubleshooting

### Common Issues

**Issue: Low training accuracy (<80%)**
- Solution: Increase training epochs or adjust learning rate
- Check: Data normalization is applied correctly

**Issue: Large accuracy drop after quantization (>5%)**
- Solution: Use quantization-aware training instead of post-training
- Check: Activation ranges are reasonable (not too large/small)

**Issue: ONNX export fails**
- Solution: Update PyTorch and ONNX versions
- Check: Model uses supported operations

**Issue: Weights file too large for FPGA**
- Solution: Reduce model size (fewer filters/neurons)
- Consider: Model pruning or knowledge distillation

## Performance Optimization

### Model Size Reduction

1. **Pruning** - Remove low-magnitude weights
2. **Knowledge Distillation** - Train smaller model from larger one
3. **Architecture Search** - Find optimal layer sizes

### Inference Speed

1. **Increase Parallelism** - More MAC units in FPGA
2. **Pipeline Stages** - Overlap computation
3. **Reduce Precision** - INT4 or binary weights

### Accuracy Improvement

1. **Data Augmentation** - Add noise, time shifts
2. **Ensemble Methods** - Multiple models voting
3. **Transfer Learning** - Pre-train on larger dataset

## References

### Papers
- "Deep Learning for EMG-based Gesture Recognition" (2019)
- "FPGA Implementation of Neural Networks" (2020)
- "Quantization and Training of Neural Networks" (2018)

### Datasets
- NinaPro Database: http://ninapro.hevs.ch/
- CapgMyo Database: http://zju-capg.org/myo.html

### Tools
- PyTorch: https://pytorch.org/
- ONNX: https://onnx.ai/
- Vivado: https://www.xilinx.com/products/design-tools/vivado.html

## Contributing

To improve this pipeline:
1. Add support for real EMG datasets
2. Implement quantization-aware training
3. Add more preprocessing options
4. Optimize model architecture
5. Create hardware-in-the-loop testing

## License

This project is for educational and research purposes.

## Contact

For questions or issues, please refer to the main project README.
