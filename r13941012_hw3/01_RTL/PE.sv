// `include "define.sv"
module PE (
    input i_clk,
    input i_rst_n,
    input i_en,
    input i_clear,
    input [3:0] i_mode,
    input [7:0] i_data,
    input [7:0] i_data0,
    input [63:0] i_data_arr, 
    output [7:0] o_median,
    output reg [13:0] o_conv_result,    
    output [11:0] o_gradient,   
    output reg [1:0] o_direction
);
integer i;
reg [16:0] conv_sum_r;
reg [16:0] conv_result_r;
reg [13:0] conv_result_round_r;
reg [3:0] ext_array [0:7];
reg [7:0] array [0:8];
reg [11:0] array_conv_n [0:7]; 
reg [16:0] conv_sum_n;
reg en_r, en_rr;
reg [2:0] kernal_x [0:8];
reg [2:0] kernal_y [0:8];
reg signed[16:0] tanx1_sum;
reg signed[11:0] tanx1_n, tanx1_r;
reg signed [11:0] tanx2_n, tanx2_r;
reg signed [11:0] gx_n, gx_r;
reg gx_sign_rr;
reg [11:0] gx_abs;
reg [11:0] gy_abs;
reg signed [11:0] gy_n, gy_r, gy_rr;
reg signed [13:0] gxtan22_5, gxtan67_5, gxtan112_5, gxtan157_5;
reg [11:0] g_n, g_r, g_rr;
reg sticky_bit;
assign o_median = array[4];
assign o_gradient = g_rr;


// when doing median arr is 8bit * 9
// doing conv arr is 12bit*8
reg [3:0] angle_range; 
reg [9:0] range;

