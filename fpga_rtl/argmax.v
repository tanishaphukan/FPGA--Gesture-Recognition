/*
 * Argmax Block for Classification Output
 * Finds the index of maximum value in output vector
 * Returns gesture class ID
 */

module argmax #(
    parameter NUM_CLASSES = 8,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire signed [DATA_WIDTH-1:0] data_in [0:NUM_CLASSES-1],
    output reg [7:0] class_id,
    output reg valid
);

    // State machine
    localparam IDLE = 1'b0;
    localparam SEARCH = 1'b1;
    
    reg state;
    reg [7:0] idx;
    reg signed [DATA_WIDTH-1:0] max_value;
    reg [7:0] max_idx;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            class_id <= 0;
            valid <= 0;
            idx <= 0;
            max_value <= {DATA_WIDTH{1'b1}};  // Most negative value
            max_idx <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= SEARCH;
                        idx <= 0;
                        max_value <= {DATA_WIDTH{1'b1}};
                        max_idx <= 0;
                        valid <= 0;
                    end
                end
                
                SEARCH: begin
                    if (idx < NUM_CLASSES) begin
                        // Compare current value with max
                        if (data_in[idx] > max_value) begin
                            max_value <= data_in[idx];
                            max_idx <= idx;
                        end
                        idx <= idx + 1;
                    end else begin
                        // Search complete
                        class_id <= max_idx;
                        valid <= 1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

endmodule
