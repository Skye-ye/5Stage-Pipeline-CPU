`include "def.v"

// Interrupt Controller Module
// Handles external interrupts, timer interrupts, and software interrupts
module interrupt(
    input        clk,
    input        reset,
    
    // External interrupt sources
    input        external_int,     // External interrupt request
    input        timer_int,        // Timer interrupt request  
    
    // CSR interface
    input [31:0] mie,             // Machine interrupt enable register
    input [31:0] mip,             // Machine interrupt pending register
    input        global_int_enable, // Global interrupt enable (mstatus.MIE)
    
    // Interrupt outputs
    output reg   interrupt_req,    // Interrupt request to CPU
    output reg [31:0] interrupt_cause // Interrupt cause code
);

    // Interrupt prioritization and request logic
    always @(*) begin
        interrupt_req = 1'b0;
        interrupt_cause = 32'h0;
        
        // Only process interrupts if globally enabled
        if (global_int_enable) begin
            // Priority: External > Software > Timer (according to RISC-V spec)
            if (mip[`MIP_MEIP] && mie[`MIE_MEIE]) begin
                interrupt_req = 1'b1;
                interrupt_cause = `CAUSE_EXTERNAL_INTERRUPT;
            end
            else if (mip[`MIP_MTIP] && mie[`MIE_MTIE]) begin
                interrupt_req = 1'b1;
                interrupt_cause = `CAUSE_TIMER_INTERRUPT;
            end
        end
    end

endmodule