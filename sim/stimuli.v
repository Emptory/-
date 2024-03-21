module debounce_tb;
    reg clk;
    reg rst;
    reg btn_in;
    wire btn_out;
    
    debounce debounce_inst (
        .clk(clk),
        .rst(rst),
        .btn_in(btn_in),
        .btn_out(btn_out)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    initial begin
        #5 rst = 0;
        #10 rst = 1;
        #20 rst = 0;
        
        #30 btn_in = 1;
        #35 btn_in = 0;
        #50 btn_in = 1;
        #55 btn_in = 1;
        #60 btn_in = 1;
        #65 btn_in = 0;
        
        #100;
        $finish;
    end
endmodule
