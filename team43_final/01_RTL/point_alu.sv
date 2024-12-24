// `include "define.v"
// `include "../01_RTL/ModSub.v"
// `include "../01_RTL/ModAdd.v"
// `include "../01_RTL/ModMul.sv"
module point_alu (
    input i_clk,
    input i_rst,
    input ivalid,
    input [764:0] point1, //{X1,Y1,Z1} 
    input [764:0] point2, //{X2,Y2,Z2} 
    input [1:0] op, //00 double, 01 add, 11 reduce
    output reg ovalid, //{X3,Y3,Z3}
    output reg [764:0] opoint
);

localparam Qconst = 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949;
localparam Qminus2 = 255'd57896044618658097711785492504343953926634992332820282019728792003956564819947;
localparam Dconst = 255'h52036cee2b6ffe738cc740797779e89800700a4d4141d8ab75eb4dca135978a3;
localparam OP_DOUBLE = 2'b00;
localparam OP_ADD = 2'b01;
localparam OP_REDUCE = 2'b11;
integer i;

//===========================================
// Wire
//=========================================== 
//Nets for ModMul
reg [254:0] MM_src1, MM_src2;
wire [254:0] MM_result;
reg MM_ivalid;
wire MM_ovalid;

//Nets for ModAdd
reg [254:0] MA_src1, MA_src2;
wire [254:0] MA_result;

//Nets for ModSub
reg [254:0] MS_src1, MS_src2;
wire [254:0] MS_result;

//Nets for R register
reg [5:0] Rwen;
reg [254:0] Rwdata [0:5];
//===========================================
// Register
//=========================================== 
reg [254:0] R [0:5];    //store point1,point2 and temp data during calculation
// reg [3:0] mul_counter;
reg [1:0]op_r;  
reg [5:0] counter_i; // count for modular inversion algorithm 
reg [5:0] counter_i_n;
reg [2:0] counter_square, counter_square_n;
reg last_window;
reg last_square;
//===========================================
// Sub Module Connection 
//=========================================== 
ModMul u_mm (
    .i_clk(i_clk),
    .i_rst(i_rst),
    .src1(MM_src1),
    .src2(MM_src2),
    .ivalid(MM_ivalid),
    .ovalid(MM_ovalid),
    .result(MM_result)
);

wire MM_result_odd = MM_result[0];

ModAdd  u_ma(
    .A(MA_src1),
    .B(MA_src2),
    .Q(Qconst),
    .Add_Result(MA_result)
);

ModSub u_ms (
    .A(MS_src1),
    .B(MS_src2),
    .Q(Qconst),
    .Sub_Result(MS_result)
);

