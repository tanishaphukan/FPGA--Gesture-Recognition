# Timing Constraints for EMG Gesture Recognition System
# Target: Xilinx Artix-7 (100 MHz system clock)

# System Clock - 100 MHz
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} -add [get_ports clk]

# Input Delays - ADC Interface
# Assuming ADC provides data with 2ns setup time
set_input_delay -clock [get_clocks sys_clk_pin] -min 0.5 [get_ports {adc_ch* adc_data_valid}]
set_input_delay -clock [get_clocks sys_clk_pin] -max 2.0 [get_ports {adc_ch* adc_data_valid}]

# Output Delays - Motor Controller Interface
set_output_delay -clock [get_clocks sys_clk_pin] -min 0.5 [get_ports {gesture_class* gesture_valid}]
set_output_delay -clock [get_clocks sys_clk_pin] -max 2.0 [get_ports {gesture_class* gesture_valid}]

# Status outputs (less critical timing)
set_output_delay -clock [get_clocks sys_clk_pin] -max 3.0 [get_ports {preprocessing_active inference_active latency_cycles* system_state*}]

# False Paths
set_false_path -from [get_ports rst_n]
set_false_path -to [get_ports {latency_cycles* system_state*}]

# Clock Uncertainty
set_clock_uncertainty -setup 0.200 [get_clocks sys_clk_pin]
set_clock_uncertainty -hold 0.100 [get_clocks sys_clk_pin]

# Maximum Delay Constraints
set_max_delay 10.0 -from [get_ports adc_data_valid] -to [get_registers */rms_valid]
set_max_delay 20.0 -from [get_registers */rms_valid] -to [get_ports gesture_valid]
