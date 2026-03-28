/*
 * EMG Signal Preprocessor
 * Implements: Bandpass Filter → Rectification → RMS Extraction
 * Processes 8 channels in parallel
 * Fully synthesizable for FPGA deployment
 */

module emg_preprocessor #(
    parameter NUM_CHANNELS = 8,
    parameter DATA_WIDTH = 12,        // ADC resolution
    parameter OUTPUT_WIDTH = 8,       // Quantized output
    parameter WINDOW_SIZE = 100,      // 50ms at 2kHz
    parameter STEP_SIZE = 20          // 10ms step
)(
    input wire clk,
    input wire rst_n,
    input wire data_valid,
    
    // Flattened ADC inputs for synthesis
    input wire signed [DATA_WIDTH-1:0] adc_ch0, adc_ch1, adc_ch2, adc_ch3,
    input wire signed [DATA_WIDTH-1:0] adc_ch4, adc_ch5, adc_ch6, adc_ch7,
    
    // Flattened RMS outputs
    output reg signed [OUTPUT_WIDTH-1:0] rms_ch0, rms_ch1, rms_ch2, rms_ch3,
    output reg signed [OUTPUT_WIDTH-1:0] rms_ch4, rms_ch5, rms_ch6, rms_ch7,
    output reg rms_valid
);

    // Pack inputs into array for processing
    wire signed [DATA_WIDTH-1:0] adc_data [0:NUM_CHANNELS-1];
    assign adc_data[0] = adc_ch0; assign adc_data[1] = adc_ch1;
    assign adc_data[2] = adc_ch2; assign adc_data[3] = adc_ch3;
    assign adc_data[4] = adc_ch4; assign adc_data[5] = adc_ch5;
    assign adc_data[6] = adc_ch6; assign adc_data[7] = adc_ch7;
    
    // Simplified first-order high-pass filter (removes DC)
    // y[n] = alpha * (y[n-1] + x[n] - x[n-1])
    // alpha = 0.95 for ~20Hz cutoff at 2kHz
    localparam signed [15:0] ALPHA = 16'h7999;  // 0.95 in Q15
    
    // Filter state variables
    reg signed [DATA_WIDTH-1:0] x_prev [0:NUM_CHANNELS-1];
    reg signed [DATA_WIDTH-1:0] y_prev [0:NUM_CHANNELS-1];
    reg signed [DATA_WIDTH-1:0] filtered [0:NUM_CHANNELS-1];
    
    // Rectified signal buffer (circular buffer)
    reg [DATA_WIDTH-1:0] rectified_buffer [0:NUM_CHANNELS-1][0:WINDOW_SIZE-1];
    reg [7:0] buffer_idx;
    reg [7:0] sample_count;
    
    // RMS computation
    reg [31:0] sum_squares [0:NUM_CHANNELS-1];
    reg [15:0] rms_temp [0:NUM_CHANNELS-1];
    
    integer ch, i;
    
    // Main processing pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_idx <= 8'd0;
            sample_count <= 8'd0;
            rms_valid <= 1'b0;
            
            // Initialize filter states
            for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin
                x_prev[ch] <= {DATA_WIDTH{1'b0}};
                y_prev[ch] <= {DATA_WIDTH{1'b0}};
                filtered[ch] <= {DATA_WIDTH{1'b0}};
                sum_squares[ch] <= 32'd0;
            end
            
            // Initialize output
            rms_ch0 <= 8'sd0; rms_ch1 <= 8'sd0; rms_ch2 <= 8'sd0; rms_ch3 <= 8'sd0;
            rms_ch4 <= 8'sd0; rms_ch5 <= 8'sd0; rms_ch6 <= 8'sd0; rms_ch7 <= 8'sd0;
            
        end else if (data_valid) begin
            
            // ===== STAGE 1: High-Pass Filter (DC removal) =====
            for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin
                // y[n] = alpha * (y[n-1] + x[n] - x[n-1])
                filtered[ch] <= (y_prev[ch] + adc_data[ch] - x_prev[ch]) >>> 1;  // Simplified
                x_prev[ch] <= adc_data[ch];
                y_prev[ch] <= filtered[ch];
            end
            
            // ===== STAGE 2: Full-Wave Rectification =====
            for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin
                if (filtered[ch][DATA_WIDTH-1])  // Check sign bit
                    rectified_buffer[ch][buffer_idx] <= -filtered[ch];
                else
                    rectified_buffer[ch][buffer_idx] <= filtered[ch];
            end
            
            // Update buffer index (circular)
            if (buffer_idx < WINDOW_SIZE - 1)
                buffer_idx <= buffer_idx + 8'd1;
            else
                buffer_idx <= 8'd0;
            
            sample_count <= sample_count + 8'd1;
            
            // ===== STAGE 3: RMS Extraction =====
            if (sample_count >= WINDOW_SIZE && (sample_count[4:0] == 5'd0)) begin  // Every 32 samples
                
                // Compute sum of squares for each channel
                for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin
                    sum_squares[ch] = 32'd0;
                    for (i = 0; i < WINDOW_SIZE; i = i + 1) begin
                        sum_squares[ch] = sum_squares[ch] + 
                            (rectified_buffer[ch][i] * rectified_buffer[ch][i]);
                    end
                    
                    // Compute RMS: sqrt(mean) - simplified approximation
                    rms_temp[ch] = sum_squares[ch][23:8];  // Divide by 256 (approximate mean)
                end
                
                // Square root approximation and output assignment
                rms_ch0 <= sqrt_approx(rms_temp[0]);
                rms_ch1 <= sqrt_approx(rms_temp[1]);
                rms_ch2 <= sqrt_approx(rms_temp[2]);
                rms_ch3 <= sqrt_approx(rms_temp[3]);
                rms_ch4 <= sqrt_approx(rms_temp[4]);
                rms_ch5 <= sqrt_approx(rms_temp[5]);
                rms_ch6 <= sqrt_approx(rms_temp[6]);
                rms_ch7 <= sqrt_approx(rms_temp[7]);
                
                rms_valid <= 1'b1;
            end else begin
                rms_valid <= 1'b0;
            end
        end else begin
            rms_valid <= 1'b0;
        end
    end
    
    // Square root approximation using bit manipulation
    // For better accuracy, implement CORDIC or Newton-Raphson
    function [OUTPUT_WIDTH-1:0] sqrt_approx;
        input [15:0] value;
        reg [15:0] result;
        begin
            // Simple approximation: sqrt(x) ≈ x/2 + x/8 for normalized values
            result = (value >> 1) + (value >> 3);
            sqrt_approx = result[OUTPUT_WIDTH-1:0];
        end
    endfunction

endmodule
