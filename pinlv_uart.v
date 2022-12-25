module	pinlv_uart
#(parameter     CLK_FS = 32'd50_000_000,
  parameter		 uart_f = 10
)
(

//系统接口
			input				sys_clk,
			input				sys_rst_n,
//用户接口
			input	[63:0]		pinlv_data_1,      //频率1
			input	[63:0]		pinlv_data_2,
			input				pinlv_1_en,		   //频率1信号更新
			input				pinlv_2_en,
//集成串口数据			
			output	reg[63:0]		uart_data,
			output	reg		   	uart_en				//还得再加一个串口使能
);

localparam	integer		uart_cnt = CLK_FS/uart_f;

reg		[63:0]		pinlv_1_data_reg;
reg		[63:0]		pinlv_2_data_reg;

reg		[31:0]		cnt;



always @(posedge sys_clk or negedge sys_rst_n) begin
	if(!sys_rst_n)
		pinlv_1_data_reg <= 32'd0;
	else if(pinlv_1_en)
		pinlv_1_data_reg <= pinlv_data_1;
	else
		pinlv_1_data_reg <= pinlv_1_data_reg;
end


always @(posedge sys_clk or negedge sys_rst_n) begin
	if(!sys_rst_n)
		pinlv_2_data_reg <= 32'd0;
	else if(pinlv_2_en)
		pinlv_2_data_reg <= pinlv_data_2;
	else
		pinlv_2_data_reg <= pinlv_2_data_reg;
end

//将两组数据进行合并
always @(posedge sys_clk or negedge sys_rst_n) begin
	if(!sys_rst_n)
		uart_data <= 64'd0;
	else
		uart_data <= {pinlv_1_data_reg[31:0],pinlv_2_data_reg[31:0]};
end


//串口多久使能一次？需要写一个函数来控制它

always @(posedge sys_clk or negedge sys_rst_n) begin
	if(!sys_rst_n) begin
		cnt <= 32'd0;
		uart_en <= 1'b0;		
		end
	else if(cnt == uart_cnt) begin
		cnt <= 32'd0;
		uart_en <= 1'b1;
		end
	else  begin
		cnt	<= cnt + 1'b1;
		uart_en <= 1'b0;		
		end
end

endmodule