`timescale 1ns / 1ps

// External Interrupt Module for Board Integration
// Generates external interrupts from button press with debouncing
module external_int(
    input        clk,            // System clock
    input        reset,          // Reset (active high)
    input        btnc_i,         // Button input (active high when pressed)
    input        ext_int_ack,    // External interrupt acknowledge signal
    output reg   external_int    // External interrupt output
);

    // Button debouncing parameters
    parameter DEBOUNCE_LIMIT = 1000000; // ~10ms at 100MHz
    
    reg [31:0] debounce_counter;
    reg        btnc_sync1, btnc_sync2;  // Synchronizer registers
    reg        btnc_debounced;
    reg        btnc_prev;
    
    // Synchronize button input to clock domain
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            btnc_sync1 <= 1'b0;
            btnc_sync2 <= 1'b0;
        end else begin
            btnc_sync1 <= btnc_i;
            btnc_sync2 <= btnc_sync1;
        end
    end
    
    // Button debouncing logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            debounce_counter <= 32'h0;
            btnc_debounced <= 1'b0;
        end else begin
            if (btnc_sync2 == btnc_debounced) begin
                debounce_counter <= 32'h0;
            end else begin
                debounce_counter <= debounce_counter + 1;
                if (debounce_counter == DEBOUNCE_LIMIT - 1) begin
                    btnc_debounced <= btnc_sync2;
                    debounce_counter <= 32'h0;
                end
            end
        end
    end
    
    // External interrupt generation on button press (rising edge)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            external_int <= 1'b0;
            btnc_prev <= 1'b0;
        end else begin
            btnc_prev <= btnc_debounced;
            
            // Handle interrupt acknowledgment
            if (external_int && ext_int_ack) begin
                external_int <= 1'b0;     // Clear interrupt when acknowledged
            end
            
            // Generate interrupt on button press (rising edge)
            if (btnc_debounced && !btnc_prev && !external_int) begin
                external_int <= 1'b1;
            end
        end
    end

endmodule