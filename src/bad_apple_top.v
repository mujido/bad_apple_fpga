module bad_apple_top(
    input wire clock_27_pad,
    input wire clock_27_alt_pad,
    input wire reset_pad,

    inout [3:0] sdio_data_pads,
    inout sdio_cmd_pad,
    output wire sdio_clk_pad,
    output wire [5:0] led_pads
);

    localparam SYS_CLK_FREQ = 100_000_000;
    localparam SDIO_BASE_FREQ = 50_000_000;
    localparam SDIO_HIGHFREQ_DIVIDER = 0;   // 25 MHz (SDIO_BASE_FREQ / (0 + 1))
    localparam SDIO_LOWFREQ_DIVIDER = 62;   // 396kHz (SDIO_BASE_FREQ / (62 + 1))

    wire clk_100;
    wire clk_50;

    Gowin_rPLL pll0(
        .clkout(clk_100),
        .clkoutd(clk_50),
        .clkin(clock_27_pad));

    sd_bus_master #(
        .LOWFREQ_CLK_DIVIDER(SDIO_LOWFREQ_DIVIDER),
        .HIGHFREQ_CLK_DIVIDER(SDIO_HIGHFREQ_DIVIDER)
    ) sd_master (
        .clk(clk_100),
        .sdio_base_clk(clk_50),
        .reset(reset_pad),
        .leds(led_pads),
        .sdio_clk(sdio_clk_pad),
        .sdio_cmd(sdio_cmd_pad),
        .sdio_data(sdio_data_pads)
    );

endmodule
