module CSA_add #(
    parameter WIDTH = 255
) (
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    input [WIDTH-1:0] Q,
    input             Cin,
    output [WIDTH:0] SUM,
    output [WIDTH:0] Cout
);

    assign Cout[0] = Cin;
    assign SUM[WIDTH] = 1'b0;

    genvar i;
    generate
        for ( i = 0 ; i < WIDTH ; i = i+1 ) begin
            assign SUM [i]   = A[i] ^ B[i] ^ Q[i];
            assign Cout[i+1] = (A[i] & B[i]) | (B[i] & Q[i]) | (Q[i] & A[i]);
        end        
    endgenerate

endmodule


