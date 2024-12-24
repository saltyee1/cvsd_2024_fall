/*Hao Syuan Chen*/
/*CVSD HW3*/
// `include "DMA.sv"
// `include "PE.sv"
// `include "define.sv"
module core (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,
	input         i_in_valid,
	input  [ 7:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [13:0] o_out_data
);


typedef enum logic [3:0]{
	S_IDLE,
	S_WAIT,
	S_LOADING,
	S_CONV,
	S_MEDIAN,
	S_SGNMS,
	S_DISPLAY
} type_s;



localparam MODE_LOAD = 2'd0;
localparam MODE_DISPLAY = 2'd1;
localparam MODE_CONV = 2'd2;
integer i;
///		wire		///
reg [5:0] origin_n;
reg [2:0] col_n, row_n;
reg [4:0] depth_n;
reg [1:0] dma_mode_n;
reg op_ready_n;
reg in_ready_n;
reg out_valid_n;
reg [7:0] out_data_n;
reg [10:0] counter_n;
wire [7:0] dma_addr_w;
wire [2:0] dma_mem_sel_w;
wire dma_zero_w;
reg [7:0] mem_wen_w;
reg [7:0] mem_data_w [0:7];
wire [7:0] median_w [0:3];
reg [3:0] pe_en_w;
reg [3:0] pe_clear_w;
reg [1:0] pe_sel_n;
reg [3:0] pe_mode_w [0:3];
reg [13:0] pe_conv_out [0:3];
reg [13:0] odata_from_pe_w;
reg [63:0] mem_data_arr;
wire [11:0] pe_gradient_w [0:3];
wire [1:0] pe_direction_w [0:3];
wire [13:0] pe_nms_out_w [0:3];
reg [14:0] nms_result_arr_n [0:3];
reg [1:0] nms_cnt;
///		buffer		///
reg op_valid_buff;
reg [3:0] op_mode_buff;
reg in_valid_buff;
reg [7:0] in_data_buff;
reg op_ready_buff;
reg in_ready_buff;
reg out_valid_buff;
reg [7:0] out_data_buff;


///		register	///
type_s cs, ns;
reg [10:0] counter;
reg [5:0] origin;
reg [4:0] depth;
reg [1:0] dma_mode_r;
reg [7:0] mem_data_r;
reg dma_zero_r;
reg [2:0] mem_sel_r;
reg [1:0] pe_sel_r;
reg [11:0] gradient_arr [0:3];
reg [1:0] direction_arr [0:3];
reg [13:0] nms_result_arr [0:3];

wire [6:0] display_num = {depth, 2'b11};																	
DMA u_dma(
	.i_counter(counter),
	.i_mode(dma_mode_r),
	.i_origin(origin[5:0]),
	.o_mem_addr(dma_addr_w),
	.o_mem_sel(dma_mem_sel_w),
	.o_zero(dma_zero_w)
);

genvar gi;
generate
    for (gi = 0; gi < 8; gi = gi + 1) begin : sram_gen
        sram_256x8 s_mem (
            .A(dma_addr_w),
            .D(in_data_buff),
            .CLK(i_clk),
            .CEN(1'b0),  // chip on
            .WEN(mem_wen_w[gi]),	//0 is write, 1 is read
            .Q(mem_data_w[gi])
        );
	end
	for (gi = 0; gi < 4; gi = gi + 1) begin : pe_gen
		PE u_pe (
			.i_clk(i_clk),
			.i_rst_n(i_rst_n),
			.i_en(pe_en_w[gi]),
			.i_clear(pe_clear_w[gi]),
			.i_mode(pe_mode_w[gi]),
			.i_data(mem_data_r),
			.i_data0(mem_data_arr[7:0]),
			.i_data_arr(mem_data_arr),
			.o_median(median_w[gi]),
			.o_conv_result(pe_conv_out[gi]),
			.o_gradient(pe_gradient_w[gi]),
			.o_direction(pe_direction_w[gi])
		);
    end
endgenerate
// ---------------------------------------------------------------------------
// Finite State Machine
// ---------------------------------------------------------------------------
always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		cs <= S_IDLE;
	end
	else begin
		cs <= ns;
	end
end
//Next State Logic
always @(*) begin
	ns = S_WAIT;
	case (cs)
		S_IDLE : ns = S_WAIT;
		S_WAIT : begin
			if (op_valid_buff) begin
				case (op_mode_buff)
					`OP_LOAD : ns = S_LOADING;
					`OP_DISPLAY : ns = S_DISPLAY;
					`OP_MEDIAN : ns = S_MEDIAN;
					`OP_CONV : ns = S_CONV;
					`OP_SGNMS : ns = S_SGNMS;
					`OP_SHIFT_D : ns = S_WAIT;
					`OP_SHIFT_U : ns = S_WAIT;
					`OP_SHIFT_R : ns = S_WAIT;
					`OP_SHIFT_L : ns = S_WAIT;
					`OP_INCREASE : ns = S_WAIT;
					`OP_REDUCE : ns = S_WAIT;
				endcase
			end
			else begin
				ns = S_WAIT;
			end
		end 
		S_LOADING : ns = (counter == 11'd2047) ? S_WAIT : S_LOADING;
		S_DISPLAY : ns = (counter == display_num + 11'd2) ? S_WAIT : S_DISPLAY;
		S_MEDIAN : ns = (counter[6:0] == 7'd66) ? S_WAIT : S_MEDIAN;
		S_CONV : ns = (counter[6:0] == 7'd68) ? S_WAIT : S_CONV;
		S_SGNMS : ns = (counter[6:0] == 7'd72) ? S_WAIT : S_SGNMS;
	endcase
end


// ---------------------------------------------------------------------------
// Sequencial Blocks
// ---------------------------------------------------------------------------

///in/out buffer 
assign o_op_ready = op_ready_buff;
assign o_in_ready = in_ready_buff;
assign o_out_valid = out_valid_buff;
assign o_out_data = (cs == S_DISPLAY) ? out_data_buff : odata_from_pe_w;

always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		op_valid_buff <= 1'b0;
		op_mode_buff <= 4'b0;
		in_valid_buff <= 1'b0;
		in_data_buff <= 8'd0;
		op_ready_buff <= 1'b0;
		in_ready_buff <= 1'b0;
		out_valid_buff <= 1'b0;
		out_data_buff <= 14'd0;
	end
	else begin
		// input buffer
		op_valid_buff <= i_op_valid;
		op_mode_buff <= i_op_mode;
		in_valid_buff <= i_in_valid;
		in_data_buff <= i_in_data;
		// output buffer
		op_ready_buff <= op_ready_n;
		in_ready_buff <= in_ready_n;
		out_valid_buff <= out_valid_n;
		out_data_buff <= out_data_n;
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		origin <= 6'd0;
		depth <= 5'd31;
		counter <= 11'd0;
		dma_mode_r <= 2'd0;
		mem_data_r <= 8'd0;
		mem_sel_r <= 4'd0;
		dma_zero_r <= 1'b0;
		pe_sel_r <= 2'd0;
	end
	else begin
		origin <= origin_n;
		depth <= depth_n;
		counter <= counter_n;
		dma_mode_r <= dma_mode_n;
		mem_data_r <= (dma_zero_r) ? 8'd0 : mem_data_w[mem_sel_r];
		mem_sel_r <= dma_mem_sel_w;
		dma_zero_r <= dma_zero_w;
		pe_sel_r <= pe_sel_n;
	end
end

always @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		for(i=0; i<4; i=i+1) begin
			gradient_arr[i] <= 12'd0;
			direction_arr[i] <= 2'd0;
            nms_result_arr[i] <= 14'b0;
		end
		nms_cnt <= 2'd0;
	end
	else if (cs == S_SGNMS)begin
		if(counter > 11'd13) begin
			if (counter[3:0] == 4'd14) begin    //14, 30, 46, 62
				gradient_arr[0] <= pe_gradient_w[0];
				direction_arr[0] <= pe_direction_w[0];
			end	
			if (counter[3:0] == 4'd15) begin    //15, 31, 47, 63
				gradient_arr[1] <= pe_gradient_w[1];
				direction_arr[1] <= pe_direction_w[1];
			end
			if (counter[3:0] == 4'd2) begin     //18, 34, 50, 66
				gradient_arr[2] <= pe_gradient_w[2];
				direction_arr[2] <= pe_direction_w[2];
			end
			if (counter[3:0] == 4'd3) begin     //19, 35, 51, 67
				gradient_arr[3] <= pe_gradient_w[3];
				direction_arr[3] <= pe_direction_w[3];
			end
            if(counter[3:0] == 4'd4) begin //from 20, 36, 52, 68
                for(i=0; i<4; i=i+1) begin
                    nms_result_arr[i] <= nms_result_arr_n[i];
                end
            end
        end
        nms_cnt <= (counter[3:0]==4'd4) ? 2'd0 : nms_cnt + 2'd1;
	end
end

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------

//output logic
always @(*) begin
	op_ready_n = 1'b0;
	in_ready_n = 1'b1;
	out_valid_n = 1'b0;
	out_data_n = 14'd0;
	odata_from_pe_w = 14'd0;
	case (cs)
		S_IDLE : begin
			op_ready_n = 1'b1;
		end 
		S_WAIT : begin
			op_ready_n = (op_mode_buff > 4'd0 && op_mode_buff < 4'd7); 
		end
		S_LOADING : begin
			op_ready_n = (counter == 11'd2047);
		end
		S_DISPLAY : begin
			out_valid_n = (counter <= display_num + 11'd1 && counter != 11'd0);
			out_data_n = {6'd0, mem_data_w[mem_sel_r]};
			op_ready_n = (counter == display_num + 11'd2);	//add one cycle for o_out_valid to avoid o_out_valid and o_op_ready both high
		end
		S_MEDIAN : begin
			out_valid_n = (counter[3:0]==4'd12) || (counter[3:0]==4'd13) || ((counter[3:0]==4'd0) && (counter[6:0]!=7'd0)) || ((counter[3:0]==4'd1) && (counter[6:0]!=7'd1));
			// out_data_n = 	use register in peian (peian_w) as output
			op_ready_n = (counter[6:0] == 7'd66);
			odata_from_pe_w = median_w[pe_sel_r];
		end
		S_CONV : begin
			out_valid_n = (counter[6:0]==7'd62 || counter[6:0]==7'd63 || counter[6:0]==7'd66 || counter[6:0]==7'd67);
			op_ready_n = (counter[6:0]==7'd68);
			odata_from_pe_w = pe_conv_out[pe_sel_r];
		end
		S_SGNMS : begin
			out_valid_n = ((counter[3:0]==4'd4) || (counter[3:0]==4'd5) || ((counter[3:0]==4'd6)) || ((counter[3:0]==4'd7))) && ((counter[6:0]>7'd19));
			op_ready_n = (counter[6:0]==7'd72);
			odata_from_pe_w = nms_result_arr[nms_cnt];
		end
	endcase
end

//origin and depth
always @(*) begin
	depth_n = depth;
	col_n = `ORIGIN_COL;
	row_n = `ORIGIN_ROW;
	if (cs==S_WAIT && op_valid_buff) begin
		case (op_mode_buff)
			`OP_SHIFT_D : row_n = (`ORIGIN_ROW==3'd6) ? `ORIGIN_ROW : `ORIGIN_ROW+3'd1;		// boundary case
			`OP_SHIFT_U : row_n = (`ORIGIN_ROW==3'd0) ? `ORIGIN_ROW : `ORIGIN_ROW-3'd1;
			`OP_SHIFT_R : col_n = (`ORIGIN_COL==3'd6) ? `ORIGIN_COL : `ORIGIN_COL+3'd1;
			`OP_SHIFT_L : col_n = (`ORIGIN_COL==3'd0) ? `ORIGIN_COL : `ORIGIN_COL-3'd1;
			`OP_INCREASE : depth_n = (depth==5'd31) ? depth : {depth[3:0], 1'b1};
			`OP_REDUCE : depth_n = (depth==5'd7) ? depth : {1'b0, depth[4:1]};
		endcase
	end
	origin_n = {row_n, col_n};
end

always @(*) begin
	counter_n = 11'd0;
	case (cs)
		S_WAIT : counter_n = 11'd0;
		S_LOADING : counter_n = (in_valid_buff) ? counter + 11'd1 : counter;
		S_DISPLAY, S_MEDIAN, S_CONV, S_SGNMS : counter_n = counter + 11'd1;
	endcase
	dma_mode_n = dma_mode_r;
	if (cs == S_WAIT) begin
		if (op_mode_buff == `OP_LOAD) begin
			dma_mode_n = MODE_LOAD;
		end
		else if (op_mode_buff == `OP_DISPLAY) begin
			dma_mode_n = MODE_DISPLAY;
		end
		else if (op_mode_buff == `OP_CONV || op_mode_buff == `OP_MEDIAN || op_mode_buff == `OP_SGNMS) begin
			dma_mode_n = MODE_CONV;
		end
	end

	mem_wen_w = 8'hff;
	if (cs == S_LOADING) begin
		case (dma_mem_sel_w) 	//choose which mem to write
			3'd0 : mem_wen_w = 8'b11111110;
			3'd1 : mem_wen_w = 8'b11111101; 
			3'd2 : mem_wen_w = 8'b11111011;
			3'd3 : mem_wen_w = 8'b11110111;
			3'd4 : mem_wen_w = 8'b11101111;
			3'd5 : mem_wen_w = 8'b11011111;
			3'd6 : mem_wen_w = 8'b10111111; 
			3'd7 : mem_wen_w = 8'b01111111; 
		endcase
	end

	mem_data_arr = {mem_data_w[7], mem_data_w[6], mem_data_w[5], mem_data_w[4], mem_data_w[3], mem_data_w[2], mem_data_w[1], mem_data_w[0]};
	if(dma_zero_r) begin
		mem_data_arr = 63'd0;
	end
	else begin
		case (depth) 
			5'd31 :  mem_data_arr = {mem_data_w[7], mem_data_w[6], mem_data_w[5], mem_data_w[4], mem_data_w[3], mem_data_w[2], mem_data_w[1], mem_data_w[0]};
			5'd15 :	mem_data_arr = {32'd0, mem_data_w[3], mem_data_w[2], mem_data_w[1], mem_data_w[0]};
			5'd7 :  mem_data_arr = {48'd0, mem_data_w[1], mem_data_w[0]};
		endcase
	end

	pe_clear_w = 4'b0;
	pe_en_w = 4'b0;
	pe_sel_n = 2'b0;

	if (cs == S_MEDIAN && counter >= 11'd2) begin
		case (counter[3:0])
			4'd2 : pe_en_w[0] = 1'b1;
			4'd3, 4'd4 : {pe_en_w[0],pe_en_w[1]} = 2'b11;
			4'd5 : pe_en_w[1] = 1'b1;
			4'd6, 4'd10 : {pe_en_w[0],pe_en_w[2]} = 2'b11;
			4'd7, 4'd8, 4'd11, 4'd12 : pe_en_w = 4'b1111;
			4'd9, 4'd13 : {pe_en_w[1], pe_en_w[3]} = 2'b11;
			4'd14 : pe_en_w[2] = 1'b1;
			4'd15, 4'd0 : {pe_en_w[2], pe_en_w[3]} = 2'b11;
			4'd1 : pe_en_w[3] = 1'b1;
		endcase
	end
	else if (((cs == S_CONV) || (cs==S_SGNMS)) && counter >= 11'd1) begin
		case (counter[3:0])
			4'd1 : pe_en_w[0] = 1'b1;
			4'd2, 4'd3 : {pe_en_w[0],pe_en_w[1]} = 2'b11;
			4'd4 : pe_en_w[1] = 1'b1;
			4'd5, 4'd9 : {pe_en_w[0],pe_en_w[2]} = 2'b11;
			4'd6, 4'd7, 4'd10, 4'd11 : pe_en_w = 4'b1111;
			4'd8, 4'd12 : {pe_en_w[1], pe_en_w[3]} = 2'b11;
			4'd13 : pe_en_w[2] = 1'b1;
			4'd14, 4'd15 : {pe_en_w[2], pe_en_w[3]} = 2'b11;
			4'd0 : pe_en_w[3] = 1'b1;
		endcase
	end
	if (cs == S_WAIT) begin
		pe_clear_w = 4'b1111;
	end
	else if ((cs == S_MEDIAN || cs == S_SGNMS) && counter >= 11'd2) begin
		pe_clear_w[0] = (counter[3:0] == 4'd13);   //at 13, 
		pe_clear_w[1] = (counter[3:0] == 4'd14);
		pe_clear_w[2] = (counter[3:0] == 4'd1);
		pe_clear_w[3] = (counter[3:0] == 4'd2); 
	end

	case(cs)
		S_MEDIAN : begin
			case(counter[3:0]) 
				4'd12 : pe_sel_n = 2'd0;		//output result from which peian_pe
				4'd13 : pe_sel_n = 2'd1;
				4'd0 : pe_sel_n = 2'd2;
				4'd1 : pe_sel_n = 2'd3;
			endcase
		end
		S_CONV, S_SGNMS : begin
			case(counter[2:0])
				3'd6 : pe_sel_n = 2'd0;		//output result from which peian_conv
				3'd7 : pe_sel_n = 2'd1;
				3'd2 : pe_sel_n = 2'd2;
				3'd3 : pe_sel_n = 2'd3;
			endcase
		end
		
	endcase

	pe_mode_w[0] = 4'd0;
	pe_mode_w[1] = 4'd0;
	pe_mode_w[2] = 4'd0;
	pe_mode_w[3] = 4'd0;

	case (cs)
		S_MEDIAN : begin	//do peien
			pe_mode_w[0] = `PE_MED;
			pe_mode_w[1] = `PE_MED;
			pe_mode_w[2] = `PE_MED;
			pe_mode_w[3] = `PE_MED;
		end
		S_CONV : begin
			case (counter[3:0]) 
				4'd1, 4'd3, 4'd9, 4'd11 	: pe_mode_w[0] = `PE_CONV1_16;
				4'd2, 4'd5, 4'd7, 4'd10 	: pe_mode_w[0] = `PE_CONV1_8;
				4'd6 						: pe_mode_w[0] = `PE_CONV1_4;
			endcase
			case (counter[3:0]) 
				4'd2, 4'd4, 4'd10, 4'd12 	: pe_mode_w[1] = `PE_CONV1_16;
				4'd3, 4'd6, 4'd8, 4'd11 	: pe_mode_w[1] = `PE_CONV1_8;
				4'd7 						: pe_mode_w[1] = `PE_CONV1_4;
			endcase
			case (counter[3:0]) 
				4'd5, 4'd7, 4'd13, 4'd15 	: pe_mode_w[2] = `PE_CONV1_16;
				4'd6, 4'd9, 4'd11, 4'd14 	: pe_mode_w[2] = `PE_CONV1_8;
				4'd10 						: pe_mode_w[2] = `PE_CONV1_4;
			endcase
			case (counter[3:0]) 
				4'd6, 4'd8, 4'd14, 4'd0 	: pe_mode_w[3] = `PE_CONV1_16;
				4'd7, 4'd10, 4'd12, 4'd15	: pe_mode_w[3] = `PE_CONV1_8;
				4'd11 						: pe_mode_w[3] = `PE_CONV1_4;
			endcase
		end
		S_SGNMS : begin
			pe_mode_w[0] = `PE_NMS0;
			pe_mode_w[1] = `PE_NMS0;
			pe_mode_w[2] = `PE_NMS0;
			pe_mode_w[3] = `PE_NMS0;
		end
	endcase
end

always @(*) begin
    case (direction_arr[0])
        2'd0 : nms_result_arr_n[0] = (gradient_arr[0] >= gradient_arr[1]) ? gradient_arr[0] : 14'd0;
        2'd1 : nms_result_arr_n[0] = (gradient_arr[0] >= gradient_arr[3]) ? gradient_arr[0] : 14'd0;
        2'd2 : nms_result_arr_n[0] = (gradient_arr[0] >= gradient_arr[2]) ? gradient_arr[0] : 14'd0;
        2'd3 : nms_result_arr_n[0] = gradient_arr[0];
    endcase
    case (direction_arr[1])
        2'd0 : nms_result_arr_n[1] = (gradient_arr[1] >= gradient_arr[0]) ? gradient_arr[1] : 14'd0;
        2'd1 : nms_result_arr_n[1] = gradient_arr[1];
        2'd2 : nms_result_arr_n[1] = (gradient_arr[1] >= gradient_arr[3]) ? gradient_arr[1] : 14'd0;
        2'd3 : nms_result_arr_n[1] = (gradient_arr[1] >= gradient_arr[2]) ? gradient_arr[1] : 14'd0;
    endcase
    case (direction_arr[2])
        2'd0 : nms_result_arr_n[2] = (gradient_arr[2] >= gradient_arr[3]) ? gradient_arr[2] : 14'd0;
        2'd1 : nms_result_arr_n[2] = gradient_arr[2];
        2'd2 : nms_result_arr_n[2] = (gradient_arr[2] >= gradient_arr[0]) ? gradient_arr[2] : 14'd0;
        2'd3 : nms_result_arr_n[2] = (gradient_arr[2] >= gradient_arr[1]) ? gradient_arr[2] : 14'd0;
    endcase
    case (direction_arr[3])
        2'd0 : nms_result_arr_n[3] = (gradient_arr[3] >= gradient_arr[2]) ? gradient_arr[3] : 14'd0;
        2'd1 : nms_result_arr_n[3] = (gradient_arr[3] >= gradient_arr[0]) ? gradient_arr[3] : 14'd0;
        2'd2 : nms_result_arr_n[3] = (gradient_arr[3] >= gradient_arr[1]) ? gradient_arr[3] : 14'd0;
        2'd3 : nms_result_arr_n[3] = gradient_arr[3];
    endcase
    
end



endmodule
