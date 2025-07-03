`timescale 1ns / 1ps

// Clock Divider Module
// Provides selectable CPU clock frequency based on SW15 switch
module CLK_DIV(
    input  wire clk,      // System clock (100MHz)
    input  wire rst,      // Reset signal (active high)
    input  wire SW15,     // Switch for clock selection
    output wire Clk_CPU   // CPU clock output
);

    reg [31:0] clkdiv;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clkdiv <= 32'b0;
        end else begin
            clkdiv <= clkdiv + 1'b1;
        end
    end
    
    assign Clk_CPU = SW15 ? clkdiv[25] : clkdiv[2];

endmodule
