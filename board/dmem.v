`timescale 1ns / 1ps

// Data Memory Module
// Byte-addressable data memory with configurable access patterns for FPGA
module dmem(
    input  wire        clk,    // Clock signal
    input  wire        we,     // Write enable
    input  wire [31:0] addr,   // Full address (for byte offset calculation and word address)
    input  wire [31:0] wd,     // Write data
    input  wire [2:0]  DMType, // Data memory access type
    output wire [31:0] rd      // Read data
);

    // RAM IP core signals
    wire [3:0] byte_we;  // Byte-wise write enable for RAM IP
    wire [31:0] raw_rd;  // Raw read data from RAM IP
    
    // Extract word address and byte offset 
    wire [9:0] word_addr = addr[11:2];  // 12-bit word address for 4096 words
    wire [1:0] byte_offset = addr[1:0];  // Byte offset within word
    
    // Generate write enable signals based on DMType and byte offset
    reg [3:0] write_enable;
    
    always @(*) begin
        if (we) begin
            case (DMType)
                3'b000: begin // Store word (SW)
                    write_enable = 4'b1111;  // Write all 4 bytes
                end
                
                3'b001, 3'b010: begin // Store halfword (SH/SHU) 
                    case (byte_offset[1])
                        1'b0: write_enable = 4'b0011;  // Lower halfword
                        1'b1: write_enable = 4'b1100;  // Upper halfword
                    endcase
                end
                
                3'b011, 3'b100: begin // Store byte (SB/SBU)
                    case (byte_offset)
                        2'b00: write_enable = 4'b0001;  // Byte 0
                        2'b01: write_enable = 4'b0010;  // Byte 1
                        2'b10: write_enable = 4'b0100;  // Byte 2
                        2'b11: write_enable = 4'b1000;  // Byte 3
                    endcase
                end
                
                default: write_enable = 4'b1111;  // Default to word
            endcase
        end else begin
            write_enable = 4'b0000;  // No write
        end
    end
    
    assign byte_we = write_enable;
    
    // Block Memory Generator IP for Data Memory
    // IP core should be configured with:
    // - Memory Type: Single Port RAM  
    // - Write Width: 32, Read Width: 32
    // - Write Depth: 1024, Read Depth: 1024
    // - Write Mode: Read First (for combinational-like read behavior)
    // - Enable A: Always Enabled
    // - Byte Write Enable: Enabled (4 bytes)
    blk_mem_gen_dmem dmem_ram (
        .clka  (clk),     // Clock
        .wea   (byte_we), // Byte-wise write enable [3:0]
        .addra (word_addr), // Address [9:0] 
        .dina  (wd),      // Write data [31:0]
        .douta (raw_rd)   // Raw read data [31:0]
    );
    
    // Load data formatting for different memory operations
    // This handles LB, LBU, LH, LHU, LW operations with proper sign/zero extension
    reg [31:0] formatted_rd;
    
    always @(*) begin
        case (DMType)
            3'b000: begin // Load word (LW)
                formatted_rd = raw_rd;
            end
            
            3'b001: begin // Load halfword signed (LH)
                case (byte_offset[1])
                    1'b0: formatted_rd = {{16{raw_rd[15]}}, raw_rd[15:0]};   // Lower halfword
                    1'b1: formatted_rd = {{16{raw_rd[31]}}, raw_rd[31:16]};  // Upper halfword
                endcase
            end
            
            3'b010: begin // Load halfword unsigned (LHU)
                case (byte_offset[1])
                    1'b0: formatted_rd = {16'b0, raw_rd[15:0]};   // Lower halfword
                    1'b1: formatted_rd = {16'b0, raw_rd[31:16]};  // Upper halfword
                endcase
            end
            
            3'b011: begin // Load byte signed (LB)
                case (byte_offset)
                    2'b00: formatted_rd = {{24{raw_rd[7]}},  raw_rd[7:0]};    // Byte 0
                    2'b01: formatted_rd = {{24{raw_rd[15]}}, raw_rd[15:8]};   // Byte 1
                    2'b10: formatted_rd = {{24{raw_rd[23]}}, raw_rd[23:16]};  // Byte 2
                    2'b11: formatted_rd = {{24{raw_rd[31]}}, raw_rd[31:24]};  // Byte 3
                endcase
            end
            
            3'b100: begin // Load byte unsigned (LBU)
                case (byte_offset)
                    2'b00: formatted_rd = {24'b0, raw_rd[7:0]};    // Byte 0
                    2'b01: formatted_rd = {24'b0, raw_rd[15:8]};   // Byte 1
                    2'b10: formatted_rd = {24'b0, raw_rd[23:16]};  // Byte 2
                    2'b11: formatted_rd = {24'b0, raw_rd[31:24]};  // Byte 3
                endcase
            end
            
            default: begin // Default to word access
                formatted_rd = raw_rd;
            end
        endcase
    end
    
    // Output formatted read data
    assign rd = formatted_rd;
    
endmodule