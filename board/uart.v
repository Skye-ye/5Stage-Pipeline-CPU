`timescale 1ns / 1ps

// UART Storage Module
// Provides memory-mapped UART functionality with 8-byte storage for RISC-V CPU
// Memory Map:
//   0xF000: Status register (bit 0 = ready to accept data, 1 = ready)
//   0xF004: Data register (write character to store)
module uart(
    input  wire        clk,           // System clock
    input  wire        rst,           // Reset (active high)
    
    // Memory-mapped interface
    input  wire        uart_we,       // Write enable from MIO_BUS
    input  wire [7:0]  data_in,       // Data from CPU (8-bit)
    output reg         uart_ready,    // UART ready signal for MIO_BUS
    
    // 7-segment display interface
    output reg  [63:0] uart_display_data  // 8 bytes for 7-segment display
);

    // 8-byte storage buffer
    reg [7:0] storage_buffer [0:7];  // 8 bytes of storage
    reg [2:0] write_ptr;             // Write pointer (0-7)
    reg       buffer_full;           // Buffer full indicator
    
    // Status: ready when buffer is not full
    always @(*) begin
        uart_ready = ~buffer_full;
    end
    
    // Data write logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            write_ptr <= 3'h0;
            buffer_full <= 1'b0;
            // Initialize buffer to spaces (0x20)
            storage_buffer[0] <= 8'h20;
            storage_buffer[1] <= 8'h20;
            storage_buffer[2] <= 8'h20;
            storage_buffer[3] <= 8'h20;
            storage_buffer[4] <= 8'h20;
            storage_buffer[5] <= 8'h20;
            storage_buffer[6] <= 8'h20;
            storage_buffer[7] <= 8'h20;
        end else begin
            if (uart_we && uart_ready) begin
                // Store the character in the buffer
                storage_buffer[write_ptr] <= data_in;
                
                // Update write pointer and buffer status
                if (write_ptr == 3'h7) begin
                    // Just wrote to the last position, buffer is now full
                    buffer_full <= 1'b1;
                    // Keep write_ptr at 7, don't wrap around
                end else begin
                    write_ptr <= write_ptr + 1;
                end
            end
        end
    end
    
    // Output buffer contents to 7-segment display
    always @(*) begin
        uart_display_data = {storage_buffer[7], storage_buffer[6], storage_buffer[5], storage_buffer[4],
                            storage_buffer[3], storage_buffer[2], storage_buffer[1], storage_buffer[0]};
    end

endmodule