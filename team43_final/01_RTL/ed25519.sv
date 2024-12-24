`include "../01_RTL/CSA_sub.v"
// `include "../01_RTL/CPA_sub.v"
`include "../01_RTL/CSA_add.v"
// `include "../01_RTL/CPA_add.v"
`include "../01_RTL/ModSub.v"
`include "../01_RTL/ModAdd.v"
`include "../01_RTL/ModMul.sv"
`include "../01_RTL/point_alu.sv"
module ed25519 (
    input i_clk, 
    input i_rst,
    
    output        o_in_ready,
    input         i_in_valid,
    input  [63:0] i_in_data,

    input         i_out_ready,    
    output        o_out_valid,
    output [63:0] o_out_data
);
//============================================
// paramer
//============================================
    integer i;
    localparam HIGH = 1'b1;
    localparam LOW  = 1'b0;
    
    localparam op_double = 2'b00;
    localparam op_add    = 2'b01;
    localparam op_reduce = 2'b11;

    localparam IDLE    = 4'd0;
    localparam READ_M  = 4'd1;
    localparam READ_PX = 4'd2;
    localparam READ_PY = 4'd3;
    localparam CAL_P2  = 4'd4;
    localparam CAL_P3  = 4'd5;
    localparam CAL_P5  = 4'd6;
    localparam CAL_P6  = 4'd7;
    localparam CAL_P7  = 4'd8;
    localparam MOV_WIN = 4'd9;
    localparam DOUBLE  = 4'd10;
    localparam ADD     = 4'd11;
    localparam REDUCE  = 4'd12;
    localparam LOOP    = 4'd13;
    localparam OUT     = 4'd14;
    localparam ADD_BUF = 4'd15;
    // localparam 
    
//============================================
// declare
//============================================
    // state
    reg [3:0] curr_state, next_state;

    // handshake
        // input
        reg o_in_ready_r;
        reg o_in_ready_rr;
        //output 
        reg o_out_valid_r;
        reg  [ 2:0] out_count;
        wire [63:0] out_data[0:7];
        reg [63:0] out_data_r;

    // input buf
    reg  [ 63:0] in_data_buf;
    reg          in_data_valid;
    reg in_out_ready;

    // M
    reg  [  1:0] counter;
    reg  [ 63:0] M_r[0:3];
    wire [254:0] M;

    // P 
    reg  [ 63:0] P_x [0:3], P_y [0:3];
    wire [764:0] P;
    reg  [764:0] P3, P5, P7;
    
    //r
    reg  [764:0] r;

    // window
    reg  [  7:0] win_position;
    wire [  2:0] window;

    // ALU port
    reg  alu_ivalid;
    wire alu_ovalid;
    reg  [764:0] alu_point1, alu_point2;
    wire [764:0] alu_opoint;
    reg  [  1:0] alu_op;

