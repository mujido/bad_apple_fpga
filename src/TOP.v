module bad_apple(
    input CLOCK_27,
    input RST,

    /* SD Card */
    input sd_chip_select,
    input sd_miso,
    output sd_mosi,

    output [0:5] LED
);

//    wire nRST = !RST;

    localparam TICKS_PER_HALF_SECOND = 27_000_000 / 2;

    //reg [23:0] counter;
    wire led_clock;

//    Clock_Divider_Pow2 #(.BITS(24)) clock_24bit(.clk_in(CLOCK_27), .clk_out(led_clock), .rst(RST));

    ClockDividerArb #(.COUNT(TICKS_PER_HALF_SECOND / 2), .COUNT_LOG2(24)) (.clk_in(CLOCK_27), .clk_out(led_clock), .rst(RST));

    reg [5:0] local_leds;

    //always @(posedge CLOCK_27 or negedge nRST) begin
    //    if (nRST == 1'b0) begin
    //        counter <= 15'h0;
    //        local_leds <= 6'h0;
    //    end
    //    else if (counter != TICKS_PER_HALF_SECOND - 1)
    //        counter <= counter + 1'b1;
    //    else begin
    //        counter <= 15'h0;        
    //        local_leds <= local_leds + 1'b1;
    //    end
    //end

    always @(posedge led_clock or posedge RST)
        if (RST)
            local_leds <= 0;
        else
            local_leds <= local_leds + 1'b1;

    assign LED = ~local_leds;

    //SD_Card sd_card(
    //    .

endmodule