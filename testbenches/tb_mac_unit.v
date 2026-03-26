/*
 * Testbench for MAC Unit
 * Verifies multiply-accumulate operations
 */

`timescale 1ns / 1ps

module tb_mac_unit;

    // Parameters
    parameter INPUT_WIDTH = 8;
    parameter WEIGHT_WIDTH = 8;
    parameter ACCUM_WIDTH = 32;
    parameter CLK_PERIOD = 10;  // 100 MHz
    
    // Signals
    reg clk;
    reg rst_n;
    reg enable;
    reg clear_accum;
    reg signed [INPUT_WIDTH-1:0] data_in;
    reg signed [WEIGHT_WIDTH-1:0] weight_in;
    wire signed [ACCUM_WIDTH-1:0] accum_out;
    wire valid;
    
    // Instantiate MAC unit
    mac_unit #(
        .INPUT_WIDTH(INPUT_WIDTH),
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .ACCUM_WIDTH(ACCUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .clear_accum(clear_accum),
        .data_in(data_in),
        .weight_in(weight_in),
        .accum_out(accum_out),
        .valid(valid)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize
        rst_n = 0;
        enable = 0;
        clear_accum = 0;
        data_in = 0;
        weight_in = 0;
        
        // Reset
        #(CLK_PERIOD*2);
        rst_n = 1;
        #(CLK_PERIOD);
        
        $display("=== MAC Unit Testbench ===");
        $display("Time\tData\tWeight\tAccum\tValid");
        
        // Test 1: Simple accumulation
        $display("\n--- Test 1: Basic MAC Operations ---");
        clear_accum = 1;
        #(CLK_PERIOD);
        clear_accum = 0;
        
        // MAC: 5 * 3 = 15
        enable = 1;
        data_in = 8'sd5;
        weight_in = 8'sd3;
        #(CLK_PERIOD);
        $display("%0t\t%0d\t%0d\t%0d\t%0b", $time, data_in, weight_in, accum_out, valid);
        
        // MAC: 15 + (4 * 2) = 23
        data_in = 8'sd4;
        weight_in = 8'sd2;
        #(CLK_PERIOD);
        $display("%0t\t%0d\t%0d\t%0d\t%0b", $time, data_in, weight_in, accum_out, valid);
        
        // MAC: 23 + (-3 * 5) = 8
        data_in = -8'sd3;
        weight_in = 8'sd5;
        #(CLK_PERIOD);
        $display("%0t\t%0d\t%0d\t%0d\t%0b", $time, data_in, weight_in, accum_out, valid);
        
        enable = 0;
        #(CLK_PERIOD*2);
        
        // Test 2: Clear and restart
        $display("\n--- Test 2: Clear Accumulator ---");
        clear_accum = 1;
        #(CLK_PERIOD);
        clear_accum = 0;
        $display("Accumulator cleared: %0d", accum_out);
        
        // New accumulation
        enable = 1;
        data_in = 8'sd10;
        weight_in = 8'sd10;
        #(CLK_PERIOD);
        $display("%0t\t%0d\t%0d\t%0d\t%0b", $time, data_in, weight_in, accum_out, valid);
        
        enable = 0;
        #(CLK_PERIOD*2);
        
        // Test 3: Overflow handling
        $display("\n--- Test 3: Large Values ---");
        clear_accum = 1;
        #(CLK_PERIOD);
        clear_accum = 0;
        
        enable = 1;
        data_in = 8'sd127;  // Max INT8
        weight_in = 8'sd127;
        #(CLK_PERIOD);
        $display("%0t\t%0d\t%0d\t%0d\t%0b", $time, data_in, weight_in, accum_out, valid);
        
        enable = 0;
        #(CLK_PERIOD*2);
        
        $display("\n=== All Tests Complete ===");
        $finish;
    end
    
    // Monitor
    initial begin
        $dumpfile("mac_unit.vcd");
        $dumpvars(0, tb_mac_unit);
    end

endmodule
