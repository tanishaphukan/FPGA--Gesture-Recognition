## Pin Assignments for Digilent Basys 3 Board
## FPGA: Xilinx Artix-7 XC7A35T-CPG236
## This is a Spartan successor (7-series) - very popular for students

## Clock Signal (100 MHz)
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

## Reset Button (Active High) - Center button
set_property PACKAGE_PIN U18 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## EMG Input Channels (8 channels via Pmod connectors)
## Pmod JA (Top row: JA1-JA4, Bottom row: JA7-JA10)
## Pmod JB (Top row: JB1-JB4, Bottom row: JB7-JB10)

# EMG Channel 0 (JA1)
set_property PACKAGE_PIN J1 [get_ports {emg_data_in[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[0]}]

# EMG Channel 1 (JA2)
set_property PACKAGE_PIN L2 [get_ports {emg_data_in[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[1]}]

# EMG Channel 2 (JA3)
set_property PACKAGE_PIN J2 [get_ports {emg_data_in[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[2]}]

# EMG Channel 3 (JA4)
set_property PACKAGE_PIN G2 [get_ports {emg_data_in[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[3]}]

# EMG Channel 4 (JB1)
set_property PACKAGE_PIN A14 [get_ports {emg_data_in[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[4]}]

# EMG Channel 5 (JB2)
set_property PACKAGE_PIN A16 [get_ports {emg_data_in[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[5]}]

# EMG Channel 6 (JB3)
set_property PACKAGE_PIN B15 [get_ports {emg_data_in[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[6]}]

# EMG Channel 7 (JB4)
set_property PACKAGE_PIN B16 [get_ports {emg_data_in[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {emg_data_in[7]}]

## ADC Control Signals (JA7, JA8)
set_property PACKAGE_PIN H1 [get_ports adc_clk]
set_property IOSTANDARD LVCMOS33 [get_ports adc_clk]

set_property PACKAGE_PIN K2 [get_ports adc_data_ready]
set_property IOSTANDARD LVCMOS33 [get_ports adc_data_ready]

## Gesture Output (3-bit binary) - Mapped to rightmost LEDs
set_property PACKAGE_PIN U16 [get_ports {gesture_class[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gesture_class[0]}]

set_property PACKAGE_PIN E19 [get_ports {gesture_class[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gesture_class[1]}]

set_property PACKAGE_PIN U19 [get_ports {gesture_class[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gesture_class[2]}]

## Status LEDs (16 LEDs available on Basys 3)
# LED 0-7 for status/debugging
set_property PACKAGE_PIN U16 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN E19 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN U19 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN V19 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

set_property PACKAGE_PIN W18 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

set_property PACKAGE_PIN U15 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

set_property PACKAGE_PIN U14 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

set_property PACKAGE_PIN V14 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

## Push Buttons (5 buttons: U, D, L, R, C)
# BTN0 - Test pattern inject (Up button)
set_property PACKAGE_PIN T18 [get_ports btn_test]
set_property IOSTANDARD LVCMOS33 [get_ports btn_test]

# BTN1 - Calibration mode (Down button)
set_property PACKAGE_PIN U17 [get_ports btn_calibrate]
set_property IOSTANDARD LVCMOS33 [get_ports btn_calibrate]

## UART Interface (USB-UART bridge built-in)
set_property PACKAGE_PIN B18 [get_ports uart_tx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_tx]

set_property PACKAGE_PIN A18 [get_ports uart_rx]
set_property IOSTANDARD LVCMOS33 [get_ports uart_rx]

## Output Valid Signal (LED 15)
set_property PACKAGE_PIN L1 [get_ports output_valid]
set_property IOSTANDARD LVCMOS33 [get_ports output_valid]

## Confidence Output (8-bit) - Mapped to LEDs 8-15
set_property PACKAGE_PIN V13 [get_ports {confidence[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[0]}]

set_property PACKAGE_PIN V3 [get_ports {confidence[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[1]}]

set_property PACKAGE_PIN W3 [get_ports {confidence[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[2]}]

set_property PACKAGE_PIN U3 [get_ports {confidence[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[3]}]

set_property PACKAGE_PIN P3 [get_ports {confidence[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[4]}]

set_property PACKAGE_PIN N3 [get_ports {confidence[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[5]}]

set_property PACKAGE_PIN P1 [get_ports {confidence[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[6]}]

set_property PACKAGE_PIN L1 [get_ports {confidence[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {confidence[7]}]

## 7-Segment Display (for gesture class display)
## Anodes (4 digits)
set_property PACKAGE_PIN U2 [get_ports {seg_an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_an[0]}]

set_property PACKAGE_PIN U4 [get_ports {seg_an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_an[1]}]

set_property PACKAGE_PIN V4 [get_ports {seg_an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_an[2]}]

set_property PACKAGE_PIN W4 [get_ports {seg_an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_an[3]}]

## Cathodes (7 segments + decimal point)
set_property PACKAGE_PIN W7 [get_ports {seg_cat[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cat[0]}]

set_property PACKAGE_PIN W6 [get_ports {seg_cat[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cat[1]}]

set_property PACKAGE_PIN U8 [get_ports {seg_cat[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cat[2]}]

set_property PACKAGE_PIN V8 [get_ports {seg_cat[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cat[3]}]

set_property PACKAGE_PIN U5 [get_ports {seg_cat[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cat[4]}]

set_property PACKAGE_PIN V5 [get_ports {seg_cat[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cat[5]}]

set_property PACKAGE_PIN U7 [get_ports {seg_cat[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg_cat[6]}]

## Configuration Options
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## Notes:
## - Basys 3 is an Artix-7 board (Spartan successor)
## - Very popular for education and prototyping
## - Has built-in USB-UART converter
## - 16 LEDs, 16 switches, 5 buttons, 4-digit 7-segment display
## - 4 Pmod connectors for expansion
## - Price: ~$150 USD
