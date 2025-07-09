`timescale 1ns / 1ps

// Multi-Channel Data Selector for 7-Segment Display
// Selects data source for display based on switch configuration
// Supports both 32-bit hex data and 64-bit ASCII data
module MULTI_CH32(
    input  wire        clk,        // System clock
    input  wire        rst,        // Reset signal (active high)
    input  wire        EN,         // Write enable for channel 0
    input  wire [5:0]  ctrl,       // Control switches SW[5:0]
    input  wire [31:0] Data0,      // Channel 0: CPU data (programmable)
    input  wire [31:0] data1,      // Channel 1: Fixed data source
    input  wire [31:0] data2,      // Channel 2: Fixed data source
    input  wire [31:0] data3,      // Channel 3: Fixed data source
    input  wire [31:0] data4,      // Channel 4: Fixed data source
    input  wire [31:0] data5,      // Channel 5: Fixed data source
    input  wire [31:0] data6,      // Channel 6: Fixed data source
    input  wire [31:0] data7,      // Channel 7: Fixed data source
    input  wire [31:0] data8,      // Channel 8: Fixed data source
    input  wire [31:0] reg_data,   // Register data (selected by SW[4:0])
    input  wire [63:0] uart_data,  // UART data (8 bytes)
    output reg  [31:0] seg7_data,  // 32-bit data output to 7-segment display
    output wire [63:0] seg7_ascii_data, // 64-bit ASCII data output to 7-segment display
    output wire        ascii_mode  // ASCII mode control output
);

    // Channel 0 Data Storage (CPU Programmable)
    reg [31:0] disp_data = 32'hAA5555AA; // Default pattern for channel 0
    
    // ASCII Data Output (always passes through UART data)
    assign seg7_ascii_data = uart_data;
    
    // ASCII Mode Control: Enable ASCII mode when SW[5:0] = 001xxx
    assign ascii_mode = (ctrl[5:3] == 3'b001);
    
    // Data Source Selection
    // SW[5:0] control mapping:
    // SW[5:3] = 000: Select from channels 0-7 based on SW[2:0] (hex mode)
    // SW[5:3] = 001: UART ASCII mode (display 8 ASCII characters)
    // SW[5:3] = 010: Channel 8 (cycle count) when SW[2:0] = 000, others reserved
    // SW[5:3] = 011: Reserved  
    // SW[5:3] = 100: Register display mode (register selected by SW[4:0])
    // SW[5:3] = 101: Reserved
    // SW[5:3] = 110: UART hex mode - lower 32 bits (chars 0-3 as hex)
    // SW[5:3] = 111: UART hex mode - upper 32 bits (chars 4-7 as hex)
    always @(*) begin
        casex (ctrl) // SW[5:0]
            6'b000000: seg7_data = disp_data;        // Channel 0 (CPU data)
            6'b000001: seg7_data = data1;            // Channel 1
            6'b000010: seg7_data = data2;            // Channel 2
            6'b000011: seg7_data = data3;            // Channel 3
            6'b000100: seg7_data = data4;            // Channel 4
            6'b000101: seg7_data = data5;            // Channel 5
            6'b000110: seg7_data = data6;            // Channel 6
            6'b000111: seg7_data = data7;            // Channel 7
            6'b001xxx: seg7_data = 32'h00000000;     // UART ASCII mode (32-bit data not used)
            6'b010000: seg7_data = data8;            // Channel 8 (cycle count)
            6'b010001: seg7_data = 32'h00000000;     // Reserved
            6'b010010: seg7_data = 32'h00000000;     // Reserved
            6'b010011: seg7_data = 32'h00000000;     // Reserved
            6'b010100: seg7_data = 32'h00000000;     // Reserved
            6'b010101: seg7_data = 32'h00000000;     // Reserved
            6'b010110: seg7_data = 32'h00000000;     // Reserved
            6'b010111: seg7_data = 32'h00000000;     // Reserved
            6'b011xxx: seg7_data = 32'hFFFFFFFF;     // Reserved
            6'b10xxxx: seg7_data = reg_data;         // Register display mode
            default:   seg7_data = 32'h00000000;     // Default case
        endcase
    end

    // Channel 0 Data Update (CPU Programmable Channel)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            disp_data <= 32'hAA5555AA;              // Reset to default pattern
        end else begin
            if (EN) begin
                disp_data <= Data0;                  // Update with CPU data
            end
        end
    end

endmodule
