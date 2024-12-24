module ModMul (
    input i_clk,
    input i_rst,
    input [254:0] src1,
    input [254:0] src2,
    input ivalid,
    output reg ovalid,
    output reg [254:0]result
);
localparam Qconst = 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949;

//===========================================
// Wire
//===========================================
reg [259:0] comp_src1, comp2_src1; 
reg [254:0] comp_src2, comp2_src2;
reg comp_pass, comp2_pass;
reg [259:0] comp_result, comp2_result;

reg [259:0] add_result, add2_result;
reg [509:0] mul_result;
reg [259:0] sub_result, sub2_result;

//===========================================
// Register
//=========================================== 
reg [254:0] R0;
reg mul_end;
reg [254:0] R1;

DW02_mult_2_stage #(255, 255) U1 (
    .A(R0),   
    .B(R1),   
    .TC(1'b0), 
    .CLK(i_clk),   
    .PRODUCT(mul_result)
);
//===========================================
// State Machine
//=========================================== 
typedef enum logic[1:0]{ 
    INIT, 
    MUL, 
    // ADD, 
    MOD 
} state_t;

state_t cs, ns;

always @(posedge i_clk) begin
    if (i_rst) begin
        cs <= INIT;
    end
    else begin
        cs <= ns;
    end
end

always @(*) begin
    case (cs)
        INIT : ns = (ivalid) ? MUL : INIT; 
        MUL : ns = (mul_end) ?  MOD : MUL;
        // MUL : ns = MOD;
        // ADD : ns = MOD;
        MOD : ns =  INIT;
    endcase
end

//===========================================
// Sequential Blocks
//=========================================== 
always @(posedge i_clk) begin
    if (i_rst) begin
        mul_end <= 1'd0;
    end
    else begin
        mul_end <= (cs==MUL) ? ~mul_end : 1'b0;
    end
end
always @(posedge i_clk) begin
    if (i_rst) begin
        R0 <= 255'd0;
        R1 <= 255'd0;
    end
    else begin
        case (cs)
            INIT : begin
                {R0, R1} <= (ivalid) ? {src1, src2} : {509'd0}; 
            end 
            MUL : begin
                {R0, R1} <= mul_result;
            end
            MOD : begin
                {R0, R1} <= comp_result;
            end
            // MOD : begin
            //     {R0, R1} <= comp_result;
            // end
        endcase
    end
end

//===========================================
// Combinational Blocks
//=========================================== 
always @(*) begin
    // mul_result = R0 * R1;
    add_result = (({5'd0,R0}<<4) + ({5'd0,R0}<<1) + {5'd0,R0} + {5'd0, R1});    //19*HigherBits + LowerBits
    sub_result = add_result - Qconst;
    comp_result = (add_result < Qconst) ? add_result : sub_result;
    comp_pass = comp_result < Qconst;

    add2_result = ((add_result[259:255]<<4) + (add_result[259:255]<<1) + add_result[259:255] + add_result[254:0]);
    sub2_result = add2_result - Qconst;
    comp2_result = (add2_result < Qconst) ? add2_result : sub2_result;
    comp2_pass = comp2_result < Qconst;

    ovalid = (cs==MOD);
    result = comp2_result[254:0];
end
endmodule