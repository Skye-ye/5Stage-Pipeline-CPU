`include "def.v"

// Testbench for Interrupt Functionality
module interrupt_tb();

    // Clock and reset
    reg clk, reset;
    
    // Timer signals
    wire timer_int;
    reg [31:0] timer_limit = 32'd100; // Generate interrupt every 100 cycles
    
    // External interrupt signals  
    reg external_int = 1'b0;
    reg software_int = 1'b0;
    
    // CPU interface signals
    wire [31:0] PC, Addr_out, Data_out;
    wire mem_w;
    wire [2:0] DMType_out;
    wire [31:0] reg_data;
    
    // Memory signals
    reg [31:0] inst_in = `NOP_INSTRUCTION;
    reg [31:0] Data_in = 32'h0;
    
    // Debug signals
    reg [4:0] reg_sel = 5'h0;
    
    // Timer instance
    timer U_TIMER(
        .clk(clk),
        .reset(reset),
        .timer_limit(timer_limit),
        .timer_int(timer_int)
    );
    
    // CPU instance with interrupt support
    cpu U_CPU(
        .clk(clk),
        .reset(reset),
        .Inst_in(inst_in),
        .Data_in(Data_in),
        .mem_w(mem_w),
        .DMType_out(DMType_out),
        .PC_out(PC),
        .Addr_out(Addr_out),
        .Data_out(Data_out),
        .external_int(external_int),
        .timer_int(timer_int),
        .software_int(software_int),
        .reg_sel(reg_sel),
        .reg_data(reg_data)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end
    
    // Test sequence
    initial begin
        // Initialize signals
        reset = 1;
        external_int = 0;
        software_int = 0;
        
        // Reset the system
        #20;
        reset = 0;
        
        // Simple instruction sequence for testing
        #10;
        inst_in = 32'h00100093; // addi x1, x0, 1
        #10;
        inst_in = 32'h00200113; // addi x2, x0, 2  
        #10;
        inst_in = 32'h00800193; // addi x3, x0, 8 (for mstatus.MIE)
        #10;
        inst_in = 32'h30019073; // csrw mstatus, x3
        #10;
        inst_in = 32'h08000213; // addi x4, x0, 128 (for mie timer enable)
        #10;
        inst_in = 32'h30421073; // csrw mie, x4
        
        // Continue with normal instructions
        #10;
        inst_in = 32'h002081b3; // add x3, x1, x2
        #10;
        inst_in = 32'h00108093; // addi x1, x1, 1
        
        // Let timer interrupt occur
        #1000;
        
        // Test external interrupt
        external_int = 1;
        #20;
        external_int = 0;
        
        // Continue simulation
        #500;
        
        // Finish simulation
        $display("Simulation completed");
        $finish;
    end
    
    // Monitor key signals
    initial begin
        $monitor("Time: %0t | PC: %h | Interrupt: timer=%b ext=%b | Reset: %b", 
                 $time, PC, timer_int, external_int, reset);
    end
    
    // Generate VCD for waveform viewing
    initial begin
        $dumpfile("interrupt_test.vcd");
        $dumpvars(0, interrupt_tb);
    end

endmodule