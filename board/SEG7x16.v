`timescale 1ns / 1ps

// 7-Segment Display Controller (8 digits)
// Displays 32-bit hexadecimal data on 8-digit 7-segment display
module SEG7x16(
    input  wire        clk,      // System clock
    input  wire        rst,      // Reset signal (active high)
    input  wire        cs,       // Chip select (data latch enable)
    input  wire [31:0] i_data,   // 32-bit input data to display
    output wire [7:0]  o_seg,    // 7-segment patterns (active low)
    output wire [7:0]  o_sel     // Digit select signals (active low)
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
    
    reg [31:0] i_data_store;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i_data_store <= 32'b0;
        end else if (cs) begin
            i_data_store <= i_data;
        end
    end
    
    reg [3:0] seg_data_r;
    
    always @(*) begin
        case (seg7_addr)
            3'd0: seg_data_r = i_data_store[3:0];    // Digit 0 (bits 3:0)
            3'd1: seg_data_r = i_data_store[7:4];    // Digit 1 (bits 7:4)
            3'd2: seg_data_r = i_data_store[11:8];   // Digit 2 (bits 11:8)
            3'd3: seg_data_r = i_data_store[15:12];  // Digit 3 (bits 15:12)
            3'd4: seg_data_r = i_data_store[19:16];  // Digit 4 (bits 19:16)
            3'd5: seg_data_r = i_data_store[23:20];  // Digit 5 (bits 23:20)
            3'd6: seg_data_r = i_data_store[27:24];  // Digit 6 (bits 27:24)
            3'd7: seg_data_r = i_data_store[31:28];  // Digit 7 (bits 31:28)
        endcase
    end
    
    reg [7:0] o_seg_r;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            o_seg_r <= 8'hFF;  // All segments off
        end else begin
            case (seg_data_r)
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
    
    assign o_sel = o_sel_r;
    assign o_seg = o_seg_r;

endmodule
