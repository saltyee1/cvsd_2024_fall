module alu #(
    parameter INST_W = 4,
    parameter INT_W  = 6,
    parameter FRAC_W = 10,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                      i_clk,
    input                      i_rst_n,

    input                      i_in_valid,
    output                     o_busy,
    input         [INST_W-1:0] i_inst,
    input  signed [DATA_W-1:0] i_data_a,
    input  signed [DATA_W-1:0] i_data_b,

    output                     o_out_valid,
    output        [DATA_W-1:0] o_data
);

// Local Parameters
localparam SADD = 4'd0; //Signed Addition
localparam SSUB = 4'd1; //Signed Subtraction
localparam SMUL = 4'd2; //Signed Multiplication
localparam SACC = 4'd3; //Signed Accumulation
localparam SOFT = 4'd4; //Softplus
localparam XOR = 4'd5;  //Xor
localparam ARSH = 4'd6; //Arithmetic Right Shift
localparam LROT = 4'd7; //Left Rotation
localparam CLZ = 4'd8;  //Count Leading Zero
localparam RM4 = 4'd9;  //Reverse Match4
localparam MEM_H = 16;  //accumulation memory size
integer i;

localparam RANGE1 = 6'b100000;
localparam RANGE2 = 6'b010000;
localparam RANGE3 = 6'b001000;
localparam RANGE4 = 6'b000100;
localparam RANGE5 = 6'b000010;
localparam RANGE6 = 6'b000001;
localparam WAIT = 1'b0;
localparam EXE = 1'b1;
// Wires and Regs
reg signed [DATA_W-1:0] comb_result; 
reg [DATA_W-1:0] rot_result; 
reg [DATA_W-1:0] add_sub_result;
reg signed [DATA_W+3:0] acc_result20;
reg signed [DATA_W-1:0] acc_result;
reg signed [DATA_W:0] add_sub_result17;
reg [DATA_W-1:0] arsh_result;
//reg [DATA_W-1:0] arsh_extension;
//reg [DATA_W-1:0] arsh_bubble;
reg [2*DATA_W-1:0] lrot_base;
reg [DATA_W-1:0] lrot_result;
reg [4:0] clz_result;
reg [12:0] rm4_result;
reg [7:0] clz8;
reg [3:0] clz4;
// wire range1, range2, range3, range4, range5, range6;
// wire [5:0] range = {range1, range2, range3, range4, range5, range6};
wire [5:0] soft_range;
reg signed [DATA_W-1:0] soft_result;

reg [DATA_W-1:0] o_data_buffer;
reg busy_buffer;
reg ovalid_buffer;
reg [INST_W-1:0] inst_buffer;
reg signed [DATA_W-1:0] data_a_buffer;
reg signed [DATA_W-1:0] data_b_buffer;
reg signed [DATA_W+3:0] acc_mem [MEM_H-1:0];    //20bits*16
reg cs, ns;


//Sequential Blocks
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        for (i=0; i<16; i=i+1) begin
            acc_mem[i] <= 20'd0;
        end
    end
    else if (inst_buffer == SACC)begin
        acc_mem[data_a_buffer[3:0]] <= acc_result20;
    end
end

/*FSM*/
always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        cs <= WAIT;
    end
    else begin
        cs <= ns;
    end
end

always @(*) begin
    if (cs == WAIT) begin
        ns = (i_in_valid) ? EXE : WAIT;
    end
    else begin
        ns = WAIT;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if(!i_rst_n) begin
        busy_buffer <= 1'b0;
        ovalid_buffer <= 1'b0;
        inst_buffer <= 4'd0;
        o_data_buffer <= 16'd0;
        data_a_buffer <= 16'd0;
        data_b_buffer <= 16'd0;
    end
    else begin
        inst_buffer <= i_inst;
        o_data_buffer <= comb_result;
        data_a_buffer <= i_data_a;
        data_b_buffer <= i_data_b;
        if (cs == WAIT) begin
            busy_buffer <= (i_in_valid) ? 1'b1 : 1'b0;
            ovalid_buffer <= 1'b0;
        end
        else begin
            busy_buffer <= 1'b0;
            ovalid_buffer <= 1'b1;
        end
    end
