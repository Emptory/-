module debounce(
    input clk,
    input rst,
    input btn_in,
    output reg btn_out
);

reg [15:0] cnt; // 计数器用于实现延时

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        cnt <= 0;
        btn_out <= 0;
    end else begin
        if (btn_in == btn_out) begin
            cnt <= 0; // 输入状态与输出状态一致时重置计数器
        end else if (cnt < 16'hffff) begin
            cnt <= cnt + 1; // 输入状态改变，开始计数
            if (cnt == 16'hfffe) begin
                btn_out <= btn_in; // 延时后确认改变
            end
        end
    end
end

endmodule

module Segment_led
(
input [3:0] cnt_units,  //cnt_units input
input [3:0] cnt_tens,  //cnt_units input
output [8:0] led_1,  
output [8:0] led_2 
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

assign led_1 = mem[cnt_units];
assign led_2 = mem[cnt_tens];

endmodule

module divide (
    input         clk,      // 输入时钟（12MHz）
    input         rst_n,    // 复位信号（低电平有效）
    output reg    clkout      // 输出10Hz信号
);

reg [23:0]       cnt;          // 定义24位寄存器用于计数，满足24位计数需求

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cnt <= 0;              // 复位时清零
    end else if (cnt == 600000-1) begin   // 12MHz时钟下计满则清零
        cnt <= 0;
    end else begin
        cnt <= cnt + 1;        // 每个时钟周期加一
    end
end

always @ (posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clkout <= 0;         // 复位时输出0
    end else if (cnt == 600000-1) begin  // 计满则改变输出状态
        clkout <= ~clkout;
    end
end

endmodule

module Stopwatch (clk,start_btn,stop_btn,inc_btn,rst,led1,led2);
 
	input clk,start_btn,stop_btn,inc_btn,rst;			
	output [8:0] led1;
    	output [8:0] led2;

	// 边缘检测变量
	reg inc_btn_prev = 0; // 上一次增量按钮的状态
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
			.cnt_units(cnt_units),         //例化的输入端口连接到cnt，输出端口连接到led  
			.led_1(led1),
			.led_2(led2),
			.cnt_tens(cnt_tens)
			);
 
	//例化分频器模块，产生一个1Hz时钟信号		
	divide u2 (         //传递参数
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