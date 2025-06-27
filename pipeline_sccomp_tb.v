`timescale 1ns / 1ps

module pipeline_sccomp_tb();

    reg clk;
    reg rstn;
    reg [4:0] reg_sel;
    wire [31:0] reg_data;
    
    // Instantiate the pipeline CPU
    pipeline_sccomp U_pipeline_sccomp(
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
        $dumpfile("pipeline_cpu.vcd");  // 指定VCD文件名
        $dumpvars(0, pipeline_sccomp_tb);        // 转储所有变量
        
        // 也可以选择性地转储特定信号
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.PC_IF);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.IFID_inst);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.stall);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.BranchTaken);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.forwardA);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.forwardB);
        
        // 转储流水线寄存器状态
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.IFID_valid);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.IDEX_valid);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.EXMEM_valid);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.MEMWB_valid);
        
        // 转储ALU相关信号
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.ALU_A);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.ALU_B);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.ALUOut_EX);
        
        // 转储寄存器文件状态
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.U_RF.RFWr);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.U_RF.A3);
        $dumpvars(1, U_pipeline_sccomp.U_pipeline_CPU.U_RF.WD);
    end
    
    // Test sequence
    initial begin
        // Initialize
        rstn = 0;
        reg_sel = 0;
        
        $display("=== Pipeline CPU Simulation Started ===");
        
        // Reset the system
        #20;
        rstn = 1;
        $display("Time: %t, Reset released", $time);
        
        // Run for several clock cycles to see pipeline behavior
        #200;
        $display("Time: %t, Pipeline warmup completed", $time);
        
        // Check some register values
        reg_sel = 1; #10;
        $display("Time: %t, r1 = 0x%h", $time, reg_data);
        
        reg_sel = 2; #10;
        $display("Time: %t, r2 = 0x%h", $time, reg_data);
        
        reg_sel = 3; #10;
        $display("Time: %t, r3 = 0x%h", $time, reg_data);
        
        reg_sel = 4; #10;
        $display("Time: %t, r4 = 0x%h", $time, reg_data);
        
        reg_sel = 8; #10;
        $display("Time: %t, r8 = 0x%h", $time, reg_data);
        
        reg_sel = 9; #10;
        $display("Time: %t, r9 = 0x%h", $time, reg_data);
        
        // Continue simulation to observe more pipeline behavior
        #300;
        
        $display("=== Final Register State ===");
        for (reg_sel = 0; reg_sel < 16; reg_sel = reg_sel + 1) begin
            #2;
            $display("r%0d = 0x%h", reg_sel, reg_data);
        end
        
        $display("=== Pipeline CPU simulation completed successfully! ===");
        $finish;
    end
    
    // Monitor pipeline state with more detailed information
    always @(posedge clk) begin
        if (rstn) begin
            $display("Cycle %t: PC=0x%h, Inst=0x%h, Stall=%b, Branch=%b, ForwardA=%b, ForwardB=%b", 
                     $time, 
                     U_pipeline_sccomp.U_pipeline_CPU.PC_IF,
                     U_pipeline_sccomp.U_pipeline_CPU.IFID_inst,
                     U_pipeline_sccomp.U_pipeline_CPU.stall,
                     U_pipeline_sccomp.U_pipeline_CPU.BranchTaken,
                     U_pipeline_sccomp.U_pipeline_CPU.forwardA,
                     U_pipeline_sccomp.U_pipeline_CPU.forwardB);
        end
    end
    
    // Monitor hazard events
    always @(posedge clk) begin
        if (rstn && U_pipeline_sccomp.U_pipeline_CPU.stall) begin
            $display("*** STALL DETECTED at time %t ***", $time);
        end
        if (rstn && U_pipeline_sccomp.U_pipeline_CPU.BranchTaken) begin
            $display("*** BRANCH TAKEN at time %t, Target: 0x%h ***", 
                     $time, U_pipeline_sccomp.U_pipeline_CPU.branch_target);
        end
        if (rstn && (U_pipeline_sccomp.U_pipeline_CPU.forwardA != 2'b00 || 
                     U_pipeline_sccomp.U_pipeline_CPU.forwardB != 2'b00)) begin
            $display("*** FORWARDING at time %t, ForwardA=%b, ForwardB=%b ***", 
                     $time, 
                     U_pipeline_sccomp.U_pipeline_CPU.forwardA,
                     U_pipeline_sccomp.U_pipeline_CPU.forwardB);
        end
    end

endmodule