end
// Continuous Assignments
assign o_data = o_data_buffer;
assign o_out_valid = ovalid_buffer;
assign o_busy = busy_buffer;
assign soft_range[5] = data_a_buffer >= 16'sh0800;                                     // x >= 2
assign soft_range[4] = (data_a_buffer >= 16'sh0000) && (data_a_buffer < 16'sh0800);    // 0 <= x < 2
assign soft_range[3] = (data_a_buffer >= 16'shfc00) && (data_a_buffer < 16'sh0000);    //-1 <= x < 0
assign soft_range[2] = (data_a_buffer >= 16'shf800) && (data_a_buffer < 16'shfc00);    //-2 <= x <-1
assign soft_range[1] = (data_a_buffer >= 16'shf400) && (data_a_buffer < 16'shf800);    //-3 <= x <-2
assign soft_range[0] = (data_a_buffer < 16'shf400);                                    // x < -3

// Combinatorial Blocks
always @(*) begin
    comb_result = 16'd0;
    case(inst_buffer)
        SADD : begin
            comb_result = add_sub_result;
        end
        SSUB : begin
            comb_result = add_sub_result;
        end 
        SMUL : begin
            comb_result = S_mul(data_a_buffer, data_b_buffer);
        end
        SACC : begin
            comb_result = acc_result;
        end
        SOFT : begin
            comb_result = soft_result;
        end
        XOR : begin
            comb_result = data_a_buffer ^ data_b_buffer;
        end
        ARSH : begin
            comb_result = arsh_result;
        end
        LROT : begin
            comb_result = lrot_result;
        end
        CLZ : begin
            comb_result = (clz_result[4]) ? 16'h0010 : {12'b0, clz_result[3:0]};
        end
        RM4 : begin
            comb_result = {3'd0,rm4_result};
        end
    endcase
end
/*accumulation*/
always @(*) begin
    acc_result20 = (acc_mem[data_a_buffer[3:0]] + data_b_buffer);
    if (acc_result20 > 20'sh07fff) begin
        acc_result = 16'h7fff;
    end
    else if (acc_result20 < 20'shf8000) begin
        acc_result = 16'h8000;
    end
    else begin
        acc_result = acc_result20[DATA_W-1:0];
    end
end

/*addition and subtraction*/
always @(*) begin
    add_sub_result17 = (inst_buffer[0]) ? (data_a_buffer - data_b_buffer) : (data_a_buffer + data_b_buffer);
    if (!add_sub_result17[DATA_W]) begin //positive
        add_sub_result = (add_sub_result17 > 17'sh07fff) ? 16'h7fff : add_sub_result17[DATA_W-1:0];  
    end
    else begin  //negative
        add_sub_result = (add_sub_result17 < 17'sh18000) ? 16'h8000 : add_sub_result17[DATA_W-1:0];
    end
end
// wire [18:0] debug1 = ({{2{data_a_buffer[DATA_W-1]}}, data_a_buffer, 1'b0} << 1) + 18'sh01000;

//SoftPlus
always @(*) begin
    soft_result = 16'd0;
    case (soft_range)
        RANGE1 : begin               
            soft_result = data_a_buffer;                                                                    // x
        end 
        RANGE2 : begin                          //extend {2'b sign, devident, 1'b0}
            soft_result = dev3($signed({data_a_buffer, 1'b0}) + 18'sh00800);    //(2x + 2) /3
        end
        RANGE3 : begin
            soft_result = dev3($signed(({data_a_buffer[DATA_W-1], data_a_buffer})) + 18'sh00800);         //(x + 2) /3
        end
        RANGE4 : begin
            soft_result = dev9($signed({data_a_buffer, 1'b0}) + 18'sh01400);    //(2x + 5) /9
        end
        RANGE5 : begin
            soft_result = dev9($signed({data_a_buffer[DATA_W-1], data_a_buffer}) + 18'sh00c00);         //(x + 3) /9
        end
        RANGE6 : begin
            soft_result = 16'd0;                                                                    // 0
        end
    endcase
end

//Arithmatic Shift Right
always @(*) begin
    // if (!data_a_buffer[DATA_W-1]) begin
    //     arsh_extension = 16'h0000;
    // end
    // else begin
    //     arsh_extension = 16'hffff;
    // end
    //{arsh_bubble, arsh_result} = (({arsh_extension, data_a_buffer}) >> data_b_buffer);
    arsh_result = data_a_buffer >>> data_b_buffer[4:0];
end

//Left Rotatation
always @(*) begin
    lrot_base = {2{data_a_buffer}};
    lrot_result = lrot_base[(5'd16-data_b_buffer[4:0])+:DATA_W];
end

//count leading zero
always @(*) begin
    clz_result[4] = (~|data_a_buffer);
    clz_result[3] = (~|data_a_buffer[15:8]);
    clz8 = (clz_result[3]) ? data_a_buffer[7:0] : data_a_buffer[15:8];
    clz_result[2] = (~|clz8[7:4]);
    clz4 = (clz_result[2]) ? clz8[3:0] : clz8[7:4];
    clz_result[1] = (~|clz4[3:2]);
    clz_result[0] = (clz_result[1]) ? ~clz4[1] : ~clz4[3];
end

/*RM4*/
always @(*) begin
    for (i=0; i<13; i=i+1) begin
        rm4_result[i] = data_a_buffer[i+:4] == data_b_buffer[(15-i)-:4];
    end
end

function automatic [DATA_W-1:0] S_mul;
    input signed [DATA_W-1:0] data_a;
    input signed [DATA_W-1:0] data_b;
    reg signed [2*DATA_W-1:0] mul_result;
    begin
        mul_result = data_a * data_b;
        if (!mul_result[2*DATA_W-1]) begin
            if (mul_result > 32'sh01fffc00) begin
                S_mul = 16'h7fff; //pos maximum
            end
            else begin
                S_mul = (mul_result[9]) ? mul_result[25:10] + 16'sd1 : mul_result[25:10];  //rotate to 10 fracion bits
            end
        end
        else begin//
            if (mul_result < 32'shfe000000) begin
                S_mul = 16'h8000;  //neg minimum
            end
            else begin
                S_mul = (mul_result[9]) ? mul_result[25:10] + 16'sd1 : mul_result[25:10];  //rotate to 10 fracion bits
            end
        end
    end
endfunction

localparam EXT_BIT = 10;

function automatic [DATA_W-1:0] dev3;
    input signed [17:0] devident;       //extend {2'b sign, devident}
    reg signed [EXT_BIT+17:0] ext_devident;
    reg signed [EXT_BIT+17:0] Q0;
    reg signed [EXT_BIT+17:0] Q1;
    reg signed [EXT_BIT+17:0] Q2;
    reg signed [EXT_BIT+17:0] Q3, Q3_plus1;

    begin
        ext_devident = {devident, 10'b0};           ///
        Q0 = ((ext_devident >> 2) + ext_devident) >> 2;
        Q1 = (Q0 + ext_devident) >> 1;
        Q2 = ((Q1 >> 6) + Q1);
        Q3 = ((Q2 >> 12) + Q2) >> 1;
        //Q3_plus1 = Q3 + 20'sh00004;
        Q3_plus1 = Q3 + $signed({18'h00001,10'b0});  ///
        dev3 = (Q3[EXT_BIT-1]) ? Q3_plus1[EXT_BIT+15:EXT_BIT] : Q3[EXT_BIT+15:EXT_BIT];

    end

endfunction

function automatic [DATA_W-1:0] dev9;
    input signed [17:0] devident;
    reg signed [EXT_BIT+17:0] ext_devident;
    reg signed [EXT_BIT+17:0] Q0;
    reg signed [EXT_BIT+17:0] Q1;
    reg signed [EXT_BIT+17:0] Q2;
    reg signed [EXT_BIT+17:0] Q3, Q3_plus1;

    begin
        ext_devident = {devident, 10'b0};   ///
        Q0 = ((ext_devident >> 1) + ext_devident) >> 1;
        Q1 = (Q0 + ext_devident) >> 1;
        Q2 = ((Q1 >> 6) + Q1);
        Q3 = ((Q2 >> 12) + Q2) >> 3;
        Q3_plus1 = Q3 + $signed({18'h00001,10'b0});  ///
        dev9 = (Q3[EXT_BIT-1]) ? Q3_plus1[EXT_BIT+15:EXT_BIT] : Q3[EXT_BIT+15:EXT_BIT];
    end
    
endfunction

endmodule
