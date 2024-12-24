module CPA_sub #(
    parameter WIDTH = 255
) (
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    input             Cin,
    output [WIDTH-1:0] Sout
);

    wire [WIDTH+1:0] SUM;
    
    assign SUM = {A,1'b1} + {B,1'b1};
    assign Sout = SUM[WIDTH+1:1];

endmodule