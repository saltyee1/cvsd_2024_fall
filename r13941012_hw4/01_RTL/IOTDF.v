`timescale 1ns/10ps
// `include "S_BOX1.v"
// `include "S_BOX2.v"
// `include "S_BOX3.v"
// `include "S_BOX4.v"
// `include "S_BOX5.v"
// `include "S_BOX6.v"
// `include "S_BOX7.v"
// `include "S_BOX8.v"
// `include "KEY.v"
// `include "F.v"
module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [2:0]   fn_sel;
output         busy;
output         valid;
output [127:0] iot_out;
// output [7:0] iotdatamsb;

integer i, j;
localparam ENCRYPT = 3'b001;
localparam DECRYPT = 3'b010;
localparam CRC = 3'b011;
localparam TOP2MAX = 3'b100;
localparam LAST2MIN = 3'b101;

localparam BIGGER = 2'd0;
localparam EQUAL = 2'd1;
localparam SMALLER = 2'd2;

/*Register*/
reg [7:0] iot_data_r [0:15];
reg [7:0] iot_in_buff;
reg in_en_buff;
reg [2:0]  fn_sel_reg;
reg busy_buff;
reg valid_buff;
reg [63:0] main_key_r;
reg [31:0] R_r, L_r;
reg [5:0] counter;
reg [2:0] crc_r;
reg  iot_dir_r;
reg first_round;
reg start;
// reg [7:0] iot_compareD [0:15];
reg [7:0] iot_compareA [0:15];
reg [7:0] iot_compareB [0:15];
reg [7:0] counter_compare;
reg [3:0] compare_addr_rd;
reg [3:0] counter_addr_rd;
reg [3:0] counter_addr_wr;
reg data_wen;
reg first_en_r;
reg output_ing, output_end;
reg [1:0] D_A_r;
reg [1:0] D_B_r;
reg en12, en123, en3, en45;
reg n_counter16;
reg [7:0] iot_data_r12, iot_data_r3, iot_data_r45;
// reg [7:0] iot_data_msb_r;
/*Wire*/
reg busy_n;
reg valid_n;
// wire [7:0] iot_data_msb = (!iot_dir_r) ? iot_data_r[0] : iot_data_r[15];
wire [7:0] iot_data_msb = iot_data_r[counter_addr_wr];
reg [5:0] counter_n;
reg [63:0] plaintext_init;
reg [63:0] main_key_pre;
reg [47:0] K1, K2, K3, K4, K5, K6, K7, K8, K9, K10, K11, K12, K13, K14, K15, K16;
reg [47:0] K1_pre, K16_pre;
reg [31:0] R1, L1;
reg [31:0] R_into_F;
reg [31:0] R_n, L_n;
reg [31:0] R_F;
reg [47:0] K_using;
reg [127:0] iot_out_w;
reg [55:0] cipher_key_0;
reg [2:0] crc_n;
reg [7:0] compare1_n, compare2_n;
reg [1:0] D_A;
reg [1:0] D_B;
reg change1, change2, nochange;
wire gclk_10, gclk_123, gclk_3, gclk_45;

wire [127:0] iotA_bus;
wire [127:0] iotB_bus;

// assign iotdatamsb = iot_data_msb;

assign iotA_bus = {iot_compareA[15], iot_compareA[14], iot_compareA[13], iot_compareA[12],
                   iot_compareA[11], iot_compareA[10], iot_compareA[9],  iot_compareA[8],
                   iot_compareA[7],  iot_compareA[6],  iot_compareA[5],  iot_compareA[4],
                   iot_compareA[3],  iot_compareA[2],  iot_compareA[1],  iot_compareA[0]};

assign iotB_bus = {iot_compareB[15], iot_compareB[14], iot_compareB[13], iot_compareB[12],
                   iot_compareB[11], iot_compareB[10], iot_compareB[9],  iot_compareB[8],
                   iot_compareB[7],  iot_compareB[6],  iot_compareB[5],  iot_compareB[4],
                   iot_compareB[3],  iot_compareB[2],  iot_compareB[1],  iot_compareB[0]};


assign iot_out = iot_out_w;

F f0 (
    .R(R_r),
    .K(K_using),
    .F_out(R_F)
);

