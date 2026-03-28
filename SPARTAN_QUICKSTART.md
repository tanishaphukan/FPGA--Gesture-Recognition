# Spartan Board Quick Start

Deploy to Spartan/Basys boards in 3 steps!

## Supported Boards

✅ **Basys 3** (XC7A35T) - Recommended  
✅ **Nexys A7** (XC7A50T/100T)  
✅ **Atlys** (XC6SLX45) - Spartan-6  
⚠️ **Nexys 3** (XC6SLX16) - May be tight  
❌ **LX9 MicroBoard** - Too small  

## Step 1: Configure Board

Edit `create_vivado_project.tcl` line 7:

```tcl
# Choose your board:

# Basys 3 (Recommended)
set fpga_part "xc7a35tcpg236-1"

# Nexys A7-50T
set fpga_part "xc7a50ticsg324-1L"

# Nexys A7-100T
set fpga_part "xc7a100ticsg324-1L"

# Atlys (Spartan-6)
set fpga_part "xc6slx45csg324-2"

# Nexys 3 (Spartan-6 - tight fit)
set fpga_part "xc6slx16csg324-2"
```

Pin assignments are auto-selected!

## Step 2: Deploy

**Windows:**
```bash
build_and_program.bat
```

**Linux/Mac:**
```bash
./build_and_program.sh
```

**Time:** ~30 minutes (automated)

## Step 3: Test

1. **Status LED**: LED0 should be ON
2. **Test Pattern**: Press Up button (Basys 3) or BTN0
3. **7-Segment**: Shows gesture class (Basys 3 only)
4. **Serial**: 115200 baud (built-in USB on Basys 3)

## Board-Specific Notes

### Basys 3 ⭐
- **Best choice** for students/hobbyists
- Built-in USB-UART (no adapter needed)
- 16 LEDs, 7-segment display
- $150, modern Artix-7

### Nexys A7
- Larger than Basys 3
- More resources for expansion
- $250-$350

### Atlys (Spartan-6)
- Legacy but works
- Requires ISE or Vivado 2017.4+
- $300

### Nexys 3 (Spartan-6)
- **Warning**: Design is tight
- May need optimization
- Consider Basys 3 instead

## Resource Usage

| Board | LUTs Used | LUTs Total | Fits? |
|-------|-----------|------------|-------|
| Basys 3 | 15,000 | 20,800 | ✅ 72% |
| Nexys A7-50T | 15,000 | 32,600 | ✅ 46% |
| Atlys | 3,500 | 6,822 | ✅ 51% |
| Nexys 3 | 3,500 | 2,278 | ⚠️ 154% |

## Troubleshooting

**"Design doesn't fit"**
- Use Basys 3 or larger board
- Or see optimization guide in SPARTAN_DEPLOYMENT.md

**"ISE required"**
- Spartan-6 needs ISE or Vivado 2017.4+
- Or upgrade to Basys 3 (uses modern Vivado)

**"Wrong pin file"**
- Script auto-selects based on FPGA part
- Check `create_vivado_project.tcl` output

## Files Generated

✅ `model_real_data_fp32.pth` (483 KB)  
✅ `model_real_data_int8.pth` (146 KB)  
✅ `fpga_weights_real_data_int8.npz` (122 KB)  
✅ `weights_real_data_init.mem` (1.25 MB)  

## Next Steps

- Connect EMG sensor to Pmod JA/JB
- Test with real gestures
- Monitor via serial terminal

## Full Documentation

- **Detailed Guide**: `SPARTAN_DEPLOYMENT.md`
- **General Guide**: `FPGA_DEPLOYMENT_GUIDE.md`
- **Checklist**: `DEPLOYMENT_CHECKLIST.md`

---

**Recommended:** Basys 3 for best experience!
