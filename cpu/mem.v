// Unified Memory Module (replaces both im.v and dm.v)
// Combines instruction and data memory into a single memory space
module mem #(
    parameter PROGRAM_FILE = "program.hex"
)(
    // Clock for data memory operations
    input          clk,
    
    // Instruction memory interface (matches im.v)
    input  [9:0]  im_addr,
    output [31:0]  im_dout,
    
    // Data memory interface (matches dm.v)  
    input          DMWr,
    input          DMRd,
    input  [31:0]  dm_addr,
    input  [31:0]  dm_din,
    input  [2:0]   DMType,
    output [31:0]  dm_dout
);

    // Unified memory array - 4KB (1024 words)
    reg [31:0] memory [1023:0];
    
    // Initialize memory from program file
    initial begin
        // Initialize all memory to zero first
        for (integer i = 0; i < 1024; i = i + 1) begin
            memory[i] = 32'h0;
        end
        
        // Load program image
        $readmemh(PROGRAM_FILE, memory);
        $display("Loaded unified program image: %s", PROGRAM_FILE);
    end
    
    // ========== Instruction Memory Interface ==========
    // Combinational read (same as original im.v)
    assign im_dout = memory[im_addr]; // word aligned
    
    // ========== Data Memory Interface ==========
    // Word address and byte offset for data memory
    wire [9:0] dm_word_addr = dm_addr[11:2];  // Word address
    wire [1:0] dm_byte_offset = dm_addr[1:0]; // Byte offset within word
    
    // Data memory write operations (synchronous, same as original dm.v)
    always @(posedge clk) begin
        if (DMWr) begin
            case (DMType)
                3'b000: begin // dm_word - store word
                    memory[dm_word_addr] <= dm_din;
                    $display("SW             mem[0x%8X] = 0x%8X", dm_addr, dm_din);
                end
                3'b001: begin // dm_halfword - store halfword
                    case (dm_byte_offset[1])
                        1'b0: memory[dm_word_addr][15:0]  <= dm_din[15:0];   // Lower halfword
                        1'b1: memory[dm_word_addr][31:16] <= dm_din[15:0];   // Upper halfword
                    endcase
                    $display("SH             mem[0x%8X] halfword = 0x%4X", dm_addr, dm_din[15:0]);
                end
                3'b011: begin // dm_byte - store byte
                    case (dm_byte_offset)
                        2'b00: memory[dm_word_addr][7:0]   <= dm_din[7:0];   // Byte 0
                        2'b01: memory[dm_word_addr][15:8]  <= dm_din[7:0];   // Byte 1
                        2'b10: memory[dm_word_addr][23:16] <= dm_din[7:0];   // Byte 2
                        2'b11: memory[dm_word_addr][31:24] <= dm_din[7:0];   // Byte 3
                    endcase
                    $display("SB             mem[0x%8X] byte = 0x%2X", dm_addr, dm_din[7:0]);
                end
                default: begin
                    memory[dm_word_addr] <= dm_din; // Default to word operation
                end
            endcase
        end
    end
    
    // Data memory read operations (combinational, same as original dm.v)
    reg [31:0] dm_load_data;
    always @(*) begin
        if (DMRd) begin
            case (DMType)
                3'b000: begin // dm_word - load word
                    dm_load_data = memory[dm_word_addr];
                end
                3'b001: begin // dm_halfword - load halfword (sign extended)
                    case (dm_byte_offset[1])
                        1'b0: dm_load_data = {{16{memory[dm_word_addr][15]}}, memory[dm_word_addr][15:0]};   // Lower halfword
                        1'b1: dm_load_data = {{16{memory[dm_word_addr][31]}}, memory[dm_word_addr][31:16]};  // Upper halfword
                    endcase
                end
                3'b010: begin // dm_halfword_unsigned - load halfword (zero extended)
                    case (dm_byte_offset[1])
                        1'b0: dm_load_data = {16'b0, memory[dm_word_addr][15:0]};   // Lower halfword
                        1'b1: dm_load_data = {16'b0, memory[dm_word_addr][31:16]};  // Upper halfword
                    endcase
                end
                3'b011: begin // dm_byte - load byte (sign extended)
                    case (dm_byte_offset)
                        2'b00: dm_load_data = {{24{memory[dm_word_addr][7]}},  memory[dm_word_addr][7:0]};    // Byte 0
                        2'b01: dm_load_data = {{24{memory[dm_word_addr][15]}}, memory[dm_word_addr][15:8]};   // Byte 1
                        2'b10: dm_load_data = {{24{memory[dm_word_addr][23]}}, memory[dm_word_addr][23:16]};  // Byte 2
                        2'b11: dm_load_data = {{24{memory[dm_word_addr][31]}}, memory[dm_word_addr][31:24]};  // Byte 3
                    endcase
                end
                3'b100: begin // dm_byte_unsigned - load byte (zero extended)
                    case (dm_byte_offset)
                        2'b00: dm_load_data = {24'b0, memory[dm_word_addr][7:0]};    // Byte 0
                        2'b01: dm_load_data = {24'b0, memory[dm_word_addr][15:8]};   // Byte 1
                        2'b10: dm_load_data = {24'b0, memory[dm_word_addr][23:16]};  // Byte 2
                        2'b11: dm_load_data = {24'b0, memory[dm_word_addr][31:24]};  // Byte 3
                    endcase
                end
                default: begin
                    dm_load_data = memory[dm_word_addr]; // Default to word operation
                end
            endcase
        end else begin
            dm_load_data = 32'b0; // Output zero when not reading
        end
    end
    
    // Data memory output
    assign dm_dout = dm_load_data;
    
    // Debug output for data memory reads (same as original dm.v)
    always @(posedge clk) begin
        if (DMRd) begin
            case (DMType)
                3'b000: $display("LW             mem[0x%8X] = 0x%8X", dm_addr, dm_load_data);
                3'b001: $display("LH             mem[0x%8X] halfword = 0x%4X", dm_addr, dm_load_data[15:0]);
                3'b010: $display("LHU            mem[0x%8X] halfword = 0x%4X", dm_addr, dm_load_data[15:0]);
                3'b011: $display("LB             mem[0x%8X] byte = 0x%2X", dm_addr, dm_load_data[7:0]);
                3'b100: $display("LBU            mem[0x%8X] byte = 0x%2X", dm_addr, dm_load_data[7:0]);
            endcase
        end
    end
    
endmodule