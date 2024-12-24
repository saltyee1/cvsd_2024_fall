module alu#(
    parameter DATA_WIDTH = 32,
    parameter MAN_WIDTH = 23,              
    parameter EXP_WIDTH = 8,                  
    parameter IEEE_COM = 1, 
    parameter F_ADD = 1'b0,
    parameter F_SUB = 1'b1   
)(
    input signed [DATA_WIDTH-1 : 0] i_op1,
    input signed [DATA_WIDTH-1 : 0] i_op2,
    input [2:0] i_func3,
    input [6:0] i_func7,
    input [6:0] i_opcode,
    output reg signed [DATA_WIDTH-1 : 0] o_out,
    output o_exception
);
    logic [DATA_WIDTH-1:0] fp_addsub_result, rounded_fp_addsub_result;
    logic [7:0] fp_addsub_status;
    logic signed [DATA_WIDTH:0] int_addsub_result;
    logic [DATA_WIDTH-1:0] class_result;
    logic fp_addsub_sel;
    logic [EXP_WIDTH-1:0] op1_exp, fp_addsub_exp, rounded_fp_addsub_exp;
    logic [MAN_WIDTH-1:0] op1_man, fp_addsub_man, rounded_fp_addsub_man;
    logic op1_sign, fp_addsub_sign;
    logic int_exc, float_exc, my_fp_exc;     
    logic is_INF_NaN;   
    logic guard_bit, round_bit, sticky_bit, incr_man, incr_exp;
    logic [DATA_WIDTH-1:0] rounded_fp_addsub;
    logic [2:0] rounding_man;
    logic compare_result;

    assign  o_exception = int_exc | float_exc;
    // DW_fp_addsub #(MAN_WIDTH, EXP_WIDTH, IEEE_COM) inst_f_addsub (
    //     .a (i_op1),              
    //     .b (i_op2),             
    //     .op (fp_addsub_sel),    
    //     .rnd (3'd0),         
    //     .z (fp_addsub_result),            
    //     .status (fp_addsub_status)
    // );

    wire [DATA_WIDTH-1:0] my_fp_result;
    FP_addsuber my_fp(
        .src1 (i_op1),
        .src2 (i_op2),
        .op (fp_addsub_sel),
        .result(my_fp_result),
        .exception(my_fp_exc)
    );
    FP_compare my_compare(
        .src1(i_op1),
        .src2(i_op2),
        .smaller(compare_result)
    );
    always@(*) begin
        o_out = 32'd0;
        case (i_opcode)
            //ADD, SUB, SLT, SLL, SRL
            `OP_ADD :  begin
                case (i_func3)
                    3'b000 : o_out = int_addsub_result[DATA_WIDTH-1:0]; //ADD or SUB
                    3'b001 : o_out = i_op1 << i_op2;    //SLL
                    3'b010 : o_out = (i_op1 < i_op2) ? 32'd1 : 32'd0; //SLT
                    3'b101 : o_out = i_op1 >> i_op2;    //SRL
                endcase
            end
            `OP_ADDI : o_out = int_addsub_result[DATA_WIDTH-1:0];
            `OP_LW : o_out = int_addsub_result[DATA_WIDTH-1:0];
            `OP_SW : o_out = int_addsub_result[DATA_WIDTH-1:0];
            `OP_FSW : o_out = int_addsub_result[DATA_WIDTH-1:0];
            `OP_FLW : o_out = int_addsub_result[DATA_WIDTH-1:0];
            `OP_BEQ : o_out = (i_func3 == 3'b000)  ? (i_op1 == i_op2) : (i_op1 < i_op2);
            //FADD, FSUB, FLT, FCLASS
            `OP_FADD : begin 
                case (i_func3) 
                    3'b000 : o_out = (i_func7[5]) ?  class_result : my_fp_result;
                    3'b001 : o_out = compare_result;
                endcase
            end

        endcase
    end
    
    wire dbug1 = ((i_func3==3'b000 && i_opcode==`OP_ADD) || (i_opcode==`OP_ADDI));
    wire dbug2 = (int_addsub_result>33'sh07fffffff);
    always@(*)begin
        int_addsub_result = (i_func7[5] && i_opcode==`OP_SUB) ? (i_op1-i_op2) : (i_op1+i_op2);    //only if op_code is sub and func7=1 do subtraction
        fp_addsub_sel = (i_func3==3'b000&&(!i_func7[2])) ? F_ADD : F_SUB;    //only if FADD do addition
        {op1_sign, op1_exp, op1_man} = i_op1;
        // {fp_addsub_sign, fp_addsub_exp, fp_addsub_man} = fp_addsub_result;

        // is_INF_NaN = (fp_addsub_exp == 8'hff);

        // class_result[0] = (op1_sign) && (op1_exp == 8'hff) && (~|op1_man);           // Negative infinity
        // class_result[1] = (op1_sign) && (op1_exp!=8'h00) && (op1_exp!=8'hff);        // Negative normal number
        // class_result[2] = (op1_sign) && (op1_exp==8'h00) && (|op1_man);              // Negative subnormal
        // class_result[3] = (op1_sign) && (op1_exp==8'h00) && (~|op1_man);             // Negative zero
        // class_result[4] = (~op1_sign) && (op1_exp == 8'h00) && (~|op1_man);          // Positive zero
        // class_result[5] = (~op1_sign) && (op1_exp == 8'h00) && (|op1_man);           // Positive subnormal number
        // class_result[6] = (~op1_sign) && (op1_exp != 8'h00) && (op1_exp != 8'hff);   // Positive normal number
        // class_result[7] = (~op1_sign) && (op1_exp == 8'hff) && (~|op1_man);          // Positive infinity
        // class_result[8] = (op1_exp == 8'hff) && (|op1_man);                          // NaN (Not a Number)
        // class_result[31:9] = 23'd0;
        class_result = 32'd0;

        if((op1_sign) && (op1_exp == 8'hff) && (~|op1_man))            // Negative infinity
            class_result = 32'd0;
        else if ((op1_sign) && (op1_exp != 8'h00) && (op1_exp != 8'hff)) // Negative normal number
            class_result = 32'd1;
        else if ((op1_sign) && (op1_exp == 8'h00) && (|op1_man))         // Negative subnormal
            class_result = 32'd2;
        else if ((op1_sign) && (op1_exp == 8'h00) && (~|op1_man))        // Negative zero
            class_result = 32'd3;
        else if ((~op1_sign) && (op1_exp == 8'h00) && (~|op1_man))       // Positive zero
            class_result = 32'd4;
        else if ((~op1_sign) && (op1_exp == 8'h00) && (|op1_man))        // Positive subnormal
            class_result = 32'd5;
        else if ((~op1_sign) && (op1_exp != 8'h00) && (op1_exp != 8'hff)) // Positive normal number
            class_result = 32'd6;
        else if ((~op1_sign) && (op1_exp == 8'hff) && (~|op1_man))       // Positive infinity
            class_result = 32'd7;
        else if ((op1_exp == 8'hff) && (|op1_man))                       // NaN (Not a Number)
            class_result = 32'd8;

        ///*exception*///
        int_exc = 1'b0;
        if ((i_func3==3'b000 && i_opcode==`OP_ADD) || (i_opcode==`OP_ADDI)) begin //ADD, SUB, ADDI
            int_exc = (int_addsub_result>33'sh07fffffff) || (int_addsub_result<33'sh180000000);
        end
        float_exc = 1'b0;
        if (i_opcode==`OP_FADD) begin
            if(i_func3==3'b001)//FLT
                float_exc = my_fp_exc;
            else if(i_func3==3'b000 && !i_func7[5])//FADD, FSUB
                float_exc = my_fp_exc; 
        end

        ///*floating point round to the nearest even[3]*///
        // guard_bit = fp_addsub_man[20];
        // round_bit = fp_addsub_man[19]; 
        // sticky_bit = |fp_addsub_man[18:0];
        // case ({guard_bit, round_bit, sticky_bit})
        //     3'b000, 3'b001, 3'b010, 3'b100, 3'b101 :  incr_man = 1'b0; 
        //     3'b011, 3'b110, 3'b111 : incr_man = 1'b1;
        // endcase
        // incr_exp = (incr_man && fp_addsub_man[22:20] == 3'b111);    //when rounding to 10.000... exp need to add 1
        // rounding_man = (incr_man) ? (fp_addsub_man[22:20] + 3'b1) : fp_addsub_man[22:20];
        // if (incr_exp) begin
        //     rounded_fp_addsub_exp = fp_addsub_exp+8'd1;
        //     rounded_fp_addsub_man = {rounding_man, 20'd0};
        // end
        // else if (incr_man) begin
        //     rounded_fp_addsub_exp = fp_addsub_exp;
        //     rounded_fp_addsub_man = {rounding_man, 20'd0};
        // end
        //else begin
        //     rounded_fp_addsub_exp = fp_addsub_exp;
        //     rounded_fp_addsub_man = fp_addsub_man;
        // //end
        // rounded_fp_addsub_result = {fp_addsub_sign, rounded_fp_addsub_exp, rounded_fp_addsub_man};
    end
endmodule