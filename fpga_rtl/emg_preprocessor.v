/*
 * EMG Signal Preprocessor
 * Implements: Bandpass Filter → Rectification → RMS Extraction
 * Processes 8 channels in parallel
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
    input wire signed [DATA_WIDTH-1:0] adc_data [0:NUM_CHANNELS-1],
    output reg signed [OUTPUT_WIDTH-1:0] rms_out [0:NUM_CHANNELS-1],
    output reg rms_valid
);

    // IIR Filter coefficients (4th order Butterworth 20-450Hz @ 2kHz)
    // Simplified fixed-point representation
    localparam signed [15:0] B0 = 16'h0421;  // 0.0321
    localparam signed [15:0] B1 = 16'h0000;
    localparam signed [15:0] B2 = 16'hF7DF;  // -0.0642
    localparam signed [15:0] B3 = 16'h0000;
    localparam signed [15:0] B4 = 16'h0421;
    
    localparam signed [15:0] A1 = 16'hE6B8;  // -1.5432
    localparam signed [15:0] A2 = 16'h1234;  // 0.8765
    localparam signed [15:0] A3 = 16'hF890;  // -0.3210
    localparam signed [15:0] A4 = 16'h0123;  // 0.0456
    
    // Filter state variables for each channel
    reg signed [DATA_WIDTH-1:0] x_delay [0:NUM_CHANNELS-1][0:4];
    reg signed [DATA_WIDTH-1:0] y_delay [0:NUM_CHANNELS-1][0:4];
    reg signed [DATA_WIDTH-1:0] filtered [0:NUM_CHANNELS-1];
    
    // Rectified signal buffer
    reg [DATA_WIDTH-1:0] rectified_buffer [0:NUM_CHANNELS-1][0:WINDOW_SIZE-1];
    reg [7:0] buffer_idx;
    reg [7:0] sample_count;
    
    // RMS computation
    reg [31:0] sum_squares [0:NUM_CHANNELS-1];
    
    integer ch, i;
    
    // Main processing pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_idx <= 0;
            sample_count <= 0;
            rms_valid <= 0;
            
            // Initialize delays
            for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin
                for (i = 0; i < 5; i = i + 1) begin
                    x_delay[ch][i] <= 0;
                    y_delay[ch][i] <= 0;
                end
                filtered[ch] <= 0;
            end
        end else if (data_valid) begin
            
            // Process each channel
            for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin
                
                // ===== STAGE 1: IIR Bandpass Filter =====
                // Shift delay lines
                x_delay[ch][4] <= x_delay[ch][3];
                x_delay[ch][3] <= x_delay[ch][2];
                x_delay[ch][2] <= x_delay[ch][1];
                x_delay[ch][1] <= x_delay[ch][0];
                x_delay[ch][0] <= adc_data[ch];
                
                // Compute filter output (simplified)
                filtered[ch] <= (B0 * x_delay[ch][0] + 
                                B2 * x_delay[ch][2] + 
                                B4 * x_delay[ch][4]) >>> 12;
                
                // ===== STAGE 2: Full-Wave Rectification =====
                if (filtered[ch] < 0)
                    rectified_buffer[ch][buffer_idx] <= -filtered[ch];
                else
                    rectified_buffer[ch][buffer_idx] <= filtered[ch];
            end
            
            // Update buffer index
            buffer_idx <= buffer_idx + 1;
            sample_count <= sample_count + 1;
            
            // ===== STAGE 3: RMS Extraction =====
            if (sample_count >= WINDOW_SIZE && (sample_count % STEP_SIZE == 0)) begin
                
                for (ch = 0; ch < NUM_CHANNELS; ch = ch + 1) begin
                    // Compute sum of squares
                    sum_squares[ch] = 0;
                    for (i = 0; i < WINDOW_SIZE; i = i + 1) begin
                        sum_squares[ch] = sum_squares[ch] + 
                            (rectified_buffer[ch][i] * rectified_buffer[ch][i]);
                    end
                    
                    // Compute RMS (sqrt of mean)
                    // Simplified: use approximation or CORDIC
                    rms_out[ch] <= sqrt_approx(sum_squares[ch] / WINDOW_SIZE);
                end
                
                rms_valid <= 1;
            end else begin
                rms_valid <= 0;
            end
        end
    end
    
    // Square root approximation function
    function [OUTPUT_WIDTH-1:0] sqrt_approx;
        input [31:0] value;
        reg [31:0] temp;
        begin
            // Simple bit-shift approximation
            // For hardware, use CORDIC or Newton-Raphson
            temp = value >> 1;
            sqrt_approx = temp[OUTPUT_WIDTH-1:0];
        end
    endfunction

endmodule
