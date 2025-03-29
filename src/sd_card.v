/*module SD_Card_SPI
(
    input wire enable,
    input wire [7:0] command,
    input wire [31:0] args,
    
    output reg [7:0] out,
    output wire out_ready,

    // Status bits in first response byte
    output wire parameter_error,
    output wire address_error,
    output wire erase_sequence_error,
    output wire crc_error,
    output wire illegal_command,
    output wire erase_reset,
    output wire in_idle_state,

    input wire clk,
    input wire miso,
    input wire reset,

    output wire chip_select,
    output wire mosi
);


    localparam ST_RESET = 4'd0;
    localparam ST_IDLE = 4'd1;
    localparam ST_RUN_CMD_R7 = 4'd2;
    //localparam ST_RUN_CMD_R7_TRANS_BIT = 4'd3;
    //localparam ST_RUN_CMD_R7_TRANSMIT = 4'd4;
    localparam ST_RECV_R7 = 4'd5;

    localparam BIT_ILLEGAL_CMD = 2;

    reg [4:0] state;
    reg [7:0] state_counter;
    reg [47:0] cmd_shift_buffer;
    reg [7:0] receive_buffer;

    reg [6:0] status_buffer;
    reg mosi_state;
    reg chip_select_state;

    assign parameter_error = status_buffer[6];
    assign address_error = status_buffer[5];
    assign erase_sequence_error = status_buffer[4];
    assign crc_error = status_buffer[3];
    assign illegal_command = status_buffer[BIT_ILLEGAL_CMD];
    assign erase_reset = status_buffer[1];
    assign in_idle_state = status_buffer[0];

    assign mosi = mosi_state;
    assign chip_select = chip_select_state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= ST_RESET;
            state_counter <= 'h0;
            mosi_state <= 1'b1;
            chip_select_state <= 1'b1;
            out_ready <= 1'b0;
            status_buffer <= 7'b0;
        end
        else begin
            case (state) 
                ST_RESET : begin
                    if (state_counter[7]) begin
                        state <= ST_RUN_CMD_R7;
                        cmd_shift_buffer <= { 2'b01, 6'd8, 32'h1aa, 7'h87, 1'b1 };
                        state_counter <= 'd0;
                    end
                    else
                        state_counter <= state_counter + 1'b1;
                end

                ST_RUN_CMD_R7 : begin
                    if (state_counter[6:0] < 7'd48) begin
                        mosi_state <= cmd_shift_buffer[47];
                        cmd_shift_buffer <= { cmd_shift_buffer[46:0], 1'b0 };
                        state_counter <= state_counter + 1'b1;
                    end
                    else begin
                        state <= ST_RECV_R7;

                        // This clock cycle we already received the first bit
                        state_counter <= 6'd1;
                        mosi_state <= 1'b1;
                        receive_buffer[0] <= miso;
                    end
                end

                ST_RECV_R7 : begin
                    receive_buffer <= { receive_buffer[6:0], miso };
                    state_counter <= state_counter + 1'b1;

                    if (state_counter[5:0] == 6'd8) begin
                        // When 8th bit is received, this represents the R1 status buffer
                        state_buffer <= receive_buffer;

                        if (receive_buffer[BIT_ILLEGAL_CMD]) begin
                            // Old V1 card doesn't support CMD8
                            state <= ST_IDLE;
                            out_ready <= 1'b1;
                        end
                    end
                    else if (state_counter[5:0] == )
                    else if (state_counter[5:0] == 6'd40) begin
                        // Received the full R7 response at this point. 

                end
            endcase
        end
    end


endmodule
*/