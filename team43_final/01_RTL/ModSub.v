// `include "CSA_sub.v"
// `include "CPA_sub.v"
module ModSub #(
    parameter WIDTH = 255
) (
    input [WIDTH-1:0] A,
    input [WIDTH-1:0] B,
    input [WIDTH-1:0] Q,
    output [WIDTH-1:0] Sub_Result
);
//===========================================
// declare
//=========================================== 
    wire [WIDTH-1:0] Binv;
    // csa port
    wire [WIDTH:0] S_csa0, S_csa1;
    wire [WIDTH:0] C_csa0, C_csa1; 
    // cpa port
    wire [WIDTH:0] S_cpa0, S_cpa1;
    wire             C_cpa1;

//===========================================
// input operation
//===========================================
    assign Binv = ~B;

//===========================================
// Input --> CSA1 --> CPA1 --> MUX1
//===========================================
    //CSA1
    CSA_sub #(
        .WIDTH(WIDTH)
    )ModSub_csa1 (
        .A(A), .B(Binv), .Q(255'd0),
        .SUM(S_csa1),
        .Cout(C_csa1)
    );
    //CPA1
    CPA_sub #(
        .WIDTH(WIDTH +1)
    )ModSub_cpa1(
        .A(S_csa1), .B(C_csa1), .Cin(1'b1),
        .Sout(S_cpa1)
    );
    assign C_cpa1 = S_cpa1[WIDTH];

//===========================================
// Input --> CSA1 --> CPA1 --> MUX1
//===========================================
    //CSA0
    CSA_sub #(
        .WIDTH(WIDTH)
    )ModSub_csa0(
        .A(A), .B(Binv), .Q(Q),
        .SUM(S_csa0),
        .Cout(C_csa0)
    );
    //CPA0
    CPA_sub #(
        .WIDTH(WIDTH +1)
    )ModSub_cpa0(
        .A(S_csa0), .B(C_csa0), .Cin(1'b1),
        .Sout(S_cpa0)
    );

//===========================================
// MUX --> output
//===========================================
    assign Sub_Result = (C_cpa1)?    S_cpa1[WIDTH-1:0] : S_cpa0[WIDTH-1:0];
    
endmodule