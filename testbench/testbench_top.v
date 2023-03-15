`timescale 1ns/1ps

module testbench_top();
	
////////////////////////////////////////////////////////////
//参数定义

`define CLK_PERIORD						20		//时钟周期设置为20ns（50MHz）	
parameter UART_BPS_RATE 		= 		115200;
parameter BPS_DLY_BIT			= 		1000000000/UART_BPS_RATE;


////////////////////////////////////////////////////////////
//接口申明
	
reg						i_clk;
reg						i_rst_n;
reg						i_uart_rx;
			
wire					w_bps_en;
wire					w_bps_done;
wire					w_rx_en;
wire	[7:0] 			w_rx_data;
				
wire					o_led_en;
wire	[31:0] 			o_para_list;
wire	[7:0] 			o_check;
	
m_bps	#(
	.UART_BPS_RATE(UART_BPS_RATE),	//串口波特率设置（<=115200），单位：bps
	.CLK_PERIORD(`CLK_PERIORD)		//时钟周期设置，单位：ns
) uut_m_bps(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_bps_en(w_bps_en),
	.o_bps_done(w_bps_done)
    );

m_s2p	uut_m_s2p(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_uart_rx(i_uart_rx),
	.i_bps_done(w_bps_done),	
	.o_bps_en(w_bps_en),
	.o_rx_en(w_rx_en),
	.o_rx_data(w_rx_data)
    );	
	
m_decoder	uut_m_decoder(
	.i_clk(i_clk),
	.i_rst_n(i_rst_n),
	.i_rx_en(w_rx_en),
	.i_rx_data(w_rx_data),
	.o_led_en(o_led_en),
	.o_para_list(o_para_list),
	.o_check(o_check)
    );	
	
////////////////////////////////////////////////////////////
//复位和时钟产生

	//时钟和复位初始化、复位产生
initial begin
	i_clk <= 0;
	i_rst_n <= 0;
	#1000;
	i_rst_n <= 1;
end
	
	//时钟产生
always #(`CLK_PERIORD/2) i_clk = ~i_clk;	

////////////////////////////////////////////////////////////
//测试激励产生

initial begin
	i_uart_rx <= 'b1;
	@(posedge i_rst_n);	//等待复位完成
	
	@(posedge i_clk);
	
	#100_000;	
	task_cmd_tx();
	#100_000;	
	$stop;
end

integer i;

//模拟一次UART传输的任务
task task_uart_tx;
	input[7:0] tx_db;
	begin
		i_uart_rx <= 'b0;
		#BPS_DLY_BIT;
		for(i=0; i<8; i=i+1) begin
			i_uart_rx <= tx_db[i];
			#BPS_DLY_BIT;
		end
		i_uart_rx <= 'b1;
		#BPS_DLY_BIT;
	end
endtask

//模拟一次完整的UART命令帧
task task_cmd_tx;

	begin
		task_uart_tx(8'h40);	//引导码
		task_uart_tx(8'h05);	//包长
		task_uart_tx(8'hee);	//命令码
		task_uart_tx(8'h22);	//参数
		task_uart_tx(8'h33);
		task_uart_tx(8'h44);

		task_uart_tx(8'hbc);	//校验码-应该是前面所有加起来的和取反再+1的值，这里固定
	end
endtask

always @(posedge i_clk)
	if(o_led_en) $display("o_para_list = %x,o_check = %x",o_para_list,o_check);
	else ;
endmodule






