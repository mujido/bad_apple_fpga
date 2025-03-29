module sd_test #(
    parameter LOWFREQ_POWER2 = 2,
    parameter TIMEOUT_DELAY = $floor(0.01 * 27_000_000)
) (
    input wire clk,
    input wire rst,

    input wire start,
    input wire [5:0] command,
    input wire [31:0] arg,
    output reg [39:0] response,
    output reg response_ready,

    input wire miso,
    output reg mosi,
    output wire sdclk,
    output reg sd_chip_select,
    output reg timeout,
    output reg busy,
    output reg command_sent,
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

    wire lowfreq_clk;
    wire lowfreq_rising;
    wire lowfreq_falling;

    clock_divider_pow2 #(.Power(LOWFREQ_POWER2)) lowfreq_divider(
        .clk_in(clk),
        .rst(rst),

        .clk_out(lowfreq_clk),
        .clk_out_rising(lowfreq_rising),
        .clk_out_falling(lowfreq_falling)
    );

    localparam SPI_HIGHFREQ = 12_000_000;
    localparam SPI_HIGHFREQ_COUNT = $ceil(1.0 * 27_000_000 / SPI_HIGHFREQ);

    reg [3:0] state = ST_RESET;
    reg [31:0] counter = 0;
    reg [46:0] send_data = 0;

    wire [47:0] CMD0 = {2'b01, 6'd0, 32'd0, 7'b1001010, 1'b1}; 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_RESET;
            counter <= 0;
            sd_chip_select <= 0;
            mosi <= 1'b1;
            response <= 0;
            response_ready <= 0;
            busy <= 0;
            command_sent <= 0;
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
                    response[5:0] <= counter[20:15];
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
                    response = { response[38:0], miso };
                    counter <= counter - 1'b1;
                    if (counter == 1)
                        state <= ST_IDLE;
                end
            endcase
        end
    end

    assign sdclk = (state == ST_IDLE) | lowfreq_clk;

endmodule