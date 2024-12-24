/*Hao Syuan Chen*/ 
/*2024/10 CVSD*/
// `include "../00_TB/define.v"
// `include "my_define.sv"
// `include "alu.sv"
// `include "DW_fp_addsub.v"
// `include "FP_addsuber.sv"
// `include "Left_Shift_To_Msb.sv"
// `include "FP_compare.sv"
module core #( // DO NOT MODIFY INTERFACE!!!
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) ( 
    input i_clk,
    input i_rst_n,

    // Testbench IOs
    output [2:0] o_status, 
    output       o_status_valid,

    // Memory IOs
    output [ADDR_WIDTH-1:0] o_addr,
    output [DATA_WIDTH-1:0] o_wdata,
    output                  o_we,
    input  [DATA_WIDTH-1:0] i_rdata
);

/*States*/
typedef enum logic [2:0] {
    S_IF  = 3'd0,  // Instruction Fetch
    S_ID  = 3'd1,  // Instruction Decode
    S_EXE = 3'd2,  // Execution
    S_MEM = 3'd3,  // Memory
    S_WB  = 3'd4,  // Write Back
    S_END = 3'd5,  // Process End
    S_EXC = 3'd6   // Exception Happen
} state_t;
state_t cs, ns;

typedef enum logic[2:0] { 
    R_TYPE = 3'd0,
    I_TYTE = 3'd1,
    S_TYPE = 3'd2,
    B_TYPE = 3'd3,
    INVALID_TYPE = 3'd4,
    EOF_TYPE = 3'd5
}type_t;

integer i;
localparam FROM_RS2 = 1'b0;
localparam FROM_IMM = 1'b1;
localparam FROM_ALU = 1'b0;
localparam FROM_MEM = 1'b1;
localparam FROM_PC4 = 1'b0;
localparam FROM_BRANCH = 1'b1;

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
reg exception_flag;
reg finish_flag;
wire is_float_inst = (`OP_CODE==`OP_FADD || `OP_CODE==`OP_FLW || `OP_CODE==`OP_FSW);
reg [DATA_WIDTH-1:0] alu_src1, alu_src2;
reg [DATA_WIDTH-1:0] wb_value;
wire [DATA_WIDTH-1:0] alu_out;
reg [DATA_WIDTH-1:0] branch_pc;
reg [DATA_WIDTH-1:0] signed_imm;
wire alu_exception;
reg branch_exception;
reg [2:0] o_status_w;
reg is_branch_inst;


reg [DATA_WIDTH-1:0] regfile_int [0:31];
reg [DATA_WIDTH-1:0] regfile_float [0:31];
reg [DATA_WIDTH-1:0] pc;
reg [DATA_WIDTH-1:0] o_addr_r;
reg [DATA_WIDTH-1:0] rs1_value_r, rs2_value_r;
reg signed [DATA_WIDTH-1:0] signed_imm_r; 
reg [DATA_WIDTH-1:0] alu_out_r;
reg [2:0] type_r;
reg [4:0] rd_index_r;
reg [2:0] func3_r;
reg [6:0] func7_r;
reg [6:0] opcode_r;
reg i_we_r;
reg f_we_r;
reg wb_sel_r;
reg pc_sel_r;
reg alu_src2_sel_r;
reg is_load_store_r;

assign o_status = o_status_w;

// ---------------------------------------------------------------------------
// Finite State Machine
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        cs <= S_IF;
    end
    else begin
        cs <= ns;
    end
end

always @(*) begin
    ns = S_IF;
    case(cs)
        S_IF :  ns = (exception_flag) ? S_EXC : S_ID; 
        S_ID :  ns = (finish_flag) ? S_END : S_EXE;
        S_EXE : ns = (exception_flag) ? S_EXC : S_MEM;
        S_MEM : ns = (exception_flag) ? S_EXC : S_WB;
        S_WB :  ns = S_IF;
        S_END : ns = S_END;
        S_EXC : ns = S_EXC;
    endcase
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------

