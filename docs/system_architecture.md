# System Architecture

## Block Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    EMG GESTURE RECOGNITION SYSTEM                    │
└─────────────────────────────────────────────────────────────────────┘

┌──────────────┐      ┌──────────────┐      ┌──────────────────────┐
│   Forearm    │      │   Analog     │      │    12-bit ADC        │
│   Muscles    │─────▶│  Front-End   │─────▶│   2000 Hz/channel    │
│  (8 channels)│      │  (INA333)    │      │   (ADS1298/99)       │
└──────────────┘      └──────────────┘      └──────────┬───────────┘
                                                        │
                                                        │ SPI/Parallel
                                                        ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         FPGA (Artix-7)                               │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │              PREPROCESSING MODULE                           │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │    │
│  │  │  Bandpass    │  │  Full-Wave   │  │     RMS      │     │    │
│  │  │   Filter     │─▶│ Rectifier    │─▶│  Extraction  │     │    │
│  │  │  (20-450Hz)  │  │   (|x|)      │  │  (50ms win)  │     │    │
│  │  └──────────────┘  └──────────────┘  └──────┬───────┘     │    │
│  └────────────────────────────────────────────────┼────────────┘    │
│                                                   │                 │
│  ┌────────────────────────────────────────────────┼────────────┐    │
│  │           NEURAL NETWORK INFERENCE ENGINE      │            │    │
│  │                                                ▼            │    │
│  │  ┌──────────────────────────────────────────────────────┐  │    │
│  │  │  Weight Memory (BRAM)                                │  │    │
│  │  │  - INT8 quantized weights                            │  │    │
│  │  │  - ~50KB total storage                               │  │    │
│  │  └──────────────────────────────────────────────────────┘  │    │
│  │                                                             │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │    │
│  │  │   Conv1D     │  │   Conv1D     │  │    Dense     │    │    │
│  │  │   Layer 1    │─▶│   Layer 2    │─▶│   Layers     │    │    │
│  │  │  (32 filters)│  │  (64 filters)│  │  (128→64→8)  │    │    │
│  │  └──────────────┘  └──────────────┘  └──────┬───────┘    │    │
│  │         ▲                ▲                   ▲             │    │
│  │         └────────────────┴───────────────────┘             │    │
│  │              Parallel MAC Units (16x)                      │    │
│  │                                                             │    │
│  │  ┌──────────────┐                                          │    │
│  │  │   Argmax     │  ◀── Classification Output               │    │
│  │  │   Block      │                                          │    │
│  │  └──────┬───────┘                                          │    │
│  └─────────┼────────────────────────────────────────────────────┘    │
│            │                                                         │
│  ┌─────────┼────────────────────────────────────────────────────┐    │
│  │         ▼                                                     │    │
│  │  ┌──────────────┐  ┌──────────────┐                         │    │
│  │  │   Control    │  │    Output    │                         │    │
│  │  │    FSM       │─▶│   Register   │                         │    │
│  │  └──────────────┘  └──────┬───────┘                         │    │
│  └────────────────────────────┼──────────────────────────────────┘    │
└────────────────────────────────┼───────────────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │   Motor Controller     │
                    │   (Prosthetic Limb)    │
                    └────────────────────────┘
```

## Dataflow Pipeline

### Stage 1: Signal Acquisition (Hardware)
- **Input**: Raw EMG signals from 8 channels
- **Processing**: Amplification (1000x), filtering (analog)
- **Output**: Analog signals → ADC
- **Timing**: Continuous at 2 kHz

### Stage 2: Digitization
- **Input**: Analog EMG signals
- **ADC**: 12-bit resolution, 2000 samples/sec/channel
- **Output**: Digital samples (12-bit values)
- **Data Rate**: 8 channels × 2000 Hz × 12 bits = 192 kbps

### Stage 3: Preprocessing (FPGA)
- **Bandpass Filter**: IIR Butterworth (20-450 Hz)
  - Removes DC offset and high-frequency noise
  - 4th order implementation
  - Latency: ~2 ms
  
- **Rectification**: Absolute value computation
  - Latency: <1 clock cycle
  
- **RMS Extraction**: Sliding window
  - Window: 50 ms (100 samples)
  - Step: 10 ms (20 samples)
  - Output rate: 100 Hz per channel
  - Latency: ~3 ms

### Stage 4: Neural Network Inference (FPGA)
- **Input**: 8 channels × 10 time steps = 80 features
- **Architecture**:
  - Conv1D Layer 1: 80×1 → 76×32 (kernel=5)
  - MaxPool1D: 76×32 → 38×32
  - Conv1D Layer 2: 38×32 → 34×64 (kernel=5)
  - MaxPool1D: 34×64 → 17×64
  - Flatten: 1088 features
  - Dense 1: 1088 → 128
  - Dense 2: 128 → 64
  - Dense 3: 64 → 8 (gesture classes)
  
- **Quantization**: INT8 (8-bit integers)
- **Inference Time**: ~8 ms
- **Power**: ~300 mW

### Stage 5: Output
- **Argmax**: Select highest probability class
- **Output**: Gesture ID (0-7)
- **Interface**: Parallel output to motor controller
- **Update Rate**: 100 Hz

## Resource Utilization (Artix-7 XC7A35T)

| Resource | Usage | Available | Utilization |
|----------|-------|-----------|-------------|
| LUTs | 12,500 | 20,800 | 60% |
| FFs | 8,000 | 41,600 | 19% |
| BRAM | 18 | 50 | 36% |
| DSP48 | 32 | 90 | 36% |

## Timing Analysis

| Stage | Latency | Notes |
|-------|---------|-------|
| ADC Sampling | 0.5 ms | Per sample |
| Preprocessing | 5 ms | Includes filtering + RMS |
| NN Inference | 8 ms | Pipelined execution |
| Output | 0.5 ms | Register transfer |
| **Total** | **14 ms** | Well under 20 ms target |

## Power Budget

| Component | Power | Notes |
|-----------|-------|-------|
| Analog Front-End | 50 mW | 8 channels |
| ADC | 100 mW | ADS1298 |
| FPGA Core | 300 mW | Dynamic power |
| FPGA Static | 50 mW | Leakage |
| **Total** | **500 mW** | Battery: ~4 hours (2000 mAh) |

## Gesture Classes

1. Rest (neutral)
2. Hand Open
3. Hand Close (fist)
4. Wrist Flexion
5. Wrist Extension
6. Pinch Grip
7. Point (index extension)
8. Thumb Up

## Key Design Decisions

### Why FPGA over MCU?
- Parallel processing for real-time inference
- Deterministic latency
- Lower power per operation
- Hardware acceleration for MAC operations

### Why INT8 Quantization?
- 4× memory reduction vs FP32
- 4× faster computation
- Minimal accuracy loss (<2%)
- Fits in FPGA BRAM

### Why 1D CNN?
- Temporal pattern recognition
- Translation invariance
- Fewer parameters than fully connected
- Hardware-friendly architecture

## Testing Strategy

1. **Software Simulation**: Validate model accuracy with Python
2. **RTL Simulation**: Verify hardware logic with testbenches
3. **Co-simulation**: Test FPGA with real EMG datasets
4. **Hardware Validation**: Deploy on FPGA with live EMG input
