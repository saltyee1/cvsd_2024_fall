module CPA_add #(
    parameter WIDTH = 255
) (
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    output [WIDTH-1:0] Sout
);

    wire [WIDTH:0] SUM;
    
    assign SUM = A + B;
    assign Sout = SUM[WIDTH-1:0];

endmodule