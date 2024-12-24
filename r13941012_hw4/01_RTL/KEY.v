module KEY (
    input [63:0] main_key,
    output reg [47:0] K1,
    output reg [47:0] K2,
    output reg [47:0] K3,
    output reg [47:0] K4,
    output reg [47:0] K5,
    output reg [47:0] K6,
    output reg [47:0] K7,
    output reg [47:0] K8,
    output reg [47:0] K9,
    output reg [47:0] K10,
    output reg [47:0] K11,
    output reg [47:0] K12,
    output reg [47:0] K13,
    output reg [47:0] K14,
    output reg [47:0] K15,
    output reg [47:0] K16
);
reg [55:0] cipher_key;
always @(*) begin
    cipher_key = PC1(main_key);
    K1 = PC2({cipher_key[54:28], cipher_key[55], cipher_key[26:0], cipher_key[27]});
    K2 = PC2({cipher_key[53:28], cipher_key[55:54], cipher_key[25:0], cipher_key[27:26]});
    K3 = PC2({cipher_key[51:28], cipher_key[55:52], cipher_key[23:0], cipher_key[27:24]});
    K4 = PC2({cipher_key[49:28], cipher_key[55:50], cipher_key[21:0], cipher_key[27:22]});
    K5 = PC2({cipher_key[47:28], cipher_key[55:48], cipher_key[19:0], cipher_key[27:20]});
    K6 = PC2({cipher_key[45:28], cipher_key[55:46], cipher_key[17:0], cipher_key[27:18]});
    K7 = PC2({cipher_key[43:28], cipher_key[55:44], cipher_key[15:0], cipher_key[27:16]});
    K8 = PC2({cipher_key[41:28], cipher_key[55:42], cipher_key[13:0], cipher_key[27:14]});
    K9 = PC2({cipher_key[40:28], cipher_key[55:41], cipher_key[12:0], cipher_key[27:13]});
    K10 = PC2({cipher_key[38:28], cipher_key[55:39], cipher_key[10:0], cipher_key[27:11]});
    K11 = PC2({cipher_key[36:28], cipher_key[55:37], cipher_key[8:0], cipher_key[27:9]});
    K12 = PC2({cipher_key[34:28], cipher_key[55:35], cipher_key[6:0], cipher_key[27:7]});
    K13 = PC2({cipher_key[32:28], cipher_key[55:33], cipher_key[4:0], cipher_key[27:5]});
    K14 = PC2({cipher_key[30:28], cipher_key[55:31], cipher_key[2:0], cipher_key[27:3]});
    K15 = PC2({cipher_key[28], cipher_key[55:29], cipher_key[0], cipher_key[27:1]});
    K16 = PC2(cipher_key);
end

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