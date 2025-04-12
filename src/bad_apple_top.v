module bad_apple_top(
    input wire clock_27_pad,
    input wire reset_pad,

    inout [3:0] sdio_data_pads,
    inout sdio_cmd_pad,
    output wire sdio_clk_pad,
    output wire [5:0] led_pads
);

    wire clk_100;

    Gowin_rPLL pll0(
        .clkout(clk_100),
        .clkin(clock_27_pad));

    sd_bus_master sd_master(
        .clk(clk_100),
        .reset(reset_pad),
        .led_pads(led_pads),
        .sdio_clk_pad(sdio_clk_pad),
        .sdio_cmd_pad(sdio_cmd_pad),
        .sdio_data_pads(sdio_data_pads)
    );

endmodule
