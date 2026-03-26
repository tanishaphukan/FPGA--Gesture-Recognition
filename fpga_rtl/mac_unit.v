/*
 * MAC (Multiply-Accumulate) Unit for Neural Network Inference
 * Performs: accumulator += input * weight
 * Optimized for INT8 operations
 */

module mac_unit #(
    parameter INPUT_WIDTH = 8,      // INT8 input
    parameter WEIGHT_WIDTH = 8,     // INT8 weight
    parameter ACCUM_WIDTH = 32      // 32-bit accumulator
)(
    input wire clk,
    input wire rst_n,
    input wire enable,
    input wire clear_accum,
    input wire signed [INPUT_WIDTH-1:0] data_in,
    input wire signed [WEIGHT_WIDTH-1:0] weight_in,
    output reg signed [ACCUM_WIDTH-1:0] accum_out,
    output wire valid
);

    // Internal signals
    reg signed [INPUT_WIDTH+WEIGHT_WIDTH-1:0] product;
    reg valid_reg;
    
    // Multiply-Accumulate operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 0;
            accum_out <= 0;
            valid_reg <= 0;
        end else begin
            if (clear_accum) begin
                accum_out <= 0;
                valid_reg <= 0;
            end else if (enable) begin
                // Multiply
                product <= data_in * weight_in;
                
                // Accumulate
                accum_out <= accum_out + product;
                valid_reg <= 1;
            end
        end
    end
    
    assign valid = valid_reg;

endmodule
