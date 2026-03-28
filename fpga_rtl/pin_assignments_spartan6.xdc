## Pin Assignments for Xilinx Spartan-6 Boards
## Compatible with: Spartan-6 LX9, LX16, LX25, LX45
## Example board: Nexys 3 (XC6SLX16)

## Clock Signal (100 MHz)
set_property PACKAGE_PIN V10 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

## Reset Button (Active High)
set_property PACKAGE_PIN B8 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## EMG Input Channels (8 channels, 12-bit ADC interface)
## Connect to Pmod JA/JB connectors
## Channel 0-3 on JA, Channel 4-7 on JB

# EMG Channel 0 (JA1)
set_property PACKAGE_PIN C12 [get_ports {emg_data_in[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[0]}]

# EMG Channel 1 (JA2)
set_property PACKAGE_PIN A13 [get_ports {emg_data_in[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[1]}]

# EMG Channel 2 (JA3)
set_property PACKAGE_PIN C13 [get_ports {emg_data_in[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[2]}]

# EMG Channel 3 (JA4)
set_property PACKAGE_PIN D13 [get_ports {emg_data_in[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[3]}]

# EMG Channel 4 (JB1)
set_property PACKAGE_PIN E13 [get_ports {emg_data_in[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[4]}]

# EMG Channel 5 (JB2)
set_property PACKAGE_PIN F13 [get_ports {emg_data_in[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[5]}]

# EMG Channel 6 (JB3)
set_property PACKAGE_PIN G13 [get_ports {emg_data_in[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[6]}]

# EMG Channel 7 (JB4)
set_property PACKAGE_PIN H13 [get_ports {emg_data_in[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[7]}]

## ADC Control Signals
set_property PACKAGE_PIN A14 [get_ports adc_clk]
set_property IOSTANDARD LVCMOS33 [get_ports adc_clk]

set_property PACKAGE_PIN B14 [get_ports adc_data_ready]
set_property IOSTANDARD LVCMOS33 [get_ports adc_data_ready]

## Gesture Output (3-bit binary for 8 classes)
set_property PACKAGE_PIN T9 [get_ports {gesture_class[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gesture_class[0]}]

set_property PACKAGE_PIN V9 [get_ports {gesture_class[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gesture_class[1]}]

set_property PACKAGE_PIN T8 [get_ports {gesture_class[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gesture_class[2]}]

## Status LEDs (8 LEDs for debugging)
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN V16 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN U15 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN V15 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

set_property PACKAGE_PIN M13 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

set_property PACKAGE_PIN R13 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

set_property PACKAGE_PIN R15 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

set_property PACKAGE_PIN R17 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

## Push Buttons
# BTN0 - Test pattern inject
set_property PACKAGE_PIN A8 [get_ports btn_test]
set_property IOSTANDARD LVCMOS33 [get_ports btn_test]

# BTN1 - Calibration mode
set_property PACKAGE_PIN C9 [get_ports btn_calibrate]
set_property IOSTANDARD LVCMOS33 [get_ports btn_calibrate]

## UART Interface (for monitoring)
set_property PACKAGE_PIN N17 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

set_property PACKAGE_PIN N18 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

## Output Valid Signal
set_property PACKAGE_PIN T10 [get_ports output_valid]
set_property IOSTANDARD LVCMOS33 [get_ports output_valid]

## Confidence Output (8-bit)
set_property PACKAGE_PIN U11 [get_ports {confidence[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[0]}]

set_property PACKAGE_PIN V11 [get_ports {confidence[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[1]}]

set_property PACKAGE_PIN U12 [get_ports {confidence[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[2]}]

set_property PACKAGE_PIN V12 [get_ports {confidence[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[3]}]

set_property PACKAGE_PIN T13 [get_ports {confidence[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[4]}]

set_property PACKAGE_PIN U13 [get_ports {confidence[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[5]}]

set_property PACKAGE_PIN V13 [get_ports {confidence[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[6]}]

set_property PACKAGE_PIN T14 [get_ports {confidence[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[7]}]

## Notes:
## - Adjust pin assignments based on your specific Spartan-6 board
## - Common Spartan-6 boards:
##   * Nexys 3: XC6SLX16-CS324
##   * Spartan-6 LX9 MicroBoard: XC6SLX9-CSG324
##   * Atlys: XC6SLX45-CSG324
## - Check your board's reference manual for exact pin locations
## - LVCMOS33 is standard for most Spartan-6 I/O banks
