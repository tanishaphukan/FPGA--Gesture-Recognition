/*
 * Dense (Fully Connected) Layer
 * Implements matrix-vector multiplication with ReLU activation
 * Uses parallel MAC units for throughput
 */

module dense_layer #(
    parameter INPUT_SIZE = 128,
    parameter OUTPUT_SIZE = 64,
    parameter DATA_WIDTH = 8,
    parameter ACCUM_WIDTH = 32,
    parameter NUM_MAC_UNITS = 16  // Parallel MAC units
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire signed [DATA_WIDTH-1:0] data_in [0:INPUT_SIZE-1],
    output reg signed [DATA_WIDTH-1:0] data_out [0:OUTPUT_SIZE-1],
    output reg valid,
    output reg done
);

    // State machine
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam ACTIVATE = 2'b10;
    localparam DONE = 2'b11;
    
    reg [1:0] state;
    reg [15:0] neuron_idx;
    reg [15:0] input_idx;
    
    // Weight and bias memory
    reg signed [DATA_WIDTH-1:0] weights [0:OUTPUT_SIZE-1][0:INPUT_SIZE-1];
    reg signed [ACCUM_WIDTH-1:0] bias [0:OUTPUT_SIZE-1];
    
    // Accumulator for each output neuron
    reg signed [ACCUM_WIDTH-1:0] accumulator [0:OUTPUT_SIZE-1];
    
    // MAC unit signals
    wire signed [ACCUM_WIDTH-1:0] mac_result [0:NUM_MAC_UNITS-1];
    wire mac_enable;
    wire mac_clear;
    
    // Generate parallel MAC units
    genvar i;
    generate
        for (i = 0; i < NUM_MAC_UNITS; i = i + 1) begin : mac_array
            mac_unit #(
                .INPUT_WIDTH(DATA_WIDTH),
                .WEIGHT_WIDTH(DATA_WIDTH),
                .ACCUM_WIDTH(ACCUM_WIDTH)
            ) mac_inst (
                .clk(clk),
                .rst_n(rst_n),
                .enable(mac_enable),
                .clear_accum(mac_clear),
                .data_in(data_in[input_idx + i]),
                .weight_in(weights[neuron_idx][input_idx + i]),
                .accum_out(mac_result[i]),
                .valid()
            );
        end
    endgenerate
    
    // Control FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            neuron_idx <= 0;
            input_idx <= 0;
            valid <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= COMPUTE;
                        neuron_idx <= 0;
                        input_idx <= 0;
                        valid <= 0;
                        done <= 0;
                        
                        // Clear accumulators
                        for (integer j = 0; j < OUTPUT_SIZE; j = j + 1) begin
                            accumulator[j] <= bias[j];
                        end
                    end
                end
                
                COMPUTE: begin
                    // Process inputs in parallel batches
                    if (input_idx < INPUT_SIZE) begin
                        input_idx <= input_idx + NUM_MAC_UNITS;
                        
                        // Accumulate MAC results
                        for (integer j = 0; j < NUM_MAC_UNITS; j = j + 1) begin
                            if (input_idx + j < INPUT_SIZE) begin
                                accumulator[neuron_idx] <= accumulator[neuron_idx] + mac_result[j];
                            end
                        end
                    end else begin
                        // Move to next neuron
                        if (neuron_idx < OUTPUT_SIZE - 1) begin
                            neuron_idx <= neuron_idx + 1;
                            input_idx <= 0;
                        end else begin
                            state <= ACTIVATE;
                        end
                    end
                end
                
                ACTIVATE: begin
                    // Apply ReLU activation: max(0, x)
                    for (integer j = 0; j < OUTPUT_SIZE; j = j + 1) begin
                        if (accumulator[j] > 0) begin
                            // Quantize back to INT8 (simplified)
                            data_out[j] <= accumulator[j][DATA_WIDTH-1:0];
                        end else begin
                            data_out[j] <= 0;
                        end
                    end
                    state <= DONE;
                    valid <= 1;
                end
                
                DONE: begin
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end
    
    assign mac_enable = (state == COMPUTE);
    assign mac_clear = (state == IDLE && start);

endmodule
