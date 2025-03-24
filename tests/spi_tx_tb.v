module spi_tx_tb;

    reg clk = 0;
    reg [4:0] send_data;
    reg start = 0;
    reg reset = 0;
    reg [1:0] step = 0;

    wire mosi;
    wire busy;
    wire done;

    spi_tx #(.BitCount(5), .BitCountLog2(3)) tx(
        .sclk(clk), 
        .mosi(mosi), 
        .data(send_data), 
        .start(start), 
        .reset(reset), 
        .busy(busy),
        .done(done));

    always #5 clk = !clk;

    initial begin
        $dumpfile("spi_tx_tb.vcd");
        $dumpvars(0, spi_tx_tb);

        send_data = 5'h0C;
        start = 0;
        reset = 1;

        // begin transfer
        #10 reset = 0;
        #5 start = 1;

        // clear send data to test copy to internal buffer
        #10 send_data = 0;
        #10 start = 0;

        #20 send_data = 5'h15;
        #10 start = 0;
    end

    always @(posedge clk) begin
        if (done) begin
            if (step == 1) 
                #20 $finish;
            else begin
                step = step + 1;
                start = 1;
                #10 start = 0;
            end
        end
    end

endmodule