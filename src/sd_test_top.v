module sd_test_top(
    input wire CLOCK_27,
    input wire RST,
    output [5:0] LED,
    input miso,
    output mosi,
    output sdclk,
    output sd_chip_select
);

    wire [39:0] sd_response;
    wire sd_response_ready;

    assign LED = ~sd_response;

    sd_test #(.LOWFREQ_POWER2(6)) test (
        .clk(CLOCK_27),
        .rst(RST),
        // .command(sd_cmd),
        // .arg(sd_arg),
        .response(sd_response),
        .response_ready(sd_response_ready),
        .miso(miso),
        .mosi(mosi),
        .sdclk(sdclk),
        .sd_chip_select(sd_chip_select));

endmodule