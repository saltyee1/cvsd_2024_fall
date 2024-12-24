module Left_Shift_To_Msb (
    input [47:0] i_data,   // 48-bit input
    output reg [47:0] o_data,  // 48-bit output
    output reg [5:0] shift_amount
);

    always @(*) begin
        shift_amount = 6'd0;   
        
        if (i_data[47]) shift_amount = 6'd0;
        else if (i_data[46]) shift_amount = 6'd1;
        else if (i_data[45]) shift_amount = 6'd2;
        else if (i_data[44]) shift_amount = 6'd3;
        else if (i_data[43]) shift_amount = 6'd4;
        else if (i_data[42]) shift_amount = 6'd5;
        else if (i_data[41]) shift_amount = 6'd6;
        else if (i_data[40]) shift_amount = 6'd7;
        else if (i_data[39]) shift_amount = 6'd8;
        else if (i_data[38]) shift_amount = 6'd9;
        else if (i_data[37]) shift_amount = 6'd10;
        else if (i_data[36]) shift_amount = 6'd11;
        else if (i_data[35]) shift_amount = 6'd12;
        else if (i_data[34]) shift_amount = 6'd13;
        else if (i_data[33]) shift_amount = 6'd14;
        else if (i_data[32]) shift_amount = 6'd15;
        else if (i_data[31]) shift_amount = 6'd16;
        else if (i_data[30]) shift_amount = 6'd17;
        else if (i_data[29]) shift_amount = 6'd18;
        else if (i_data[28]) shift_amount = 6'd19;
        else if (i_data[27]) shift_amount = 6'd20;
        else if (i_data[26]) shift_amount = 6'd21;
        else if (i_data[25]) shift_amount = 6'd22;
        else if (i_data[24]) shift_amount = 6'd23;
        else if (i_data[23]) shift_amount = 6'd24;
        else if (i_data[22]) shift_amount = 6'd25;
        else if (i_data[21]) shift_amount = 6'd26;
        else if (i_data[20]) shift_amount = 6'd27;
        else if (i_data[19]) shift_amount = 6'd28;
        else if (i_data[18]) shift_amount = 6'd29;
        else if (i_data[17]) shift_amount = 6'd30;
        else if (i_data[16]) shift_amount = 6'd31;
        else if (i_data[15]) shift_amount = 6'd32;
        else if (i_data[14]) shift_amount = 6'd33;
        else if (i_data[13]) shift_amount = 6'd34;
        else if (i_data[12]) shift_amount = 6'd35;
        else if (i_data[11]) shift_amount = 6'd36;
        else if (i_data[10]) shift_amount = 6'd37;
        else if (i_data[9]) shift_amount = 6'd38;
        else if (i_data[8]) shift_amount = 6'd39;
        else if (i_data[7]) shift_amount = 6'd40;
        else if (i_data[6]) shift_amount = 6'd41;
        else if (i_data[5]) shift_amount = 6'd42;
        else if (i_data[4]) shift_amount = 6'd43;
        else if (i_data[3]) shift_amount = 6'd44;
        else if (i_data[2]) shift_amount = 6'd45;
        else if (i_data[1]) shift_amount = 6'd46;
        else if (i_data[0]) shift_amount = 6'd47;
        else shift_amount = 6'd47;  // All zero case

        o_data = i_data << shift_amount;
    end

endmodule
