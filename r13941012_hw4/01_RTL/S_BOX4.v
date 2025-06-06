module S_BOX4 (
    input [5:0] in_6,   // 6-bit input to the S-box
    output reg [3:0] out_4  // 4-bit output after substitution
);

    wire [3:0] x = in_6[4:1]; 
    wire [1:0] y = {in_6[5], in_6[0]}; 

    always @(*) begin
        case (y)  // Check the row value (y)
            2'b00: begin // y = 0yyyy0
                case (x)  // Check the column value (x)
                    4'b0000: out_4 = 4'd7;  
                    4'b0001: out_4 = 4'd13; 
                    4'b0010: out_4 = 4'd14;
                    4'b0011: out_4 = 4'd3;  
                    4'b0100: out_4 = 4'd0; 
                    4'b0101: out_4 = 4'd6; 
                    4'b0110: out_4 = 4'd9; 
                    4'b0111: out_4 = 4'd10; 
                    4'b1000: out_4 = 4'd1; 
                    4'b1001: out_4 = 4'd2;  
                    4'b1010: out_4 = 4'd8; 
                    4'b1011: out_4 = 4'd5;  
                    4'b1100: out_4 = 4'd11; 
                    4'b1101: out_4 = 4'd12;
                    4'b1110: out_4 = 4'd4;  
                    4'b1111: out_4 = 4'd15; 
                endcase
            end

            2'b01: begin // y = 0yyyy1
                case (x)
                    4'b0000: out_4 = 4'd13;
                    4'b0001: out_4 = 4'd8;
                    4'b0010: out_4 = 4'd11;
                    4'b0011: out_4 = 4'd5;
                    4'b0100: out_4 = 4'd6;
                    4'b0101: out_4 = 4'd15;
                    4'b0110: out_4 = 4'd0;
                    4'b0111: out_4 = 4'd3;
                    4'b1000: out_4 = 4'd4;
                    4'b1001: out_4 = 4'd7;
                    4'b1010: out_4 = 4'd2;
                    4'b1011: out_4 = 4'd12;
                    4'b1100: out_4 = 4'd1;
                    4'b1101: out_4 = 4'd10;
                    4'b1110: out_4 = 4'd14;
                    4'b1111: out_4 = 4'd9;
                endcase
            end

            2'b10: begin // y = 1yyyy0
                case (x)
                    4'b0000: out_4 = 4'd10;
                    4'b0001: out_4 = 4'd6;
                    4'b0010: out_4 = 4'd9;
                    4'b0011: out_4 = 4'd0;
                    4'b0100: out_4 = 4'd12;
                    4'b0101: out_4 = 4'd11;
                    4'b0110: out_4 = 4'd7;
                    4'b0111: out_4 = 4'd13;
                    4'b1000: out_4 = 4'd15;
                    4'b1001: out_4 = 4'd1;
                    4'b1010: out_4 = 4'd3;
                    4'b1011: out_4 = 4'd14;
                    4'b1100: out_4 = 4'd5;
                    4'b1101: out_4 = 4'd2;
                    4'b1110: out_4 = 4'd8;
                    4'b1111: out_4 = 4'd4;
                endcase
            end

            2'b11: begin // y = 1yyyy1
                case (x)
                    4'b0000: out_4 = 4'd3;
                    4'b0001: out_4 = 4'd15;
                    4'b0010: out_4 = 4'd0;
                    4'b0011: out_4 = 4'd6;
                    4'b0100: out_4 = 4'd10;
                    4'b0101: out_4 = 4'd1;
                    4'b0110: out_4 = 4'd13;
                    4'b0111: out_4 = 4'd8;
                    4'b1000: out_4 = 4'd9;
                    4'b1001: out_4 = 4'd4;
                    4'b1010: out_4 = 4'd5;
                    4'b1011: out_4 = 4'd11;
                    4'b1100: out_4 = 4'd12;
                    4'b1101: out_4 = 4'd7;
                    4'b1110: out_4 = 4'd2;
                    4'b1111: out_4 = 4'd14;
                endcase
            end
        endcase
    end
endmodule
