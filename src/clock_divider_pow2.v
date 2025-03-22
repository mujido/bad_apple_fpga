module Clock_Divider_Pow2 #( 
    BITS = 'd1 
) ( 
    input wire clk_in,
    input wire rst,
    
    output wire clk_out
);

    reg [BITS : 0] counter;

    always @(posedge clk_in or posedge rst)
        if (rst)
            counter <= 0;
        else
            counter <= counter + 1'b1;

    assign clk_out = counter[BITS - 1];

endmodule
