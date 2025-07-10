`timescale 1ns / 1ps

// Memory-Mapped I/O Bus Controller
// Routes CPU memory accesses to appropriate peripherals based on address
module MIO_BUS(
    input  wire        mem_w,          // Memory write enable from CPU
    input  wire [15:0] sw_i,           // Switch input (16-bit)
    input  wire [31:0] cpu_data_out,   // Data from CPU
    input  wire [31:0] cpu_data_addr,  // Address from CPU
    input  wire [31:0] ram_data_out,   // Data from data memory
    input  wire [2:0]  cpu_DMType,     // Data memory access type from CPU
    
    output reg  [31:0] cpu_data_in,    // Data to CPU
    output reg  [31:0] ram_data_in,    // Data to data memory
    output reg  [31:0] ram_addr,       // Address for data memory
    output reg  [2:0]  DMType,         // Data memory access type
    output reg  [31:0] cpuseg7_data,   // Data for 7-segment display
    output reg         ram_we,         // Write enable for data memory
    output reg         seg7_we,        // Write enable for 7-segment display
    output reg         uart_we,        // Write enable for UART
    output reg         uart_clear,     // Clear enable for UART
    output reg  [7:0]  uart_data_in    // Data to UART
);

    // Memory Map:
    // 0x0000F004 : UART data register (write-only)
    // 0x0000F00C : UART clear register (write-only)
    // 0xFFFF0004 : Switch input (read-only)
    // 0xFFFF000C : 7-segment display (write-only) 
    // Other      : Data memory (read/write)
    always @(*) begin
        // Default values
        ram_addr     = 32'h0;
        ram_data_in = 32'h0;
        cpuseg7_data = 32'h0;
        cpu_data_in = 32'h0;
        seg7_we      = 1'b0;
        ram_we       = 1'b0;
        uart_we      = 1'b0;
        uart_clear   = 1'b0;
        uart_data_in = 8'h0;
        DMType       = 3'b0;

        case (cpu_data_addr[31:0])
            // UART Data Register (Write-Only)
            32'h0000F004: begin
                uart_we = mem_w;
                uart_data_in = cpu_data_out[7:0];
            end

            // UART Clear Register (Write-Only)
            32'h0000F00C: begin
                uart_we = mem_w;
                uart_clear = cpu_data_out[0];
            end

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
                ram_addr     = cpu_data_addr;  // Word-aligned address
                ram_data_in  = cpu_data_out;
                ram_we       = mem_w;
                DMType       = cpu_DMType;
                cpu_data_in  = ram_data_out;
            end
        endcase
    end

endmodule
