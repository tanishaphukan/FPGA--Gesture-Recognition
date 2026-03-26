# Hardware Specifications

## Signal Acquisition Hardware

### EMG Electrode Array

**Configuration**: 8-channel forearm array
- **Electrode Type**: Ag/AgCl surface electrodes
- **Spacing**: 20mm inter-electrode distance
- **Placement**: Circumferential around forearm
- **Reference**: Elbow (bony prominence)
- **Ground**: Wrist

**Recommended Product**: 
- Delsys Trigno Avanti (wireless)
- OT Bioelettronica QUATTROCENTO (research grade)
- Custom PCB with disposable electrodes (cost-effective)

### Analog Front-End (AFE)

**Instrumentation Amplifier**: INA333 (Texas Instruments)
- **Gain**: 1000× (60 dB)
- **CMRR**: >100 dB
- **Input Impedance**: >10 GΩ
- **Bandwidth**: 10 Hz - 500 Hz
- **Power**: 50 μA per channel

**Anti-Aliasing Filter**: 2nd order Sallen-Key
- **Cutoff**: 500 Hz
- **Type**: Low-pass Butterworth
- **Components**: Op-amp (OPA2350), R=10kΩ, C=33nF

### Analog-to-Digital Converter

**Recommended**: ADS1298 (Texas Instruments)
- **Channels**: 8 simultaneous
- **Resolution**: 24-bit (effective 16-bit for EMG)
- **Sampling Rate**: 2000 Hz per channel
- **Input Range**: ±2.4V (programmable)
- **Interface**: SPI (up to 20 MHz)
- **Power**: 0.75 mW per channel
- **Integrated Features**: PGA, lead-off detection

**Alternative**: AD7606 (Analog Devices)
- 8 channels, 16-bit, 200 kSPS

## FPGA Development Board

### Primary Recommendation: Xilinx Artix-7

**Board**: Digilent Arty A7-35T
- **FPGA**: XC7A35T-1CSG324C
- **Logic Cells**: 33,280
- **LUTs**: 20,800
- **Flip-Flops**: 41,600
- **Block RAM**: 1.8 Mb (50 blocks)
- **DSP Slices**: 90 DSP48E1
- **Clock**: 100 MHz (on-board oscillator)
- **I/O**: 48 user I/O pins
- **Power**: USB or external 5V
- **Price**: ~$129

**Advantages**:
- Sufficient resources for CNN inference
- Good development ecosystem (Vivado)
- Built-in USB-UART for debugging
- 4 Pmod connectors for expansion

### Alternative Boards

**Option 2**: Xilinx Zynq-7000 (Zybo Z7-20)
- Includes ARM Cortex-A9 processor
- Useful for complex control logic
- Higher cost (~$299)

**Option 3**: Intel Cyclone V (DE10-Nano)
- ARM Cortex-A9 + FPGA
- Good for Linux-based systems
- Price: ~$130

## Interface Connections

### ADC to FPGA Interface

**SPI Connection**:
```
ADS1298          Arty A7
--------         -------
SCLK     ───────> JA1 (SPI Clock)
DIN      <─────── JA2 (MOSI)
DOUT     ───────> JA3 (MISO)
CS       <─────── JA4 (Chip Select)
DRDY     ───────> JA7 (Data Ready)
START    <─────── JA8 (Start Convert)
```

**Timing**:
- SPI Clock: 4 MHz (safe for 2 kHz sampling)
- Data transfer: 24 bits × 8 channels = 192 bits per sample
- Transfer time: 48 μs per sample set

### Motor Controller Interface

**Parallel Output**:
```
FPGA             Motor Controller
----             ----------------
GPIO[7:0]  ────> Gesture Class ID
GPIO[8]    ────> Valid Signal
GPIO[9]    ────> System Ready
```

**Alternative**: PWM signals for direct servo control
- 8 PWM channels for multi-DOF prosthetic
- Frequency: 50 Hz (standard servo)
- Duty cycle: 1-2 ms (position control)

## Power Supply Design

### Power Requirements

| Component | Voltage | Current | Power |
|-----------|---------|---------|-------|
| FPGA Core | 1.0V | 300 mA | 300 mW |
| FPGA I/O | 3.3V | 50 mA | 165 mW |
| ADC | 3.3V | 30 mA | 100 mW |
| AFE (8ch) | 5.0V | 10 mA | 50 mW |
| **Total** | - | - | **615 mW** |

### Battery Configuration

