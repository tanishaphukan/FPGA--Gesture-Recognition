# Spartan Board Deployment Guide

Deploy your EMG gesture recognition system to Spartan-series FPGA boards.

## Supported Boards

### Spartan-6 Family (Legacy)
- **Nexys 3**: XC6SLX16-CS324 (~$200)
- **Spartan-6 LX9 MicroBoard**: XC6SLX9-CSG324 (~$150)
- **Atlys**: XC6SLX45-CSG324 (~$300)

### Spartan Successors (7-Series Artix)
- **Basys 3**: XC7A35T-CPG236 (~$150) ⭐ Recommended
- **Nexys A7-50T**: XC7A50T-CSG324 (~$250)
- **Nexys A7-100T**: XC7A100T-CSG324 (~$350)

> Note: Spartan-6 is legacy. For new projects, use Basys 3 (Artix-7) which is the modern equivalent.

---

## Quick Start

### Step 1: Configure for Your Board

Edit `create_vivado_project.tcl` and set your FPGA part:

```tcl
# For Basys 3 (Recommended)
set fpga_part "xc7a35tcpg236-1"

# For Nexys 3 (Spartan-6)
set fpga_part "xc6slx16csg324-2"

# For Spartan-6 LX9
set fpga_part "xc6slx9csg324-2"

# For Atlys (Spartan-6 LX45)
set fpga_part "xc6slx45csg324-2"

# For Nexys A7-50T
set fpga_part "xc7a50ticsg324-1L"
```

The script will automatically select the correct pin assignments!

### Step 2: Train Model (if not done)

```bash
python ml_model/train_with_real_dataset.py
```

### Step 3: Deploy

**Automated:**
```bash
# Windows
build_and_program.bat

# Linux/Mac
./build_and_program.sh
```

**Manual:**
```bash
vivado -mode batch -source create_vivado_project.tcl
vivado -mode batch -source run_complete_flow.tcl
vivado -mode batch -source program_fpga.tcl
```

---

## Board-Specific Notes

### Basys 3 (XC7A35T) ⭐ Recommended

**Why Basys 3?**
- Modern Artix-7 architecture (Spartan successor)
- Excellent student/hobbyist board
- Built-in USB-UART converter
- 16 LEDs, 16 switches, 5 buttons
- 4-digit 7-segment display
- 4 Pmod connectors
- Great documentation and support

**Pin Assignments:**
- EMG Channels: Pmod JA (Ch 0-3), Pmod JB (Ch 4-7)
- LEDs: 16 onboard LEDs for status
- Buttons: 5 buttons (Up, Down, Left, Right, Center)
- UART: Built-in USB-UART (no external adapter needed)
- 7-Segment: Shows gesture class

**Resource Usage:**
```
LUTs:        ~15,000 / 20,800  (72%)
Flip-Flops:  ~8,000  / 41,600  (19%)
BRAMs:       ~25     / 50      (50%)
DSPs:        ~40     / 90      (44%)
✓ Fits comfortably
```

**Clock:** 100 MHz onboard oscillator

**Programming:** USB cable (same cable for power and programming)

---

### Nexys 3 (XC6SLX16) - Spartan-6

**Considerations:**
- Legacy Spartan-6 architecture
- ISE Design Suite required (not Vivado)
- Smaller resources than Basys 3
- Still capable for this project

**Resource Usage:**
```
Slices:      ~3,500 / 2,278   (⚠ May not fit!)
Flip-Flops:  ~8,000  / 18,224  (44%)
BRAMs:       ~25     / 32      (78%)
DSPs:        ~40     / 32      (⚠ Exceeds!)
```

**⚠ Warning:** The design may be too large for XC6SLX16. Consider:
1. Reducing model complexity
2. Using fewer MAC units
3. Upgrading to Atlys (XC6SLX45)
4. Switching to Basys 3 (recommended)

**Clock:** 100 MHz onboard oscillator

**Programming:** USB cable via Digilent Adept

---

### Spartan-6 LX9 MicroBoard

**Considerations:**
- Very small FPGA (LX9)
- Design will NOT fit without significant modifications
- Not recommended for this project

**Recommendation:** Use Basys 3 or larger Spartan-6 (LX45)

---

### Atlys (XC6SLX45) - Spartan-6

**Considerations:**
- Larger Spartan-6 (LX45)
- Design should fit comfortably
- Good for legacy Spartan-6 development

**Resource Usage:**
```
Slices:      ~3,500 / 6,822   (51%)
Flip-Flops:  ~8,000  / 54,576  (15%)
BRAMs:       ~25     / 116     (22%)
DSPs:        ~40     / 58      (69%)
✓ Fits well
```

**Clock:** 100 MHz onboard oscillator

**Programming:** USB cable via Digilent Adept

---

### Nexys A7 (XC7A50T/XC7A100T)

**Considerations:**
- Modern Artix-7 architecture
- Larger than Basys 3
- More resources for expansion
- Higher cost

**Resource Usage (A7-50T):**
```
LUTs:        ~15,000 / 32,600  (46%)
Flip-Flops:  ~8,000  / 65,200  (12%)
BRAMs:       ~25     / 75      (33%)
DSPs:        ~40     / 120     (33%)
✓ Plenty of room for expansion
```

**Clock:** 100 MHz onboard oscillator

**Programming:** USB cable (built-in JTAG)

---

## Pin Assignment Files

The project includes pin assignments for:

1. **Arty A7**: `fpga_rtl/pin_assignments_arty_a7.xdc`
2. **Basys 3**: `fpga_rtl/pin_assignments_basys3.xdc`
3. **Spartan-6**: `fpga_rtl/pin_assignments_spartan6.xdc`

