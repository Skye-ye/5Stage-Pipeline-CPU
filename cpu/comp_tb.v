`timescale 1ns / 1ps

module comp_tb();

    reg clk;
    reg rstn;
    reg [4:0] reg_sel;
    wire [31:0] reg_data;
    reg stop_monitoring = 0;
    
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
        clk = 0;
        forever #5 clk = ~clk; // 10ns period, 100MHz
    end
    
    // VCD dump for GTKWave
    initial begin
        $dumpfile("cpu.vcd");  // 指定VCD文件名
        $dumpvars(0, comp_tb);        // 转储所有变量
    end
    
    // Test sequence
    initial begin
        // Initialize
        rstn = 0;
        
        $display("=== Pipeline CPU Simulation Started ===");
        
        // Reset the system
        #5;
        rstn = 1;
        $display("Time: %10t: Reset released", $time);
        
        // Continue simulation to observe more pipeline behavior
        #500;
        
        // Stop the clock monitoring to avoid interleaving
        stop_monitoring = 1;
        
        // Wait for current clock cycle to complete
        @(posedge clk);
        @(posedge clk);
        
        // Now display final register state without interruption
        $display("\n=== Final Register State ===");
        reg_sel = 0;
        repeat (32) begin
            #2;
            if (reg_sel < 10) begin
                $write("x%0d  = 0x%08h", reg_sel, reg_data);  // Extra space for single digits
            end else begin
                $write("x%0d = 0x%08h", reg_sel, reg_data);   // Normal for double digits
            end
            if ((reg_sel % 4) == 3) begin
                $display("");  // New line after every 4 registers
            end else begin
                $write("  ");  // Two spaces between registers on same line
            end
            reg_sel = reg_sel + 1;
        end
        
        $display("=== Pipeline CPU simulation completed successfully! ===");
        $finish;
    end
    
    // Monitor pipeline state with more detailed information
    always @(posedge clk) begin
        if (rstn && !stop_monitoring) begin
            $display("Cycle %10t: PC=0x%08h, Inst=0x%08h, Stall=%b, Branch=%b, ForwardA=%02b, ForwardB=%02b", 
                     $time, 
                     U_COMP.U_CPU.PC,
                     U_COMP.U_CPU.IFID_inst,
                     U_COMP.U_CPU.stall,
                     U_COMP.U_CPU.BranchTaken,
                     U_COMP.U_CPU.forwardA,
                     U_COMP.U_CPU.forwardB);
        end
    end
    
    // Monitor hazard events
    always @(posedge clk) begin
        if (rstn && !stop_monitoring) begin
            if (U_COMP.U_CPU.stall) begin
                $display("STALL %10t", $time);
            end
            if (U_COMP.U_CPU.BranchTaken) begin
                $display("BRANCH %9t: Target: 0x%08h", 
                         $time, U_COMP.U_CPU.branch_target);
            end
            if (U_COMP.U_CPU.forwardA != 2'b00 || U_COMP.U_CPU.forwardB != 2'b00) begin
                $display("FORWARD %8t: ForwardA=%02b, ForwardB=%02b", 
                         $time, 
                         U_COMP.U_CPU.forwardA,
                         U_COMP.U_CPU.forwardB);
            end
        end
    end

endmodule