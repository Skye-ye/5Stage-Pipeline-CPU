`timescale 1ns / 1ps

// RISC-V CPU FPGA Top Level Module
// Integrates 5-stage pipelined RISC-V CPU with memory and I/O peripherals
module xgriscv_fpga_top(
    input  wire        clk,         // System clock (100MHz)
    input  wire        rstn,        // Reset (active low)
    input  wire [15:0] sw_i,        // Switch inputs
    input  wire        btnc_i,      // Center button input
    output wire [7:0]  disp_seg_o,  // 7-segment display segments
    output wire [7:0]  disp_an_o    // 7-segment display anodes
);

    wire rst;
    assign rst = ~rstn;  // Convert active-low reset to active-high
    
    wire Clk_CPU;  // CPU clock (derived from system clock)
    
    wire [31:0] instr;          // Instruction from instruction memory
    wire [31:0] PC;             // Program counter
    wire        mem_w;          // Memory write enable from CPU
    wire [2:0]  cpu_DMType;     // Data memory access type from CPU
    wire [31:0] cpu_data_out;   // Data from CPU to memory
    wire [31:0] cpu_data_addr;  // Address from CPU
    wire [31:0] cpu_data_in;    // Data to CPU from memory system
    
    wire [31:0] dm_din, dm_dout;  // Data memory input/output
    wire [31:0] ram_addr;         // Data memory address (word-aligned)
    wire        ram_we;           // Write enable for data memory
    wire [2:0]  DMType;           // Data memory access type to data memory
    
    wire [31:0] seg7_data;        // Data for 7-segment display (32-bit hex)
    wire [63:0] seg7_ascii_data;  // ASCII data for 7-segment display (64-bit)
    wire        seg7_ascii_mode;  // ASCII mode control from MULTI_CH32
    wire [31:0] cpuseg7_data;     // CPU data for display (memory-mapped)
    wire        seg7_we;          // Write enable for display
    wire [31:0] reg_data;         // Selected register data for debug
    wire [4:0]  reg_sel;          // Register selection for debug
    
    // Cycle Counter
    reg [31:0] cycle_count;       // CPU cycle counter
    
    // UART signals
    wire        uart_we;          // Write enable for UART
    wire        uart_clear;       // Clear enable for UART
    wire [7:0]  uart_data_in;     // Data to UART (8-bit)
    wire [63:0] uart_display_data; // 8 bytes for 7-segment display
    
    // Timer signals
    wire        timer_int;        // Timer interrupt signal
    wire        timer_int_ack;    // Timer interrupt acknowledge
    
    // External interrupt signals
    wire        external_int;     // External interrupt signal
    wire        ext_int_ack;      // External interrupt acknowledge
    
    // Register Selection for Debug Display
    // Use SW[4:0] to select which register to display
    assign reg_sel = sw_i[4:0];
    
    // Cycle Counter Logic
    always @(posedge Clk_CPU or posedge rst) begin
        if (rst) begin
            cycle_count <= 32'b0;
        end else begin
            cycle_count <= cycle_count + 1'b1;
        end
    end
    
    // Instruction Memory (ROM IP Core)
    imem U_IM(
        .a   (PC[11:2]), // Word-aligned address (PC >> 2)
        .spo (instr)     // Instruction output
    );
    
    // Data Memory
    dmem U_dmem(
        .clk    (clk),           // CPU clock
        .we     (ram_we),        // Write enable from MIO_BUS
        .wd     (dm_din),        // Write data from MIO_BUS
        .addr   (ram_addr),      // Full address for byte offset calculation
        .DMType (DMType),        // Data memory access type from CPU
        .rd     (dm_dout)        // Read data to MIO_BUS
    );
    
    // Memory-Mapped I/O Bus Controller
    MIO_BUS U_MIO(
        .mem_w         (mem_w),         // Memory write enable from CPU
        .sw_i          (sw_i),          // Switch inputs
        .cpu_data_out  (cpu_data_out),  // Data from CPU
        .cpu_data_addr (cpu_data_addr), // Address from CPU
        .cpu_DMType    (cpu_DMType),    // Data memory access type from CPU
        .ram_data_out  (dm_dout),       // Data from data memory
        .cpu_data_in   (cpu_data_in),   // Data to CPU
        .ram_data_in   (dm_din),        // Data to data memory
        .ram_addr      (ram_addr),      // Address to data memory
        .DMType        (DMType),        // Data memory access type to data memory
        .cpuseg7_data  (cpuseg7_data),  // Data to display controller
        .ram_we        (ram_we),        // Write enable to data memory
        .seg7_we       (seg7_we),       // Write enable to display
        .uart_we       (uart_we),       // Write enable to UART
        .uart_clear    (uart_clear),    // Clear enable to UART
        .uart_data_in  (uart_data_in)   // Data to UART (8-bit)
    );
    
    // UART Module
    uart U_UART(
        .clk              (Clk_CPU),            // CPU clock
        .rst              (rst),                // Reset
        .uart_we          (uart_we),            // Write enable from MIO_BUS
        .uart_clear       (uart_clear),         // Clear enable from MIO_BUS
        .data_in          (uart_data_in),       // Data from CPU (8-bit)
        .uart_display_data(uart_display_data)   // 8 bytes for 7-segment display
    );
    
    // Multi-Channel Display Data Selector
    MULTI_CH32 U_Multi(
        .clk            (clk),                    // System clock
        .rst            (rst),                    // Reset
        .EN             (seg7_we),                // Write enable from MIO_BUS
        .ctrl           (sw_i[5:0]),              // Control switches SW[5:0]
        .Data0          (cpuseg7_data),           // Channel 0: CPU data (programmable)
        .data1          ({2'b00, PC[31:2]}),      // Channel 1: PC (word-aligned)
        .data2          (PC),                     // Channel 2: Full PC
        .data3          (instr),                  // Channel 3: Current instruction
        .data4          (cpu_data_addr),          // Channel 4: Data memory address
        .data5          (cpu_data_out),           // Channel 5: Data to memory
        .data6          (dm_dout),                // Channel 6: Data from memory
        .data7          (ram_addr),               // Channel 7: RAM address
        .data8          (cycle_count),            // Channel 8: CPU cycle count
        .reg_data       (reg_data),               // Register data for display
        .uart_data      (uart_display_data),      // UART data input
        .seg7_data      (seg7_data),              // 32-bit hex data output
        .seg7_ascii_data(seg7_ascii_data),        // 64-bit ASCII data output
        .ascii_mode     (seg7_ascii_mode)         // ASCII mode control output
    );
    
    // 5-Stage Pipelined RISC-V CPU
    cpu U_CPU(
        .clk          (Clk_CPU),       // CPU clock
        .reset        (rst),           // Reset (active high)
        
        // Instruction Memory Interface
        .IMRd         (1'b1),          // Always enable instruction reads (connected to constant)
        .IMAddr       (PC),            // Instruction memory address
        .Inst_in      (instr),         // Instruction input
        
        // Data Memory Interface
        .DMRd         (1'b1),          // Always enable data reads (logic handled by MIO_BUS)
        .DMWr         (mem_w),         // Data memory write enable
        .DMAddr       (cpu_data_addr), // Data memory address
        .Data_out     (cpu_data_out),  // Data output
        .DMType       (cpu_DMType),    // Data memory access type
        .Data_in      (cpu_data_in),   // Data input from memory system
        
        // Interrupt Interface
        .external_int (external_int),  // External interrupt from button
        .timer_int    (timer_int),     // Timer interrupt from board timer
        .timer_int_ack(timer_int_ack), // Timer interrupt acknowledge to board timer
        .ext_int_ack  (ext_int_ack),   // External interrupt acknowledge to button module
        
        // Debug Interface
        .reg_sel      (reg_sel),       // Register select for debug
        .reg_data     (reg_data)       // Register data for debug
    );
    
    // 7-Segment Display Controller
    SEG7x16 U_7SEG(
        .clk          (clk),               // System clock
        .rst          (rst),               // Reset
        .cs           (1'b1),              // Always enabled
        .ascii_mode   (seg7_ascii_mode),   // ASCII mode control from MULTI_CH32
        .i_data       (seg7_data),         // 32-bit data for hex mode
        .i_data_ascii (seg7_ascii_data),   // 64-bit data for ASCII mode
        .o_seg        (disp_seg_o),        // Segment outputs
        .o_sel        (disp_an_o)          // Digit select outputs
    );
    
    // Clock Divider
    CLK_DIV U_CLKDIV(
        .clk     (clk),      // System clock input
        .rst     (rst),      // Reset
        .SW15    (sw_i[15]), // Clock speed selection switch
        .Clk_CPU (Clk_CPU)   // CPU clock output
    );
    
    // Timer Module for Interrupt Generation
    timer U_TIMER(
        .clk          (clk),           // System clock (100MHz)
        .reset        (rst),           // Reset
        .timer_int_ack(timer_int_ack), // Acknowledge from CPU
        .timer_int    (timer_int)      // Interrupt to CPU
    );
    
    // External Interrupt Module for Button Input
    external_int U_EXT_INT(
        .clk          (clk),           // System clock (100MHz)
        .reset        (rst),           // Reset
        .btnc_i       (btnc_i),        // Center button input
        .ext_int_ack  (ext_int_ack),   // Acknowledge from CPU
        .external_int (external_int)   // Interrupt to CPU
    );

endmodule
