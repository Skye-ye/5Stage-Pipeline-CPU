`timescale 1ns / 1ps

// Memory-Mapped I/O Bus Controller
// Routes CPU memory accesses to appropriate peripherals based on address
module MIO_BUS(
    input  wire        mem_w,          // Memory write enable from CPU
    input  wire [15:0] sw_i,           // Switch input (16-bit)
    input  wire [31:0] cpu_data_out,   // Data from CPU
    input  wire [31:0] cpu_data_addr,  // Address from CPU
    input  wire [3:0]  cpu_data_amp,   // Access pattern from CPU
    input  wire [31:0] ram_data_out,   // Data from data memory
    
    output reg  [31:0] cpu_data_in,    // Data to CPU
    output reg  [31:0] ram_data_in,    // Data to data memory
    output reg  [6:0]  ram_addr,       // Address for data memory
    output reg  [31:0] cpuseg7_data,   // Data for 7-segment display
    output reg         ram_we,         // Write enable for data memory
    output reg  [3:0]  ram_amp,        // Access pattern for data memory
    output reg         seg7_we         // Write enable for 7-segment display
);

    // Memory Map:
    // 0xFFFF0004 : Switch input (read-only)
    // 0xFFFF000C : 7-segment display (write-only) 
    // Other      : Data memory (read/write)
    always @(*) begin
        // Default values
        ram_addr     = 7'h0;
        ram_data_in = 32'h0;
        cpuseg7_data = 32'h0;
        cpu_data_in = 32'h0;
        seg7_we      = 1'b0;
        ram_we       = 1'b0;
        ram_amp      = 4'b0;
        
        case (cpu_data_addr[31:0])
            // Switch Input (Read-Only)
            32'hFFFF0004: begin
                cpu_data_in = {16'h0000, sw_i};
            end

            // 7-Segment Display (Write-Only)
            32'hFFFF000C: begin
                cpuseg7_data = cpu_data_out;
                seg7_we      = mem_w;
            end
            
            // Data Memory (Read/Write)
            default: begin
                ram_addr     = cpu_data_addr[8:2];  // Word-aligned address
                ram_data_in  = cpu_data_out;
                ram_we       = mem_w;
                ram_amp      = cpu_data_amp;
                cpu_data_in  = ram_data_out;
            end
        endcase
    end

endmodule
