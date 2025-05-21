module edge_detector #(
   parameter EDGE = 1,           // Which edge: 1 == rising, 0 == falling
   parameter IGNORE_FIRST = 0    // If IGNORE_FIRST != 0 and first sample matches desired edge level, ignore.
) (
    input wire clk,
    input wire reset,

    input wire signal,
    output wire edge_pulse
);

    localparam EDGE_BIT = EDGE ? 1'b1 : 1'b0;

    reg prev = IGNORE_FIRST ? EDGE_BIT : ~EDGE_BIT;

    always @(posedge clk) begin
        prev <= signal;
    end

    assign edge_pulse = (signal == EDGE_BIT) & (prev != EDGE_BIT);
endmodule
