module sd_test(
    input wire CLOCK_27,
    input wire RST,

    input wire miso,
    output reg mosi,
    output wire sdclk,
    output reg sd_chip_select,
    output reg timeout,
    output wire [5:0] LED,

    // Debugging signals
    output wire [3:0] state_out
);

assign state_out = state;

localparam ST_RESET = 4'h0;
localparam ST_INIT_SPI = 4'h1;
localparam ST_SEND = 4'h2;
localparam ST_RECV = 4'h3;
localparam ST_IDLE = 4'h4;
localparam ST_RECV_WAIT = 4'h5;
localparam ST_TIMEOUT = 4'h6;

// localparam SPI_LOWFREQ = 400_000;
localparam SPI_LOWFREQ_POWER2 = 6;

wire lowfreq_rising;
wire lowfreq_falling;

clock_divider_pow2 #(.Power(SPI_LOWFREQ_POWER2)) lowfreq_divider(
    .clk_in(CLOCK_27),
    .rst(RST),

    .clk_out(sdclk),
    .clk_out_rising(lowfreq_rising),
    .clk_out_falling(lowfreq_falling)
);

localparam SPI_HIGHFREQ = 12_000_000;
localparam SPI_HIGHFREQ_COUNT = $ceil(1.0 * 27_000_000 / SPI_HIGHFREQ);

localparam TIMEOUT_DELAY = $floor(0.01 * 27_000_000);

// reg [SPI_LOWFREQ_POWER2 - 1:0] lowfreq_clock_divider = 0;
// reg [7:0] highfreq_clock_divider = 0;

// wire lowfreq_clock = lowfreq_clock_divider[SPI_LOWFREQ_POWER2 - 1];
// wire highfreq_clock = highfreq_clock_divider == SPI_HIGHFREQ_COUNT;

// assign sdclk = lowfreq_clock_divider[SPI_LOWFREQ_POWER2 - 1];

// wire sdclk_rising = sdclk & ~lowfreq_clock_divider[SPI_LOWFREQ_POWER2 - 2:0]

// always @(posedge CLOCK_27 or posedge RST) begin
//     if (RST) begin
//         lowfreq_clock_divider <= 0;
//         // highfreq_clock_divider <= 0;
//     end else begin
//         lowfreq_clock_divider <= lowfreq_clock_divider + 1'b1;
//         // if (lowfreq_clock) 
//         //     lowfreq_clock_divider <= 0;
//         // else 
//         //     lowfreq_clock_divider <= lowfreq_clock_divider + 1'b1;

//         // if (highfreq_clock)
//         //     highfreq_clock_divider <= 0;
//         // else
//         //     highfreq_clock_divider <= highfreq_clock_divider + 1'b1;
//     end
// end

// always @(posedge CLOCK_27 or posedge RST) begin
//     if (RST)
//         sdclk <= 1'b1;
//     else if (lowfreq_clock)
//         sdclk <= ~sdclk;
// end

reg [3:0] state = ST_RESET;
reg [31:0] counter = 0;
reg [46:0] send_data = 0;
reg [39:0] received_data = 0;

wire [47:0] CMD0 = {2'b01, 6'd0, 32'd0, 7'b1001010, 1'b1}; 

assign LED = ~received_data[5:0];
// assign LED = ~state;

always @(posedge CLOCK_27 or posedge RST) begin
    if (RST) begin
        state <= ST_RESET;
        counter <= 0;
        sd_chip_select <= 0;
        mosi <= 1'b1;
        // LED <= 0;
    end else if (lowfreq_rising) begin
        case (state)
            ST_RESET : begin
                state <= ST_INIT_SPI;
                counter <= 80;
                mosi <= 1'b1;
                sd_chip_select <= 1'b1;
                timeout <= 1'b0;
            end

            ST_INIT_SPI : begin
                counter <= counter - 1'b1;

                if (!counter) begin
                    state <= ST_SEND;
                    { mosi, send_data } <= CMD0;
                    counter <= 'd48;
                    sd_chip_select = 1'b0;
                end
            end

            ST_SEND : begin
                mosi <= send_data[46];
                send_data <= send_data << 1;
                counter <= counter - 1'b1;

                if (counter == 1) begin
                    state <= ST_RECV_WAIT;
                    counter <= TIMEOUT_DELAY;
                end
            end

            ST_IDLE : sd_chip_select <= 1'b1;

            ST_TIMEOUT : begin
                sd_chip_select <= 1'b1;
                counter <= counter + 1'b1;
                received_data[5:0] <= counter[20:15];

                // if (counter < 200_000) begin
                //     received_data <=  8'hFF;
                // end else if (counter > 400_000) begin
                //     received_data <= 8'h0;
                //     counter <= 0;
                // end 
            end
        endcase
    end else if (lowfreq_falling) begin
        // Read on low of clock to stay in correct phase
        case (state)
            ST_RECV_WAIT : begin
                counter <= counter - 1'b1;
                if (!miso) begin
                    state <= ST_RECV;
                    counter <= 'd7;
                end else if (counter == 0) begin
                    state <= ST_TIMEOUT;
                    counter <= 0;
                    timeout <= 1'b1;
                end
            end

            ST_RECV : begin
                if (counter == 0) begin
                    state <= ST_IDLE;
                    // LED <= ~received_data[6:0];
                end else begin
                    received_data = { received_data[38:0], miso };
                    counter <= counter - 1'b1;
                end
            end
        endcase
    end
end

endmodule