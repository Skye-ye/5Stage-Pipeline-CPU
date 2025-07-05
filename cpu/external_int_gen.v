`include "def.v"

// External Interrupt Generator Module
// Generates periodic external interrupts for testing
module external_int_gen #(
    parameter EXT_INT_LIMIT = 200
)(
    input        clk,
    input        reset,
    input        ext_int_ack,    // External interrupt acknowledge signal
    output reg   external_int    // External interrupt output
);

    reg [31:0] ext_counter;
    
    // External interrupt counter logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ext_counter <= 32'h0;
            external_int <= 1'b0;
        end else begin
            // Handle interrupt acknowledgment
            if (external_int && ext_int_ack) begin
                external_int <= 1'b0;     // Clear interrupt when acknowledged
            end
            
            // External interrupt counter logic: count 0 to EXT_INT_LIMIT-1 (exactly EXT_INT_LIMIT cycles)
            if (ext_counter == EXT_INT_LIMIT - 1) begin
                ext_counter <= 32'h0;  // Reset counter after EXT_INT_LIMIT cycles
                if (!external_int) begin
                    external_int <= 1'b1;  // Generate interrupt if not already pending
                end
            end else begin
                ext_counter <= ext_counter + 1;  // Increment counter
            end
        end
    end

endmodule