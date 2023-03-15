`timescale 1ns/1ps

module m_decoder(
	input				 	i_clk			,
	input				 	i_rst_n			,
	input				 	i_rx_en			,
	input		[7:0]	 	i_rx_data		,
	output reg		 		o_led_en		,
	output reg	[31:0] 		o_para_list		,
	output reg	[7:0] 		o_check
    );

	//帧头
localparam DATA_FRAME_HEADER	= 8'h40;	
	//帧尾或校验和
localparam DATA_FRAME_TAIL		= 8'hbc;	
	
	//状态
localparam IDLE		=			4'd0;	
localparam CLEN		=			4'd1;	//包长
localparam RXDB 	=			4'd2; 	//cmd+para        
localparam EOF1		=			4'd3;	//结束/帧尾/校验
localparam DONE		=			4'd4;	

reg		[3:0]			r_cstate,r_nstate;
reg		[3:0]			r_bytecnt;
reg		[7:0]			r_cmdlen;
////////////////////////////////////////////
//时序逻辑状态切换

always @(posedge i_clk)
	if(!i_rst_n) r_cstate <= IDLE;
	else r_cstate <= r_nstate;

////////////////////////////////////////////
//组合逻辑切换状态

always @(*) begin
	case(r_cstate)
		IDLE: begin
			if(i_rx_en) begin
				if(i_rx_data == DATA_FRAME_HEADER) r_nstate = CLEN;
				else r_nstate = IDLE;
			end
			else r_nstate = IDLE;
		end	
		CLEN: begin
			if(i_rx_en) begin
				if(i_rx_data >= 8'd1) r_nstate = RXDB;
				else r_nstate = CLEN;
			end
			else r_nstate = CLEN;
		end	
		
		RXDB: begin
			if(i_rx_en) begin//r_cmdlen-1		//4'd5
				if(r_bytecnt >= r_cmdlen-2) r_nstate = EOF1;//数据包长度改为可变的
				else r_nstate = RXDB;
			end
			else r_nstate = RXDB;
		end	
		
		EOF1: begin
			if(i_rx_en) begin//  下面条件，数据包长度+1后必须是帧尾，并判断是否与预定的帧尾相同				
				if(i_rx_data == DATA_FRAME_TAIL) r_nstate = DONE;
				else r_nstate = IDLE;
			end
			else r_nstate = EOF1;
		end		
		
		DONE:begin 
			r_nstate = IDLE;
			r_cmdlen=8'd0;
		end
		default: ;
	endcase
end
	
////////////////////////////////////////////
//获得命令包的数据长度(不包括引导码)
always @(posedge i_clk)
	if(r_cstate == CLEN) begin
		if(i_rx_en) r_cmdlen <= i_rx_data;	//
		else ;
	end
	
//对有效数据字节进行计数（有效数据：命令码+参数列表）
always @(posedge i_clk)
	if((r_cstate == RXDB)&&(r_bytecnt<=r_cmdlen-1)) begin
		if(i_rx_en) r_bytecnt <= r_bytecnt+1;
		else ;
	end
	else r_bytecnt <= 'b0;
	
////////////////////////////////////////////
//对有效数据进行锁存（采集）

always @(posedge i_clk)
	if((r_cstate == RXDB) && i_rx_en ) begin
		case(r_bytecnt)// 命令包计数的个数，这里32bit最高8bit是命令码应该单独定义8bit存
			4'd0: o_para_list[31:24] 	<= i_rx_data;
			4'd1: o_para_list[23:16] 	<= i_rx_data;
			4'd2: o_para_list[15:8] 	<= i_rx_data;
			4'd3: o_para_list[7:0] 		<= i_rx_data;
			default: ;
		endcase
	end
	
////////////////////////////////////////////
//DONE后改变指示灯状态并存校验，校验值应该把前面所有数据相加后取反后在+1，然后对比是否一致。

always @(posedge i_clk)	
	if(!i_rst_n) o_led_en <= 'b0;
	else if(r_cstate == DONE)begin 
		o_led_en <= 'b1;
		o_check[7:0] <= i_rx_data;
		end
	else o_led_en <= 'b0;
	

endmodule

