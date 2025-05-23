module bad_apple_top(
    input wire clock_27_pad,
    input wire reset_pad,

    inout [3:0] sdio_data_pads,
    inout sdio_cmd_pad,
    output wire sdio_clk_pad,
    output wire [5:0] led_pads
);

    localparam SYS_CLK_FREQ = 100_000_000;
    localparam SDIO_HIGHFREQ_DIVIDER = 1;   // 25 MHz (SYS_CLK_FREQ / (2 * (1 + 1))
    localparam SDIO_LOWFREQ_DIVIDER = 124;  // 400 kHz (SYS_CLK_FREQ / (2 * (124 + 1))

    wire clk_100;

    Gowin_rPLL pll0(
        .clkout(clk_100),
        .clkin(clock_27_pad));

    reg [3:0] reset_sync = 4'hf;
    wire reset_signal = reset_sync[3];

    always @(posedge clk_100) begin
        if (reset_pad) begin
            reset_sync <= 4'hf;
        end else begin
            reset_sync <= {reset_sync[2:0], 1'b0};
        end
    end

    sd_bus_master #(
        .LOWFREQ_CLK_DIVIDER(SDIO_LOWFREQ_DIVIDER),
        .HIGHFREQ_CLK_DIVIDER(SDIO_HIGHFREQ_DIVIDER)
    ) sd_master (
        .clk(clk_100),
        .sdio_base_clk(clk_100),
        .reset(reset_signal),
        .leds(led_pads),
        .sdio_clk(sdio_clk_pad),
        .sdio_cmd(sdio_cmd_pad),
        .sdio_data(sdio_data_pads)
    );

endmodule