//===========================================
// State Machine
//=========================================== 
typedef enum logic[5:0]{
    INIT,
    ADD1, ADD2, ADD3, ADD4, 
    ADD5, ADD6, ADD7, ADD8,
    ADD9, ADD10, ADD11, ADD12,
    DOB1, DOB2, DOB3, DOB4,
    DOB5, DOB6, DOB7,
    Z1, Z2, Z3, Z4, Z5, Z6, Z7, Z8,
    SQUARE, MUL11, MUL31, 
    REDUCEX1, REDUCEX2,
    REDUCEY1, REDUCEY2
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
//next state logic
always @(*) begin
    case (cs)
        INIT : begin
            if (ivalid) begin
                if (op == 2'b00) begin
                    ns = DOB1;
                end
                else if (op == 2'b01)begin
                    ns = ADD1;
                end
                else begin
                    ns = Z1;
                end
            end
            else begin
                ns = INIT;
            end
        end
        DOB1 : ns = (MM_ovalid) ? DOB2 : DOB1;
        DOB2 : ns = (MM_ovalid) ? DOB3 : DOB2;
        DOB3 : ns = (MM_ovalid) ? DOB4 : DOB3;
        DOB4 : ns = (MM_ovalid) ? DOB5 : DOB4;
        DOB5 : ns = (MM_ovalid) ? DOB6 : DOB5;
        DOB6 : ns = (MM_ovalid) ? DOB7 : DOB6;
        DOB7 : ns = (MM_ovalid) ? INIT : DOB7;
        ADD1 : ns = (MM_ovalid) ? ADD2 : ADD1;
        ADD2 : ns = (MM_ovalid) ? ADD3 : ADD2;
        ADD3 : ns = (MM_ovalid) ? ADD4 : ADD3;
        ADD4 : ns = (MM_ovalid) ? ADD5 : ADD4;
        ADD5 : ns = (MM_ovalid) ? ADD6 : ADD5;
        ADD6 : ns = (MM_ovalid) ? ADD7 : ADD6;
        ADD7 : ns = (MM_ovalid) ? ADD8 : ADD7;
        ADD8 : ns = (MM_ovalid) ? ADD9 : ADD8;
        ADD9 : ns = (MM_ovalid) ? ADD10 : ADD9;
        ADD10 : ns = (MM_ovalid) ? ADD11 : ADD10;
        ADD11 : ns = (MM_ovalid) ? ADD12 : ADD11;
        ADD12 : ns = (MM_ovalid) ? INIT : ADD12;
        Z1 : ns = (MM_ovalid) ? Z2 : Z1;
        Z2 : ns = (MM_ovalid) ? Z3 : Z2;
        Z3 : ns = (MM_ovalid) ? Z4 : Z3;
        Z4 : ns = (MM_ovalid) ? Z5 : Z4; 
        Z5 : ns = (MM_ovalid) ? Z6 : Z5; 
        Z6 : ns = (MM_ovalid) ? Z7 : Z6; 
        Z7 : ns = (MM_ovalid) ? SQUARE : Z7;
        SQUARE : ns = (MM_ovalid) ? ((last_square) ? ((last_window) ? MUL11 : MUL31) : SQUARE) : SQUARE;
        MUL31 : ns = (MM_ovalid) ? SQUARE : MUL31;
        MUL11 : ns = (MM_ovalid) ? REDUCEX1 : MUL11;
        REDUCEX1 : ns = (MM_ovalid) ? ((MM_result_odd) ? REDUCEX2 : REDUCEY1) : REDUCEX1;
        REDUCEX2 : ns = REDUCEY1;
        REDUCEY1 : ns = (MM_ovalid) ? ((MM_result_odd) ? REDUCEY2 : INIT) : REDUCEY1;
        REDUCEY2 : ns = INIT;
        default : ns = INIT;
    endcase
end

//===========================================
// Sequential Blocks
//=========================================== 

always @(posedge i_clk ) begin
    if (i_rst) begin
        for (i=0; i<6; i=i+1) begin
            R[i] <= 255'b0;
        end
    end
    else begin
        for (i=0; i<6; i=i+1) begin
            R[i] <= (Rwen[i]) ? Rwdata[i] : R[i];   //Change if Rwen
        end
    end
end

always @(posedge i_clk) begin
    if (i_rst) begin
        MM_ivalid <= 1'b0;
    end
    else begin
        if (cs == ADD12 || cs == DOB7 || cs==REDUCEX1&&MM_result_odd) begin        //last round of addition and double
            MM_ivalid <= 1'b0;
        end
        else begin
            MM_ivalid <= (MM_ovalid | ivalid | cs==REDUCEX2);
        end
    end
end

always @(posedge i_clk) begin
    if (i_rst) begin
        // mul_counter <= 'd0;
        op_r <= 2'd0;
        counter_i <= 6'd0;
        counter_square <= 3'd0;
        last_window <= 1'b0;
        last_square <= 1'b0;
    end
    else begin
        // mul_counter <= (MM_ovalid || cs == INIT) ? 'd0 : mul_counter + 'd1;
        op_r <= (ivalid) ? op : op_r;
        counter_i <= counter_i_n;
        counter_square <= counter_square_n;
        last_window <= (counter_i==6'd50);
        last_square <= (counter_square==3'd4);
    end
end

//===========================================
// Combinational Blocks
//=========================================== 


always @(*) begin
    ovalid = (((cs==ADD12||cs==DOB7||(cs==REDUCEY1&&!MM_result_odd))) && (MM_ovalid)) || cs==REDUCEY2;
    case (op_r)
        OP_ADD : opoint = {MM_result, R[2], R[3]};
        OP_DOUBLE : opoint = {MM_result, R[1], R[2]};
        OP_REDUCE : opoint = (cs == REDUCEY2) ? {R[0], MS_result, 255'd0} : {R[0], MM_result, 255'd1};
        default: opoint = 765'd0;
    endcase

    counter_i_n = (cs == MUL31 && MM_ovalid) ? counter_i+6'd1 : counter_i;
    if (cs == SQUARE && MM_ovalid) begin
        case (counter_square)
            3'd0 : counter_square_n = 3'd1;
            3'd1 : counter_square_n = 3'd2;
            3'd2 : counter_square_n = 3'd3;
            3'd3 : counter_square_n = 3'd4;
            3'd4 : counter_square_n = 3'd0; 
            default: counter_square_n = 3'd1;
        endcase
    end
    else begin
        counter_square_n = counter_square;
    end
end

wire [254:0]debug_opointx = opoint[764:510];
wire [254:0]debug_opointy = opoint[509:255];
wire [254:0]debug_opointz = opoint[254:0];

always @(*) begin
    for (i=0; i<6; i=i+1) begin
        Rwdata[i] = R[i];
    end
    Rwen = 6'd0;
    MM_src1 = 255'd0;
    MM_src2 = 255'd0;
    MA_src1 = 255'd0;
    MA_src2 = 255'd0;
    MS_src1 = 255'd0;
    MS_src2 = 255'd0;
    case (cs)
        INIT : begin
            Rwen = (ivalid) ? 6'b111111 : 6'b000000;
            if (op==OP_ADD) begin
                {Rwdata[0], Rwdata[2], Rwdata[4]} = point1;
                {Rwdata[1], Rwdata[3], Rwdata[5]} = point2;
            end
            else if (op==OP_DOUBLE) begin
                {Rwdata[0], Rwdata[1], Rwdata[2]} = point1;
                {Rwdata[3], Rwdata[4], Rwdata[5]} = point2;
            end
            else begin
                {Rwdata[0], Rwdata[1], Rwdata[2]} = point1;
                {Rwdata[3], Rwdata[4], Rwdata[5]} = {255'd0, 255'd0, 255'd1};
            end
    
        end
        DOB1 :  begin
            Rwen = (MM_ovalid) ? 6'b001111 : 6'b000000;     //change R0123
            Rwdata[0] = MA_result;
            Rwdata[1] = R[0];
            Rwdata[2] = MM_result;
            Rwdata[3] = R[2];
            {MM_src1, MM_src2} = {R[1], R[1]};
            {MA_src1, MA_src2} = {R[0], R[1]};
        end
        DOB2 : begin
            Rwen = (MM_ovalid) ? 6'b000010 : 6'b000000;     //change R1
            Rwdata[1] = MM_result;
            {MM_src1, MM_src2} = {R[1], R[1]}; 
        end
        DOB3 : begin
            Rwen = (MM_ovalid) ? 6'b001110 : 6'b000000;     //change R123
            Rwdata[1] = MA_result;
            Rwdata[2] = MS_result;
            Rwdata[3] = MM_result;
            {MM_src1, MM_src2} = {R[3], R[3]};
            {MA_src1, MA_src2} = {R[2], R[1]};
            {MS_src1, MS_src2} = {R[2], R[1]};
        end
        DOB4 : begin
            Rwen = (MM_ovalid) ? 6'b001011 : 6'b000000;     //change R0123
            Rwdata[0] = MM_result;
            Rwdata[1] = MS_result;
            Rwdata[3] = MA_result;
            {MM_src1, MM_src2} = {R[0], R[0]};
            {MA_src1, MA_src2} = {R[3], R[3]};
            {MS_src1, MS_src2} = {255'd0, R[1]};
        end
        DOB5 : begin
            Rwen = (MM_ovalid) ? 6'b001011 : 6'b000000;     //change R013
            Rwdata[0] = MA_result;
            Rwdata[1] = MM_result;
            Rwdata[3] = MS_result;
            {MM_src1, MM_src2} = {R[1], R[2]};
            {MA_src1, MA_src2} = {R[0], R[1]};
            {MS_src1, MS_src2} = {R[2], R[3]};
        end
        DOB6 : begin
            Rwen = (MM_ovalid) ? 6'b000100 : 6'b000000;     //change R2
            Rwdata[2] = MM_result;
            {MM_src1, MM_src2} = {R[2], R[3]};
        end
        DOB7 : begin
            Rwen = (MM_ovalid) ? 6'b000001 : 6'b000000;     //change R0
            Rwdata[0] = MM_result;
            {MM_src1, MM_src2} = {R[0], R[3]};
        end
        ADD1 : begin
            Rwen = (MM_ovalid) ? 6'b100000 : 6'b000000;     //change R6
            Rwdata[5] = MM_result;
            {MM_src1, MM_src2} = {R[4], R[5]};
        end
        ADD2 : begin
            Rwen = (MM_ovalid) ? 6'b011000 : 6'b000000;     //change R34
            Rwdata[3] = MM_result;
            Rwdata[4] = MA_result;
            {MM_src1, MM_src2} = {R[2], R[3]};
            {MA_src1, MA_src2} = {R[1], R[3]};
        end
        ADD3 : begin
            Rwen = (MM_ovalid) ? 6'b000011 : 6'b000000;     //change R01
            Rwdata[0] = MA_result;
            Rwdata[1] = MM_result;
            {MM_src1, MM_src2} = {R[0], R[1]};
            {MA_src1, MA_src2} = {R[0], R[2]};
        end
        ADD4 : begin
            Rwen = (MM_ovalid) ? 6'b111100 : 6'b000000;     //change R2345
            Rwdata[2] = R[3]; 
            Rwdata[3] = R[4];
            Rwdata[4] = R[5];
            Rwdata[5] = MM_result;
            {MM_src1, MM_src2} = {R[5], R[5]};
        end
        ADD5 : begin
            Rwen = (MM_ovalid) ? 6'b000110 : 6'b000000;     //change R12
            Rwdata[1] = MM_result;
            Rwdata[2] = MA_result;
            {MM_src1, MM_src2} = {R[1], R[2]};
            {MA_src1, MA_src2} = {R[1], R[2]};
        end
        ADD6 : begin
            Rwen = (MM_ovalid) ? 6'b000010 : 6'b000000;     //change R1
            Rwdata[1] = MM_result;
            {MM_src1, MM_src2} = {R[1], Dconst};
        end
        ADD7 : begin
            Rwen = (MM_ovalid) ? 6'b000001 : 6'b000000;     //change R0
            Rwdata[0] = MM_result;
            {MM_src1, MM_src2} = {R[0], R[3]};
        end
        ADD8 : begin
            Rwen = (MM_ovalid) ? 6'b111110 : 6'b000000;     //change R12345 
            Rwdata[1] = R[2];
            Rwdata[2] = MS_result;
            Rwdata[3] = MM_result;
            Rwdata[4] = MA_result;
            Rwdata[5] = R[4];
            {MM_src1, MM_src2} = {R[4], R[2]};
            {MA_src1, MA_src2} = {R[5], R[1]};
            {MS_src1, MS_src2} = {R[5], R[1]};
        end
        ADD9 : begin
            Rwen = (MM_ovalid) ? 6'b011111 : 6'b000000;     //change R01234
            Rwdata[0] = MS_result;
            Rwdata[1] = R[2];
            Rwdata[2] = MM_result;
            Rwdata[3] = R[4];
            Rwdata[4] = R[5];
            {MM_src1, MM_src2} = {R[3], R[4]};
            {MS_src1, MS_src2} = {R[0], R[1]};
        end
        ADD10 : begin
            Rwen = (MM_ovalid) ? 6'b000001 : 6'b000000;     //change R0
            Rwdata[0] = MM_result;
            {MM_src1, MM_src2} = {R[0], R[4]};
        end
        ADD11 : begin
            Rwen = (MM_ovalid) ? 6'b001000 : 6'b000000;     //change R3
            Rwdata[3] = MM_result;
            {MM_src1, MM_src2} = {R[1], R[3]};
        end
        ADD12 : begin
            Rwen = (MM_ovalid) ? 6'b000010 : 6'b000000;     //change R1
            Rwdata[1] = MM_result;
            {MM_src1, MM_src2} = {R[0], R[1]};
        end
        Z1 : begin
            Rwen = (MM_ovalid) ? 6'b001000 : 6'b000000;     //change R3
            Rwdata[3] = MM_result;
            {MM_src1, MM_src2} = {R[2], R[2]};
        end
        Z2 : begin
            Rwen = (MM_ovalid) ? 6'b010000 : 6'b000000;     //change R4
            Rwdata[4] = MM_result;
            {MM_src1, MM_src2} = {R[2], R[3]};
        end 
        Z3 : begin
            Rwen = (MM_ovalid) ? 6'b001000 : 6'b000000;     //change R3
            Rwdata[3] = MM_result;
            {MM_src1, MM_src2} = {R[3], R[4]};
        end 
        Z4 :begin
            Rwen = (MM_ovalid) ? 6'b001000 : 6'b000000;     //change R3
            Rwdata[3] = MM_result;
            {MM_src1, MM_src2} = {R[3], R[3]};
        end  
        Z5 : begin
            Rwen = (MM_ovalid) ? 6'b000100 : 6'b000000;     //change R2
            Rwdata[2] = MM_result;
            {MM_src1, MM_src2} = {R[2], R[3]};
        end  
        Z6 : begin
            Rwen = (MM_ovalid) ? 6'b001000 : 6'b000000;     //change R3
            Rwdata[3] = MM_result;
            {MM_src1, MM_src2} = {R[3], R[3]};
        end  
        Z7 : begin
            Rwen = (MM_ovalid) ? 6'b001000 : 6'b000000;     //change R3
            Rwdata[3] = MM_result;
            {MM_src1, MM_src2} = {R[2], R[3]};
        end
        SQUARE : begin
            Rwen = (MM_ovalid) ? 6'b100000 : 6'b000000;     //change R5
            Rwdata[5] = MM_result;
            {MM_src1, MM_src2} = {R[5], R[5]};
        end  
        MUL11 : begin
            Rwen = (MM_ovalid) ? 6'b100000 : 6'b000000;     //change R5
            Rwdata[5] = MM_result;
            {MM_src1, MM_src2} = {R[2], R[5]};
        end 
        MUL31 : begin
            Rwen = (MM_ovalid) ? 6'b100000 : 6'b000000;     //change R5
            Rwdata[5] = MM_result;
            {MM_src1, MM_src2} = {R[3], R[5]};
        end 
        REDUCEX1 : begin
            Rwen = (MM_ovalid) ? 6'b000001 : 6'b000000;     //change R0
            Rwdata[0] = MM_result;
            {MM_src1, MM_src2} = {R[0], R[5]};
        end 
        REDUCEX2 : begin
            Rwen = 6'b000001;     //change R0
            Rwdata[0] = MS_result;
            {MS_src1, MS_src2} = {255'd0, R[0]};
        end 
        REDUCEY1 : begin
            Rwen = (MM_ovalid) ? 6'b000010 : 6'b000000;     //change R1
            Rwdata[1] = MM_result;
            {MM_src1, MM_src2} = {R[1], R[5]};
        end  
        REDUCEY2 : begin
            Rwen = 6'b000010;     //change R1
            Rwdata[1] = MS_result;
            {MS_src1, MS_src2} = {255'd0, R[1]};
        end 
    endcase
end



endmodule

