module comp #(
    parameter INSTR_FILE = "./instr/non_data_sim5.dat"
)(
    input          clk,
    input          rstn,
    input [4:0]    reg_sel,
    output [31:0]  reg_data
);
   
   wire [31:0]    instr;
   wire [31:0]    PC;
   wire           MemWrite;
   wire [2:0]     DMType;
   wire [31:0]    dm_addr, dm_din, dm_dout;
   
   wire rst = ~rstn;
       
  // instantiation of pipeline CPU   
   cpu U_CPU(
         .clk(clk),                 // input:  cpu clock
         .reset(rst),               // input:  reset
         .inst_in(instr),           // input:  instruction
         .Data_in(dm_dout),         // input:  data to cpu  
         .mem_w(MemWrite),          // output: memory write signal
         .DMType_out(DMType),       // output: data memory type
         .PC(PC),                   // output: PC
         .Addr_out(dm_addr),        // output: address from cpu to memory
         .Data_out(dm_din),         // output: data from cpu to memory
         .reg_sel(reg_sel),         // input:  register selection
         .reg_data(reg_data)        // output: register data
         );
         
  // instantiation of data memory  
   dm    U_DM(
         .clk(clk),           // input:  cpu clock
         .DMWr(MemWrite),     // input:  ram write
         .addr(dm_addr),      // input:  full ram address
         .din(dm_din),        // input:  data to ram
         .dout(dm_dout),      // output: data from ram
         .DMType(DMType)      // input:  data memory type
         );
         
  // instantiation of instruction memory (used for simulation)
   im #(.INSTR_FILE(INSTR_FILE)) U_IM ( 
      .addr(PC[8:2]),     // input:  rom address
      .dout(instr)        // output: instruction
   );
        
endmodule