The build script automatically selects the correct file based on your FPGA part number.

### Custom Board?

If using a different board, create a new pin assignment file:

1. Copy an existing `.xdc` file
2. Update pin numbers from your board's reference manual
3. Update the auto-selection logic in `create_vivado_project.tcl`

---

## Resource Optimization for Smaller FPGAs

If your design doesn't fit, try these optimizations:

### 1. Reduce Model Complexity

Edit `ml_model/train_with_real_dataset.py`:

```python
# Reduce filters
model = nn.Sequential(
    nn.Conv1d(8, 16, kernel_size=5),  # Was 32
    nn.ReLU(),
    nn.MaxPool1d(2),
    nn.Conv1d(16, 32, kernel_size=3),  # Was 64
    # ... rest of model
)
```

### 2. Reduce Parallelism

Edit `fpga_rtl/conv1d_layer.v`:

```verilog
// Reduce number of parallel MAC units
parameter NUM_MAC_UNITS = 4;  // Was 8
```

### 3. Use Fewer Channels

Edit `fpga_rtl/top_module.v`:

```verilog
// Use 4 channels instead of 8
parameter NUM_CHANNELS = 4;  // Was 8
```

### 4. Lower Clock Frequency

Edit `fpga_rtl/constraints.xdc`:

```tcl
# Reduce to 50 MHz
create_clock -period 20.000 [get_ports clk]  # Was 10.000
```

---

## Spartan-6 Specific: Using ISE Instead of Vivado

Spartan-6 boards require ISE Design Suite (legacy tool).

### Install ISE

1. Download ISE WebPACK 14.7 (free)
2. Install on Windows 7/10 or Linux
3. Install Digilent Adept for board support

### Create ISE Project

```bash
# ISE doesn't use TCL scripts the same way
# Use ISE GUI:
1. File → New Project
2. Select Spartan-6 device
3. Add Verilog files from fpga_rtl/
4. Add constraints (.ucf format, not .xdc)
5. Run Synthesis → Implementation → Generate Bitstream
```

### Convert XDC to UCF

XDC (Vivado) constraints need conversion to UCF (ISE):

```ucf
# Example UCF for Spartan-6
NET "clk" LOC = "V10" | IOSTANDARD = LVCMOS33;
NET "rst" LOC = "B8" | IOSTANDARD = LVCMOS33;
NET "led<0>" LOC = "U16" | IOSTANDARD = LVCMOS33;
# ... etc
```

---

## Comparison Table

| Board | FPGA | LUTs | BRAMs | DSPs | Price | Fits? | Recommended |
|-------|------|------|-------|------|-------|-------|-------------|
| Basys 3 | XC7A35T | 20,800 | 50 | 90 | $150 | ✅ Yes | ⭐ Best |
| Nexys A7-50T | XC7A50T | 32,600 | 75 | 120 | $250 | ✅ Yes | Good |
| Nexys A7-100T | XC7A100T | 63,400 | 135 | 240 | $350 | ✅ Yes | Overkill |
| Atlys | XC6SLX45 | 6,822 | 116 | 58 | $300 | ✅ Yes | Legacy |
| Nexys 3 | XC6SLX16 | 2,278 | 32 | 32 | $200 | ⚠ Tight | Legacy |
| LX9 MicroBoard | XC6SLX9 | 1,430 | 32 | 16 | $150 | ❌ No | Too small |

---

## Testing on Spartan Boards

### Basys 3 Testing

1. **Power On**: Connect USB cable
2. **Program**: Run programming script
3. **Status Check**:
   - LED 0: System ready (ON)
   - LED 1-2: Gesture class (binary)
   - 7-Segment: Shows gesture number
4. **Test Pattern**: Press Up button (BTN0)
5. **Serial Monitor**: 
   - Open PuTTY/Tera Term
   - Find COM port in Device Manager
   - 115200 baud, 8N1

### Spartan-6 Testing

1. **Power On**: Connect USB cable
2. **Program**: Use Digilent Adept
3. **Status Check**:
   - LEDs show system status
   - No 7-segment on most Spartan-6 boards
4. **Test Pattern**: Press button
5. **Serial Monitor**: 
   - May need external USB-UART adapter
   - Connect to UART pins on Pmod

---

## Troubleshooting

### "Design doesn't fit"

**Solution:**
1. Check resource utilization report
2. Apply optimizations (see above)
3. Consider upgrading to larger FPGA
4. Basys 3 is recommended minimum

### "ISE required for Spartan-6"

**Solution:**
1. Download ISE WebPACK 14.7
2. Convert project to ISE format
3. Or upgrade to Basys 3 (uses Vivado)

### "Timing not met on Spartan-6"

**Solution:**
1. Reduce clock frequency to 50 MHz
2. Add pipeline stages
3. Simplify design

### "No 7-segment display"

**Solution:**
- Spartan-6 boards may not have 7-segment
- Use LEDs for gesture indication
- Or add external 7-segment via Pmod

---

## Recommendation Summary

**For New Projects:** Use **Basys 3** (XC7A35T)
- Modern architecture
- Great support
- Perfect size for this project
- Best value ($150)

**For Legacy Projects:** Use **Atlys** (XC6SLX45)
- If you already have Spartan-6 tools
- Larger Spartan-6 device
- Design fits comfortably

**Avoid:**
- Nexys 3 (XC6SLX16) - Too small
- LX9 MicroBoard - Way too small

---

## Next Steps

1. Choose your board
2. Update `fpga_part` in `create_vivado_project.tcl`
3. Run deployment scripts
4. Test with EMG hardware

For detailed deployment instructions, see `FPGA_DEPLOYMENT_GUIDE.md`

---

**Questions?** Check the main deployment guide or open an issue on GitHub.
