module cymometer
#(parameter		CLK_FS = 32'd50_000_000)    //基准时钟频率
	(
		input					clk_fs,
		input					rst_n,
		
		
		input					clk_fx,

		output  reg             fre_done,
		output  reg[63:0]		   data_fx
);

localparam	MAX			= 8'd32;			//定义计数的最大位宽，，，32位
localparam	GATE_TIME	= 32'd5000;			//定义门控时间是多少个被测信号的周期

reg                gate        ;           // 门控信号
reg                gate_fs     ;           // 同步到基准时钟的门控信号
reg                gate_fs_r   ;           // 用于同步gate信号的寄存器
reg                gate_fs_d0  ;           // 用于采集基准时钟下gate下降沿
reg                gate_fs_d1  ;           // 
reg				   gate_fs_d2  ;		   //用于采集基准时钟下gate上升沿
reg				   gate_fs_d3  ;
reg                gate_fx_d0  ;           // 用于采集被测时钟下gate下降沿
reg                gate_fx_d1  ;           // 
reg    [   63:0]   data_fx_t   ;          // 
reg    [   15:0]   gate_cnt    ;           // 门控计数
reg    [MAX-1:0]   fs_cnt      ;           // 门控时间内基准时钟的计数值
reg    [MAX-1:0]   fs_cnt_temp ;           // fs_cnt 临时值
reg    [MAX-1:0]   fx_cnt      ;           // 门控时间内被测时钟的计数值
reg    [MAX-1:0]   fx_cnt_temp ;           // fx_cnt 临时值


//wire define
wire               neg_gate_fs;            // 基准时钟下门控信号下降沿
wire               neg_gate_fx;            // 被测时钟下门控信号下降沿

wire			   up_gate_fs;			   // 基准时钟下门控信号上升沿


//边沿检测，捕获信号下降沿
assign neg_gate_fs = gate_fs_d1 & (~gate_fs_d0);   //一个处于高电平、另一个处于低电平，就可以采集得到
assign neg_gate_fx = gate_fx_d1 & (~gate_fx_d0);

//边沿检测，捕获信号上降沿
assign up_gate_fs = gate_fs_d2 & (~gate_fs_d3);


//门控信号计数器，使用被测时钟计数
always @(posedge clk_fx or negedge rst_n) begin		//使用被测时钟来计数门控信号，，前20个先不要
    if(!rst_n)
        gate_cnt <= 16'd0; 
    else if(gate_cnt == GATE_TIME + 5'd20)
        gate_cnt <= 16'd0;
    else
        gate_cnt <= gate_cnt + 1'b1;				//依次计数
end

//门控信号，拉高时间为GATE_TIME个实测时钟周期
always @(posedge clk_fx or negedge rst_n) begin		//这里表示，开始拉高
    if(!rst_n)
        gate <= 1'b0;
    else if(gate_cnt < 4'd10)
        gate <= 1'b0;     
    else if(gate_cnt < GATE_TIME + 4'd10)
        gate <= 1'b1;
    else if(gate_cnt <= GATE_TIME + 5'd20)
        gate <= 1'b0;
    else 
        gate <= 1'b0;
end

//将门控信号同步到基准时钟下						//讲门控信号也给到基准时钟
always @(posedge clk_fs or negedge rst_n) begin
    if(!rst_n) begin
        gate_fs_r <= 1'b0;
        gate_fs   <= 1'b0;
    end
    else begin
        gate_fs_r <= gate;							
        gate_fs   <= gate_fs_r;
    end
end

//打拍采门控信号的下降沿（被测时钟下）				//采集门控信号的下降沿。
always @(posedge clk_fx or negedge rst_n) begin
    if(!rst_n) begin
        gate_fx_d0 <= 1'b0;
        gate_fx_d1 <= 1'b0;
    end
    else begin
        gate_fx_d0 <= gate;
        gate_fx_d1 <= gate_fx_d0;
    end
end

//打拍采门控信号的下降沿（基准时钟下）
always @(posedge clk_fs or negedge rst_n) begin
    if(!rst_n) begin
        gate_fs_d0 <= 1'b0;
        gate_fs_d1 <= 1'b0;
    end
    else begin
        gate_fs_d0 <= gate_fs;
        gate_fs_d1 <= gate_fs_d0;
    end
end


//打拍采门控信号的上降沿（基准时钟下）
always @(posedge clk_fs or negedge rst_n) begin
    if(!rst_n) begin
        gate_fs_d2 <= 1'b0;
        gate_fs_d3 <= 1'b0;
    end
    else begin
        gate_fs_d2 <= gate_fs;
        gate_fs_d3 <= gate_fs_d2;
    end
end


 //门控时间内对被测时钟计数
always @(posedge clk_fx or negedge rst_n) begin
    if(!rst_n) begin
        fx_cnt_temp <= 32'd0;
        fx_cnt <= 32'd0;
    end
    else if(gate)
        fx_cnt_temp <= fx_cnt_temp + 1'b1;
    else if(neg_gate_fx) begin
        fx_cnt_temp <= 32'd0;
        fx_cnt   <= fx_cnt_temp;
    end
end 

//门控时间内对基准时钟计数
always @(posedge clk_fs or negedge rst_n) begin
    if(!rst_n) begin
        fs_cnt_temp <= 32'd0;
        fs_cnt <= 32'd0;
    end
    else if(gate_fs)
        fs_cnt_temp <= fs_cnt_temp + 1'b1;
    else if(neg_gate_fs) begin
        fs_cnt_temp <= 32'd0;
        fs_cnt <= fs_cnt_temp;
    end
end

//计算被测信号频率
always @(posedge clk_fs or negedge rst_n) begin
    if(!rst_n) begin
        data_fx_t <= 64'd0;
    end
    else if(gate_fs == 1'b0)
        data_fx_t <= CLK_FS * fx_cnt ;
end

always @(posedge clk_fs or negedge rst_n) begin
    if(!rst_n) begin
        data_fx <= 64'd0; 
    end
    else if(gate_fs == 1'b0)
        data_fx <= ((data_fx_t*10000)/fs_cnt);
end

//频率计算完毕，可以开始发送标志
always @(posedge clk_fs or negedge rst_n) begin
	if(!rst_n) begin
		fre_done <= 1'b0;
	end
	else  if(up_gate_fs)
		fre_done <= 1'b1;
	else
		fre_done <= 1'b0;		
end

endmodule 



