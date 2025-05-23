`timescale 1ns / 1ns

module sd_bus_master_tb;

    reg clk = 0;

    reg reset = 1;
    wire sdio_clk_pad;
    wire sdio_cmd_pad;
    wire [3:0] sdio_data_pads;

    always #1 clk = !clk;

    sd_bus_master sd_master(
        .clk(clk),
        .reset(reset),
        .sdio_clk(sdio_clk_pad),
        .sdio_cmd(sdio_cmd_pad),
        .sdio_data(sdio_data_pads)
    );

    initial begin
        $dumpfile("sd_bus_master_tb.vcd");
        $dumpvars(0, sd_bus_master_tb);

        #6 reset = 0;

        #120 $finish;
    end
endmodule
