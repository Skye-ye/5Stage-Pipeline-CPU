`timescale 1ns / 1ps

// FPGA Timer Module for Board Integration
// Generates periodic timer interrupts using clock divider pattern
module timer(
    input        clk,            // System clock
    input        reset,          // Reset (active high)
    input        timer_int_ack,  // Timer interrupt acknowledge signal
    output reg   timer_int       // Timer interrupt output
);

    reg [31:0] clkdiv;
    reg        prev_timer_clk;
    
    // Clock divider counter (same pattern as CLK_DIV)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clkdiv <= 32'b0;
        end else begin
            clkdiv <= clkdiv + 1'b1;
        end
    end
    
    wire timer_clk = clkdiv[27];  // Use bit 27 for timer signal
    
    // Timer interrupt generation on timer_clk rising edge
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            timer_int <= 1'b0;
            prev_timer_clk <= 1'b0;
        end else begin
            prev_timer_clk <= timer_clk;
            
            // Handle interrupt acknowledgment
            if (timer_int && timer_int_ack) begin
                timer_int <= 1'b0;     // Clear interrupt when acknowledged
            end
            
            // Generate interrupt on timer_clk rising edge
            if (timer_clk && !prev_timer_clk && !timer_int) begin
                timer_int <= 1'b1;
            end
        end
    end

endmodule