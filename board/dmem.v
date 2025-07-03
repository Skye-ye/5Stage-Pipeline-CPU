`timescale 1ns / 1ps

// Data Memory Module
// Byte-addressable data memory with configurable access patterns for FPGA
module dmem(
    input  wire        clk,    // Clock signal
    input  wire        we,     // Write enable
    input  wire [3:0]  amp,    // Access pattern mask
    input  wire [6:0]  a,      // Address (7-bit for 128 words)
    input  wire [31:0] wd,     // Write data
    output wire [31:0] rd      // Read data
);

    reg [31:0] dmem_array [0:127];
    
    integer i;
    initial begin
        for (i = 0; i < 128; i = i + 1) begin
            dmem_array[i] = 32'h00000000;
        end
    end
    
    // Write Operation (Synchronous)
    // Access patterns:
    //   amp[3:0] = 4'b1111 : Word access (32-bit)
    //   amp[3:0] = 4'b0011 : Halfword access (16-bit)  
    //   amp[3:0] = 4'b0001 : Byte access (8-bit)
    always @(posedge clk) begin
        if (we) begin
            case (amp)
                4'b1111: begin // Word access - write all 4 bytes
                    dmem_array[a] <= wd;
                    $display("DMEM WRITE WORD: addr=0x%02X, data=0x%08X", a, wd);
                end
                
                4'b0011: begin // Halfword access - write lower 2 bytes
                    dmem_array[a][15:0] <= wd[15:0];
                    $display("DMEM WRITE HALFWORD: addr=0x%02X, data=0x%04X", a, wd[15:0]);
                end
                
                4'b0001: begin // Byte access - write lowest byte
                    dmem_array[a][7:0] <= wd[7:0];
                    $display("DMEM WRITE BYTE: addr=0x%02X, data=0x%02X", a, wd[7:0]);
                end
                
                default: begin // Default to word access
                    dmem_array[a] <= wd;
                    $display("DMEM WRITE DEFAULT: addr=0x%02X, data=0x%08X", a, wd);
                end
            endcase
        end
    end
    
    // Read Operation (Combinational)
    assign rd = dmem_array[a];
    
endmodule