`timescale 1ns / 1ps

// UART Storage Module
// Provides memory-mapped UART functionality with 8-byte storage for RISC-V CPU
// Memory Map:
//   0xF004: Data register (write character to store)
//   0xF00C: Clear register (write any value to clear buffer)
module uart(
    input  wire        clk,           // System clock
    input  wire        rst,           // Reset (active high)
    
    // Memory-mapped interface
    input  wire        uart_we,       // Write enable from MIO_BUS
    input  wire        uart_clear,    // Clear enable from MIO_BUS
    input  wire [7:0]  data_in,       // Data from CPU (8-bit)
    // 7-segment display interface
    output reg  [63:0] uart_display_data  // 8 bytes for 7-segment display
);

    // 8-byte storage buffer
    reg [7:0] storage_buffer [0:7];  // 8 bytes of storage
    reg [2:0] write_ptr;             // Write pointer (0-7)
    reg [2:0] read_ptr;              // Read pointer (0-7)
    reg       buffer_full;           // Buffer full indicator
    reg [3:0] count;                 // Number of valid bytes in buffer (0-8)
    
    // Data write logic with circular buffer and clear functionality
    always @(posedge clk or posedge rst) begin
        if (rst | (uart_we && uart_clear)) begin
            write_ptr <= 3'h0;
            read_ptr <= 3'h0;
            buffer_full <= 1'b0;
            count <= 4'h0;
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
            if (uart_we) begin
                // Store the character in the buffer
                storage_buffer[write_ptr] <= data_in;
                
                // Always advance write pointer (circular)
                write_ptr <= write_ptr + 1;
                
                if (buffer_full) begin
                    // Buffer is full, pop the oldest data by advancing read pointer
                    read_ptr <= read_ptr + 1;
                    // Count stays at 8 when buffer is full
                end else begin
                    // Buffer not full, increment count
                    count <= count + 1;
                    if (count == 4'h7) begin
                        // After this write, buffer will be full
                        buffer_full <= 1'b1;
                    end
                end
            end
        end
    end
    
    // Output buffer contents to 7-segment display
    // Display the data in chronological order (oldest to newest)
    always @(*) begin
        if (buffer_full) begin
            // When buffer is full, display from read_ptr (oldest) to write_ptr-1 (newest)
            uart_display_data = {storage_buffer[read_ptr], 
                                storage_buffer[read_ptr + 1], 
                                storage_buffer[read_ptr + 2], 
                                storage_buffer[read_ptr + 3],
                                storage_buffer[read_ptr + 4], 
                                storage_buffer[read_ptr + 5], 
                                storage_buffer[read_ptr + 6], 
                                storage_buffer[read_ptr + 7]};
        end else begin
            // When buffer is not full, display from position 0
            uart_display_data = {storage_buffer[0], storage_buffer[1], storage_buffer[2], storage_buffer[3],
                                storage_buffer[4], storage_buffer[5], storage_buffer[6], storage_buffer[7]};
        end
    end

endmodule