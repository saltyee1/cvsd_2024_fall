module FP_compare(
    input [31:0] src1,
    input [31:0] src2,
    output reg smaller
);
wire src1_sign = src1[31];
wire src2_sign = src2[31];
wire [7:0] src1_exp = src1[30:23]; 
wire [7:0] src2_exp = src2[30:23];
wire [22:0] src1_man = src1[22:0]; 
wire [22:0] src2_man = src2[22:0]; 
wire src1_zero = (src1_exp==8'd0 && src1_man==23'd0);
wire src2_zero = (src2_exp==8'd0 && src2_man==23'd0);
wire is_same = (src1_exp==src2_exp && src1_man==src2_man);

always @(*) begin
    if (src1_zero && src2_zero) begin
        smaller = 1'b0;
    end
    else begin
        case ({src1_sign, src2_sign})
            2'b00 : begin
                if (src1_exp < src2_exp)begin
                    smaller = 1'b1;
                end
                else if (src1_exp == src2_exp) begin
                    smaller = (src1_man < src2_man);    //note that src1_man==src2_man => 1'b0 
                end
                else begin
                    smaller = 1'b0;
                end
            end
            2'b11 : begin
                if (src1_exp < src2_exp)begin
                    smaller = 1'b0;
                end
                else if (src1_exp == src2_exp) begin
                    smaller = (src1_man > src2_man);    //note that src1_man==src2_man => 1'b0
                end
                else begin
                    smaller = 1'b1;
                end
            end
            2'b01 : smaller = 1'b0;
            2'b10 : smaller = 1'b1;
        endcase
    end
end
endmodule