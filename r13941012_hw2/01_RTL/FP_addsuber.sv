module FP_addsuber (
    input [31:0] src1, 
    input [31:0] src2,
    input  op,  //1 for sub, 0 for add
    output reg [31:0] result,
    output reg exception
);
wire src1_sign = src1[31];
wire src2_sign = src2[31];
wire [7:0] src1_exp = src1[30:23]; 
wire [7:0] src2_exp = src2[30:23];
wire [22:0] src1_man = src1[22:0]; 
wire [22:0] src2_man = src2[22:0]; 
logic [48:0] man_result49;
logic [47:0] norm_man_result48;
logic [48:0] to_round_man48;
logic [5:0] norm_shiftamt;
logic [7:0] max_shiftamt;
wire [48:0] sr1_man49 = man_result49 >> 1;
wire [47:0] slmax_man48 = man_result49[47:0] << max_shiftamt;
wire [47:0] slamt_man48 = man_result49[47:0] << norm_shiftamt;
logic [24:0] man_result25;
logic [63:0] man_result64;
logic result_sign;
logic [47:0] shifted_man, n_shifted_man;
logic [7:0] exp_diff;
logic [7:0] bigger_exp;
logic src1_abs_bigger;
wire guard_bit = to_round_man48[24];
wire round_bit = to_round_man48[23];
wire sticky_bit = |to_round_man48[22:0];
wire p_add_p = (!op && !src1_sign && !src2_sign);
wire n_add_n = (!op && src1_sign && src2_sign);
wire p_add_n = (!op && !src1_sign && src2_sign);
wire n_add_p = (!op && src1_sign && !src2_sign);
wire p_sub_p = (op && !src1_sign && !src2_sign);
wire n_sub_n = (op && src1_sign && src2_sign);
wire p_sub_n = (op && !src1_sign && src2_sign);
wire n_sub_p = (op && src1_sign && !src2_sign);


logic incr_man, incr_exp, renorm_incr_man, renorm_incr_exp;
logic [22:0] result_man;
logic [7:0] result_exp;
logic [15:0] clz16;
logic [7:0] clz8;
logic [3:0] clz4;
logic [5:0] clz_result;

wire src1_zero = (src1_exp==8'd0 && src1_man==23'd0);
wire src2_zero = (src2_exp==8'd0 && src2_man==23'd0);
wire is_same = (src1_exp==src2_exp && src1_man==src2_man);

Left_Shift_To_Msb msb1 (.i_data(man_result49[47:0]), .o_data(norm_man_result48), .shift_amount(norm_shiftamt));
//Left_Shift_To_Msb msb2 (.i_data(norm_man_result48), .o_data(renorm_man_result48), .shift_amount(renorm_shiftamt));

always@(*) begin
    exception = 1'b0;
    exception = (src1_exp == 8'd255 || src2_exp == 8'd255);    //input is +-INF or NaN is an excetion
    if (src1_exp> src2_exp) begin
        src1_abs_bigger = 1'b1;
    end
    else if (src1_exp == src2_exp) begin
        src1_abs_bigger = (src1_man > src2_man);
    end
    else begin
        src1_abs_bigger = 1'b0;
    end

    if (src1_abs_bigger) begin
        exp_diff = src1_exp - src2_exp;
        bigger_exp = src1_exp;
        if (src2_exp==8'd0) begin
            shifted_man = (src1_exp==8'd0) ? {1'b0, src2_man, 24'b0} : ({1'b0, src2_man, 24'b0} >> (exp_diff-8'd1));
        end
        else begin
            shifted_man = ({1'b1, src2_man, 24'b0} >> exp_diff);
        end
        // shifted_man = (src2_exp==8'd0) ? ({1'b0, src2_man, 24'b0} >> (exp_diff-8'd1)) : ({1'b1, src2_man, 24'b0} >> exp_diff);
        n_shifted_man = (src1_exp==8'd0) ?  {1'b0, src1_man, 24'b0} :{1'b1, src1_man, 24'b0};
    end
    else begin
        exp_diff = src2_exp - src1_exp;
        bigger_exp = src2_exp;
        if (src1_exp==8'd0) begin
            shifted_man = (src2_exp==8'd0) ? {1'b0, src1_man, 24'b0} : ({1'b0, src1_man, 24'b0} >> (exp_diff-8'd1));
        end
        else begin
            shifted_man = ({1'b1, src1_man, 24'b0} >> exp_diff);
        end
        // shifted_man = (src1_exp==8'd0) ? ({1'b0, src1_man, 24'b0} >> (exp_diff-8'd1)) : ({1'b1, src1_man, 24'b0} >> exp_diff);
        n_shifted_man = (src2_exp==8'd0) ? {1'b0, src2_man, 24'b0} : {1'b1, src2_man, 24'b0};
    end

    if (src1_zero && src2_zero) begin
        result_sign = 1'b0;
    end
    else if(p_add_p || p_sub_n) begin
        result_sign = 1'b0;
    end
    else if (n_add_n || n_sub_p) begin
        result_sign = 1'b1;
    end
    else if (p_add_n || p_sub_p) begin
        result_sign = (src1_abs_bigger || is_same) ? 1'b0 : 1'b1; 
    end
    else begin
        result_sign = (src1_abs_bigger && !is_same) ? 1'b1 : 1'b0;
    end

    max_shiftamt =(bigger_exp == 8'd0) ? 8'd0 : bigger_exp - 8'd1;

    if (!op) begin //fadd
        man_result49 = (src1_sign==src2_sign) ? n_shifted_man + shifted_man : n_shifted_man - shifted_man;    //if same sign, do add
    end
    else begin //fsub
        man_result49 = (src1_sign!=src2_sign) ? n_shifted_man + shifted_man : n_shifted_man - shifted_man;    //if diff sign, do add
    end

    incr_exp = man_result49[48];

    if(incr_exp) begin
        to_round_man48 = (bigger_exp == 8'd254) ? 48'h800000000000 : sr1_man49[47:0]; //INFT 
        result_exp = bigger_exp + 8'd1;
        exception = (result_exp == 8'd255);
    end
    else if ({2'b0, norm_shiftamt} >= max_shiftamt) begin   //////////////
        to_round_man48 = man_result49[47:0] << max_shiftamt;
        result_exp = (to_round_man48[47]) ? 8'd1 : 8'd0;    //normal or subnormal
    end
    else begin
        to_round_man48 = man_result49[47:0] << norm_shiftamt;
        result_exp = (man_result49==49'd0) ? 8'd0 : bigger_exp - norm_shiftamt;
    end

    case ({guard_bit, round_bit, sticky_bit})
        3'b000, 3'b001, 3'b010, 3'b100, 3'b101 :  incr_man = 1'b0; 
        3'b011, 3'b110, 3'b111 : incr_man = 1'b1;
    endcase
    result_man = (incr_man) ? to_round_man48[46:24]+23'd1 : to_round_man48[46:24];

    result = {result_sign, result_exp, result_man};


end

endmodule