module comp #(
    parameter INSTR_FILE = "./instr/morse/program.dat",
    parameter TIMER_LIMIT = 100,
    parameter EXT_INT_LIMIT = 200
)(
    input          clk,
    input          rstn,
    input [4:0]    reg_sel,
    output [31:0]  reg_data
);
   
   // Unified memory interface wires
   wire           IMRd;
   wire [31:0]    IMAddr;
   wire [31:0]    IMOut;
   wire           DMRd, DMWr;
   wire [31:0]    DMAddr, DMIn, DMOut;
   wire [2:0]     DMType;
   wire           timer_int;
   wire           timer_int_ack;
   wire           external_int;
   wire           ext_int_ack;
   
   wire rst = ~rstn;
       
  // instantiation of pipeline CPU   
   cpu U_CPU(
         .clk(clk),                 // input:  cpu clock
         .reset(rst),               // input:  reset
         
         // Unified Memory Interface
         .IMRd(IMRd),               // output: instruction memory read enable
         .IMAddr(IMAddr),           // output: instruction memory address
         .Inst_in(IMOut),           // input:  instruction from memory
         
         .DMRd(DMRd),               // output: data memory read enable
         .DMWr(DMWr),               // output: data memory write enable
         .DMAddr(DMAddr),           // output: data memory address
         .Data_out(DMIn),           // output: data to memory
         .DMType(DMType),           // output: data memory access type
         .Data_in(DMOut),           // input:  data from memory
         
         .external_int(external_int), // input:  external interrupt from external interrupt generator
         .timer_int(timer_int),     // input:  timer interrupt from timer module
         .timer_int_ack(timer_int_ack), // output: timer interrupt acknowledge
         .ext_int_ack(ext_int_ack), // output: external interrupt acknowledge
         .reg_sel(reg_sel),         // input:  register selection
         .reg_data(reg_data)        // output: register data
         );
         
  // instantiation of unified memory (replaces both im and dm)
   mem #(.PROGRAM_FILE(INSTR_FILE)) U_MEM(
         .clk(clk),                 // input:  cpu clock
         
         // Instruction memory interface
         .im_addr(IMAddr[11:2]),    // input:  instruction address
         .im_dout(IMOut),           // output: instruction
         
         // Data memory interface
         .DMWr(DMWr),               // input:  data memory write
         .DMRd(DMRd),               // input:  data memory read
         .dm_addr(DMAddr),          // input:  data memory address
         .dm_din(DMIn),             // input:  data to memory
         .dm_dout(DMOut),           // output: data from memory
         .DMType(DMType)            // input:  data memory type
         );

   // instantiation of timer
   timer #(.TIMER_LIMIT(TIMER_LIMIT)) U_TIMER(
      .clk(clk),
      .reset(rst),
      .timer_int_ack(timer_int_ack),
      .timer_int(timer_int)
   );

   // instantiation of external interrupt generator
   external_int_gen #(.EXT_INT_LIMIT(EXT_INT_LIMIT)) U_EXT_INT_GEN(
      .clk(clk),
      .reset(rst),
      .ext_int_ack(ext_int_ack),
      .external_int(external_int)
   );
        
endmodule