KEY u_key (
    .main_key(main_key_r),
    .K1(K1),
    .K2(K2),
    .K3(K3),
    .K4(K4),
    .K5(K5),
    .K6(K6),
    .K7(K7),
    .K8(K8),
    .K9(K9),
    .K10(K10),
    .K11(K11),
    .K12(K12),
    .K13(K13),
    .K14(K14),
    .K15(K15),
    .K16(K16)
);

wire [63:0] plaintext = {
    iot_data_r[7],
    iot_data_r[6],
    iot_data_r[5],
    iot_data_r[4],
    iot_data_r[3],
    iot_data_r[2],
    iot_data_r[1],
    iot_data_r[0]
};
wire [63:0] main_key = {
    iot_data_r[15],
    iot_data_r[14],
    iot_data_r[13],
    iot_data_r[12],
    iot_data_r[11],
    iot_data_r[10],
    iot_data_r[9],
    iot_data_r[8]
};


///*Input Output Buffer*///
assign busy = busy_buff;
assign valid = valid_buff;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        iot_in_buff <= 8'd0;
        in_en_buff <= 1'b0;
        fn_sel_reg <= 3'b0;
        busy_buff <= 1'b1;
        valid_buff <= 1'b0;
    end
    else begin
        if (in_en)
            iot_in_buff <= iot_in;
        in_en_buff <= in_en;
        fn_sel_reg <= fn_sel;
        busy_buff <= busy_n;
        valid_buff <= valid_n;
    end
end

assign gclk_10 = clk & en12;
assign gclk_123 = clk & en123;
assign gclk_3 = clk & en3;
assign gclk_45 = clk & en45;

//Clock Gating
always @(posedge clk or posedge rst) begin
    if (rst) begin
        en12 <= 1'b1;
        en123 <= 1'b1;
        en3 <= 1'b1;
        en45 <= 1'b1;
    end
    else begin
        en12 <= (fn_sel==ENCRYPT || fn_sel==DECRYPT);
        en123 <= (fn_sel==ENCRYPT || fn_sel==DECRYPT || fn_sel==CRC);
        en3 <= (fn_sel==CRC);
        en45 <= (fn_sel_reg==TOP2MAX || fn_sel==LAST2MIN);
    end
end


