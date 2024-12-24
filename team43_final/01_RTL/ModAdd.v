// `include "CSA_add.v"
// `include "CPA_add.v"
module ModAdd #(
    parameter WIDTH = 255
)
(
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    input [WIDTH-1:0] Q,
    output [WIDTH-1:0] Add_Result
);
//===========================================
// declare
//===========================================
    wire [WIDTH-1:0] Qinv;
    // cpa0 port
    wire [WIDTH-1:0] S_cpa0;
    // csa port
    wire [WIDTH:0] S_csa, C_csa;
    // cpa1 port
    wire [WIDTH  :0] S_cpa1;
    wire C_cpa1;

//===========================================
// input operation
//===========================================
    assign Qinv = ~Q;

//===========================================
// CPA0 -->MUX0
//===========================================
    CPA_add #(
        .WIDTH(WIDTH)
    ) ModAdd_cpa0(
        .A(A), 
        .B(B),
        .Sout(S_cpa0)
    );

//===========================================
// CSA --> CPA1 --> MUX1
//===========================================   
    // CSA -->  CPA1
    CSA_add #(
        .WIDTH(WIDTH)
    ) ModAdd_csa(
        .A(A), 
        .B(B), 
        .Q(Qinv), 
        .Cin(1'b1),
        .SUM(S_csa),
        .Cout(C_csa)
    );
    // CPA1 --> MUX
    CPA_add #(
        .WIDTH(WIDTH+1) //256
    ) ModAdd_cpa1(
        .A(S_csa),
        .B(C_csa),
        .Sout(S_cpa1) // 256bit [255:0]
    );
    assign C_cpa1 = S_cpa1[WIDTH]; 
//===========================================
// MUX
//===========================================
    assign Add_Result = (C_cpa1)?   S_cpa1[WIDTH-1:0] : S_cpa0[WIDTH-1:0];
endmodule