always @(*) begin
    range[0] = (i_data < array[0]);
    range[1] = (i_data < array[1]) && (i_data >= array[0]);
    range[2] = (i_data < array[2]) && (i_data >= array[1]);
    range[3] = (i_data < array[3]) && (i_data >= array[2]);
    range[4] = (i_data < array[4]) && (i_data >= array[3]);
    range[5] = (i_data < array[5]) && (i_data >= array[4]);
    range[6] = (i_data < array[6]) && (i_data >= array[5]);
    range[7] = (i_data < array[7]) && (i_data >= array[6]);
    range[8] = (i_data < array[8]) && (i_data >= array[7]);
    range[9] = (i_data >= array[8]);


    if (!gx_sign_rr) begin
        angle_range[0] = ($signed({gy_rr, 1'b0}) > gxtan157_5) && ($signed({gy_rr, 1'b0}) < gxtan22_5);     //0
        angle_range[1] = ($signed({gy_rr, 1'b0}) >= gxtan22_5) && ($signed({gy_rr, 1'b0}) <= gxtan67_5);    //45
        angle_range[2] = ($signed({gy_rr, 1'b0}) > gxtan67_5) || ($signed({gy_rr, 1'b0}) < gxtan112_5);     //90
        angle_range[3] = ($signed({gy_rr, 1'b0}) >= gxtan112_5) && ($signed({gy_rr, 1'b0}) <= gxtan157_5);  //135
    end
    else begin
        angle_range[0] = ($signed({gy_rr, 1'b0}) < gxtan157_5) && ($signed({gy_rr, 1'b0}) > gxtan22_5);     //0
        angle_range[1] = ($signed({gy_rr, 1'b0}) <= gxtan22_5) && ($signed({gy_rr, 1'b0}) >= gxtan67_5);    //45
        angle_range[2] = ($signed({gy_rr, 1'b0}) < gxtan67_5) || ($signed({gy_rr, 1'b0}) > gxtan112_5);     //90
        angle_range[3] = ($signed({gy_rr, 1'b0}) <= gxtan112_5) && ($signed({gy_rr, 1'b0}) >= gxtan157_5);  //135
    end
    case(1'b1) 
        angle_range[0] : o_direction = 2'd0;
        angle_range[1] : o_direction = 2'd1;
        angle_range[2] : o_direction = 2'd2;
        angle_range[3] : o_direction = 2'd3;
        default : o_direction = 2'd0;
    endcase
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        for (i = 0; i < 9; i = i + 1)
            array[i] <= 8'd0;
        for (i=0; i<8; i=i+1) 
            ext_array[i] <= 4'd0;
    end
    else if (i_clear) begin
        if (i_mode == `PE_NMS0) begin
            for (i = 0; i < 3; i = i + 1)   //Do not flush pipeline reg
                array[i] <= 8'd0;
            for (i=0; i<3; i=i+1) 
                ext_array[i] <= 4'd0;
            {ext_array[3], array[3]} <= tanx1_n;
            {ext_array[4], array[4]} <= tanx2_n;
            {ext_array[5], array[5]} <= {ext_array[2], array[2]};   //pipeline register for G
            {ext_array[6], array[6]} <= {ext_array[1], array[1]};   //pipeline register gor Gy 
        end
        else begin
            for (i = 0; i < 9; i = i + 1)
                array[i] <= 8'd0;
            for (i=0; i<8; i=i+1) 
                ext_array[i] <= 4'd0;
        end
    end
    else begin
        case (i_mode)
            `PE_MED : begin
                if (i_en) begin
                    if (range[9]) begin
                        array[8] <= i_data;
                        for (i = 0; i < 8; i = i + 1)
                            array[i] <= array[i + 1];
                    end
                    else if (range[8]) begin
                        array[7] <= i_data;
                        for (i = 0; i < 7; i = i + 1)
                            array[i] <= array[i + 1];
                    end
                    else if (range[7]) begin
                        array[6] <= i_data;
                        for (i = 0; i < 6; i = i + 1)
                            array[i] <= array[i + 1];
                    end
                    else if (range[6]) begin
                        array[5] <= i_data;
                        for (i = 0; i < 5; i = i + 1)
                            array[i] <= array[i + 1];
                    end
                    else if (range[5]) begin
                        array[4] <= i_data;
                        for (i = 0; i < 4; i = i + 1)
                            array[i] <= array[i + 1];
                    end
                    else if (range[4]) begin
                        array[3] <= i_data;
                        for (i = 0; i < 3; i = i + 1)
                            array[i] <= array[i + 1];
                    end
                    else if (range[3]) begin
                        array[2] <= i_data;
                        for (i = 0; i < 2; i = i + 1)
                            array[i] <= array[i + 1];
                    end
                    else if (range[2]) begin
                        array[1] <= i_data;
                        array[0] <= array[1];
                    end
                    else if (range[1]) begin
                        array[0] <= i_data;
                    end
                end
            end
            `PE_CONV1_16, `PE_CONV1_8, `PE_CONV1_4 : begin
                if (i_en) begin
                    for (i=0; i<8; i=i+1) begin
                        {ext_array[i], array[i]} <= array_conv_n[i];
                    end
                end
            end
            `PE_NMS0 : begin
                if (i_en) begin
                    array[8] <= i_data0;
                end
                if (en_r) begin
                    {ext_array[0], array[0]} <= gx_n;
                    {ext_array[1], array[1]} <= gy_n;
                    {ext_array[2], array[2]} <= g_n;
                end
                {ext_array[3], array[3]} <= tanx1_n;
                {ext_array[4], array[4]} <= tanx2_n;
                {ext_array[5], array[5]} <= {ext_array[2], array[2]};   //pipeline register for G
                {ext_array[6], array[6]} <= {ext_array[1], array[1]};   //pipeline register gor Gy 
            end
        endcase
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        en_r <= 1'b0;
        en_rr <= 1'b0;
        conv_sum_r <= 17'd0;
        conv_result_r <= 17'b0;
        conv_result_round_r <= 14'd0;
        gx_sign_rr <= 1'b0;
    end
    else begin
        en_r <= i_en;
        en_rr <= en_r;
        if (i_clear) begin
            conv_sum_r <= 17'd0;
            conv_result_r <= 17'd0;
            conv_result_round_r <= 14'd0;
        end
        else begin
            conv_sum_r <= conv_sum_n;
            conv_result_r <= (en_rr) ? conv_result_r + conv_sum_r : conv_result_r;
            conv_result_round_r <= (conv_result_r[3]) ? (conv_result_r[16:4] + 14'd1) : {1'b0, conv_result_r[16:4]};
        end
        gx_sign_rr <= gx_r[11];
    end
end


//kernal for gradient
always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        kernal_x[0] <= -3'sd1; kernal_x[1] <= 3'sd0; kernal_x[2] <= 3'sd1;
        kernal_x[3] <= -3'sd2; kernal_x[4] <= 3'sd0; kernal_x[5] <= 3'sd2;
        kernal_x[6] <= -3'sd1; kernal_x[7] <= 3'sd0; kernal_x[8] <= 3'sd1;
        kernal_y[0] <= -3'sd1; kernal_y[1] <= -3'sd2; kernal_y[2] <= -3'sd1;
        kernal_y[3] <= 3'sd0; kernal_y[4] <= 3'sd0; kernal_y[5] <= 3'sd0;
        kernal_y[6] <= 3'sd1; kernal_y[7] <= 3'sd2; kernal_y[8] <= 3'sd1;
    end
    else if (i_clear) begin
        kernal_x[0] <= -3'sd1; kernal_x[1] <= 3'sd0; kernal_x[2] <= 3'sd1;
        kernal_x[3] <= -3'sd2; kernal_x[4] <= 3'sd0; kernal_x[5] <= 3'sd2;
        kernal_x[6] <= -3'sd1; kernal_x[7] <= 3'sd0; kernal_x[8] <= 3'sd1;
        kernal_y[0] <= -3'sd1; kernal_y[1] <= -3'sd2; kernal_y[2] <= -3'sd1;
        kernal_y[3] <= 3'sd0; kernal_y[4] <= 3'sd0; kernal_y[5] <= 3'sd0;
        kernal_y[6] <= 3'sd1; kernal_y[7] <= 3'sd2; kernal_y[8] <= 3'sd1;
    end
    else if (en_r && i_mode==`PE_NMS0) begin
        for (i = 0; i < 8 ; i = i+1) begin
            kernal_x[i] <= kernal_x[i+1];
            kernal_y[i] <= kernal_y[i+1];
        end
        kernal_x[8] <= kernal_x[0];
        kernal_y[8] <= kernal_y[0];
    end
end

integer j;
always @(*) begin
    for (j=0; j<8; j=j+1) begin
        array_conv_n[j] = 12'd0;
        if (i_mode==`PE_CONV1_16) 
            array_conv_n[j] = {4'b0, i_data_arr[j*8 +:8]};
        else if (i_mode==`PE_CONV1_8)
            array_conv_n[j] = {3'b0, i_data_arr[j*8 +:8], 1'b0};
        else if (i_mode==`PE_CONV1_4)
            array_conv_n[j] = {2'b0, i_data_arr[j*8 +:8], 2'b0};
    end

    conv_sum_n = (  {ext_array[0], array[0]} +
                    {ext_array[1], array[1]} +
                    {ext_array[2], array[2]} +
                    {ext_array[3], array[3]} +
                    {ext_array[4], array[4]} +
                    {ext_array[5], array[5]} +
                    {ext_array[6], array[6]} +
                    {ext_array[7], array[7]});

    o_conv_result = conv_result_round_r;

    gx_r = {ext_array[0], array[0]};
    gy_r = {ext_array[1], array[1]};
    gy_rr = {ext_array[6], array[6]};
    g_r = {ext_array[2], array[2]};
    g_rr = {ext_array[5], array[5]};
    tanx1_r = {ext_array[3], array[3]};
    tanx2_r = {ext_array[4], array[4]};

    gx_n = gx_r;
    gy_n = gy_r;
    case (kernal_x[0]) 
        -3'sd2 : gx_n = gx_r - $signed({1'b0, array[8], 1'b0}); 
        -3'sd1 : gx_n = gx_r - $signed({1'b0, array[8]});
        3'sd0 : gx_n = gx_r;
        3'sd1 : gx_n = gx_r + $signed({1'b0, array[8]});
        3'sd2 : gx_n = gx_r + $signed({1'b0, array[8], 1'b0}); 
    endcase
    case (kernal_y[0])
        -3'sd2 : gy_n = gy_r - $signed({1'b0, array[8], 1'b0}); 
        -3'sd1 : gy_n = gy_r - $signed({1'b0, array[8]});
        3'sd0 : gy_n = gy_r;
        3'sd1 : gy_n = gy_r + $signed({1'b0, array[8]});
        3'sd2 : gy_n = gy_r + $signed({1'b0, array[8], 1'b0}); 
    endcase
    // case (kernal_x[0])
    //     -3'sd2, 3'sd2 : gx_abs = {array[8], 1'b0};
    //     -3'sd1, 3'sd1 : gx_abs = {1'b0, array[8]};
    //     3'sd0 :  gx_abs = 9'd0;
    // endcase
    // case (kernal_y[0])
    //     -3'sd2, 3'sd2 : gy_abs = {array[8], 1'b0};
    //     -3'sd1, 3'sd1 : gy_abs = {1'b0, array[8]};
    //     3'sd0 :  gy_abs = 9'd0;
    // endcase
    
    gx_abs = (gx_n[11]) ? -gx_n : gx_n;
    gy_abs = (gy_n[11]) ? -gy_n : gy_n;
    g_n = gx_abs + gy_abs;

    //17bit = 16bit + 15bit + 13bit + 11bit
    tanx1_sum = $signed({gx_r[10:0], 5'd0}) + $signed({gx_r[10:0], 4'd0}) + $signed({gx_r[10:0], 2'd0}) + $signed({gx_r[10:0]});
    //12bit
    sticky_bit = |tanx1_sum[6:0];
    tanx1_n = $signed({tanx1_sum[16:7], sticky_bit});  //{10'b int, 1'b man}
    tanx2_n = $signed({gx_r[10:0], 1'b0});

    gxtan22_5 = tanx1_r;
    //14bit = 11bit + 13bit
    gxtan67_5 = $signed(tanx1_r[10:0]) + $signed({tanx2_r, 1'd0});
    gxtan112_5 = -gxtan67_5;
    gxtan157_5 = -gxtan22_5;
end


//debugging
// reg [7:0] debug_p0;
// reg [7:0] debug_in_arr [0:7];
// reg [11:0] debug_conv_arr [0:7];
// always @(*) begin
//     for (i=0; i<8; i=i+1) begin
//         debug_conv_arr[i] = {ext_array[i], array[i]};
//     end
//     debug_p0 = array[8];
// end


endmodule