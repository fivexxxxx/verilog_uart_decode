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

	//֡ͷ
localparam DATA_FRAME_HEADER	= 8'h40;	
	//֡β��У���
localparam DATA_FRAME_TAIL		= 8'hbc;	
	
	//״̬
localparam IDLE		=			4'd0;	
localparam CLEN		=			4'd1;	//����
localparam RXDB 	=			4'd2; 	//cmd+para        
localparam EOF1		=			4'd3;	//����/֡β/У��
localparam DONE		=			4'd4;	

reg		[3:0]			r_cstate,r_nstate;
reg		[3:0]			r_bytecnt;
reg		[7:0]			r_cmdlen;
////////////////////////////////////////////
//ʱ���߼�״̬�л�

always @(posedge i_clk)
	if(!i_rst_n) r_cstate <= IDLE;
	else r_cstate <= r_nstate;

////////////////////////////////////////////
//����߼��л�״̬

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
				if(r_bytecnt >= r_cmdlen-2) r_nstate = EOF1;//���ݰ����ȸ�Ϊ�ɱ��
				else r_nstate = RXDB;
			end
			else r_nstate = RXDB;
		end	
		
		EOF1: begin
			if(i_rx_en) begin//  �������������ݰ�����+1�������֡β�����ж��Ƿ���Ԥ����֡β��ͬ				
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
//�������������ݳ���(������������)
always @(posedge i_clk)
	if(r_cstate == CLEN) begin
		if(i_rx_en) r_cmdlen <= i_rx_data;	//
		else ;
	end
	
//����Ч�����ֽڽ��м�������Ч���ݣ�������+�����б�
always @(posedge i_clk)
	if((r_cstate == RXDB)&&(r_bytecnt<=r_cmdlen-1)) begin
		if(i_rx_en) r_bytecnt <= r_bytecnt+1;
		else ;
	end
	else r_bytecnt <= 'b0;
	
////////////////////////////////////////////
//����Ч���ݽ������棨�ɼ���

always @(posedge i_clk)
	if((r_cstate == RXDB) && i_rx_en ) begin
		case(r_bytecnt)// ����������ĸ���������32bit���8bit��������Ӧ�õ�������8bit��
			4'd0: o_para_list[31:24] 	<= i_rx_data;
			4'd1: o_para_list[23:16] 	<= i_rx_data;
			4'd2: o_para_list[15:8] 	<= i_rx_data;
			4'd3: o_para_list[7:0] 		<= i_rx_data;
			default: ;
		endcase
	end
	
////////////////////////////////////////////
//DONE��ı�ָʾ��״̬����У�飬У��ֵӦ�ð�ǰ������������Ӻ�ȡ������+1��Ȼ��Ա��Ƿ�һ�¡�

always @(posedge i_clk)	
	if(!i_rst_n) o_led_en <= 'b0;
	else if(r_cstate == DONE)begin 
		o_led_en <= 'b1;
		o_check[7:0] <= i_rx_data;
		end
	else o_led_en <= 'b0;
	

endmodule

