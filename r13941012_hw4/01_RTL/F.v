module F (
    input [31:0] R,
    input [47:0] K,
    output reg[31:0] F_out
);

reg [47:0] R_48, R_48_xor;
reg [3:0] S_result [1:8];

S_BOX1 s1 (
    .in_6(R_48_xor[47:42]),
    .out_4(S_result[1])
);
S_BOX2 s2 (
    .in_6(R_48_xor[41:36]),
    .out_4(S_result[2])
);
S_BOX3 s3 (
    .in_6(R_48_xor[35:30]),
    .out_4(S_result[3])
);
S_BOX4 s4 (
    .in_6(R_48_xor[29:24]),
    .out_4(S_result[4])
);
S_BOX5 s5 (
    .in_6(R_48_xor[23:18]),
    .out_4(S_result[5])
);
S_BOX6 s6 (
    .in_6(R_48_xor[17:12]),
    .out_4(S_result[6])
);
S_BOX7 s7 (
    .in_6(R_48_xor[11:6]),
    .out_4(S_result[7])
);
S_BOX8 s8 (
    .in_6(R_48_xor[5:0]),
    .out_4(S_result[8])
);


always @(*) begin
    R_48 = expansion(R);
    R_48_xor = R_48 ^ K;
    F_out = P({S_result[1], S_result[2], S_result[3], S_result[4], S_result[5], S_result[6], S_result[7], S_result[8]});
end

function [31:0] P;
    input [31:0] in_32; 
    begin
        P[31] = in_32[16];
        P[30] = in_32[25];
        P[29] = in_32[12];
        P[28] = in_32[11];
        P[27] = in_32[3];
        P[26] = in_32[20];
        P[25] = in_32[4];
        P[24] = in_32[15];
        P[23] = in_32[31];
        P[22] = in_32[17];
        P[21] = in_32[9];
        P[20] = in_32[6];
        P[19] = in_32[27];
        P[18] = in_32[14];
        P[17] = in_32[1];
        P[16] = in_32[22];
        P[15] = in_32[30];
        P[14] = in_32[24];
        P[13] = in_32[8];
        P[12] = in_32[18];
        P[11] = in_32[0];
        P[10] = in_32[5];
        P[9]  = in_32[29];
        P[8]  = in_32[23];  
        P[7]  = in_32[13];
        P[6]  = in_32[19];
        P[5]  = in_32[2];
        P[4]  = in_32[26];
        P[3]  = in_32[10];
        P[2]  = in_32[21];
        P[1]  = in_32[28];
        P[0]  = in_32[7];
    end
endfunction

function [47:0] expansion;
    input [31:0] in_32; 
    begin
        expansion[47] = in_32[0];
        expansion[46] = in_32[31];
        expansion[45] = in_32[30];
        expansion[44] = in_32[29];
        expansion[43] = in_32[28];
        expansion[42] = in_32[27];
        expansion[41] = in_32[28];
        expansion[40] = in_32[27]; 
        expansion[39] = in_32[26];
        expansion[38] = in_32[25];
        expansion[37] = in_32[24];
        expansion[36] = in_32[23];
        expansion[35] = in_32[24];
        expansion[34] = in_32[23];
        expansion[33] = in_32[22];
        expansion[32] = in_32[21];
        expansion[31] = in_32[20];
        expansion[30] = in_32[19];
        expansion[29] = in_32[20];
        expansion[28] = in_32[19];
        expansion[27] = in_32[18];
        expansion[26] = in_32[17];
        expansion[25] = in_32[16];
        expansion[24] = in_32[15];
        expansion[23] = in_32[16];
        expansion[22] = in_32[15];
        expansion[21] = in_32[14];
        expansion[20] = in_32[13];
        expansion[19] = in_32[12];
        expansion[18] = in_32[11];
        expansion[17] = in_32[12];
        expansion[16] = in_32[11];
        expansion[15] = in_32[10];
        expansion[14] = in_32[9];
        expansion[13] = in_32[8];
        expansion[12] = in_32[7];
        expansion[11] = in_32[8];
        expansion[10] = in_32[7];
        expansion[9]  = in_32[6];
        expansion[8]  = in_32[5];
        expansion[7]  = in_32[4];
        expansion[6]  = in_32[3];
        expansion[5]  = in_32[4];
        expansion[4]  = in_32[3];
        expansion[3]  = in_32[2];
        expansion[2]  = in_32[1];
        expansion[1]  = in_32[0];
        expansion[0]  = in_32[31];
    end
endfunction
endmodule