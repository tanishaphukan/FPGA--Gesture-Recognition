/*
 * Argmax Block for Classification Output
 * Finds the index of maximum value in output vector
 * Returns gesture class ID (0-7)
 * Fully synthesizable implementation
 */

module argmax #(
    parameter NUM_CLASSES = 8,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    // Flattened inputs for synthesis
    input wire signed [DATA_WIDTH-1:0] data0, data1, data2, data3,
    input wire signed [DATA_WIDTH-1:0] data4, data5, data6, data7,
    
    output reg [2:0] class_id,  // 3 bits for 0-7
    output reg valid
);

    // State machine
    localparam IDLE = 1'b0;
    localparam SEARCH = 1'b1;
    
    reg state;
    reg [2:0] idx;
    reg signed [DATA_WIDTH-1:0] max_value;
    reg [2:0] max_idx;
    
    // Internal array for processing
    reg signed [DATA_WIDTH-1:0] data_array [0:NUM_CLASSES-1];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            class_id <= 3'd0;
            valid <= 1'b0;
            idx <= 3'd0;
            max_value <= 8'sh80;  // Most negative INT8 value
            max_idx <= 3'd0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    if (start) begin
                        // Capture inputs
                        data_array[0] <= data0; data_array[1] <= data1;
                        data_array[2] <= data2; data_array[3] <= data3;
                        data_array[4] <= data4; data_array[5] <= data5;
                        data_array[6] <= data6; data_array[7] <= data7;
                        
                        state <= SEARCH;
                        idx <= 3'd0;
                        max_value <= 8'sh80;  // Reset to most negative
                        max_idx <= 3'd0;
                    end
                end
                
                SEARCH: begin
                    if (idx < NUM_CLASSES) begin
                        // Compare current value with max
                        if (data_array[idx] > max_value) begin
                            max_value <= data_array[idx];
                            max_idx <= idx;
                        end
                        idx <= idx + 3'd1;
                    end else begin
                        // Search complete
                        class_id <= max_idx;
                        valid <= 1'b1;
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule
