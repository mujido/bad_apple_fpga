module ClockDividerArb
#(
    COUNT = 1,
    COUNT_LOG2 = 1
)
(
    input wire clk_in,
    input wire rst,
    output wire clk_out
);

    reg [COUNT_LOG2 - 1 : 0] counter;

    always @(posedge clk_in or posedge rst)
        if (rst)
            counter <= 0;
        else if (clk_out)
            counter <= 0;
        else
            counter <= counter + 1'b1;

    assign clk_out = counter == COUNT;

endmodule