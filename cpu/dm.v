
// data memory
module dm(clk, DMWr, addr, din, dout, DMType);
   input          clk;
   input          DMWr;
   input  [31:0]  addr;  // Full address input
   input  [31:0]  din;
   input  [2:0]   DMType;  // Data memory type control
   output [31:0]  dout;
     
   reg [31:0] dmem[127:0];
   
   // Word address and byte offset
   wire [6:0] word_addr = addr[8:2];
   wire [1:0] byte_offset = addr[1:0];
   
   // Store operation
   always @(posedge clk) begin
      if (DMWr) begin
         case (DMType)
            3'b000: begin // dm_word - store word
               dmem[word_addr] <= din;
               $display("SW: dmem[0x%8X] = 0x%8X", addr << 2, din); 
            end
            3'b001: begin // dm_halfword - store halfword
               case (byte_offset[1])
                  1'b0: dmem[word_addr][15:0]  <= din[15:0];   // Lower halfword
                  1'b1: dmem[word_addr][31:16] <= din[15:0];   // Upper halfword
               endcase
               $display("SH: dmem[0x%8X] halfword = 0x%4X", addr << 2, din[15:0]); 
            end
            3'b011: begin // dm_byte - store byte
               case (byte_offset)
                  2'b00: dmem[word_addr][7:0]   <= din[7:0];   // Byte 0
                  2'b01: dmem[word_addr][15:8]  <= din[7:0];   // Byte 1
                  2'b10: dmem[word_addr][23:16] <= din[7:0];   // Byte 2
                  2'b11: dmem[word_addr][31:24] <= din[7:0];   // Byte 3
               endcase
               $display("SB: dmem[0x%8X] byte = 0x%2X", addr << 2, din[7:0]); 
            end
            default: begin
               dmem[word_addr] <= din; // Default to word operation
            end
         endcase
      end
   end
   
   // Load operation
   reg [31:0] load_data;
   always @(*) begin
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
   end
   
   assign dout = load_data;
    
endmodule    
