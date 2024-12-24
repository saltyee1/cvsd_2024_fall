module DMA (
    input [10:0] i_counter,
    input [1:0] i_mode,
    input [5:0] i_origin,
    output reg [7:0] o_mem_addr,
    output reg [2:0] o_mem_sel,
    output reg o_zero
);
localparam mode_load = 2'd0;
localparam mode_display = 2'd1;
localparam mode_conv = 2'd2;

reg [10:0] display_offset;      
reg signed [8:0] conv_offset; //extend 1 bit
wire [2:0] origin_row = i_origin[5:3];
wire [2:0] origin_col = i_origin[2:0];
wire [5:0] conv_origin = i_origin[5:0] - 6'd9;
wire bound_left = origin_col==3'd0;
wire bound_right = origin_col==3'd6;
wire bound_top = origin_row==3'd0;
wire bound_bottom = origin_row==3'd6;
wire bound_left_top = origin_col==3'd0 && origin_row==3'd0;
wire bound_left_bottom = origin_col==3'd0 && origin_row==3'd6;
wire bound_right_top = origin_col==3'd6 && origin_row==3'd0;
wire bound_right_bottom = origin_col==3'd6 && origin_row==3'd6;

always @(*) begin
    o_mem_addr = 8'd0;
    o_mem_sel = 3'd0;
    o_zero = 1'b0;
    display_offset = {i_counter[6:2], 2'b0, i_counter[1], 2'b0, i_counter[0]}; //0,1,8,9,64,65,66,67,128,129,130,131...
    conv_offset = $signed({1'b0, i_counter[5:4], 1'b0, i_counter[3:2], 1'b0, i_counter[1:0]}) - 9'sd9;//0,1,2,3,8,9,10,11,16,17,18,19...
    case (i_mode)
        mode_load : begin
            {o_mem_sel, o_mem_addr} = i_counter;
        end 
        mode_display : begin
            {o_mem_sel, o_mem_addr} = i_origin + display_offset;
        end
        mode_conv : begin
            case(1'b1)
                bound_left_top : o_zero = (i_counter[1:0] == 2'd0) || (i_counter[3:0] < 4'd4);
                bound_left_bottom : o_zero = (i_counter[1:0] == 2'd0) || (i_counter[3:0] > 4'd11);
                bound_right_top : o_zero = (i_counter[1:0] == 2'd3)|| (i_counter[3:0] < 4'd4);
                bound_right_bottom : o_zero = (i_counter[1:0] == 2'd3) || (i_counter[3:0] > 4'd11);
                bound_top : o_zero = (i_counter[3:0] < 4'd4);
                bound_bottom : o_zero = (i_counter[3:0] > 4'd11);
                bound_left : o_zero = (i_counter[1:0] == 2'd0);
                bound_right : o_zero = (i_counter[1:0] == 2'd3);
            endcase
            {o_mem_sel, o_mem_addr} = $signed({1'b0, i_origin}) + conv_offset;
        end
    endcase
end
endmodule