`timescale 1ns / 1ps

// RISC-V CPU FPGA Top Level Module
// Integrates 5-stage pipelined RISC-V CPU with memory and I/O peripherals
module xgriscv_fpga_top(
    input  wire        clk,         // System clock (100MHz)
    input  wire        rstn,        // Reset (active low)
    input  wire [15:0] sw_i,        // Switch inputs
    output wire [7:0]  disp_seg_o,  // 7-segment display segments
    output wire [7:0]  disp_an_o    // 7-segment display anodes
);

    wire rst;
    assign rst = ~rstn;  // Convert active-low reset to active-high
    
    wire Clk_CPU;  // CPU clock (derived from system clock)
    
    wire [31:0] instr;          // Instruction from instruction memory
    wire [31:0] PC;             // Program counter
    wire        mem_w;       // Memory write enable from CPU
    wire [2:0]  DMType;         // Data memory access type from CPU
    wire [31:0] cpu_data_out;   // Data from CPU to memory
    wire [31:0] cpu_data_addr;  // Address from CPU
    wire [31:0] cpu_data_in;    // Data to CPU from memory system
    
    wire [31:0] dm_din, dm_dout;  // Data memory input/output
    wire [6:0]  ram_addr;         // Data memory address (word-aligned)
    wire [3:0]  ram_amp;          // Access pattern for data memory
    wire        ram_we;           // Write enable for data memory
    
    wire [31:0] seg7_data;        // Data for 7-segment display
    wire [31:0] cpuseg7_data;     // CPU data for display (memory-mapped)
    wire        seg7_we;          // Write enable for display
    wire [31:0] reg_data;         // Selected register data for debug
    wire [4:0]  reg_sel;          // Register selection for debug
    
    reg [3:0]   cpu_data_amp;
    
    always @(*) begin
        case (DMType)
            3'b000:  cpu_data_amp = 4'b1111;  // Word (32-bit)
            3'b001:  cpu_data_amp = 4'b0011;  // Halfword signed (16-bit)
            3'b010:  cpu_data_amp = 4'b0011;  // Halfword unsigned (16-bit)
            3'b011:  cpu_data_amp = 4'b0001;  // Byte signed (8-bit)
            3'b100:  cpu_data_amp = 4'b0001;  // Byte unsigned (8-bit)
            default: cpu_data_amp = 4'b1111;  // Default to word access
        endcase
    end
    
    // Register Selection for Debug Display
    // Use SW[4:0] to select which register to display
    assign reg_sel = sw_i[4:0];
    
    // Instruction Memory (ROM IP Core)
    imem U_IM(
        .a   (PC[8:2]),  // Word-aligned address (PC >> 2)
        .spo (instr)     // Instruction output
    );
    
    // Data Memory
    dmem U_dmem(
        .clk (Clk_CPU),   // CPU clock
        .we  (ram_we),    // Write enable from MIO_BUS
        .amp (ram_amp),   // Access pattern from MIO_BUS
        .a   (ram_addr),  // Address from MIO_BUS
        .wd  (dm_din),    // Write data from MIO_BUS
        .rd  (dm_dout)    // Read data to MIO_BUS
    );
    
    // Memory-Mapped I/O Bus Controller
    MIO_BUS U_MIO(
        .mem_w         (mem_w),         // Memory write enable from CPU
        .sw_i          (sw_i),          // Switch inputs
        .cpu_data_out  (cpu_data_out),  // Data from CPU
        .cpu_data_addr (cpu_data_addr), // Address from CPU
        .cpu_data_amp  (cpu_data_amp),  // Access pattern from CPU
        .ram_data_out  (dm_dout),       // Data from data memory
        .cpu_data_in   (cpu_data_in),   // Data to CPU
        .ram_data_in   (dm_din),        // Data to data memory
        .ram_addr      (ram_addr),      // Address to data memory
        .cpuseg7_data  (cpuseg7_data),  // Data to display controller
        .ram_we        (ram_we),        // Write enable to data memory
        .ram_amp       (ram_amp),       // Access pattern to data memory
        .seg7_we       (seg7_we)        // Write enable to display
    );
    
    // Multi-Channel Display Data Selector
    MULTI_CH32 U_Multi(
        .clk      (clk),                    // System clock
        .rst      (rst),                    // Reset
        .EN       (seg7_we),                // Write enable from MIO_BUS
        .ctrl     (sw_i[5:0]),              // Control switches SW[5:0]
        .Data0    (cpuseg7_data),           // Channel 0: CPU data (programmable)
        .data1    ({2'b00, PC[31:2]}),      // Channel 1: PC (word-aligned)
        .data2    (PC),                     // Channel 2: Full PC
        .data3    (instr),                  // Channel 3: Current instruction
        .data4    (cpu_data_addr),          // Channel 4: Data memory address
        .data5    (cpu_data_out),           // Channel 5: Data to memory
        .data6    (dm_dout),                // Channel 6: Data from memory
        .data7    ({ram_addr, 2'b00}),      // Channel 7: RAM address (extended)
        .reg_data (reg_data),               // Register data for display
        .seg7_data(seg7_data)               // Output to 7-segment display
    );
    
    // 5-Stage Pipelined RISC-V CPU
    cpu U_CPU(
        .clk        (Clk_CPU),       // CPU clock
        .reset      (rst),          // Reset (active low)
        .inst_in    (instr),         // Instruction input
        .Data_in    (cpu_data_in),   // Data input from memory system
        .mem_w      (mem_w),         // Memory write enable output
        .DMType_out (DMType),        // Data memory access type output
        .PC         (PC),            // Program counter output
        .Addr_out   (cpu_data_addr), // Address output
        .Data_out   (cpu_data_out),  // Data output
        .reg_sel    (reg_sel),       // Register select for debug
        .reg_data   (reg_data)       // Register data for debug
    );
    
    // 7-Segment Display Controller
    SEG7x16 U_7SEG(
        .clk    (clk),         // System clock
        .rst    (rst),         // Reset
        .cs     (1'b1),        // Always enabled
        .i_data (seg7_data),   // Data to display
        .o_seg  (disp_seg_o),  // Segment outputs
        .o_sel  (disp_an_o)    // Digit select outputs
    );
    
    // Clock Divider
    CLK_DIV U_CLKDIV(
        .clk     (clk),      // System clock input
        .rst     (rst),      // Reset
        .SW15    (sw_i[15]), // Clock speed selection switch
        .Clk_CPU (Clk_CPU)   // CPU clock output
    );

endmodule
