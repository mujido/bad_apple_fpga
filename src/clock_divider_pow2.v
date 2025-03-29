module clock_divider_pow2 #( 
    parameter Power = 1
) ( 
    input wire clk_in,
    input wire rst,
    
    output wire clk_out,
    output wire clk_out_rising,
    output wire clk_out_falling
);

    reg [Power:0] counter = 0;

    always @(posedge clk_in or posedge rst) begin
        if (rst)
            counter <= 0;
        else 
            counter <= counter + 1'b1;
    end

    assign clk_out = counter[Power];
    assign clk_out_rising = clk_out & ~|counter[Power - 1:0];
    assign clk_out_falling = &counter;

endmodule
