module teststuff(
    input wire CLOCK_27,
    input wire RST,
    output wire [5:0] LED);

    reg [5:0] mem [3:0];
    reg [9:0] address = 0;

    always @(posedge CLOCK_27) begin
        if (RST)
            address <= address + 1'b1;

        mem[address] <= mem[address] + 1;
    end

    assign LED = mem[address];
endmodule