//============================================
// state machine
//============================================
    always @(posedge i_clk) begin
        if (i_rst) curr_state <=  IDLE;
        else       curr_state <= next_state;
    end
    always @(*) begin
        next_state = IDLE;
        case (curr_state)
            IDLE    : next_state = READ_M;
            READ_M  : next_state = (counter == 2'd3)?  READ_PX : READ_M;
            READ_PX : next_state = (counter == 2'd3)?  READ_PY : READ_PX;
            READ_PY : next_state = (counter == 2'd3)?  CAL_P2  : READ_PY;
            CAL_P2  : next_state = (alu_ovalid)?  CAL_P3 : CAL_P2;
            CAL_P3  : next_state = (alu_ovalid)?  CAL_P5 : CAL_P3;
            CAL_P5  : next_state = (alu_ovalid)?  CAL_P6 : CAL_P5;
            CAL_P6  : next_state = (alu_ovalid)?  CAL_P7 : CAL_P6;
            CAL_P7  : next_state = (alu_ovalid)?  LOOP   : CAL_P7;
            MOV_WIN : next_state = (win_position!=8'd2)?   LOOP : REDUCE;
            LOOP    :begin 
                case (counter)
                    2'd0:begin
                        next_state = DOUBLE;
                    end
                    2'd1:begin
                        case (window)
                            3'd4: next_state = ADD; 
                            default:  next_state = DOUBLE;
                        endcase
                    end
                    2'd2:begin
                        case (window)
                            3'd2, 3'd6: next_state = ADD;
                            default:  next_state = DOUBLE;
                        endcase
                    end
                    2'd3: begin
                        case (window)
                            3'd0: next_state = ADD_BUF;
                            3'd2, 3'd4, 3'd6: next_state = DOUBLE;
                            default:  next_state = ADD;
                        endcase
                    end
                endcase
            end
            ADD_BUF: begin
                if (counter==2'd0)  next_state = MOV_WIN;                 
                else                next_state = LOOP;
            end
            DOUBLE : begin
                if (counter==2'd0)  next_state = (alu_ovalid)?  MOV_WIN : DOUBLE;                 
                else                next_state = (alu_ovalid)?  LOOP    : DOUBLE;
            end
            ADD    : begin
                if (counter==2'd0)  next_state = (alu_ovalid)?  MOV_WIN : ADD;                 
                else                next_state = (alu_ovalid)?  LOOP    : ADD;
            end
            REDUCE : next_state = (alu_ovalid)?  OUT  : REDUCE;
            OUT    : next_state = OUT;
        endcase
    end

//============================================
// handshake
//============================================
    // input 
    assign o_in_ready = o_in_ready_r;
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_in_ready_r <= LOW;
            o_in_ready_rr <= LOW;
        end else begin
            case (curr_state)
                READ_M, READ_PX, READ_PY: 
                    o_in_ready_r <= HIGH;
                default: 
                    o_in_ready_r <= LOW; 
            endcase
            o_in_ready_rr <= o_in_ready_r;
        end 
    end
    // output
    assign o_out_valid = o_out_valid_r;
    always @(posedge i_clk) begin
        if (i_rst) o_out_valid_r <= LOW; 
        else if (curr_state==OUT) o_out_valid_r <=  HIGH;
    end
    always @(posedge i_clk) begin
        if (i_rst) begin 
            out_count <= 3'd0;
            // out_data_r<= 64'd0;
        end
        else if (curr_state==OUT && i_out_ready && o_out_valid_r) begin
            out_count <= out_count + 3'd1;
            // out_data_r <= out_data[out_count + 3'd1];
        end
    end
    always @(posedge i_clk) begin
        if (i_rst) begin
            out_data_r<= 64'd0;
        end
        else begin
            out_data_r <= (curr_state==OUT && i_out_ready && o_out_valid_r) ? out_data[out_count + 3'd1] : out_data[out_count];
        end
    end
    assign o_out_data = out_data_r;
    // x
    assign out_data[0] = {1'b0, r[764:702]};
    assign out_data[1] =        r[701:638] ;
    assign out_data[2] =        r[637:574] ;
    assign out_data[3] =        r[573:510] ;   
    // y
    assign out_data[4] = {1'b0, r[509:447]}; 
    assign out_data[5] =        r[448:383] ; 
    assign out_data[6] =        r[382:319] ;
    assign out_data[7] =        r[318:255] ;


//============================================
// input buf
//============================================
    always @(posedge i_clk) begin
        if (i_rst) begin
            in_data_buf   <= 64'd0;
            in_data_valid <= LOW; 
        end else begin
            in_data_buf   <= i_in_data;
            in_data_valid <= i_in_valid;
        end
    end

//============================================
// counter for READ and window OP
//============================================
    always @(posedge i_clk) begin
        if (i_rst) begin
            counter <= 2'd0;
        end else begin
            case (curr_state)
                READ_M, READ_PX, READ_PY: begin
                    if (in_data_valid && o_in_ready_rr) counter <= counter + 2'd1;
                end
                LOOP:begin
                    counter <= counter + 2'd1;
                end
            endcase
        end
    end

//============================================
// M
//============================================
    always @(posedge i_clk) begin
        if (i_rst) begin
            for ( i=0; i<4 ;  i = i+1) begin
                M_r[i] <= 64'd0;
            end
        end else if (curr_state == READ_M) begin
            if (in_data_valid && o_in_ready_rr) M_r[counter] <= in_data_buf;
        end
    end
    assign M = {M_r[0][62:0], M_r[1], M_r[2], M_r[3]};

//============================================
// P
//============================================
    always @(posedge i_clk) begin
        if (i_rst) begin
            for ( i=0; i<4 ;  i = i+1) begin
                P_x[i] <= 64'd0;
                P_y[i] <= 64'd0;
            end
        end else if (in_data_valid && o_in_ready_rr) begin
            if (curr_state == READ_PX) P_x[counter] <= in_data_buf;
            if (curr_state == READ_PY) P_y[counter] <= in_data_buf;
        end
    end

    assign P = {P_x[0][62:0], P_x[1], P_x[2], P_x[3],
                P_y[0][62:0], P_y[1], P_y[2], P_y[3],
                255'd1};

//============================================
// P3, P5, P7
//============================================
    always @(posedge i_clk) begin
        if (i_rst) begin
            P3 <= 765'd0;
            P5 <= 765'd0;
            P7 <= 765'd0;
        end else if(alu_ovalid) begin
            if (curr_state == CAL_P3) P3 <= alu_opoint;
            if (curr_state == CAL_P2 || curr_state == CAL_P5) P5 <= alu_opoint;
            if (curr_state == CAL_P6 || curr_state == CAL_P7) P7 <= alu_opoint;
        end
    end

//============================================
// r
//============================================
    always @(posedge i_clk) begin
        if (i_rst) r <= {255'd0, 255'd1, 255'd1};
        else if (alu_ovalid) begin
            case (curr_state)
                ADD, DOUBLE, REDUCE: r <= alu_opoint; 
                default: r <= r;
            endcase
        end 
    end

//============================================
// window 
//============================================
    always @(posedge i_clk) begin
        if (i_rst) win_position <= 8'd254;
        else if (curr_state==MOV_WIN && win_position!=8'd2) win_position <= win_position - 8'd3;
    end

    assign window = M[win_position -: 3];

//============================================
// ALU
//============================================
    point_alu ed25519_alu(
        .i_clk(i_clk), .i_rst(i_rst),
        .ivalid(alu_ivalid), .op(alu_op),
        .point1(alu_point1), .point2(alu_point2),
        .ovalid(alu_ovalid), .opoint(alu_opoint)
    );

    always @(*) begin
        alu_point1 = P;
        alu_point2 = P;
        alu_op     = op_double;
        case (curr_state)
            CAL_P2:begin
               alu_point1 = P;
               alu_op     = op_double; 
            end
            CAL_P3:begin
                alu_point1 = P;
                alu_point2 = P5;    // now P5==P2;
                alu_op     = op_add;
            end
            CAL_P5:begin
                alu_point1 = P5;    // now P5==P2;
                alu_point2 = P3;    
                alu_op     = op_add;
            end 
            CAL_P6:begin
                alu_point1 = P3;    
                alu_op     = op_double;
            end
            CAL_P7:begin
                alu_point1 = P;
                alu_point2 = P7;    // now P7==P6;
                alu_op     = op_add;
            end
            DOUBLE:begin
                alu_point1 = r;
                alu_op = op_double;
            end
            ADD:begin
                alu_point1 = r;
                alu_op = op_add;
                case (window)
                    3'd1, 3'd2, 3'd4: 
                        alu_point2 = P;
                    3'd3, 3'd6: 
                        alu_point2 = P3;
                    3'd5:
                        alu_point2 = P5;
                    3'd7:
                        alu_point2 = P7;
                endcase
            end
            REDUCE:begin
                alu_point1 = r;
                alu_op = op_reduce;
            end
        endcase 
    end

    always @(posedge i_clk) begin
        if (i_rst) 
            alu_ivalid <= LOW;
        else if (curr_state != next_state) begin
            // if (curr_state!=IDLE && curr_state!=READ_M && curr_state!=READ_PX && 
            //     curr_state!=CAL_P7 && curr_state!=MOV_WIN && curr_state!=DOUBLE && curr_state!=ADD) 
            //     alu_ivalid <= HIGH;
            case (curr_state)
                READ_PY, CAL_P2, CAL_P3, CAL_P5, CAL_P6, LOOP: 
                    if(next_state!=ADD_BUF) alu_ivalid <= HIGH;
                MOV_WIN:
                    if(next_state==REDUCE) alu_ivalid <= HIGH; 
                default:  
                    alu_ivalid <= LOW;
            endcase
        end else begin
            alu_ivalid <= LOW;
        end
    end
//============================================
// test
//============================================
    wire [254:0] P3_x, P3_y, P3_z, P5_x, P5_y, P5_z, P7_x, P7_y, P7_z;
    assign P3_x = P3[764:510]; assign P3_y = P3[509:255]; assign P3_z = P3[254:0];
    assign P5_x = P5[764:510]; assign P5_y = P5[509:255]; assign P5_z = P5[254:0];
    assign P7_x = P7[764:510]; assign P7_y = P7[509:255]; assign P7_z = P7[254:0];

    wire [254:0] alu_p1_x, alu_p1_y, alu_p1_z, alu_p2_x, alu_p2_y, alu_p2_z;
    assign alu_p1_x = alu_point1[764:510];assign alu_p1_y = alu_point1[509:255];assign alu_p1_z = alu_point1[254:0];
    assign alu_p2_x = alu_point2[764:510];assign alu_p2_y = alu_point2[509:255];assign alu_p2_z = alu_point2[254:0];
    
    wire [254:0] alu_opoint_x, alu_opoint_y, alu_opoint_z;
    assign alu_opoint_x = alu_opoint[764:510];
    assign alu_opoint_y = alu_opoint[509:255];
    assign alu_opoint_z = alu_opoint[254:  0];

    wire [254:0] r_x, r_y, r_z;
    assign r_x = r[764:510];
    assign r_y = r[509:255];
    assign r_z = r[254:  0];

endmodule
