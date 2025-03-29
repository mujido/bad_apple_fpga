`timescale 1us / 1ns

module sd_test_tb();

    reg clk = 0;
    reg rst = 1;
    reg miso = 1;
    wire mosi;
    wire sdclk;
    wire sd_chip_select = 1;
    wire [3:0] sd_state;
    reg [5:0] sd_cmd;
    wire sd_cmd_sent;
    reg [31:0] sd_arg;
    wire [39:0] response;
    wire response_ready;

    always #1 clk = !clk;

    sd_test #(.LOWFREQ_POWER2(2)) test(
        .clk(clk),
        .rst(rst),
        .command(sd_cmd),
        .command_sent(sd_cmd_sent),
        .arg(sd_arg),
        .response(response),
        .response_ready(response_ready),
        .miso(miso),
        .mosi(mosi),
        .sdclk(sdclk),
        .sd_chip_select(sd_chip_select));

    initial begin
        $dumpfile("sd_test_tb.vcd");
        $dumpvars(0, sd_test_tb);

        #2 rst = 0;

        wait (sd_cmd_sent);
        miso = 0;
        #8 miso = 1;
        #32 miso = 0;
        #80 miso = 1;
    end

    reg [1:0] chip_select_count = 0;

    always @(posedge sd_chip_select) begin
        chip_select_count = chip_select_count + 1;
        if (chip_select_count == 2)
            #10 $finish;
    end

endmodule