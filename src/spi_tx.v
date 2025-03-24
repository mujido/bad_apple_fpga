module spi_tx #(
    parameter BitCount = 8,
    parameter BitCountLog2 = 4,
    parameter MosiIdleState = 1'b1
) (

    input wire sclk,
    output wire mosi,

    input wire [BitCount - 1:0] data,

    input wire start,
    input wire reset,
    output reg busy,
    output reg done
);

    reg [BitCountLog2 - 1:0] send_counter;
    reg [BitCount - 1:0] buffer;

    always @(posedge sclk or posedge reset) begin
        if (reset) begin
            send_counter <= 0;
            buffer <= 0;
            buffer[BitCount - 1] <= MosiIdleState;
            busy <= 0;
            done <= 0;
        end else if (!busy & start) begin
            // Start a new send transaction
            send_counter <= 0;
            buffer <= data;
            busy <= 1'b1;
            done <= 1'b0;
        end else if (busy) begin
            // Continue sending data
            buffer <= {buffer[BitCount - 2:0], 1'b0};

            if (send_counter != BitCount - 1)
                send_counter <= send_counter + 1'b1;

            // Toggle busy/done now so that a new transaction can
            // begin on the next clock cycle when done sending 
            if (send_counter == BitCount - 2) begin
                busy <= 1'b0;
                done <= 1'b1;
            end
        end else 
            buffer[BitCount - 1] = MosiIdleState;
    end
            
    // assign mosi = !busy | buffer[BitCount - 1];
    assign mosi = buffer[BitCount - 1];
endmodule

/*
module spi #(
    parameter MaxSendBits = 7,
    parameter MaxSendBitsLog2 = 3,
    parameter MaxReceiveBits = 7,
    parameter MaxReceiveBitsLog2 = 3
) (
    input wire sclk,
    input wire miso,
    output wire mosi,

    input wire [MaxSendBitsLog2 - 1:0] send_bit_count,
    input wire [MaxReceiveBitsLog2 - 1:0] receive_bit_count,
    input wire [MaxSendBits - 1:0] send_data,
    output wire [MaxReceiveBits - 1:0] received_data,

    input wire start,
    input wire reset,
    output reg busy
);

    localparam BufferBits = MaxReceiveBits > MaxSendBits ? MaxReceiveBits : MaxSendBits;

    reg [MaxSendBitsLog2 - 1:0] remaining_send_bits;
    reg [MaxReceiveBitsLog2 - 1:0] remaining_receive_bits;
    reg [BufferBits - 1:0] buffer;

    always @(posedge sclk or posedge reset) begin
        if (reset) begin
            remaining_receive_bits <= 0;
            remaining_send_bits <= 0;
            busy <= 0;
        end else if (!busy & start) begin
            remaining_send_bits <= send_bit_count;
            remaining_receive_bits <= receive_bit_count;
            buffer[BufferBits - 1 : BufferBits - MaxReceiveBitsLog2] <= send_data;    // left adjust bits
            busy <= 1'b1;
        end else if (busy) begin
            if (send_bit_count)
                buffer <= {buffer[BufferBits - 1:1], 1'b0};
            else if (receive_bit_count)
                buffer = {buffer[BufferBits - 1:1], miso};
            else
                busy <= 1'b0;
        end
    end
            
    assign mosi = !send_bit_count | buffer[BufferBits - 1];
    assign received_data = buffer[MaxReceiveBits - 1:0];

endmodule
*/