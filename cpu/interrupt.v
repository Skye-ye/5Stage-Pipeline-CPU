`include "def.v"

// Interrupt Controller Module
// Handles external interrupts, timer interrupts, and software interrupts
module interrupt(
    input        clk,
    input        reset,
    
    // External interrupt sources
    input        external_int,     // External interrupt request
    input        timer_int,        // Timer interrupt request  
    input        software_int,     // Software interrupt request
    
    // CSR interface
    input [31:0] mie,             // Machine interrupt enable register
    input [31:0] mstatus,         // Machine status register
    input        global_int_enable, // Global interrupt enable (mstatus.MIE)
    
    // Interrupt outputs
    output reg   interrupt_req,    // Interrupt request to CPU
    output reg [31:0] interrupt_cause, // Interrupt cause code
    output reg [31:0] mip          // Machine interrupt pending register
);

    // Update interrupt pending register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mip <= 32'h0;
        end else begin
            // Set pending bits based on interrupt sources
            mip[`MIE_TIMER_INT] <= timer_int;
            mip[`MIE_EXTERNAL_INT] <= external_int;  
            mip[`MIE_SOFTWARE_INT] <= software_int;
        end
    end
    
    // Interrupt prioritization and request logic
    always @(*) begin
        interrupt_req = 1'b0;
        interrupt_cause = 32'h0;
        
        // Only process interrupts if globally enabled
        if (global_int_enable) begin
            // Priority: External > Timer > Software
            if (mip[`MIE_EXTERNAL_INT] && mie[`MIE_EXTERNAL_INT]) begin
                interrupt_req = 1'b1;
                interrupt_cause = `CAUSE_EXTERNAL_INTERRUPT;
            end
            else if (mip[`MIE_TIMER_INT] && mie[`MIE_TIMER_INT]) begin
                interrupt_req = 1'b1;
                interrupt_cause = `CAUSE_TIMER_INTERRUPT;
            end
            else if (mip[`MIE_SOFTWARE_INT] && mie[`MIE_SOFTWARE_INT]) begin
                interrupt_req = 1'b1;
                interrupt_cause = `CAUSE_SOFTWARE_INTERRUPT;
            end
        end
    end

endmodule