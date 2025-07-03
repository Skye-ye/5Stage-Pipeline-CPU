module rf(
    input         clk, 
    input         rst,
    input         RFWr, 
    input  [4:0]  A1, A2, A3, 
    input  [31:0] WD, 
    output [31:0] RD1, RD2
);

    reg [31:0] rf[31:0];

    integer i;

    always @(negedge clk or negedge rst) begin
        if (!rst) begin
            for (i=1; i<32; i=i+1)
                rf[i] <= 0;
        end
        else if (RFWr && A3 != 0) begin
            rf[A3] <= WD;
        end
    end
    
    assign RD1 = (A1 != 0) ? 
                 ((RFWr && (A1 == A3)) ? WD : rf[A1]) : 0;
                 
    assign RD2 = (A2 != 0) ? 
                 ((RFWr && (A2 == A3)) ? WD : rf[A2]) : 0;

endmodule