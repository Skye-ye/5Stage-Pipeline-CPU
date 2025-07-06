
// data memory
module dm(
   input          clk,
   input          DMWr,
   input          DMRd,
   input  [31:0]  addr,
   input  [31:0]  din,
   input  [2:0]   DMType,
   output [31:0]  dout
);
     
   reg [31:0] dmem[255:0];
   
   // Initialize data memory to zero
   initial begin
      for (integer i = 0; i < 256; i = i + 1) begin
         dmem[i] = 32'h0;
      end
   end
   
   // Word address and byte offset
   wire [7:0] word_addr = addr[9:2];
   wire [1:0] byte_offset = addr[1:0];
   
   // Store operation
   always @(posedge clk) begin
      if (DMWr) begin
         case (DMType)
            3'b000: begin // dm_word - store word
               dmem[word_addr] <= din;
               $display("SW             dmem[0x%8X] = 0x%8X", addr, din); 
            end
            3'b001: begin // dm_halfword - store halfword
               case (byte_offset[1])
                  1'b0: dmem[word_addr][15:0]  <= din[15:0];   // Lower halfword
                  1'b1: dmem[word_addr][31:16] <= din[15:0];   // Upper halfword
               endcase
               $display("SH             dmem[0x%8X] halfword = 0x%4X", addr, din[15:0]); 
            end
            3'b011: begin // dm_byte - store byte
               case (byte_offset)
                  2'b00: dmem[word_addr][7:0]   <= din[7:0];   // Byte 0
                  2'b01: dmem[word_addr][15:8]  <= din[7:0];   // Byte 1
                  2'b10: dmem[word_addr][23:16] <= din[7:0];   // Byte 2
                  2'b11: dmem[word_addr][31:24] <= din[7:0];   // Byte 3
               endcase
               $display("SB             dmem[0x%8X] byte = 0x%2X", addr, din[7:0]); 
            end
            default: begin
               dmem[word_addr] <= din; // Default to word operation
            end
         endcase
      end
   end
   
   // Load operation - combinational logic for data
   reg [31:0] load_data;
   always @(*) begin
      if (DMRd) begin
         case (DMType)
            3'b000: begin // dm_word - load word
               load_data = dmem[word_addr];
            end
            3'b001: begin // dm_halfword - load halfword (sign extended)
               case (byte_offset[1])
                  1'b0: load_data = {{16{dmem[word_addr][15]}}, dmem[word_addr][15:0]};   // Lower halfword
                  1'b1: load_data = {{16{dmem[word_addr][31]}}, dmem[word_addr][31:16]};  // Upper halfword
               endcase
            end
            3'b010: begin // dm_halfword_unsigned - load halfword (zero extended)
               case (byte_offset[1])
                  1'b0: load_data = {16'b0, dmem[word_addr][15:0]};   // Lower halfword
                  1'b1: load_data = {16'b0, dmem[word_addr][31:16]};  // Upper halfword
               endcase
            end
            3'b011: begin // dm_byte - load byte (sign extended)
               case (byte_offset)
                  2'b00: load_data = {{24{dmem[word_addr][7]}},  dmem[word_addr][7:0]};    // Byte 0
                  2'b01: load_data = {{24{dmem[word_addr][15]}}, dmem[word_addr][15:8]};   // Byte 1
                  2'b10: load_data = {{24{dmem[word_addr][23]}}, dmem[word_addr][23:16]};  // Byte 2
                  2'b11: load_data = {{24{dmem[word_addr][31]}}, dmem[word_addr][31:24]};  // Byte 3
               endcase
            end
            3'b100: begin // dm_byte_unsigned - load byte (zero extended)
               case (byte_offset)
                  2'b00: load_data = {24'b0, dmem[word_addr][7:0]};    // Byte 0
                  2'b01: load_data = {24'b0, dmem[word_addr][15:8]};   // Byte 1
                  2'b10: load_data = {24'b0, dmem[word_addr][23:16]};  // Byte 2
                  2'b11: load_data = {24'b0, dmem[word_addr][31:24]};  // Byte 3
               endcase
            end
            default: begin
               load_data = dmem[word_addr]; // Default to word operation
            end
         endcase
      end else begin
         load_data = 32'b0; // Output zero when not reading
      end
   end
   
   // Display for load operations - only on positive clock edge to avoid spurious displays
   always @(posedge clk) begin
      if (DMRd) begin
         case (DMType)
            3'b000: $display("LW             dmem[0x%8X] = 0x%8X", addr, load_data);
            3'b001: $display("LH             dmem[0x%8X] halfword = 0x%4X", addr, load_data[15:0]);
            3'b010: $display("LHU            dmem[0x%8X] halfword = 0x%4X", addr, load_data[15:0]);
            3'b011: $display("LB             dmem[0x%8X] byte = 0x%2X", addr, load_data[7:0]);
            3'b100: $display("LBU            dmem[0x%8X] byte = 0x%2X", addr, load_data[7:0]);
         endcase
      end
   end
   
   assign dout = load_data;
    
endmodule    
