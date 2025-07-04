`include "def.v"

// Simple Timer Module for Interrupt Testing
// Generates periodic timer interrupts
module timer(
    input        clk,
    input        reset,
    input [31:0] timer_limit,    // Timer limit value
    output reg   timer_int       // Timer interrupt output
);

    reg [31:0] timer_counter;
    
    // Timer counter logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            timer_counter <= 32'h0;
            timer_int <= 1'b0;
        end else begin
            if (timer_counter >= timer_limit) begin
                timer_counter <= 32'h0;
                timer_int <= 1'b1;     // Generate interrupt pulse
            end else begin
                timer_counter <= timer_counter + 1;
                timer_int <= 1'b0;     // Clear interrupt
            end
        end
    end

endmodule