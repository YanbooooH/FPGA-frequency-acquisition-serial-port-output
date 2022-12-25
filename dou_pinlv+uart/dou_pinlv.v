module dou_pinlv(
		input           sys_clk,            //外部50M时钟
		input           sys_rst_n,          //外部复位信号，低有效
		input				 clk_fx_1,
		input				 clk_fx_2,
		output          uart_txd            //UART发送端口
    );

	
	
//parameter define
parameter  integer  CLK_FREQ =50000000;         //定义系统时钟频率
parameter  integer  UART_BPS = 115200;           //定义串口波特率
parameter  integer  BYTES    = 8;
parameter  integer  uart_f    = 10;

//wire			locked;
//wire			clk_100m;
//wire			rst_n;

//wire define   
wire        fre_done_1;                //UART发送使能
wire        fre_done_2;                //UART发送
wire			fre_done;
wire [63:0] uart_send_data;              //UART发送数据
wire		uart_bytes_done;

wire	[63:0]	pinlv_data_1;
wire	[63:0]	pinlv_data_2;


//assign		rst_n = sys_rst_n & locked;   //用作其他模块的复位信号


//串口发送模块    
uart_bytes_tx #(                          
    .CLK_FRE       		(CLK_FREQ),         //设置系统时钟频率
    .BPS       	   		(UART_BPS),
	.BYTES			 	(BYTES))         //设置串口发送波特率
	
u_uart_bytes_tx(                 
    .sys_clk        	(sys_clk),
    .sys_rst_n      	(sys_rst_n),
		
    .uart_bytes_data    (uart_send_data),
    .uart_bytes_en      (fre_done),
    .uart_bytes_done   	(uart_bytes_done),
    .uart_txd       		(uart_txd)
    );
    
//频率计   
cymometer #(
	 .CLK_FS 				(CLK_FREQ))
u_cymometer_1(
    .clk_fs        		(sys_clk),             
    .rst_n      			(sys_rst_n),           
   
    .clk_fx      			(clk_fx_1),   //接收一帧数据完成标志信号
    .data_fx      		(pinlv_data_1),   //接收的数据
   
    .fre_done      		(fre_done_1)     //发送忙状态标志      
    );
 
cymometer #(
	 .CLK_FS 				(CLK_FREQ))
u_cymometer_2(
    .clk_fs        		(sys_clk),             
    .rst_n      			(sys_rst_n),           
   
    .clk_fx      			(clk_fx_2),   //接收一帧数据完成标志信号
    .data_fx      		(pinlv_data_2),   //接收的数据
   
    .fre_done      		(fre_done_2)     //发送忙状态标志      
    );
	 
pinlv_uart	#(
	.CLK_FS					(CLK_FREQ),
	.uart_f              (uart_f))
u_pinlv_uart(
	.sys_clk					(sys_clk),
	.sys_rst_n				(sys_rst_n),

	.pinlv_data_1			(pinlv_data_1),   
	.pinlv_data_2			(pinlv_data_2),
	.pinlv_1_en				(fre_done_1),		
	.pinlv_2_en				(fre_done_2),

	.uart_data				(uart_send_data),				
	.uart_en					(fre_done)
	);


    
endmodule