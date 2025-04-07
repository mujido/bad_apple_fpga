module spi_rx #(
    parameter MaxBitCount = 8,
    parameter MaxBitCountLog2 = 4
) (
    input wire sclk,
    input wire miso,
    input wire [MaxBitCountLog2 - 1:0] read_length,

    output reg [MaxBitCount - 1:0] data,
    output reg data_ready,

    input wire start,
    input wire reset
);

    reg [MaxBitCountLog2 - 1:0] read_counter;

    wire busy = read_counter != 0;

    always @(posedge sclk or posedge reset) begin
        if (reset) begin
            read_counter <= 0;
            data <= 0;
            data_ready <= 0;
        end else if (!busy & start) begin
            // Start a new read transaction
            read_counter <= read_length - 1'b1;
            data[0] <= miso;
        end else if (busy) begin
            // Continue sending data
            data <= {data[MaxBitCount - 2:0], miso};
            read_counter <= read_counter - 1'b1;

            if (read_counter == 1)
                data_ready <= 1'b1;
        end 
    end
endmodule
