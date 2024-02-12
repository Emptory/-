module debounce(
    input clk,
    input rst,
    input btn_in,
    output reg btn_out
);

reg [15:0] counter; // 计数器用于实现延时

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        counter <= 0;
        btn_out <= 0;
    end else begin
        if (btn_in == btn_out) begin
            counter <= 0; // 输入状态与输出状态一致时重置计数器
        end else if (counter < 16'hffff) begin
            counter <= counter + 1; // 输入状态改变，开始计数
            if (counter == 16'hfffe) begin
                btn_out <= btn_in; // 延时后确认改变
            end
        end
    end
end

endmodule

module Segment_led
(
input [3:0] heart_cnt,  //heart_cnt input
input [3:0] ten,  //heart_cnt input
output [8:0] Segment_led_1,  //Segment_led output, MSB~LSB = SPGFEDCBA
output [8:0] Segment_led_2  //Segment_led output, MSB~LSB = SPGFEDCBA
);

reg[8:0] mem [9:0]; 
initial 
	begin
		mem[0] = 9'h3f;   //  0
		mem[1] = 9'h06;   //  1
		mem[2] = 9'h5b;   //  2
		mem[3] = 9'h4f;   //  3
		mem[4] = 9'h66;   //  4
		mem[5] = 9'h6d;   //  5
		mem[6] = 9'h7d;   //  6
		mem[7] = 9'h07;   //  7
		mem[8] = 9'h7f;   //  8
		mem[9] = 9'h6f;   //  9
	end

assign Segment_led_1 = mem[heart_cnt];
assign Segment_led_2 = mem[ten];

endmodule

module divide (	clk,rst_n,clkout);
 
    input 	clk,rst_n;       //输入信号，其中clk连接到FPGA的C1脚，频率为12MHz
    output	clkout;          //输出信号，可以连接到LED观察分频的时钟
 
    //parameter是verilog里常数语句
	parameter	WIDTH	= 3;     //计数器的位数，计数的最大值为 2**WIDTH-1
	parameter	N	= 5;         //分频系数，请确保 N < 2**WIDTH-1，否则计数会溢出
 
	reg 	[WIDTH-1:0]	cnt_p,cnt_n;     //cnt_p为上升沿触发时的计数器，cnt_n为下降沿触发时的计数器
	reg			clk_p,clk_n;     //clk_p为上升沿触发时分频时钟，clk_n为下降沿触发时分频时钟
 
	//上升沿触发时计数器的控制
	always @ (posedge clk or negedge rst_n )   //posedge和negedge是verilog表示信号上升沿和下降沿
                                               //当clk上升沿来临或者rst_n变低的时候执行一次always里的语句
		begin
			if(!rst_n)
				cnt_p<=0;
			else if (cnt_p==(N-1))
				cnt_p<=0;
			else cnt_p<=cnt_p+1;             //计数器一直计数，当计数到N-1的时候清零，这是一个模N的计数器
		end
 
     //上升沿触发的分频时钟输出,如果N为奇数得到的时钟占空比不是50%；如果N为偶数得到的时钟占空比为50%
     always @ (posedge clk or negedge rst_n)
		begin
			if(!rst_n)
				clk_p<=0;
			else if (cnt_p<(N>>1))          //N>>1表示右移一位，相当于除以2去掉余数
				clk_p<=0;
			else 
				clk_p<=1;               //得到的分频时钟正周期比负周期多一个clk时钟
		end
 
       //下降沿触发时计数器的控制        	
	 always @ (negedge clk or negedge rst_n)
		begin
			if(!rst_n)
				cnt_n<=0;
			else if (cnt_n==(N-1))
				cnt_n<=0;
			else cnt_n<=cnt_n+1;
		end
 
        //下降沿触发的分频时钟输出，和clk_p相差半个时钟
	always @ (negedge clk)
		begin
			if(!rst_n)
				clk_n<=0;
			else if (cnt_n<(N>>1))  
				clk_n<=0;
			else 
				clk_n<=1;                //得到的分频时钟正周期比负周期多一个clk时钟
		end
 
    assign clkout = (N==1)?clk:(N[0])?(clk_p&clk_n):clk_p;      //条件判断表达式
                                                                    //当N=1时，直接输出clk
                                                                    //当N为偶数也就是N的最低位为0，N（0）=0，输出clk_p
                                                                    //当N为奇数也就是N最低位为1，N（0）=1，输出clk_p&clk_n。正周期多所以是相与
endmodule   

module flashled (clk,start_btn,stop_btn,inc_btn,rst,led1,led2);
 
	input clk,start_btn,stop_btn,inc_btn,rst;			
	output [8:0] led1;
    output [8:0] led2;

	reg   [3:0] cnt_units ;         //定义了一个3位的计数器，输出可以作为3-8译码器的输入
	reg   [3:0] cnt_tens ;         //定义了一个3位的计数器，输出可以作为3-8译码器的输入
    reg start_flag = 0;      // 开始标志
    reg stop_flag = 0;       // 停止标志
    reg start_btn_prev = 0;  // 开始按钮前一状态，用于边缘检测
    reg stop_btn_prev = 0;   // 停止按钮前一状态，用于边缘检测
	wire clk1h;               //定义一个中间变量，表示分频得到的时钟，用作计数器的触发        
    wire inc_btn_debounced;
	//例化module decode38，相当于调用
	Segment_led u1 (                                   
			.heart_cnt(cnt_units),         //例化的输入端口连接到cnt，输出端口连接到led  
			.Segment_led_1(led1),
			.Segment_led_2(led2),
			.ten(cnt_tens)
			);
 
	//例化分频器模块，产生一个1Hz时钟信号		
	divide #(.WIDTH(32),.N(1200000)) u2 (         //传递参数
			.clk(clk),
			.rst_n(rst),      //例化的端口信号都连接到定义好的信号
			.clkout(clk1h)
			);       
	// 消抖模块实例
debounce db_inc_btn(
    .clk(clk),
    .rst(rst),
    .btn_in(inc_btn),
    .btn_out(inc_btn_debounced)
);		
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        start_flag <= 0;
        stop_flag <= 0;

        start_btn_prev <= 0;
        stop_btn_prev <= 0;
    end else begin
        start_btn_prev <= start_btn;
        stop_btn_prev <= stop_btn;

        if (start_btn && !start_btn_prev) begin
            // 允许计数器开始工作
            start_flag <= 1;
            stop_flag <= 0;
        end
        if (stop_btn && !stop_btn_prev) begin
            // 停止计数器工作
            stop_flag <= 1;
        end
    end
end

// 计数器变量
reg [3:0] counter = 0;

// 边缘检测变量
reg inc_btn_prev = 0; // 上一次增量按钮的状态

// 自动计数逻辑，根据clk1h进行计数
always @(posedge clk1h or negedge rst) begin
    if (!rst) begin
        cnt_units <= 0;
        cnt_tens <= 0;
        inc_btn_prev <= 0;
    end else
    begin
    inc_btn_prev <= inc_btn_debounced; // 更新上一次按钮状态
    if (start_flag && !stop_flag) begin // 当开始标志为1且停止标志为0时，根据1Hz时钟计数
        if (cnt_units >= 9) begin
            cnt_units <= 0;
            if (cnt_tens >= 9) cnt_tens <= 0;
            else cnt_tens <= cnt_tens + 1;
        end else cnt_units <= cnt_units + 1;
        end
    if (inc_btn_debounced && !inc_btn_prev && cnt_tens >=1) begin
            if (cnt_units >= 9) begin
                cnt_units <= 0;
                if (cnt_tens >= 9) cnt_tens <= 0;
                else cnt_tens <= cnt_tens + 1;
            end else cnt_units <= cnt_units + 1;
        end
    end
end


endmodule