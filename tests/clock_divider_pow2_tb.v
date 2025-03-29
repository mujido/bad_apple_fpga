`timescale 1us / 1us

module clock_divider_pow2_tb;

    reg reset = 0;
    reg clk = 0;
    always #5 clk = !clk;

    wire clk_out;
    wire clk_out_rising;
    wire clk_out_falling;
    clock_divider_pow2 #(.Power(2)) divider(
        .clk_in(clk), 
        .clk_out(clk_out),
        .clk_out_rising(clk_out_rising),
        .clk_out_falling(clk_out_falling),
        .rst(reset));

    initial begin 
        $dumpfile("clock_divider_pow2_tb.vcd");
        $dumpvars(0, clock_divider_pow2_tb);
        
        #15 reset = 1;
        #10 reset = 0;

        #200 $finish;
    end


endmodule