module rf(
    input         clk,     // Clock signal
    input         rst,     // Reset signal
    input         RFWr,    // Register file write enable
    input  [4:0]  A1,      // Read address 1
    input  [4:0]  A2,      // Read address 2
    input  [4:0]  A3,      // Write address
    input  [31:0] WD,      // Write data
    output [31:0] RD1,     // Read data 1
    output [31:0] RD2      // Read data 2
);
    
    // Register file array (32 registers x 32 bits)
    reg [31:0] rf[31:0];
    integer i;

    // ========== Register File Write Logic ==========
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            // Reset all registers except x0 (which is hardwired to 0)
            for (i = 1; i < 32; i = i + 1) begin
                rf[i] <= 32'b0;
            end
        end else if (RFWr && (A3 != `REG_ZERO)) begin
            // Write to register (except x0 which is always 0)
            rf[A3] <= WD;
        end
    end
        
    // ========== Register File Read Logic ==========
    // x0 is hardwired to 0, other registers return stored values
    assign RD1 = (A1 != `REG_ZERO) ? rf[A1] : 32'b0;
    assign RD2 = (A2 != `REG_ZERO) ? rf[A2] : 32'b0;
    
endmodule 
