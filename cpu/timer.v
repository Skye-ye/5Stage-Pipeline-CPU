`include "def.v"

// Simple Timer Module for Interrupt Testing
// Generates periodic timer interrupts
module timer #(
    parameter TIMER_LIMIT = 100
)(
    input        clk,
    input        reset,
    input        timer_int_ack,  // Timer interrupt acknowledge signal
    output reg   timer_int       // Timer interrupt output
);

    reg [31:0] timer_counter;
    
    // Timer counter logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            timer_counter <= 32'h0;
            timer_int <= 1'b0;
        end else begin
            // Handle interrupt acknowledgment
            if (timer_int && timer_int_ack) begin
                timer_int <= 1'b0;     // Clear interrupt when acknowledged
            end
            
            if (timer_counter == TIMER_LIMIT - 1) begin
                timer_counter <= 32'h0;  // Reset counter after TIMER_LIMIT cycles
                if (!timer_int) begin
                    timer_int <= 1'b1;  // Generate interrupt if not already pending
                end
            end else begin
                timer_counter <= timer_counter + 1;  // Increment counter
            end
        end
    end

endmodule