/*Instruction Decode*/
always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        type_r <= R_TYPE;
        rs1_value_r <= 32'd0;
        rs2_value_r <= 32'd0;
        signed_imm_r <= 32'd0;
        rd_index_r <= 5'd0;
        func3_r <= 3'd0;
        func7_r <= 7'd0;
        opcode_r <= 7'd0;
        alu_src2_sel_r <= 1'b0;
        wb_sel_r <= 1'b0;
        i_we_r <= 1'b0;
        f_we_r <= 1'b0;
        is_load_store_r <= 1'b0;
    end
    else if (cs == S_ID)begin
        rs1_value_r <= (`OP_CODE==`OP_FADD) ?  regfile_float[`RS1_INDEX] : regfile_int[`RS1_INDEX];
        rs2_value_r <= (`OP_CODE==`OP_FADD || `OP_CODE==`OP_FSW) ? regfile_float[`RS2_INDEX] : regfile_int[`RS2_INDEX];
        rd_index_r <= `RD_INDEX;
        func3_r <= `FUNC3;
        func7_r <= `FUNC7;
        opcode_r <= `OP_CODE;
        is_load_store_r <= (`OP_CODE==`OP_FLW || `OP_CODE==`OP_LW || `OP_CODE==`OP_SW || `OP_CODE==`OP_FSW) ? 1'b1 : 1'b0;
        //R-type Instruction
        if (`OP_CODE==`OP_ADD||`OP_CODE==`OP_FADD) begin
            type_r <= R_TYPE;
            alu_src2_sel_r <= FROM_RS2;
            wb_sel_r <= FROM_ALU;
            //either write regfile_int or regfile_float
            {i_we_r, f_we_r} <= (`OP_CODE==`OP_ADD || (`OP_CODE==`OP_FCLASS && `FUNC7==`FUNCT7_FCLASS) || (`OP_CODE==`OP_FCLASS && `FUNC7==`FUNCT7_FLT)) ? 2'b10 : 2'b01;
        end
        //I-type Instruction
        else if (`OP_CODE==`OP_ADDI||`OP_CODE==`OP_LW||`OP_CODE==`OP_FLW) begin
            type_r <= I_TYTE;
            signed_imm_r <= $signed(`IMM_I);
            alu_src2_sel_r <= FROM_IMM;
            wb_sel_r <= (`OP_CODE==`OP_ADDI) ? FROM_ALU : FROM_MEM;
            //either write regfile_int or regfile_float
            {i_we_r, f_we_r} <= (`OP_CODE==`OP_FLW) ? 2'b01 : 2'b10;
        end
        //S-type Instruction
        else if (`OP_CODE==`OP_SW||`OP_CODE==`OP_FSW) begin
            type_r <= S_TYPE;
            signed_imm_r <= $signed(`IMM_S);
            alu_src2_sel_r <= FROM_IMM;
            {i_we_r, f_we_r} <= 2'd0;
        end
        //B-type Instruction
        else if (`OP_CODE==`OP_BEQ) begin
            type_r <= B_TYPE;
            signed_imm_r <= $signed(`IMM_B);
            alu_src2_sel_r <= FROM_RS2;
            {i_we_r, f_we_r} <= 2'd0;
        end
        //EOF Instruction
        else if (`OP_CODE==`OP_EOF) begin
            type_r <= EOF_TYPE;
            alu_src2_sel_r <= FROM_IMM;
            {i_we_r, f_we_r} <= 2'd0;
        end
    end
end


/*Execution*/
always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        alu_out_r <= 32'd0;
        pc_sel_r <= 1'b0;
    end    
    else if (cs == S_EXE) begin
        alu_out_r <= alu_out;
        pc_sel_r <= (alu_out[0] && opcode_r==`OP_BEQ) ? FROM_BRANCH : FROM_PC4;
    end
end

/*Write Back*/
always @(posedge i_clk or negedge i_rst_n) begin
    if (~i_rst_n) begin
        for(i=0; i<32; i=i+1) begin
            regfile_int[i] <= 32'd0;
            regfile_float[i] <= 32'd0;
        end
        pc <= 32'd0;
    end 
    else if (cs == S_WB) begin
        regfile_int[rd_index_r] <= (i_we_r) ? wb_value : regfile_int[rd_index_r];
        regfile_float[rd_index_r] <= (f_we_r) ? wb_value : regfile_float[rd_index_r];
        pc <= (pc_sel_r) ? branch_pc : pc + 32'd4;
    end
end

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------

assign o_addr = (cs == S_IF) ? pc : alu_out_r;
assign o_wdata = rs2_value_r;
assign o_we = ((opcode_r==`OP_SW || opcode_r==`OP_FSW) && cs==S_MEM && !exception_flag); 
assign o_status_valid = ((cs==S_WB) || cs==S_EXC || cs==S_END);
always @(*) begin
    alu_src1 = rs1_value_r;
    alu_src2 = (alu_src2_sel_r) ?  signed_imm_r : rs2_value_r;
    wb_value = (wb_sel_r) ? i_rdata : alu_out_r; // data memory data or alu result
    branch_pc = $signed(pc) + signed_imm_r; // pc is fetching instruction from data memory
    branch_exception = (opcode_r==`OP_BEQ && branch_pc>32'h00000fff);
    finish_flag = (`OP_CODE == `OP_EOF);
end

always @(*) begin
    if (cs == S_EXE) begin
        exception_flag = alu_exception || branch_exception; //Integer or floating point calculation exception(ie. overflow, NaN...)
    end
    else if (cs == S_MEM) begin
        if (is_load_store_r) begin
            exception_flag = (alu_out_r<32'h00001000 || alu_out_r>32'h00001fff) ? 1'b1 : 1'b0; //load or store data from intruction memory
        end
        else begin
            exception_flag = 1'b0;
        end
    end
    else begin
        exception_flag = 1'b0;
    end
end

//status
always @(*) begin
    if (cs == S_EXC) begin
        o_status_w = INVALID_TYPE;
    end
    else if (cs == S_END) begin
        o_status_w = EOF_TYPE;
    end
    else begin
        o_status_w = type_r;
    end
end
alu alu_inst(
    .i_op1 (alu_src1),
    .i_op2 (alu_src2),
    .i_func3 (func3_r),
    .i_func7 (func7_r),
    .i_opcode (opcode_r),
    .o_out (alu_out),
    .o_exception(alu_exception)
);


endmodule