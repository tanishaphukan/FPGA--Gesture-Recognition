# Quick Start: Deploy to FPGA in 5 Minutes

## Prerequisites
- Xilinx Vivado installed
- Arty A7 FPGA board
- USB cable

## Step 1: Train Model (if not done)
```bash
python ml_model/train_with_real_dataset.py
```

## Step 2: Create Vivado Project
```bash
vivado -mode batch -source create_vivado_project.tcl
```

## Step 3: Build Complete Design
```bash
vivado -mode batch -source run_complete_flow.tcl
```
⏱️ This takes 20-30 minutes

## Step 4: Connect FPGA Board
- Plug USB cable into FPGA board
- Board should power on (LEDs light up)

## Step 5: Program FPGA
```bash
vivado -mode batch -source program_fpga.tcl
```

## Done! 🎉

Your gesture recognition system is now running on the FPGA.

### Test It
1. Press BTN0 on the board to inject test pattern
2. Watch LEDs change to show gesture classification
3. Connect serial terminal (115200 baud) to see output

### With EMG Hardware
1. Connect EMG sensor to Pmod JA
2. Place electrodes on forearm
3. Perform gestures (Rest, Open, Close, Flex, Extend, Pinch, Point, Thumb)
4. Observe real-time classification on LEDs and serial output

---

## Troubleshooting

**"No hardware targets found"**
- Check USB cable
- Install board drivers
- Try different USB port

**"Timing not met"**
- Edit `fpga_rtl/constraints.xdc`
- Change clock period from 10ns to 20ns (50 MHz)
- Re-run build

**"Weight file not found"**
- Run training script first
- Check `ml_model/weights_real_data_init.mem` exists

---

For detailed instructions, see: `FPGA_DEPLOYMENT_GUIDE.md`
