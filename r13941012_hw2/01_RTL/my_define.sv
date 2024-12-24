//
`define OP_CODE i_rdata[6:0]
`define FUNC3 i_rdata[14:12]
`define FUNC7 i_rdata[31:25]
`define RD_INDEX i_rdata[11:7]
`define RS1_INDEX i_rdata[19:15]
`define RS2_INDEX i_rdata[24:20]
`define IMM_I i_rdata[31:20]
`define IMM_B {i_rdata[31],i_rdata[7],i_rdata[30:25],i_rdata[11:8],1'b0}
`define IMM_S {i_rdata[31:25],i_rdata[11:7]}