///*Sequential Blocks*///
always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 'd0;
        iot_dir_r <= 1'b0;
    end
    else if (en123) begin
        counter <= counter_n;
        iot_dir_r <= (!n_counter16) ? ~iot_dir_r : iot_dir_r; 
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        main_key_r <= 56'd0;
        R_r <= 32'd0;
        L_r <= 32'd0;
    end
    else if (en12) begin
        main_key_r <= (counter=='d16 || counter=='d33) ? main_key : main_key_r;   //change every 16 cycle
        R_r <= R_n;
        L_r <= L_n;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        crc_r <= 'd0;
        first_round<=1'b1;
        start <= 1'b0;
        n_counter16 <= 1'b1;
    end
    else begin
        crc_r <= crc_n;
        first_round <= (counter=='d16) ? 1'b0 : first_round;
        start <= (in_en) ? 1'b1 : start;
        n_counter16 <= ((counter=='d15) && (fn_sel_reg==CRC)) ? 1'b0 : 1'b1;
    end
end

//input iot to iot_data_r sequentially
// always @(posedge clk or posedge rst) begin
//     if (rst) begin
//          for (i=0; i<16; i=i+1 ) begin
//             iot_data_r[i] <= 8'd0;
//         end
//     end
//     else if (n_counter16)begin
//         if (!iot_dir_r) begin   
//             for (i = 0; i<15 ; i=i+1 ) begin
//                 iot_data_r[i] <= iot_data_r[i+1]; 
//             end
//             iot_data_r[15] <= iot_in_buff;
//         end
//         else begin
//             for (i = 1; i<16 ; i=i+1 ) begin
//                 iot_data_r[i] <= iot_data_r[i-1]; 
//             end
//             iot_data_r[0] <= iot_in_buff;
//         end
//     end
// end
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i=0; i<16; i=i+1 ) begin
            iot_data_r[i] <= 8'd0;
        end
    end
    else if (n_counter16)begin
        iot_data_r[counter_addr_wr] <= iot_in_buff;
    end
end

always @(*) begin
    case (fn_sel_reg)
        ENCRYPT, DECRYPT : counter_addr_wr = (counter[5:0] > 6'd16) ? counter[3:0]-3'd1 : counter[3:0];
        CRC : counter_addr_wr = (!iot_dir_r) ? counter[3:0] : 4'd15-counter[3:0];
        TOP2MAX, LAST2MIN : counter_addr_wr = counter_compare[3:0];
        default : counter_addr_wr = 4'd0;
    endcase
end


// always @(posedge clk or posedge rst) begin
//     if (rst) begin
//         iot_data_msb_r <= 8'd0;
//     end
//     else if (en3)begin
//         if (counter==6'd16)
//             iot_data_msb_r <= (~iot_dir_r) ? iot_data_r[15] : iot_data_r[0];
//         else 
//             iot_data_msb_r <= (iot_dir_r) ? iot_data_r[14] : iot_data_r[1];
//     end
// end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        iot_data_r45 <= 8'd0;
    end
    else if (en45) begin
        iot_data_r45 <= iot_in_buff;
    end
end

// always @(posedge clk or posedge rst) begin
//     if (rst) begin
//         iot_data_msb_r <= 8'd0;
//     end
//     else if (en3) begin
//         if (counter=='d15) begin
            
//         end
//         if (iot_dir_r) begin
//             iot_data_msb_r <= (counter=='d)
//         end
//         else begin
            
//         end
//     end
// end

///*Output Logic*///
always @(*) begin
    case (fn_sel_reg)
        ENCRYPT, DECRYPT: begin
            busy_n = (counter[5:0] == 'd13 || counter=='d30);
            valid_n = (counter == 'd32) ? 1'b1 : 1'b0;
            iot_out_w = {main_key_r, {final_permutation({L_r, R_r})}};
        end
        CRC : begin
            busy_n = (counter == 'd13) ? 1'b1 : 1'b0;    //do not get iot data at 16
            valid_n = (counter == 'd15 && !first_round) ? 1'b1 : 1'b0;
            iot_out_w = {125'b0, crc_r};
        end
        TOP2MAX, LAST2MIN : begin
            busy_n = (counter_compare==8'd125 || counter_compare==8'd126 || counter_compare==8'd127) ?1'b1 : 1'b0;
            valid_n = (counter_compare==8'd128 || counter_compare==8'd130) ? ~valid_buff : valid_buff;
            iot_out_w = (counter_compare==8'd130) ? iotB_bus : iotA_bus;
        end
        default : begin
            busy_n = 1'b1;
            valid_n = 1'b0;
            iot_out_w = 128'd0;
        end
    endcase
end

////*Combinational Blocks*///
always @(*) begin

    plaintext_init = initial_permutation(plaintext);
    // main_key_pre = {main_key[55:0], iot_data_r[7]};
    // R_into_F = (counter[3:0] == 'd0) ? plaintext_init[31:0] : R_r;  //R0 is from plaintext
    //Do K1 first
    // cipher_key_0 = PC1(main_key);
    // K1_pre = PC2({cipher_key_0[54:28], cipher_key_0[55], cipher_key_0[26:0], cipher_key_0[27]});
    // K16_pre = PC2(cipher_key_0);

    if (counter == 'd16 || counter == 'd33)    //at 16 and 33
        R_n = plaintext_init[31:0];  //F(R0) xor L0
    else if (counter[3:0] == 'd0)
        R_n = R_r;
    else
        R_n = R_F ^ L_r; 

    if (counter == 'd16 || counter == 'd33)    //at 16 and 32
        L_n = plaintext_init[63:32];
    else if (counter[3:0] == 'd0)
        L_n = R_F ^ L_r;
    else
        L_n = R_r;
    
    if (fn_sel_reg == ENCRYPT) begin    //encryption uses K1 to K16
        case (counter[3:0])
            4'd1: K_using = K1;
            4'd2: K_using = K2;
            4'd3: K_using = K3;
            4'd4: K_using = K4;
            4'd5: K_using = K5;
            4'd6: K_using = K6;
            4'd7: K_using = K7;
            4'd8: K_using = K8;
            4'd9: K_using = K9;
            4'd10: K_using = K10;
            4'd11: K_using = K11;
            4'd12: K_using = K12;
            4'd13: K_using = K13;
            4'd14: K_using = K14;
            4'd15: K_using = K15;
            4'd0: K_using = K16;
        endcase
    end
    else begin                          //decryption uses K1 to K16
        case (counter[3:0])
            4'd1: K_using = K16;
            4'd2: K_using = K15;
            4'd3: K_using = K14;
            4'd4: K_using = K13;
            4'd5: K_using = K12;
            4'd6: K_using = K11;
            4'd7: K_using = K10;
            4'd8: K_using = K9;
            4'd9: K_using = K8;
            4'd10: K_using = K7;
            4'd11: K_using = K6;
            4'd12: K_using = K5;
            4'd13: K_using = K4;
            4'd14: K_using = K3;
            4'd15: K_using = K2;
            4'd0: K_using = K1;
        endcase
    end
end

always @(*) begin
    counter_n = 'd0;
    case (fn_sel_reg)
        ENCRYPT, DECRYPT : begin
            if (counter == 'd33) 
                counter_n = 'd17;
            else if (start) 
                counter_n = counter + 'd1; 
        end
        CRC : begin
            if (counter == 'd16) 
                counter_n = 'd0;
            else if (start)
                counter_n = counter + 'd1; 
        end
    endcase
end

always @(*) begin
    // iot_data_msb = (!iot_dir_r) ? iot_data_r[0] : iot_data_r[15];
    // iot_data_msb = 1'b0;
    if (counter=='d16) begin
        crc_n = 3'd0;
    end
    else if (counter == 'd15) begin
        crc_n[2] = crc_r[1] ^ crc_r[0] ^ iot_data_msb[6] ^ iot_data_msb[5] ^ iot_data_msb[3] ^ iot_data_msb[2] ^ iot_data_msb[0];
        crc_n[1] = crc_r[2] ^ crc_r[1] ^ iot_data_msb[7] ^ iot_data_msb[6] ^ iot_data_msb[4] ^ iot_data_msb[3] ^ iot_data_msb[1] ^ iot_data_msb[0];
        crc_n[0] = 1'b0;
    end
    else begin 
        crc_n[2] = crc_r[1] ^ crc_r[0] ^ iot_data_msb[6] ^ iot_data_msb[5] ^ iot_data_msb[3] ^ iot_data_msb[2];     
        crc_n[1] = crc_r[2] ^ crc_r[1] ^ iot_data_msb[7] ^ iot_data_msb[6] ^ iot_data_msb[4] ^ iot_data_msb[3] ^ iot_data_msb[1];
        crc_n[0] = iot_data_msb[0];
    end
end



///////////////////////////////////////////
///              MAX MIN                ///
///////////////////////////////////////////

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i=0; i<16; i=i+1) begin
            iot_compareA[i] <= 8'd0;
            iot_compareB[i] <= 8'd0;
        end
    end
    else if (en45) begin
        if(output_ing) begin
            for (i=0; i<16; i=i+1) begin
                iot_compareA[i] <= iot_compareA[i];
                iot_compareB[i] <= iot_compareB[i];
            end
        end
        if (counter_compare==8'd0)begin
            for (i=0; i<16; i=i+1) begin
                iot_compareA[i] <= (fn_sel_reg==TOP2MAX) ? 8'd0 : 8'hff;
                iot_compareB[i] <= (fn_sel_reg==TOP2MAX) ? 8'd0 : 8'hff;
            end
        end
        else if (counter_compare[3:0]==4'd0) begin
            if (nochange) begin
                for (i=0; i<16; i=i+1) begin
                    iot_compareA[i] <= iot_compareA[i];            //not change
                    iot_compareB[i] <= iot_compareB[i];     
                end    
            end
            else if (change2) begin
                for (i=0; i<16; i=i+1) begin
                    iot_compareA[i] <= iot_data_r[i];               //A <= D
                    iot_compareB[i] <= iot_compareA[i];               //B <= A
                end
            end
            else begin
                for (i=0; i<16; i=i+1) begin
                    iot_compareA[i] <= iot_compareA[i];               //A <= A
                    iot_compareB[i] <= iot_data_r[i];               //B <= D
                end
            end
        end
        // else begin
        //     for (i=0; i<16; i=i+1) begin
        //         iot_compareA[i] <= iot_compareA[i];            //not change
        //         iot_compareB[i] <= iot_compareB[i];     
        //     end
        // end
    end
end
    // else if (counter_compare[3:0]==4'd0) begin
    //         if (nochange) begin
    //             for (i=0; i<15; i=i+1) begin
    //                 iot_compareA[i] <= iot_compareA[i+1];            //not change
    //                 iot_compareB[i] <= iot_compareB[i+1];         
    //             end
    //             iot_compareA[15] <= iot_compareA[0];
    //             iot_compareB[15] <= iot_compareB[0];
    //         end
    //         else if (change2) begin
    //             for (i=0; i<15; i=i+1) begin
    //                 iot_compareA[i] <= iot_data_r[i+1];               //A <= D
    //                 iot_compareB[i] <= iot_compareA[i+1];               //B <= A
    //             end
    //             iot_compareA[15] <= iot_data_r[0];
    //             iot_compareB[15] <= iot_compareA[0];
    //         end
    //         else begin
    //             for (i=0; i<15; i=i+1) begin
    //                 iot_compareA[i] <= iot_compareA[i+1];               //A <= A
    //                 iot_compareB[i] <= iot_data_r[i+1];               //B <= D
    //             end
    //             iot_compareA[15] <= iot_compareA[0];                    
    //             iot_compareB[15] <= iot_data_r[0];
    //         end
    //     end
    //     else begin
    //         for (i=0; i<15; i=i+1) begin
    //             iot_compareA[i] <= iot_compareA[i+1];
    //             iot_compareB[i] <= iot_compareB[i+1];
    //         end
    //         iot_compareA[15] <= iot_compareA[0];
    //         iot_compareB[15] <= iot_compareB[0];
    //     end
    // end
// end

// always @(posedge clk or posedge rst) begin
//     if (rst) begin
//         for (i=0; i<16; i=i+1) begin
//             iot_compareD[i] <= 8'd0;
//         end
//     end
//     else if (en45) begin
//         for (i=0; i<15; i=i+1) begin
//             iot_compareD[i] <= iot_compareD[i+1];
//         end
//         iot_compareD[15] <= iot_in_buff;
//     end
// end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        D_A_r <= BIGGER;
        D_B_r <= BIGGER;
    end
    else begin
        if (D_A==BIGGER || (D_A==EQUAL&&D_A_r==BIGGER))
            D_A_r <= BIGGER;
        else if (D_A==EQUAL && D_A_r==EQUAL) 
            D_A_r <= EQUAL;
        else
            D_A_r <= SMALLER;

        if (D_B==BIGGER || (D_B==EQUAL&&D_B_r==BIGGER))
            D_B_r <= BIGGER;
        else if (D_B==EQUAL && D_B_r==EQUAL) 
            D_B_r <= EQUAL;
        else
            D_B_r <= SMALLER;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter_compare <= 8'd0;
        first_en_r <= 1'b0;
        output_ing <= 1'd0;
        output_end <= 1'd0;
        compare_addr_rd <= 4'd0;
    end
    else if (en45) begin
        first_en_r <= (in_en) ? in_en : first_en_r;         // pull high after first in_en
        if (first_en_r)
            counter_compare <= (counter_compare==8'd130) ? 'd0 : counter_compare + 'd1;
        output_ing <= (counter_compare==8'd128) ? 1'b1 : 1'b0;
        output_end <= (counter_compare==8'd129) ? 1'b1 : 1'b0;
        compare_addr_rd <= counter_compare[3:0];
    end
end

always @(*) begin
    // D_A = (iot_compareD[15]>iot_compareA[15]) ? BIGGER : (iot_compareD[15]==iot_compareA[15]) ? EQUAL : SMALLER;
    // D_B = (iot_compareD[15]>iot_compareB[15]) ? BIGGER : (iot_compareD[15]==iot_compareB[15]) ? EQUAL : SMALLER;
    D_A = (iot_data_r45>iot_compareA[compare_addr_rd]) ? BIGGER : (iot_data_r45==iot_compareA[compare_addr_rd]) ? EQUAL : SMALLER;
    D_B = (iot_data_r45>iot_compareB[compare_addr_rd]) ? BIGGER : (iot_data_r45==iot_compareB[compare_addr_rd]) ? EQUAL : SMALLER;
    if (fn_sel_reg == TOP2MAX) begin
        change2 = (D_A==BIGGER) || (D_A==EQUAL&&D_A_r==BIGGER);
        nochange = (D_B==SMALLER) || (D_B==EQUAL&&D_B_r==SMALLER);
        change1 = ~(change2 | nochange);
    end
    else begin
        change2 = (D_A==SMALLER) || (D_A==EQUAL&&D_A_r==SMALLER);
        nochange = (D_B==BIGGER) || (D_B==EQUAL&&D_B_r==BIGGER);
        change1 = ~(change2 | nochange);
    end
end




/*LUT*/
function [63:0] initial_permutation; 
    input [63:0] in_64; 
    begin
        initial_permutation[63] = in_64[6];
        initial_permutation[62] = in_64[14];
        initial_permutation[61] = in_64[22];
        initial_permutation[60] = in_64[30];
        initial_permutation[59] = in_64[38];
        initial_permutation[58] = in_64[46];
        initial_permutation[57] = in_64[54];
        initial_permutation[56] = in_64[62];
        initial_permutation[55] = in_64[4];
        initial_permutation[54] = in_64[12];
        initial_permutation[53] = in_64[20];
        initial_permutation[52] = in_64[28];
        initial_permutation[51] = in_64[36];
        initial_permutation[50] = in_64[44];
        initial_permutation[49] = in_64[52];
        initial_permutation[48] = in_64[60];
        initial_permutation[47] = in_64[2];
        initial_permutation[46] = in_64[10];
        initial_permutation[45] = in_64[18];
        initial_permutation[44] = in_64[26];
        initial_permutation[43] = in_64[34];
        initial_permutation[42] = in_64[42];
        initial_permutation[41] = in_64[50];
        initial_permutation[40] = in_64[58];
        initial_permutation[39] = in_64[0];
        initial_permutation[38] = in_64[8];
        initial_permutation[37] = in_64[16];
        initial_permutation[36] = in_64[24];
        initial_permutation[35] = in_64[32];
        initial_permutation[34] = in_64[40];
        initial_permutation[33] = in_64[48];
        initial_permutation[32] = in_64[56];
        initial_permutation[31] = in_64[7];
        initial_permutation[30] = in_64[15];
        initial_permutation[29] = in_64[23];
        initial_permutation[28] = in_64[31];
        initial_permutation[27] = in_64[39];
        initial_permutation[26] = in_64[47];
        initial_permutation[25] = in_64[55];
        initial_permutation[24] = in_64[63];
        initial_permutation[23] = in_64[5];
        initial_permutation[22] = in_64[13];
        initial_permutation[21] = in_64[21];
        initial_permutation[20] = in_64[29];
        initial_permutation[19] = in_64[37];
        initial_permutation[18] = in_64[45];
        initial_permutation[17] = in_64[53];
        initial_permutation[16] = in_64[61];
        initial_permutation[15] = in_64[3];
        initial_permutation[14] = in_64[11];
        initial_permutation[13] = in_64[19];
        initial_permutation[12] = in_64[27];
        initial_permutation[11] = in_64[35];
        initial_permutation[10] = in_64[43];
        initial_permutation[9]  = in_64[51];
        initial_permutation[8]  = in_64[59];
        initial_permutation[7]  = in_64[1];
        initial_permutation[6]  = in_64[9];
        initial_permutation[5]  = in_64[17];
        initial_permutation[4]  = in_64[25];
        initial_permutation[3]  = in_64[33];
        initial_permutation[2]  = in_64[41];
        initial_permutation[1]  = in_64[49];
        initial_permutation[0]  = in_64[57];
    end
endfunction



function [63:0] final_permutation;
    input [63:0] in_64; 
    begin
        final_permutation[63] = in_64[24];
        final_permutation[62] = in_64[56];
        final_permutation[61] = in_64[16];
        final_permutation[60] = in_64[48];
        final_permutation[59] = in_64[8];
        final_permutation[58] = in_64[40];
        final_permutation[57] = in_64[0];
        final_permutation[56] = in_64[32];
        final_permutation[55] = in_64[25];
        final_permutation[54] = in_64[57];
        final_permutation[53] = in_64[17];
        final_permutation[52] = in_64[49];
        final_permutation[51] = in_64[9];
        final_permutation[50] = in_64[41];
        final_permutation[49] = in_64[1];
        final_permutation[48] = in_64[33];
        final_permutation[47] = in_64[26];
        final_permutation[46] = in_64[58];
        final_permutation[45] = in_64[18];
        final_permutation[44] = in_64[50];
        final_permutation[43] = in_64[10];
        final_permutation[42] = in_64[42];
        final_permutation[41] = in_64[2];
        final_permutation[40] = in_64[34];
        final_permutation[39] = in_64[27];
        final_permutation[38] = in_64[59];
        final_permutation[37] = in_64[19];
        final_permutation[36] = in_64[51];
        final_permutation[35] = in_64[11];
        final_permutation[34] = in_64[43];
        final_permutation[33] = in_64[3];
        final_permutation[32] = in_64[35];
        final_permutation[31] = in_64[28];
        final_permutation[30] = in_64[60];
        final_permutation[29] = in_64[20];
        final_permutation[28] = in_64[52];
        final_permutation[27] = in_64[12];
        final_permutation[26] = in_64[44];
        final_permutation[25] = in_64[4];
        final_permutation[24] = in_64[36];
        final_permutation[23] = in_64[29];
        final_permutation[22] = in_64[61];
        final_permutation[21] = in_64[21];
        final_permutation[20] = in_64[53];
        final_permutation[19] = in_64[13];
        final_permutation[18] = in_64[45];
        final_permutation[17] = in_64[5];
        final_permutation[16] = in_64[37];
        final_permutation[15] = in_64[30];
        final_permutation[14] = in_64[62];
        final_permutation[13] = in_64[22];
        final_permutation[12] = in_64[54];
        final_permutation[11] = in_64[14];
        final_permutation[10] = in_64[46];
        final_permutation[9]  = in_64[6];
        final_permutation[8]  = in_64[38];
        final_permutation[7]  = in_64[31];
        final_permutation[6]  = in_64[63];
        final_permutation[5]  = in_64[23];
        final_permutation[4]  = in_64[55];
        final_permutation[3]  = in_64[15];
        final_permutation[2]  = in_64[47];
        final_permutation[1]  = in_64[7];
        final_permutation[0]  = in_64[39];
    end
endfunction

function [55:0] PC1; 
    input [63:0] in_64;
    begin
        PC1[55] = in_64[7];
        PC1[54] = in_64[15];
        PC1[53] = in_64[23];
        PC1[52] = in_64[31];
        PC1[51] = in_64[39];
        PC1[50] = in_64[47];
        PC1[49] = in_64[55];
        PC1[48] = in_64[63];
        PC1[47] = in_64[6];
        PC1[46] = in_64[14];
        PC1[45] = in_64[22];
        PC1[44] = in_64[30];
        PC1[43] = in_64[38];
        PC1[42] = in_64[46];
        PC1[41] = in_64[54];
        PC1[40] = in_64[62];
        PC1[39] = in_64[5];
        PC1[38] = in_64[13];
        PC1[37] = in_64[21];
        PC1[36] = in_64[29];
        PC1[35] = in_64[37];
        PC1[34] = in_64[45];
        PC1[33] = in_64[53];
        PC1[32] = in_64[61];
        PC1[31] = in_64[4];
        PC1[30] = in_64[12];
        PC1[29] = in_64[20];
        PC1[28] = in_64[28];
        PC1[27] = in_64[1];
        PC1[26] = in_64[9];
        PC1[25] = in_64[17];
        PC1[24] = in_64[25];
        PC1[23] = in_64[33];
        PC1[22] = in_64[41];
        PC1[21] = in_64[49];
        PC1[20] = in_64[57];
        PC1[19] = in_64[2];
        PC1[18] = in_64[10];
        PC1[17] = in_64[18];
        PC1[16] = in_64[26];
        PC1[15] = in_64[34];
        PC1[14] = in_64[42];
        PC1[13] = in_64[50];
        PC1[12] = in_64[58];
        PC1[11] = in_64[3];
        PC1[10] = in_64[11];
        PC1[9]  = in_64[19];
        PC1[8]  = in_64[27];
        PC1[7]  = in_64[35];
        PC1[6]  = in_64[43];
        PC1[5]  = in_64[51];
        PC1[4]  = in_64[59];
        PC1[3]  = in_64[36];
        PC1[2]  = in_64[44];
        PC1[1]  = in_64[52];
        PC1[0]  = in_64[60];
    end
endfunction

// Function for PC2 permutation
function [47:0] PC2;
    input [55:0] in_56;
    begin
        PC2[47] = in_56[42];  // Output index 47 -> Input index 42
        PC2[46] = in_56[39];  // Output index 46 -> Input index 39
        PC2[45] = in_56[45];  // Output index 45 -> Input index 45
        PC2[44] = in_56[32];  // Output index 44 -> Input index 32
        PC2[43] = in_56[55];  // Output index 43 -> Input index 55
        PC2[42] = in_56[51];  // Output index 42 -> Input index 51
        PC2[41] = in_56[53];  // Output index 41 -> Input index 53
        PC2[40] = in_56[28];  // Output index 40 -> Input index 28
        
        PC2[39] = in_56[41];  // Output index 39 -> Input index 41
        PC2[38] = in_56[50];  // Output index 38 -> Input index 50
        PC2[37] = in_56[35];  // Output index 37 -> Input index 35
        PC2[36] = in_56[46];  // Output index 36 -> Input index 46
        PC2[35] = in_56[33];  // Output index 35 -> Input index 33
        PC2[34] = in_56[37];  // Output index 34 -> Input index 37
        PC2[33] = in_56[44];  // Output index 33 -> Input index 44
        PC2[32] = in_56[52];  // Output index 32 -> Input index 52
        
        PC2[31] = in_56[30];  // Output index 31 -> Input index 30
        PC2[30] = in_56[48];  // Output index 30 -> Input index 48
        PC2[29] = in_56[40];  // Output index 29 -> Input index 40
        PC2[28] = in_56[49];  // Output index 28 -> Input index 49
        PC2[27] = in_56[29];  // Output index 27 -> Input index 29
        PC2[26] = in_56[36];  // Output index 26 -> Input index 36
        PC2[25] = in_56[43];  // Output index 25 -> Input index 43
        PC2[24] = in_56[54];  // Output index 24 -> Input index 54
        
        PC2[23] = in_56[15];  // Output index 23 -> Input index 15
        PC2[22] = in_56[4];   // Output index 22 -> Input index 4
        PC2[21] = in_56[25];  // Output index 21 -> Input index 25
        PC2[20] = in_56[19];  // Output index 20 -> Input index 19
        PC2[19] = in_56[9];   // Output index 19 -> Input index 9
        PC2[18] = in_56[1];   // Output index 18 -> Input index 1
        PC2[17] = in_56[26];  // Output index 17 -> Input index 26
        PC2[16] = in_56[16];  // Output index 16 -> Input index 16
        
        PC2[15] = in_56[5];   // Output index 15 -> Input index 5
        PC2[14] = in_56[11];  // Output index 14 -> Input index 11
        PC2[13] = in_56[23];  // Output index 13 -> Input index 23
        PC2[12] = in_56[8];   // Output index 12 -> Input index 8
        PC2[11] = in_56[12];  // Output index 11 -> Input index 12
        PC2[10] = in_56[7];   // Output index 10 -> Input index 7
        PC2[9]  = in_56[17];  // Output index 9  -> Input index 17
        PC2[8]  = in_56[0];   // Output index 8  -> Input index 0
        
        PC2[7]  = in_56[22];  // Output index 7  -> Input index 22
        PC2[6]  = in_56[3];   // Output index 6  -> Input index 3
        PC2[5]  = in_56[10];  // Output index 5  -> Input index 10
        PC2[4]  = in_56[14];  // Output index 4  -> Input index 14
        PC2[3]  = in_56[6];   // Output index 3  -> Input index 6
        PC2[2]  = in_56[20];  // Output index 2  -> Input index 20
        PC2[1]  = in_56[27];  // Output index 1  -> Input index 27
        PC2[0]  = in_56[24];  // Output index 0  -> Input index 24
    end
endfunction
    

endmodule
