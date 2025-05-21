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
    reg tx_active = 1'b0;
    reg rx_active = 1'b0;

    reg qio_mode_reg;
    reg dummy_reg;

    wire tx_size_0 = tx_size_reg == 1'd0;
    wire rx_size_0 = rx_size_reg == 1'd0;

    wire busy = !(tx_size_0 && rx_size_0);
    wire spi_active_cycle = spi_clk && (busy || start);

    edge_detector #(.EDGE(1'b0), .IGNORE_FIRST(1)) tx_complete_detector (
        .clk(clk),
        .signal(tx_active),
        .edge_pulse(tx_complete)
    );

    edge_detector #(.EDGE(1'b0), .IGNORE_FIRST(1)) rx_complete_detector(
        .clk(clk),
        .signal(rx_active),
        .edge_pulse(rx_complete)
    );

    always @(posedge clk) begin
        if (!busy && start) begin
            qio_mode_reg <= qio_mode;
            dummy_reg <= dummy;

            tx_data_reg <= tx_data;
            tx_size_reg <= tx_size;

            // Need to delay by one cycle before read if delay_cycle is true. Can accomplish the same thing by just
            // reading an extra time.
            rx_size_reg <= rx_size + (
                tx_size != 1'd0 || rx_size == 1'd0 || !delay_cycle ? 1'b0 : 1'b1
            );

            tx_active <= tx_size != 1'd0;
            rx_active <= rx_size != 1'd0;
        end else if (spi_active_cycle) begin
            if (!tx_size_0) tx_size_reg <= tx_size_reg - 1'b1;
            if (!rx_size_0) rx_size_reg <= rx_size_reg - (qio_mode_reg ? 3'd4 : 3'd1);
        end

        if (!busy && !start) begin
            tx_active <= !tx_size_0;
            rx_active <= !rx_size_0;
        end
    end

    always @(posedge clk) begin
        if (spi_active_cycle) begin
            if (!tx_size_0) tx_data_reg <= {tx_data_reg[MAX_TX_LENGTH - 2:0], 1'b0};

            if (!rx_size_0) begin
                if (qio_mode_reg) begin
                    // Assumes that rx_data is a multiple of 4. This is not enforced and must be taken care of by user
                    // of module.
                    rx_data <= {rx_data[MAX_RX_LENGTH - 4:1], data_in};
                end else begin
                    rx_data <= {rx_data[MAX_RX_LENGTH - 2:0], data_in[0]};
                end
            end

            if (tx_size_reg == 1'd1) begin
                // If at end of transmission and still reading more, activate dummy mode.
                dummy_reg <= 1'b1;
            end
        end
    end

    assign spi_clk_pad = spi_clk;
    assign data_out = !reset && !dummy_reg && tx_data_reg[MAX_TX_LENGTH - 1];

endmodule
