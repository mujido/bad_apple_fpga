module qspi #(
    parameter MAX_TX_LENGTH = 8,
    parameter MAX_TX_LENGTH_LOG2 = 4,

    parameter MAX_RX_LENGTH = 8,
    parameter MAX_RX_LENGTH_LOG2 = 4,

    parameter CLOCK_DIVIDER = 2,
    parameter CLOCK_DIVIDER_LOG2 = 1
) (
    input wire clk,
    input wire reset,
    input wire start,
    input wire qio_mode,
    input wire dummy,
    input wire delay_cycle,

    input wire [MAX_TX_LENGTH - 1:0] tx_data,
    input wire [MAX_TX_LENGTH_LOG2 - 1:0] tx_size,

    output reg [MAX_RX_LENGTH - 1:0] rx_data,
    input wire [MAX_RX_LENGTH_LOG2 - 1:0] rx_size,

    output wire tx_complete,
    output wire rx_complete,

    output wire spi_clk_pad,

    input wire [3:0] data_in,
    output wire data_out
);

    reg spi_clk = 0;

    generate
        if (CLOCK_DIVIDER > 2) begin
            reg [CLOCK_DIVIDER_LOG2 - 2:0] clk_divider_reg = 0;

            always @(posedge clk) begin
                if (reset || !busy) begin
                    clk_divider_reg <= 0;
                    spi_clk <= 1'b0;
                end else if (clk_divider_reg == CLOCK_DIVIDER - 2) begin
                    clk_divider_reg <= 0;
                    spi_clk <= ~spi_clk;
                end else begin
                    clk_divider_reg <= clk_divider_reg + 1'b1;
                end
            end
        end else begin
            always @(posedge clk) begin
                if (reset || !busy) begin
                    spi_clk <= 1'b0;
                end else begin
                    spi_clk <= ~spi_clk;
                end
            end
        end
    endgenerate

    reg [MAX_TX_LENGTH - 1:0] tx_data_reg = 0;
    reg [MAX_TX_LENGTH_LOG2 - 1:0] tx_size_reg = 0;
    reg [MAX_RX_LENGTH_LOG2 - 1:0] rx_size_reg = 0;

    reg qio_mode_reg;
    reg dummy_reg;

    wire busy = !(tx_complete & rx_complete);

    always @(posedge clk) begin
        if (!busy && start) begin
            qio_mode_reg <= qio_mode;
            dummy_reg <= dummy;

            tx_data_reg <= tx_data;
            tx_size_reg <= tx_size;

            if (tx_size != 1'd0 || rx_size == 1'd0 || !delay_cycle) begin
                rx_size_reg <= rx_size;
            end else begin
                // Need to delay by one cycle before read. Can accomplish the same thing by just reading an extra time
                // at the end.
                rx_size_reg <= rx_size + 1'd1;
            end
        end

        if (spi_clk && (busy || start)) begin
            if (!tx_complete) begin
                tx_data_reg <= {tx_data_reg[MAX_TX_LENGTH - 2:0], 1'b0};
                tx_size_reg <= tx_size_reg - 1'b1;
            end

            if (!rx_complete) begin
                if (qio_mode_reg) begin
                    // Assumes that rx_data is a multiple of 4. This is not enforced and must be taken care of by user
                    // of module.
                    rx_data <= {rx_data[MAX_RX_LENGTH - 4:1], data_in};
                    rx_size_reg <= rx_size_reg - 3'd4;
                end else begin
                    rx_data <= {rx_data[MAX_RX_LENGTH - 2:0], data_in[0]};
                    rx_size_reg <= rx_size_reg - 1'd1;
                end
            end

            if (tx_size_reg == 1'd1) begin
                // If we receiving more data, switch to dummy mode.
                dummy_reg <= 1'b1;
            end
        end
    end

    assign spi_clk_pad = spi_clk;
    assign data_out = !reset && !dummy_reg && tx_data_reg[MAX_TX_LENGTH - 1];
    assign tx_complete = tx_size_reg == 1'd0;
    assign rx_complete = rx_size_reg == 1'd0;

endmodule
