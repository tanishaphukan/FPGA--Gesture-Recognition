/*
 * Top-Level Module for EMG Gesture Recognition System
 * Complete synthesizable implementation for FPGA deployment
 * Target: Xilinx Artix-7 (XC7A35T or higher)
 */

module emg_gesture_recognition_top #(
    parameter NUM_CHANNELS = 8,
    parameter ADC_WIDTH = 12,
    parameter NUM_CLASSES = 8,
    parameter FEATURE_WIDTH = 8
)(
    // Clock and reset
    input wire clk,              // 100 MHz system clock
    input wire rst_n,            // Active-low reset
    
    // ADC interface - flattened for synthesis
    input wire adc_data_valid,
    input wire signed [ADC_WIDTH-1:0] adc_ch0,
    input wire signed [ADC_WIDTH-1:0] adc_ch1,
    input wire signed [ADC_WIDTH-1:0] adc_ch2,
    input wire signed [ADC_WIDTH-1:0] adc_ch3,
    input wire signed [ADC_WIDTH-1:0] adc_ch4,
    input wire signed [ADC_WIDTH-1:0] adc_ch5,
    input wire signed [ADC_WIDTH-1:0] adc_ch6,
    input wire signed [ADC_WIDTH-1:0] adc_ch7,
    
    // Output interface
    output reg [2:0] gesture_class,    // 0-7 gesture ID
    output reg gesture_valid,
    
    // Status and debug signals
    output wire preprocessing_active,
    output wire inference_active,
    output reg [15:0] latency_cycles,
    output reg [3:0] system_state
);

    // Pack ADC inputs into array for internal use
    wire signed [ADC_WIDTH-1:0] adc_data [0:NUM_CHANNELS-1];
    assign adc_data[0] = adc_ch0;
    assign adc_data[1] = adc_ch1;
    assign adc_data[2] = adc_ch2;
    assign adc_data[3] = adc_ch3;
    assign adc_data[4] = adc_ch4;
    assign adc_data[5] = adc_ch5;
    assign adc_data[6] = adc_ch6;
    assign adc_data[7] = adc_ch7;
    
    // Internal signals - flattened RMS features
    wire signed [FEATURE_WIDTH-1:0] rms_ch0, rms_ch1, rms_ch2, rms_ch3;
    wire signed [FEATURE_WIDTH-1:0] rms_ch4, rms_ch5, rms_ch6, rms_ch7;
    wire rms_valid;
    
    // Neural network outputs - flattened
    wire signed [7:0] nn_out0, nn_out1, nn_out2, nn_out3;
    wire signed [7:0] nn_out4, nn_out5, nn_out6, nn_out7;
    wire nn_valid;
    
    wire [2:0] argmax_class;
    wire argmax_valid;
    
    // Latency measurement
    reg counting;
    
    // ===== PREPROCESSING MODULE =====
    emg_preprocessor #(
        .NUM_CHANNELS(NUM_CHANNELS),
        .DATA_WIDTH(ADC_WIDTH),
        .OUTPUT_WIDTH(FEATURE_WIDTH),
        .WINDOW_SIZE(100),
        .STEP_SIZE(20)
    ) preprocessor (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid(adc_data_valid),
        .adc_ch0(adc_ch0), .adc_ch1(adc_ch1), .adc_ch2(adc_ch2), .adc_ch3(adc_ch3),
        .adc_ch4(adc_ch4), .adc_ch5(adc_ch5), .adc_ch6(adc_ch6), .adc_ch7(adc_ch7),
        .rms_ch0(rms_ch0), .rms_ch1(rms_ch1), .rms_ch2(rms_ch2), .rms_ch3(rms_ch3),
        .rms_ch4(rms_ch4), .rms_ch5(rms_ch5), .rms_ch6(rms_ch6), .rms_ch7(rms_ch7),
        .rms_valid(rms_valid)
    );
    
    // ===== NEURAL NETWORK INFERENCE ENGINE =====
    nn_inference_engine #(
        .INPUT_CHANNELS(NUM_CHANNELS),
        .NUM_CLASSES(NUM_CLASSES)
    ) nn_engine (
        .clk(clk),
        .rst_n(rst_n),
        .start(rms_valid),
        .feat_ch0(rms_ch0), .feat_ch1(rms_ch1), .feat_ch2(rms_ch2), .feat_ch3(rms_ch3),
        .feat_ch4(rms_ch4), .feat_ch5(rms_ch5), .feat_ch6(rms_ch6), .feat_ch7(rms_ch7),
        .score0(nn_out0), .score1(nn_out1), .score2(nn_out2), .score3(nn_out3),
        .score4(nn_out4), .score5(nn_out5), .score6(nn_out6), .score7(nn_out7),
        .valid(nn_valid)
    );
    
    // ===== ARGMAX CLASSIFICATION =====
    argmax #(
        .NUM_CLASSES(NUM_CLASSES),
        .DATA_WIDTH(8)
    ) argmax_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(nn_valid),
        .data0(nn_out0), .data1(nn_out1), .data2(nn_out2), .data3(nn_out3),
        .data4(nn_out4), .data5(nn_out5), .data6(nn_out6), .data7(nn_out7),
        .class_id(argmax_class),
        .valid(argmax_valid)
    );
    
    // ===== OUTPUT REGISTER =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gesture_class <= 3'b000;
            gesture_valid <= 1'b0;
        end else begin
            if (argmax_valid) begin
                gesture_class <= argmax_class;
                gesture_valid <= 1'b1;
            end else begin
                gesture_valid <= 1'b0;
            end
        end
    end
    
    // ===== LATENCY MEASUREMENT =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latency_cycles <= 16'd0;
            counting <= 1'b0;
        end else begin
            if (adc_data_valid && !counting) begin
                counting <= 1'b1;
                latency_cycles <= 16'd0;
            end else if (counting) begin
                if (latency_cycles < 16'hFFFF)
                    latency_cycles <= latency_cycles + 16'd1;
                if (gesture_valid) begin
                    counting <= 1'b0;
                end
            end
        end
    end
    
    // ===== SYSTEM STATE MONITORING =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            system_state <= 4'd0;
        end else begin
            system_state <= {1'b0, argmax_valid, nn_valid, rms_valid};
        end
    end
    
    // Status outputs
    assign preprocessing_active = rms_valid;
    assign inference_active = nn_valid;

endmodule


/*
 * Simplified Neural Network Inference Engine
 * Implements direct feature-to-class mapping with learned weights
 * Suitable for real-time FPGA implementation
 */

module nn_inference_engine #(
    parameter INPUT_CHANNELS = 8,
    parameter NUM_CLASSES = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    // Flattened feature inputs
    input wire signed [7:0] feat_ch0, feat_ch1, feat_ch2, feat_ch3,
    input wire signed [7:0] feat_ch4, feat_ch5, feat_ch6, feat_ch7,
    
    // Flattened class score outputs
    output reg signed [7:0] score0, score1, score2, score3,
    output reg signed [7:0] score4, score5, score6, score7,
    output reg valid
);

    // State machine
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam DONE = 2'b10;
    
    reg [1:0] state;
    reg [7:0] compute_cycles;
    
    // Simplified weight matrix (8 inputs x 8 outputs)
    // In production, load from BRAM or external memory
    reg signed [7:0] weights [0:NUM_CLASSES-1][0:INPUT_CHANNELS-1];
    reg signed [15:0] bias [0:NUM_CLASSES-1];
    
    // Accumulators
    reg signed [23:0] acc [0:NUM_CLASSES-1];
    
    // Feature array
    reg signed [7:0] features [0:INPUT_CHANNELS-1];
    
    integer i, j;
    
    // Initialize weights (placeholder - replace with actual trained weights)
    initial begin
        for (i = 0; i < NUM_CLASSES; i = i + 1) begin
            for (j = 0; j < INPUT_CHANNELS; j = j + 1) begin
                weights[i][j] = 8'sd10;  // Placeholder
            end
            bias[i] = 16'sd0;
        end
    end
    
    // Main FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            valid <= 1'b0;
            compute_cycles <= 8'd0;
            score0 <= 8'sd0; score1 <= 8'sd0; score2 <= 8'sd0; score3 <= 8'sd0;
            score4 <= 8'sd0; score5 <= 8'sd0; score6 <= 8'sd0; score7 <= 8'sd0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    if (start) begin
                        // Capture input features
                        features[0] <= feat_ch0; features[1] <= feat_ch1;
                        features[2] <= feat_ch2; features[3] <= feat_ch3;
                        features[4] <= feat_ch4; features[5] <= feat_ch5;
                        features[6] <= feat_ch6; features[7] <= feat_ch7;
                        
                        // Initialize accumulators with bias
                        for (i = 0; i < NUM_CLASSES; i = i + 1) begin
                            acc[i] <= {{8{bias[i][15]}}, bias[i]};
                        end
                        
                        state <= COMPUTE;
                        compute_cycles <= 8'd0;
                    end
                end
                
                COMPUTE: begin
                    // Perform matrix multiplication
                    if (compute_cycles < INPUT_CHANNELS) begin
                        for (i = 0; i < NUM_CLASSES; i = i + 1) begin
                            acc[i] <= acc[i] + (features[compute_cycles] * weights[i][compute_cycles]);
                        end
                        compute_cycles <= compute_cycles + 8'd1;
                    end else begin
                        // Apply ReLU and quantize to INT8
                        score0 <= (acc[0][23]) ? 8'sd0 : acc[0][15:8];
                        score1 <= (acc[1][23]) ? 8'sd0 : acc[1][15:8];
                        score2 <= (acc[2][23]) ? 8'sd0 : acc[2][15:8];
                        score3 <= (acc[3][23]) ? 8'sd0 : acc[3][15:8];
                        score4 <= (acc[4][23]) ? 8'sd0 : acc[4][15:8];
                        score5 <= (acc[5][23]) ? 8'sd0 : acc[5][15:8];
                        score6 <= (acc[6][23]) ? 8'sd0 : acc[6][15:8];
                        score7 <= (acc[7][23]) ? 8'sd0 : acc[7][15:8];
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    valid <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
