module debounce(
    input clk,        // Clock input
    input rst,        // Reset input
    input btn_in,     // Input button signal
    output reg btn_out // Debounced button signal output
);

reg [15:0] cnt;        // Counter used for implementing delay

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        cnt <= 0;       // Reset counter
        btn_out <= 0;   // Reset output signal
    end else begin
        if (btn_in == btn_out) begin
            cnt <= 0;   // Reset counter if input matches output
        end else if (cnt < 16'hffff) begin
            cnt <= cnt + 1; // Start counting if input changes
            if (cnt == 16'hfffe) begin
                btn_out <= btn_in; // Confirm change after delay
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

module divide(
  input clk, // 12MHz main clock input
  output reg clkout // 10Hz clock output
);

reg [31:0] counter; // Counter for dividing the clock

always @(posedge clk) begin
  if (counter == 600000-1) begin // When the counter reaches 600000-1, output a clock pulse
    counter <= 0; // Reset the counter
    clkout <= ~clkout; // Toggle the clock signal
  end else begin
    counter <= counter + 1; // Increment the counter
  end
end

endmodule


module Stopwatch (clk, start_btn, stop_btn, inc_btn, rst, led1, led2);
 
    input clk, start_btn, stop_btn, inc_btn, rst;            
    output [8:0] led1;
    output [8:0] led2;

    // Edge detection variables
    reg inc_btn_prev = 0; // Previous state of the increment button
    reg [3:0] cnt_units;         // Define a 3-bit counter, output can be used as input to a 3-to-8 decoder
    reg [3:0] cnt_tens;         // Define a 3-bit counter, output can be used as input to a 3-to-8 decoder
    reg start_flag = 0;      // Start flag
    reg stop_flag = 0;       // Stop flag
    reg start_btn_prev = 0;  // Previous state of the start button for edge detection
    reg stop_btn_prev = 0;   // Previous state of the stop button for edge detection
    wire clk1h;               // Intermediate variable representing the divided clock used as trigger for the counter        
    wire inc_btn_debounced;   // Debounced increment button signal

    // Instantiate the decode38 module
    Segment_led u1 (
        .cnt_units(cnt_units),  // Input port connected to cnt, outputs connected to led  
        .led_1(led1),
        .led_2(led2),
        .cnt_tens(cnt_tens)
    );

    // Instantiate the divider module to generate a 1Hz clock signal
    divide u2 (
        .clk(clk),
        .clkout(clk1h)
    );

    // Instantiate the debounce module
    debounce db_inc_btn(
        .clk(clk),
        .rst(rst),
        .btn_in(inc_btn),
        .btn_out(inc_btn_debounced)
    );

    always @(posedge clk or negedge rst) begin
    if (!rst) begin
        // Reset condition: when the reset signal is active low
        start_flag <= 0;        // Set start_flag to 0
        stop_flag <= 0;         // Set stop_flag to 0
        start_btn_prev <= 0;    // Set previous state of start button to 0
        stop_btn_prev <= 0;     // Set previous state of stop button to 0
    end else begin
        start_btn_prev <= start_btn;  // Update previous state of start button
        stop_btn_prev <= stop_btn;    // Update previous state of stop button

        if (start_btn && !start_btn_prev) begin
            // Start button pressed and was not previously pressed
            // Enable the counter to start counting
            start_flag <= 1;    // Set start_flag to 1 to enable counting
            stop_flag <= 0;     // Set stop_flag to 0 to disable stopping
        end

        if (stop_btn && !stop_btn_prev) begin
            // Stop button pressed and was not previously pressed
            // Stop the counter from counting
            stop_flag <= 1;     // Set stop_flag to 1 to stop counting
        end
    end
end


    // Automatic counting logic based on clk1h
    always @(posedge clk1h or negedge rst) begin
    if (!rst) begin
        // Reset condition: when the reset signal is active low
        cnt_units <= 0;             // Set units counter to 0
        cnt_tens <= 0;              // Set tens counter to 0
        inc_btn_prev <= 0;          // Set previous state of increment button to 0
    end else begin
        inc_btn_prev <= inc_btn_debounced;   // Update previous state of increment button

        if (start_flag && !stop_flag) begin
            // Count based on 1Hz clock when start flag is 1 and stop flag is 0
            if (cnt_units >= 9) begin
                // Increment tens counter when units counter reaches 9
                cnt_units <= 0;
                
                if (cnt_tens >= 9) 
                    cnt_tens <= 0;      // Reset tens counter when it reaches 9
                else 
                    cnt_tens <= cnt_tens + 1;   // Increment tens counter by 1
            end else 
                cnt_units <= cnt_units + 1;     // Increment units counter by 1
        end

        if (inc_btn_debounced && !inc_btn_prev && cnt_tens >= 1) begin
            // Increment counters when increment button is pressed and tens counter is greater than or equal to 1
            if (cnt_units >= 9) begin
                // Increment tens counter when units counter reaches 9
                cnt_units <= 0;
                
                if (cnt_tens >= 9) 
                    cnt_tens <= 0;      // Reset tens counter when it reaches 9
                else 
                    cnt_tens <= cnt_tens + 1;   // Increment tens counter by 1
            end else 
                cnt_units <= cnt_units + 1;     // Increment units counter by 1
        end
    end
end


endmodule