**Option 1**: Single-cell LiPo (3.7V nominal)
- Capacity: 2000 mAh
- Runtime: ~10 hours (with DC-DC converters)
- Weight: 40g
- Cost: ~$15

**Required Converters**:
- Buck converter: 3.7V → 1.0V (FPGA core)
- LDO: 3.7V → 3.3V (I/O, ADC)
- Boost converter: 3.7V → 5.0V (AFE)

**Option 2**: Dual-cell LiPo (7.4V nominal)
- Better efficiency for 5V generation
- Heavier but longer runtime

## PCB Design Considerations

### Layer Stack-Up (4-layer recommended)
1. **Top**: Signal routing, components
2. **GND**: Solid ground plane
3. **PWR**: Power distribution (1.0V, 3.3V, 5V)
4. **Bottom**: Signal routing, components

### Critical Design Rules

**EMG Signal Integrity**:
- Differential routing for EMG signals
- Guard traces around analog signals
- Star grounding topology
- Separate analog and digital grounds (single-point connection)

**FPGA Considerations**:
- Decoupling capacitors: 0.1μF + 10μF per power pin
- Length-matched differential pairs for high-speed I/O
- Impedance control: 50Ω single-ended, 100Ω differential

**Thermal Management**:
- Thermal vias under FPGA
- Heatsink optional (low power design)
- Ambient operating temp: 0-40°C

## Bill of Materials (BOM)

### Core Components

| Component | Part Number | Qty | Unit Price | Total |
|-----------|-------------|-----|------------|-------|
| FPGA Board | Arty A7-35T | 1 | $129 | $129 |
| ADC | ADS1298IPAG | 1 | $45 | $45 |
| Inst. Amp | INA333 | 8 | $3 | $24 |
| Op-Amp | OPA2350 | 4 | $2 | $8 |
| Electrodes | Disposable Ag/AgCl | 10 | $1 | $10 |
| Battery | LiPo 2000mAh | 1 | $15 | $15 |
| DC-DC Conv | TPS63001 | 2 | $3 | $6 |
| LDO | TLV1117-33 | 1 | $1 | $1 |
| Passives | Resistors, Caps | - | - | $20 |
| PCB | 4-layer, 100×80mm | 1 | $50 | $50 |
| Enclosure | 3D printed | 1 | $10 | $10 |
| **Total** | | | | **$318** |

### Optional Components
- LCD Display (128×64): $15
- Bluetooth Module (HC-05): $8
- SD Card for logging: $5
- Vibration feedback motor: $3

## Assembly and Testing

### Assembly Steps
1. Solder AFE components (INA333, filters)
2. Mount ADC (QFP package - hot air or reflow)
3. Connect FPGA board via headers
4. Wire power distribution
5. Attach electrode cables

### Testing Procedure
1. **Power-On Test**: Verify all voltage rails
2. **ADC Test**: Read noise floor (should be <5 μV RMS)
3. **FPGA Test**: Load test bitstream, verify LED blink
4. **Signal Path Test**: Inject 100 Hz sine wave, verify ADC capture
5. **System Test**: Apply EMG electrodes, verify gesture recognition

## Safety and Regulatory

### Electrical Safety
- Isolated power supply (medical-grade if patient contact)
- Current limiting on all electrode paths (<10 μA)
- ESD protection on all external connections

### EMC Compliance
- Shielded enclosure for EMI reduction
- Ferrite beads on cables
- Proper grounding

### Medical Device Considerations
- If used clinically: FDA Class II device (510(k) required)
- IEC 60601-1 compliance for medical electrical equipment
- Biocompatibility testing for skin contact (ISO 10993)

Note: This prototype is for research/educational purposes. Clinical use requires regulatory approval.

## Mechanical Integration

### Prosthetic Socket Mounting
- Embed electronics in forearm socket
- Waterproof enclosure (IP65 rating)
- Weight budget: <150g total
- Vibration resistance: Secure all connectors

### Electrode Placement
- Consistent positioning critical for accuracy
- Use anatomical landmarks (e.g., 2cm below elbow)
- Skin preparation: clean, dry, light abrasion
- Conductive gel for better contact

## Maintenance and Calibration

### Daily Use
- Replace electrodes every 8-12 hours
- Recharge battery overnight
- Clean electrode sites

### Weekly Calibration
- Perform gesture training (5 reps per gesture)
- Update normalization parameters
- Verify accuracy with test sequence

### Monthly Maintenance
- Inspect electrode cables for damage
- Check connector integrity
- Update firmware if available
