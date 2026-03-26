/*
 * 1D Convolutional Layer for EMG Processing
 * Implements parallel convolution with multiple filters
 * Uses pipelined MAC units for efficiency
 */

module conv1d_layer #(
    parameter INPUT_CHANNELS = 8,
    parameter OUTPUT_CHANNELS = 32,
    parameter KERNEL_SIZE = 5,
    parameter INPUT_LENGTH = 10,
    parameter DATA_WIDTH = 8,
    parameter ACCUM_WIDTH = 32
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire signed [DATA_WIDTH-1:0] data_in [0:INPUT_CHANNELS-1],
    output reg signed [DATA_WIDTH-1:0] data_out [0:OUTPUT_CHANNELS-1],
    output reg valid,
    output reg done
);

    // State machine
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam ACTIVATE = 2'b10;
    localparam DONE = 2'b11;
    
    reg [1:0] state;
    reg [7:0] time_step;
    reg [7:0] filter_idx;
    reg [7:0] kernel_idx;
    
    // Weight memory (placeholder - load from external file)
    reg signed [DATA_WIDTH-1:0] weights [0:OUTPUT_CHANNELS-1][0:INPUT_CHANNELS-1][0:KERNEL_SIZE-1];
    reg signed [ACCUM_WIDTH-1:0] bias [0:OUTPUT_CHANNELS-1];
    
    // MAC units
    wire signed [ACCUM_WIDTH-1:0] mac_accum [0:OUTPUT_CHANNELS-1];
    wire mac_enable;
    wire mac_clear;
    
    // Generate MAC units for each output channel
    genvar i;
    generate
        for (i = 0; i < OUTPUT_CHANNELS; i = i + 1) begin : mac_array
            mac_unit #(
                .INPUT_WIDTH(DATA_WIDTH),
                .WEIGHT_WIDTH(DATA_WIDTH),
                .ACCUM_WIDTH(ACCUM_WIDTH)
            ) mac_inst (
                .clk(clk),
                .rst_n(rst_n),
                .enable(mac_enable),
                .clear_accum(mac_clear),
                .data_in(data_in[0]),  // Simplified - actual implementation needs mux
                .weight_in(weights[i][0][0]),
                .accum_out(mac_accum[i]),
                .valid()
            );
        end
    endgenerate
    
    // Control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            valid <= 0;
            done <= 0;
            time_step <= 0;
            filter_idx <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (start) begin
                        state <= COMPUTE;
                        time_step <= 0;
                        filter_idx <= 0;
                        valid <= 0;
                        done <= 0;
                    end
                end
                
                COMPUTE: begin
                    // Perform convolution
                    // Iterate through time steps and filters
                    if (filter_idx < OUTPUT_CHANNELS) begin
                        filter_idx <= filter_idx + 1;
                    end else begin
                        state <= ACTIVATE;
                    end
                end
                
                ACTIVATE: begin
                    // Apply ReLU activation
                    for (integer j = 0; j < OUTPUT_CHANNELS; j = j + 1) begin
                        // ReLU: max(0, x)
                        if (mac_accum[j] > 0)
                            data_out[j] <= mac_accum[j][DATA_WIDTH-1:0];
                        else
                            data_out[j] <= 0;
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
