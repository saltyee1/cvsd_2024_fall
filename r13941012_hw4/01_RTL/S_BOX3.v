module S_BOX3 (
    input [5:0] in_6,   // 6-bit input to the S-box
    output reg [3:0] out_4  // 4-bit output after substitution
);

    // Extract row (y) and column (x) from the input
    wire [3:0] x = in_6[4:1];  // The middle 4 bits represent the column index
    wire [1:0] y = {in_6[5], in_6[0]}; // The first and last bit represent the row index


    always @(*) begin
        case (y)  // Check the row value (y)
            2'b00: begin // y = 0yyyy0
                case (x)  // Check the column value (x)
                    4'b0000: out_4 = 4'd10; // S3[0][0]
                    4'b0001: out_4 = 4'd0;  // S3[0][1]
                    4'b0010: out_4 = 4'd9;  // S3[0][2]
                    4'b0011: out_4 = 4'd14; // S3[0][3]
                    4'b0100: out_4 = 4'd6;  // S3[0][4]
                    4'b0101: out_4 = 4'd3;  // S3[0][5]
                    4'b0110: out_4 = 4'd15; // S3[0][6]
                    4'b0111: out_4 = 4'd5;  // S3[0][7]
                    4'b1000: out_4 = 4'd1;  // S3[0][8]
                    4'b1001: out_4 = 4'd13; // S3[0][9]
                    4'b1010: out_4 = 4'd12; // S3[0][10]
                    4'b1011: out_4 = 4'd7;  // S3[0][11]
                    4'b1100: out_4 = 4'd11; // S3[0][12]
                    4'b1101: out_4 = 4'd4;  // S3[0][13]
                    4'b1110: out_4 = 4'd2;  // S3[0][14]
                    4'b1111: out_4 = 4'd8;  // S3[0][15]
                endcase
            end

            2'b01: begin // y = 0yyyy1
                case (x)
                    4'b0000: out_4 = 4'd13; // S3[1][0]
                    4'b0001: out_4 = 4'd7;  // S3[1][1]
                    4'b0010: out_4 = 4'd0;  // S3[1][2]
                    4'b0011: out_4 = 4'd9;  // S3[1][3]
                    4'b0100: out_4 = 4'd3;  // S3[1][4]
                    4'b0101: out_4 = 4'd4;  // S3[1][5]
                    4'b0110: out_4 = 4'd6;  // S3[1][6]
                    4'b0111: out_4 = 4'd10; // S3[1][7]
                    4'b1000: out_4 = 4'd2;  // S3[1][8]
                    4'b1001: out_4 = 4'd8;  // S3[1][9]
                    4'b1010: out_4 = 4'd5;  // S3[1][10]
                    4'b1011: out_4 = 4'd14; // S3[1][11]
                    4'b1100: out_4 = 4'd12; // S3[1][12]
                    4'b1101: out_4 = 4'd11; // S3[1][13]
                    4'b1110: out_4 = 4'd15; // S3[1][14]
                    4'b1111: out_4 = 4'd1;  // S3[1][15]
                endcase
            end

            2'b10: begin // y = 1yyyy0
                case (x)
                    4'b0000: out_4 = 4'd13; // S3[2][0]
                    4'b0001: out_4 = 4'd6;  // S3[2][1]
                    4'b0010: out_4 = 4'd4;  // S3[2][2]
                    4'b0011: out_4 = 4'd9;  // S3[2][3]
                    4'b0100: out_4 = 4'd8;  // S3[2][4]
                    4'b0101: out_4 = 4'd15; // S3[2][5]
                    4'b0110: out_4 = 4'd3;  // S3[2][6]
                    4'b0111: out_4 = 4'd0;  // S3[2][7]
                    4'b1000: out_4 = 4'd11; // S3[2][8]
                    4'b1001: out_4 = 4'd1;  // S3[2][9]
                    4'b1010: out_4 = 4'd2;  // S3[2][10]
                    4'b1011: out_4 = 4'd12; // S3[2][11]
                    4'b1100: out_4 = 4'd5;  // S3[2][12]
                    4'b1101: out_4 = 4'd10; // S3[2][13]
                    4'b1110: out_4 = 4'd14; // S3[2][14]
                    4'b1111: out_4 = 4'd7;  // S3[2][15]
                endcase
            end

            2'b11: begin // y = 1yyyy1
                case (x)
                    4'b0000: out_4 = 4'd1;  // S3[3][0]
                    4'b0001: out_4 = 4'd10; // S3[3][1]
                    4'b0010: out_4 = 4'd13; // S3[3][2]
                    4'b0011: out_4 = 4'd0;  // S3[3][3]
                    4'b0100: out_4 = 4'd6;  // S3[3][4]
                    4'b0101: out_4 = 4'd9;  // S3[3][5]
                    4'b0110: out_4 = 4'd8;  // S3[3][6]
                    4'b0111: out_4 = 4'd7;  // S3[3][7]
                    4'b1000: out_4 = 4'd4;  // S3[3][8]
                    4'b1001: out_4 = 4'd15; // S3[3][9]
                    4'b1010: out_4 = 4'd14; // S3[3][10]
                    4'b1011: out_4 = 4'd3;  // S3[3][11]
                    4'b1100: out_4 = 4'd11; // S3[3][12]
                    4'b1101: out_4 = 4'd5;  // S3[3][13]
                    4'b1110: out_4 = 4'd2;  // S3[3][14]
                    4'b1111: out_4 = 4'd12; // S3[3][15]
                endcase
            end

        endcase
    end

endmodule
