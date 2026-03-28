# Pin Assignments for Digilent Arty A7-35T Board
# EMG Gesture Recognition System

# System Clock (100 MHz on-board oscillator)
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports clk]

# Reset Button (BTN0)
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports rst_n]

# ADC Data Valid Signal - Pmod JA1
set_property -dict {PACKAGE_PIN G13 IOSTANDARD LVCMOS33} [get_ports adc_data_valid]

# ADC Data Inputs - Pmod JA (8 channels, 12-bit each)
# Using multiple Pmod connectors for 8 channels
# Pmod JA (Channels 0-3)
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[0]}]
set_property -dict {PACKAGE_PIN A11 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[1]}]
set_property -dict {PACKAGE_PIN D12 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[2]}]
set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[3]}]
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[4]}]
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[5]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[6]}]
set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[7]}]
set_property -dict {PACKAGE_PIN E16 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[8]}]
set_property -dict {PACKAGE_PIN D15 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[9]}]
set_property -dict {PACKAGE_PIN C15 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[10]}]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {adc_ch0[11]}]

# Note: For full 8-channel implementation, you would need to map all channels
# This is a simplified example showing channel 0
# In practice, use SPI interface to ADC to reduce pin count

# Gesture Output (3 bits for 8 classes) - LEDs
set_property -dict {PACKAGE_PIN H5 IOSTANDARD LVCMOS33} [get_ports {gesture_class[0]}]
set_property -dict {PACKAGE_PIN J5 IOSTANDARD LVCMOS33} [get_ports {gesture_class[1]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports {gesture_class[2]}]

# Gesture Valid - LED
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports gesture_valid]

# Status Outputs - LEDs
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports preprocessing_active]
set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS33} [get_ports inference_active]

# System State - RGB LEDs (simplified)
set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS33} [get_ports {system_state[0]}]
set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS33} [get_ports {system_state[1]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports {system_state[2]}]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports {system_state[3]}]

# Configuration
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
