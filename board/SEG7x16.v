`timescale 1ns / 1ps

// 7-Segment Display Controller (8 digits)
// Displays data on 8-digit 7-segment display
// Supports both hexadecimal mode (32-bit) and ASCII mode (64-bit)
module SEG7x16(
    input  wire        clk,         // System clock
    input  wire        rst,         // Reset signal (active high)
    input  wire        cs,          // Chip select (data latch enable)
    input  wire        ascii_mode,  // ASCII mode control (1=ASCII, 0=HEX)
    input  wire [31:0] i_data,      // 32-bit input data for hex mode
    input  wire [63:0] i_data_ascii, // 64-bit input data for ASCII mode (8 chars)
    output wire [7:0]  o_seg,       // 7-segment patterns (active low)
    output wire [7:0]  o_sel        // Digit select signals (active low)
);

    reg [14:0] cnt;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt <= 15'b0;
        end else begin
            cnt <= cnt + 1'b1;
        end
    end
    
    wire seg7_clk = cnt[14];  // Divided clock for digit scanning
    
    reg [2:0] seg7_addr;
    
    always @(posedge seg7_clk or posedge rst) begin
        if (rst) begin
            seg7_addr <= 3'b0;
        end else begin
            seg7_addr <= seg7_addr + 1'b1;
        end
    end
    
    reg [7:0] o_sel_r;
    
    always @(*) begin
        case (seg7_addr)
            3'd7: o_sel_r = 8'b01111111;  // Digit 7 (MSB)
            3'd6: o_sel_r = 8'b10111111;  // Digit 6
            3'd5: o_sel_r = 8'b11011111;  // Digit 5
            3'd4: o_sel_r = 8'b11101111;  // Digit 4
            3'd3: o_sel_r = 8'b11110111;  // Digit 3
            3'd2: o_sel_r = 8'b11111011;  // Digit 2
            3'd1: o_sel_r = 8'b11111101;  // Digit 1
            3'd0: o_sel_r = 8'b11111110;  // Digit 0 (LSB)
        endcase
    end
    
    reg [31:0] i_data_store;        // Storage for hex mode data
    reg [63:0] i_data_ascii_store;  // Storage for ASCII mode data
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i_data_store <= 32'b0;
            i_data_ascii_store <= 64'b0;
        end else if (cs) begin
            i_data_store <= i_data;
            i_data_ascii_store <= i_data_ascii;
        end
    end
    
    reg [7:0] seg_data_r;  // Changed to 8-bit to support ASCII
    
    always @(*) begin
        if (ascii_mode) begin
            // ASCII mode: treat as 8 characters (8 bits each from 64-bit input)
            case (seg7_addr)
                3'd0: seg_data_r = i_data_ascii_store[7:0];    // Character 0
                3'd1: seg_data_r = i_data_ascii_store[15:8];   // Character 1
                3'd2: seg_data_r = i_data_ascii_store[23:16];  // Character 2
                3'd3: seg_data_r = i_data_ascii_store[31:24];  // Character 3
                3'd4: seg_data_r = i_data_ascii_store[39:32];  // Character 4
                3'd5: seg_data_r = i_data_ascii_store[47:40];  // Character 5
                3'd6: seg_data_r = i_data_ascii_store[55:48];  // Character 6
                3'd7: seg_data_r = i_data_ascii_store[63:56];  // Character 7
            endcase
        end else begin
            // Hex mode: treat as 8 hex digits (4 bits each from 32-bit input)
            case (seg7_addr)
                3'd0: seg_data_r = {4'h0, i_data_store[3:0]};    // Digit 0 (bits 3:0)
                3'd1: seg_data_r = {4'h0, i_data_store[7:4]};    // Digit 1 (bits 7:4)
                3'd2: seg_data_r = {4'h0, i_data_store[11:8]};   // Digit 2 (bits 11:8)
                3'd3: seg_data_r = {4'h0, i_data_store[15:12]};  // Digit 3 (bits 15:12)
                3'd4: seg_data_r = {4'h0, i_data_store[19:16]};  // Digit 4 (bits 19:16)
                3'd5: seg_data_r = {4'h0, i_data_store[23:20]};  // Digit 5 (bits 23:20)
                3'd6: seg_data_r = {4'h0, i_data_store[27:24]};  // Digit 6 (bits 27:24)
                3'd7: seg_data_r = {4'h0, i_data_store[31:28]};  // Digit 7 (bits 31:28)
            endcase
        end
    end
    
    reg [7:0] o_seg_r;
    
    // 7-segment encoding function for ASCII characters
    function [7:0] ascii_to_7seg;
        input [7:0] ascii_char;
        begin
            case (ascii_char)
                8'h20: ascii_to_7seg = 8'hFF;  // Space (all segments off)
                8'h30: ascii_to_7seg = 8'hC0;  // '0'
                8'h31: ascii_to_7seg = 8'hF9;  // '1'
                8'h32: ascii_to_7seg = 8'hA4;  // '2'
                8'h33: ascii_to_7seg = 8'hB0;  // '3'
                8'h34: ascii_to_7seg = 8'h99;  // '4'
                8'h35: ascii_to_7seg = 8'h92;  // '5'
                8'h36: ascii_to_7seg = 8'h82;  // '6'
                8'h37: ascii_to_7seg = 8'hF8;  // '7'
                8'h38: ascii_to_7seg = 8'h80;  // '8'
                8'h39: ascii_to_7seg = 8'h90;  // '9'
                8'h41, 8'h61: ascii_to_7seg = 8'h88;  // 'A' or 'a'
                8'h42, 8'h62: ascii_to_7seg = 8'h83;  // 'B' or 'b'
                8'h43, 8'h63: ascii_to_7seg = 8'hC6;  // 'C' or 'c'
                8'h44, 8'h64: ascii_to_7seg = 8'hA1;  // 'D' or 'd'
                8'h45, 8'h65: ascii_to_7seg = 8'h86;  // 'E' or 'e'
                8'h46, 8'h66: ascii_to_7seg = 8'h8E;  // 'F' or 'f'
                8'h47, 8'h67: ascii_to_7seg = 8'hC2;  // 'G' or 'g'
                8'h48, 8'h68: ascii_to_7seg = 8'h89;  // 'H' or 'h'
                8'h49, 8'h69: ascii_to_7seg = 8'hF9;  // 'I' or 'i' (same as 1)
                8'h4A, 8'h6A: ascii_to_7seg = 8'hF1;  // 'J' or 'j'
                8'h4C, 8'h6C: ascii_to_7seg = 8'hC7;  // 'L' or 'l'
                8'h4E, 8'h6E: ascii_to_7seg = 8'hAB;  // 'N' or 'n'
                8'h4F, 8'h6F: ascii_to_7seg = 8'hC0;  // 'O' or 'o' (same as 0)
                8'h50, 8'h70: ascii_to_7seg = 8'h8C;  // 'P' or 'p'
                8'h52, 8'h72: ascii_to_7seg = 8'hAF;  // 'R' or 'r'
                8'h53, 8'h73: ascii_to_7seg = 8'h92;  // 'S' or 's' (same as 5)
                8'h54, 8'h74: ascii_to_7seg = 8'h87;  // 'T' or 't'
                8'h55, 8'h75: ascii_to_7seg = 8'hC1;  // 'U' or 'u'
                8'h59, 8'h79: ascii_to_7seg = 8'h91;  // 'Y' or 'y'
                8'h2D: ascii_to_7seg = 8'hBF;  // '-' (minus sign)
                8'h5F: ascii_to_7seg = 8'hF7;  // '_' (underscore)
                default: ascii_to_7seg = 8'hFF;  // Unknown character (all segments off)
            endcase
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            o_seg_r <= 8'hFF;  // All segments off
        end else begin
            if (ascii_mode) begin
                // ASCII mode: use ASCII to 7-segment conversion
                o_seg_r <= ascii_to_7seg(seg_data_r);
            end else begin
                // Hex mode: use original hex to 7-segment conversion
                case (seg_data_r[3:0])
                    4'h0: o_seg_r <= 8'hC0;  // Display "0"
                    4'h1: o_seg_r <= 8'hF9;  // Display "1"
                    4'h2: o_seg_r <= 8'hA4;  // Display "2"
                    4'h3: o_seg_r <= 8'hB0;  // Display "3"
                    4'h4: o_seg_r <= 8'h99;  // Display "4"
                    4'h5: o_seg_r <= 8'h92;  // Display "5"
                    4'h6: o_seg_r <= 8'h82;  // Display "6"
                    4'h7: o_seg_r <= 8'hF8;  // Display "7"
                    4'h8: o_seg_r <= 8'h80;  // Display "8"
                    4'h9: o_seg_r <= 8'h90;  // Display "9"
                    4'hA: o_seg_r <= 8'h88;  // Display "A"
                    4'hB: o_seg_r <= 8'h83;  // Display "B"
                    4'hC: o_seg_r <= 8'hC6;  // Display "C"
                    4'hD: o_seg_r <= 8'hA1;  // Display "D"
                    4'hE: o_seg_r <= 8'h86;  // Display "E"
                    4'hF: o_seg_r <= 8'h8E;  // Display "F"
                endcase
            end
        end
    end
    
    assign o_sel = o_sel_r;
    assign o_seg = o_seg_r;

endmodule
