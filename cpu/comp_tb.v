`timescale 1ns / 1ps

module comp_tb();

    reg clk;
    reg rstn;
    reg [4:0] reg_sel;
    wire [31:0] reg_data;
    reg stop_monitoring = 0;
    reg [31:0] cycle = 0;
    
    // ANSI Color Codes
    parameter COLOR_RESET = "\033[0m";
    parameter COLOR_RED = "\033[31m";
    parameter COLOR_GREEN = "\033[32m";
    parameter COLOR_YELLOW = "\033[33m";
    parameter COLOR_PURPLE = "\033[35m";
    parameter COLOR_BLUE = "\033[34m";
    parameter COLOR_MAGENTA = "\033[35m";
    parameter COLOR_CYAN = "\033[36m";
    parameter COLOR_WHITE = "\033[37m";
    parameter COLOR_BOLD = "\033[1m";
    parameter COLOR_BOLD_GREEN = "\033[1;32m";
    parameter COLOR_BOLD_RED = "\033[1;31m";
    parameter COLOR_BOLD_YELLOW = "\033[1;33m";
    parameter COLOR_BOLD_BLUE = "\033[1;34m";
    
    // Instantiate the pipeline CPU
    comp #(
`ifdef INSTR_FILE
        .INSTR_FILE(`INSTR_FILE)
`else
        .INSTR_FILE("./instr/non_data_sim5.dat")
`endif
    ) U_COMP(
        .clk(clk),
        .rstn(rstn),
        .reg_sel(reg_sel),
        .reg_data(reg_data)
    );
    
    // Clock generation
    initial begin
        clk = 1;
        forever #5 clk = ~clk; // 10ns period, 100MHz
    end
    
    // Cycle counter
    always @(posedge clk) begin
        if (~rstn) begin
            cycle <= 0;
        end else begin
            cycle <= cycle + 1;
        end
    end
    
    // VCD dump for GTKWave
    initial begin
        $dumpfile("cpu.vcd");  // 指定VCD文件名
        $dumpvars(0, comp_tb);        // 转储所有变量
    end
    
    // Test sequence
    initial begin
        // Initialize - rstn=0 means reset active (since rst = ~rstn in comp.v)
        rstn = 0;
        
        $display("%s%s=== Pipeline CPU Simulation Started ===%s", COLOR_BOLD_GREEN, COLOR_BOLD, COLOR_RESET);
        
        // Release reset after a few cycles
        #1;
        rstn = 1;
        $display("%sCycle: %6d: Reset released%s", COLOR_GREEN, cycle, COLOR_RESET);
        
        // Continue simulation to observe more pipeline behavior
        #1000;
        
        // Stop the clock monitoring to avoid interleaving
        stop_monitoring = 1;
        
        // Wait for current clock cycle to complete
        @(posedge clk);
        @(posedge clk);
        
        // Now display final register state without interruption
        $display("\n%s%s=== Final Register State ===%s", COLOR_BOLD_BLUE, COLOR_BOLD, COLOR_RESET);
        reg_sel = 0;
        repeat (32) begin
            #2;
            if (reg_sel < 10) begin
                $write("%sx%0d  = 0x%08h%s", COLOR_CYAN, reg_sel, reg_data, COLOR_RESET);  // Extra space for single digits
            end else begin
                $write("%sx%0d = 0x%08h%s", COLOR_CYAN, reg_sel, reg_data, COLOR_RESET);   // Normal for double digits
            end
            if ((reg_sel % 4) == 3) begin
                $display("");  // New line after every 4 registers
            end else begin
                $write("  ");  // Two spaces between registers on same line
            end
            reg_sel = reg_sel + 1;
        end
        
        $display("%s%s=== Pipeline CPU simulation completed successfully! ===%s", COLOR_BOLD_GREEN, COLOR_BOLD, COLOR_RESET);
        $finish;
    end
    
    // Monitor pipeline state with more detailed information
    always @(posedge clk) begin
        if (rstn && !stop_monitoring) begin
            $display("%sCycle %7d%s: %sPC=0x%08h%s, %sInst=0x%08h%s, %sStall=%b%s,   %sBranch=%b%s,   %sForwardA=%02b%s,   %sForwardB=%02b%s,   %sFlush_IF/ID=%b%s,   %sFlush_ID/EX=%b%s", 
                     COLOR_WHITE, cycle, COLOR_RESET,
                     COLOR_BLUE, U_COMP.U_CPU.PC_out, COLOR_RESET,
                     COLOR_MAGENTA, U_COMP.U_CPU.Inst_in, COLOR_RESET,
                     U_COMP.U_CPU.stall ? COLOR_RED : COLOR_GREEN, U_COMP.U_CPU.stall, COLOR_RESET,
                     U_COMP.U_CPU.branch_taken ? COLOR_YELLOW : COLOR_GREEN, U_COMP.U_CPU.branch_taken, COLOR_RESET,
                     U_COMP.U_CPU.forwardA != 2'b00 ? COLOR_BLUE : COLOR_GREEN, U_COMP.U_CPU.forwardA, COLOR_RESET,
                     U_COMP.U_CPU.forwardB != 2'b00 ? COLOR_BLUE : COLOR_GREEN, U_COMP.U_CPU.forwardB, COLOR_RESET,
                     U_COMP.U_CPU.flush_IFID ? COLOR_PURPLE : COLOR_GREEN, U_COMP.U_CPU.flush_IFID, COLOR_RESET,
                     U_COMP.U_CPU.flush_IDEX ? COLOR_PURPLE : COLOR_GREEN, U_COMP.U_CPU.flush_IDEX, COLOR_RESET);
        end
    end
    
    // Monitor hazard events
    always @(posedge clk) begin
        if (rstn && !stop_monitoring) begin
            if (U_COMP.U_CPU.stall) begin
                $display("%s%sSTALL %7d%s", COLOR_BOLD_RED, COLOR_BOLD, cycle, COLOR_RESET);
            end
            if (U_COMP.U_CPU.branch_taken) begin
                $display("%s%sBRANCH %6d%s: %sTarget: 0x%08h%s", 
                         COLOR_BOLD_YELLOW, COLOR_BOLD, cycle, COLOR_RESET,
                         COLOR_YELLOW, U_COMP.U_CPU.branch_target, COLOR_RESET);
            end
            if (U_COMP.U_CPU.forwardA != 2'b00 || U_COMP.U_CPU.forwardB != 2'b00) begin
                $display("%s%sFORWARD %5d%s: %sForwardA=%02b%s, %sForwardB=%02b%s", 
                         COLOR_BOLD_BLUE, COLOR_BOLD, cycle, COLOR_RESET,
                         COLOR_BLUE, U_COMP.U_CPU.forwardA, COLOR_RESET,
                         COLOR_BLUE, U_COMP.U_CPU.forwardB, COLOR_RESET);
            end
            if (U_COMP.U_CPU.flush_IFID || U_COMP.U_CPU.flush_IDEX) begin
                $display("%s%sFLUSH  %6d%s: %sFlush_IF/ID=%b%s, %sFlush_ID/EX=%b%s", 
                         COLOR_PURPLE, COLOR_BOLD, cycle, COLOR_RESET,
                         COLOR_PURPLE, U_COMP.U_CPU.flush_IFID, COLOR_RESET,
                         COLOR_PURPLE, U_COMP.U_CPU.flush_IDEX, COLOR_RESET);
            end
        end
    end

endmodule