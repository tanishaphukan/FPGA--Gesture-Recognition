/*
 * Top-Level Module for EMG Gesture Recognition System
 * Integrates all components: Preprocessing, NN Inference, Output
 */

module emg_gesture_recognition_top #(
    parameter NUM_CHANNELS = 8,
    parameter ADC_WIDTH = 12,
    parameter NUM_CLASSES = 8,
    parameter SYSTEM_CLK_FREQ = 100_000_000  // 100 MHz
)(
    // Clock and reset
    input wire clk,
    input wire rst_n,
    
    // ADC interface (SPI or parallel)
    input wire adc_data_valid,
    input wire signed [ADC_WIDTH-1:0] adc_data [0:NUM_CHANNELS-1],
    
    // Output interface
    output wire [7:0] gesture_class,
    output wire gesture_valid,
    
    // Status signals
    output wire preprocessing_active,
    output wire inference_active,
    output wire [15:0] latency_cycles
);

    // Internal signals
    wire signed [7:0] rms_features [0:NUM_CHANNELS-1];
    wire rms_valid;
    
    wire signed [7:0] nn_output [0:NUM_CLASSES-1];
    wire nn_valid;
    
    wire [7:0] argmax_class;
    wire argmax_valid;
    
    // Latency counter
    reg [15:0] cycle_counter;
    reg counting;
    
    // ===== PREPROCESSING MODULE =====
    emg_preprocessor #(
        .NUM_CHANNELS(NUM_CHANNELS),
        .DATA_WIDTH(ADC_WIDTH),
        .OUTPUT_WIDTH(8),
        .WINDOW_SIZE(100),
        .STEP_SIZE(20)
    ) preprocessor (
        .clk(clk),
        .rst_n(rst_n),
        .data_valid(adc_data_valid),
        .adc_data(adc_data),
        .rms_out(rms_features),
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
        .features_in(rms_features),
        .class_scores(nn_output),
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
        .data_in(nn_output),
        .class_id(argmax_class),
        .valid(argmax_valid)
    );
    
    // ===== OUTPUT REGISTER =====
    reg [7:0] gesture_class_reg;
    reg gesture_valid_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gesture_class_reg <= 0;
            gesture_valid_reg <= 0;
        end else begin
            if (argmax_valid) begin
                gesture_class_reg <= argmax_class;
                gesture_valid_reg <= 1;
            end else begin
                gesture_valid_reg <= 0;
            end
        end
    end
    
    // ===== LATENCY MEASUREMENT =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_counter <= 0;
            counting <= 0;
        end else begin
            if (adc_data_valid && !counting) begin
                counting <= 1;
                cycle_counter <= 0;
            end else if (counting) begin
                cycle_counter <= cycle_counter + 1;
                if (gesture_valid_reg) begin
                    counting <= 0;
                end
            end
        end
    end
    
    // Output assignments
    assign gesture_class = gesture_class_reg;
    assign gesture_valid = gesture_valid_reg;
    assign preprocessing_active = rms_valid;
    assign inference_active = nn_valid;
    assign latency_cycles = cycle_counter;

endmodule


/*
 * Neural Network Inference Engine
 * Implements the complete CNN architecture
 */

module nn_inference_engine #(
    parameter INPUT_CHANNELS = 8,
    parameter NUM_CLASSES = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire signed [7:0] features_in [0:INPUT_CHANNELS-1],
    output reg signed [7:0] class_scores [0:NUM_CLASSES-1],
    output reg valid
);

    // State machine
    localparam IDLE = 3'b000;
    localparam CONV1 = 3'b001;
    localparam CONV2 = 3'b010;
    localparam DENSE1 = 3'b011;
    localparam DENSE2 = 3'b100;
    localparam DENSE3 = 3'b101;
    localparam DONE = 3'b110;
    
    reg [2:0] state;
    
    // Layer outputs (simplified sizes)
    reg signed [7:0] conv1_out [0:31];
    reg signed [7:0] conv2_out [0:63];
    reg signed [7:0] dense1_out [0:127];
    reg signed [7:0] dense2_out [0:63];
    
    // Layer control signals
    reg layer_start;
    wire layer_done;
    
    // Main control FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            valid <= 0;
            layer_start <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= CONV1;
                        layer_start <= 1;
                    end
                    valid <= 0;
                end
                
                CONV1: begin
                    layer_start <= 0;
                    if (layer_done) begin
                        state <= CONV2;
                        layer_start <= 1;
                    end
                end
                
                CONV2: begin
                    layer_start <= 0;
                    if (layer_done) begin
                        state <= DENSE1;
                        layer_start <= 1;
                    end
                end
                
                DENSE1: begin
                    layer_start <= 0;
                    if (layer_done) begin
                        state <= DENSE2;
                        layer_start <= 1;
                    end
                end
                
                DENSE2: begin
                    layer_start <= 0;
                    if (layer_done) begin
                        state <= DENSE3;
                        layer_start <= 1;
                    end
                end
                
                DENSE3: begin
                    layer_start <= 0;
                    if (layer_done) begin
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    valid <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // Note: Actual layer instantiations would go here
    // This is a simplified control structure
    assign layer_done = 1'b1;  // Placeholder

endmodule
