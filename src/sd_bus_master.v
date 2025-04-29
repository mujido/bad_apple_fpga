module sd_bus_master #(
    parameter LOWFREQ_CLK_DIVIDER = 1,
    parameter HIGHFREQ_CLK_DIVIDER = 1
) (
    input wire clk,
    input wire sdio_base_clk,
    input wire reset,

    inout wire [3:0] sdio_data,
    inout wire sdio_cmd,
    output wire sdio_clk,
    output wire [5:0] leds
);

    // Wishbone bus registers
    wire wb_clk = clk;
    reg wb_rst;

    reg [31:0] sdc_wb_dat_o;
    wire [31:0] sdc_wb_dat_i;
    reg [7:0] sdc_wb_adr_o;
    reg [3:0] sdc_wb_sel_o;
    reg sdc_wb_we_o;
    reg sdc_wb_cyc_o;
    reg sdc_wb_stb_o;
    wire sdc_wb_ack_i;
    wire sdc_cmd_oe;
    wire sdc_data_oe;
    wire sdc_cmd_out;
    wire [3:0] sdc_data_out;

    wire [31:0] sdc_dataout_wb_dat_i;

    assign sdio_cmd = sdc_cmd_oe ? sdc_cmd_out : 1'bz;
    assign sdio_data = sdc_data_oe ? sdc_data_out : 4'bzzzz;

    sdc_controller sd_controller0(
        .wb_clk_i(wb_clk),
        .wb_rst_i(wb_rst),
        .wb_dat_i(sdc_wb_dat_o),
        .wb_dat_o(sdc_wb_dat_i),
        .wb_adr_i(sdc_wb_adr_o),
        .wb_sel_i(sdc_wb_sel_o),
        .wb_we_i(sdc_wb_we_o),
        .wb_stb_i(sdc_wb_stb_o),
        .wb_cyc_i(sdc_wb_cyc_o),
        .wb_ack_o(sdc_wb_ack_i),
        // .m_wb_adr_o(wbm_sdm_adr_o),
        // .m_wb_sel_o(wbm_sdm_sel_o),
        // .m_wb_we_o(wbm_sdm_we_o),
        .m_wb_dat_o(sdc_dataout_wb_dat_i),
        // .m_wb_dat_i(sdc_dataout_wb_dat_o),
        // .m_wb_cyc_o(wbm_sdm_cyc_o),
        // .m_wb_stb_o(wbm_sdm_stb_o),
        // .m_wb_ack_i(wbm_sdm_ack_i),
        // .m_wb_cti_o(wbm_sdm_cti_o),
        // .m_wb_bte_o(wbm_sdm_bte_o),
        .sd_cmd_dat_i(sdio_cmd),
        .sd_cmd_out_o(sdc_cmd_out),
        .sd_cmd_oe_o(sdc_cmd_oe),
        .sd_dat_dat_i(sdio_data),
        .sd_dat_out_o(sdc_data_out),
        .sd_dat_oe_o(sdc_data_oe),
        .sd_clk_o_pad(sdio_clk),
        .sd_clk_i_pad(sdio_base_clk)
        // .int_cmd (int_cmd),
        // .int_data (int_data)
    );

    reg [1:0] reset_counter = 0;

    always @(posedge wb_clk or posedge reset) begin
        if (reset) begin
            reset_counter <= 2'd0;
            wb_rst = 1'b1;
        end else if (~&reset_counter) begin
            reset_counter <= reset_counter + 1'b1;
        end else begin
            wb_rst = 1'b0;
        end
    end

    localparam SDC_ADDR_ARGUMENT = 8'h00;
    localparam SDC_ADDR_COMMAND = 8'h04;
    localparam SDC_ADDR_RESPONSE_0 = 8'h08;
    localparam SDC_ADDR_RESPONSE_1 = 8'h0C;
    localparam SDC_ADDR_RESPONSE_2 = 8'h10;
    localparam SDC_ADDR_RESPONSE_3 = 8'h14;
    localparam SDC_ADDR_DATA_TIMEOUT = 8'h18;
    localparam SDC_ADDR_CONTROL = 8'h1C;
    localparam SDC_ADDR_CMD_TIMEOUT = 8'h20;
    localparam SDC_ADDR_CLOCK_DIVIDER = 8'h24;
    // localparam SDC_ADDR_RESET = 8'h28;
    localparam SDC_ADDR_VOLTAGE = 8'h2C;
    localparam SDC_ADDR_CAPABILITIES = 8'h30;
    localparam SDC_ADDR_CMD_EVENT_STATUS = 8'h34;
    localparam SDC_ADDR_CMD_EVENT_ENABLE = 8'h38;
    localparam SDC_ADDR_DATA_EVENT_STATUS = 8'h3C;
    localparam SDC_ADDR_DATA_EVENT_ENABLE = 8'h40;
    localparam SDC_ADDR_BLOCK_SIZE = 8'h44;
    localparam SDC_ADDR_BLOCK_COUNT = 8'h48;
    localparam SDC_ADDR_DATA_XFER_ADDRESS = 8'h60;

    localparam SDC_CONFIG_TIMEOUT = 24'h7FFF;

    localparam MMC_RSP_PRESENT  = 32'b00001;
    localparam MMC_RSP_136      = 32'b00010;     // 136 bit response
    localparam MMC_RSP_CRC      = 32'b00100;     // expect valid CRC
    localparam MMC_RSP_BUSY     = 32'b01000;     // card may send busy signal
    localparam MMC_RSP_OPCODE   = 32'b10000;     // response contains opcode

    localparam MMC_RSP_NONE = 5'd0;
    localparam MMC_RSP_R1   = MMC_RSP_PRESENT | MMC_RSP_CRC | MMC_RSP_OPCODE;
    localparam MMC_RSP_R1b  = MMC_RSP_R1 | MMC_RSP_BUSY;
    localparam MMC_RSP_R2   = MMC_RSP_PRESENT | MMC_RSP_CRC | MMC_RSP_OPCODE;
    localparam MMC_RSP_R3   = MMC_RSP_PRESENT;
    localparam MMC_RSP_R4   = MMC_RSP_PRESENT;
    localparam MMC_RSP_R5   = MMC_RSP_PRESENT | MMC_RSP_CRC | MMC_RSP_OPCODE;
    localparam MMC_RSP_R6   = MMC_RSP_PRESENT | MMC_RSP_CRC | MMC_RSP_OPCODE;
    localparam MMC_RSP_R7   = MMC_RSP_PRESENT | MMC_RSP_CRC | MMC_RSP_OPCODE;

    localparam MMC_CMD_GO_IDLE_STATE        = 6'd0;
    localparam MMC_CMD_SEND_OP_COND         = 6'd1;
    localparam MMC_CMD_ALL_SEND_CID         = 6'd2;
    localparam MMC_CMD_SET_RELATIVE_ADDR    = 6'd3;
    localparam MMC_CMD_SET_DSR              = 6'd4;
    localparam MMC_CMD_SWITCH               = 6'd6;
    localparam MMC_CMD_SELECT_CARD          = 6'd7;
    localparam MMC_CMD_SEND_EXT_CSD         = 6'd8;
    localparam MMC_CMD_SEND_CSD             = 6'd9;
    localparam MMC_CMD_SEND_CID             = 6'd10;
    localparam MMC_CMD_STOP_TRANSMISSION    = 6'd12;
    localparam MMC_CMD_SEND_STATUS          = 6'd13;
    localparam MMC_CMD_SET_BLOCKLEN         = 6'd16;
    localparam MMC_CMD_READ_SINGLE_BLOCK    = 6'd17;
    localparam MMC_CMD_READ_MULTIPLE_BLOCK  = 6'd18;
    localparam MMC_CMD_WRITE_SINGLE_BLOCK   = 6'd24;
    localparam MMC_CMD_WRITE_MULTIPLE_BLOCK = 6'd25;
    localparam MMC_CMD_ERASE_GROUP_START    = 6'd35;
    localparam MMC_CMD_ERASE_GROUP_END      = 6'd36;
    localparam MMC_CMD_ERASE                = 6'd38;
    localparam MMC_CMD_APP_CMD              = 6'd55;
    localparam MMC_CMD_SPI_READ_OCR         = 6'd58;
    localparam MMC_CMD_SPI_CRC_ON_OFF       = 6'd59;

    localparam SD_CMD_SEND_RELATIVE_ADDR	= 6'd3;
    localparam SD_CMD_SWITCH_FUNC		    = 6'd6;
    localparam SD_CMD_SEND_IF_COND		    = 6'd8;

    localparam SD_CMD_APP_SET_BUS_WIDTH	    = 6'd6;
    localparam SD_CMD_ERASE_WR_BLK_START	= 6'd32;
    localparam SD_CMD_ERASE_WR_BLK_END		= 6'd33;
    localparam SD_CMD_APP_SEND_OP_COND		= 6'd41;
    localparam SD_CMD_APP_SEND_SCR		    = 6'd51;

    localparam MMC_DATA_XFER_NONE  = 2'b00;
    localparam MMC_DATA_XFER_READ  = 2'b01;
    localparam MMC_DATA_XFER_WRITE = 2'b10;

    reg [5:0] led_regs;

    task sdc_bus_idle;
        begin
            sdc_wb_we_o <= 1'b0;
            sdc_wb_cyc_o <= 1'b0;
            sdc_wb_stb_o <= 1'b0;
        end
    endtask

    localparam SD_OP_WIDTH = 2;
    localparam SD_OP_IDLE = 2'd0;
    localparam SD_OP_SET_REG = 2'd1;
    localparam SD_OP_READ_REG = 2'd2;
    localparam SD_OP_JUMP = 2'd3;

    localparam SD_INIT_OP_COUNT = 5'd27;
    localparam SD_INIT_OP_COUNT_LOG2 = 5;

    function automatic [41:0] sd_op_set_reg(
        input [7:0] sdc_addr,
        input [31:0] reg_value
    );
        sd_op_set_reg = {SD_OP_SET_REG, sdc_addr, reg_value};
    endfunction

    function automatic [41:0] sd_op_read_reg(input [7:0] sdc_addr);
        sd_op_read_reg = {SD_OP_READ_REG, sdc_addr, 32'd0};
    endfunction

    function automatic [41:0] sd_op_no_args(input [1:0] opcode);
        sd_op_no_args = {opcode, 40'd0};
    endfunction

    function automatic [41:0] sd_op_set_cmd(input [5:0] mmc_cmd, input [3:0] response_type, input [1:0] data_xfer_direction);
        sd_op_set_cmd = sd_op_set_reg(SDC_ADDR_COMMAND, {mmc_cmd, 1'b0, data_xfer_direction, response_type});
    endfunction

    function automatic [41:0] sd_op_jump(input [SD_INIT_OP_COUNT_LOG2 - 1:0] index);
        sd_op_jump = {SD_OP_JUMP, {(41 - SD_OP_WIDTH - SD_INIT_OP_COUNT_LOG2 + 1){1'b0}}, index};
    endfunction

    reg [SD_INIT_OP_COUNT_LOG2 - 1:0] sd_init_ops_index;
    reg [SD_INIT_OP_COUNT_LOG2 - 1:0] sd_init_ops_next_index;

    wire [41:0] sd_init_ops[SD_INIT_OP_COUNT - 1:0];
    assign sd_init_ops[0] = sd_op_set_reg(SDC_ADDR_DATA_TIMEOUT, SDC_CONFIG_TIMEOUT);
    assign sd_init_ops[1] = sd_op_set_reg(SDC_ADDR_CONTROL, 1'b1);
    assign sd_init_ops[2] = sd_op_set_reg(SDC_ADDR_CMD_TIMEOUT, SDC_CONFIG_TIMEOUT);
    assign sd_init_ops[3] = sd_op_set_reg(SDC_ADDR_CLOCK_DIVIDER, LOWFREQ_CLK_DIVIDER);
    assign sd_init_ops[4] = sd_op_set_reg(SDC_ADDR_CMD_EVENT_ENABLE, 0);
    assign sd_init_ops[5] = sd_op_set_reg(SDC_ADDR_CMD_EVENT_STATUS, 0);
    assign sd_init_ops[6] = sd_op_set_reg(SDC_ADDR_DATA_EVENT_ENABLE, 0);
    assign sd_init_ops[7] = sd_op_set_reg(SDC_ADDR_DATA_EVENT_STATUS, 0);
    assign sd_init_ops[8] = sd_op_set_reg(SDC_ADDR_BLOCK_SIZE, 511);
    assign sd_init_ops[9] = sd_op_set_reg(SDC_ADDR_BLOCK_COUNT, 0);
    assign sd_init_ops[10] = sd_op_set_reg(SDC_ADDR_DATA_XFER_ADDRESS, 0);
    assign sd_init_ops[11] = sd_op_read_reg(SDC_ADDR_DATA_TIMEOUT);
    assign sd_init_ops[12] = sd_op_read_reg(SDC_ADDR_CONTROL);
    assign sd_init_ops[13] = sd_op_read_reg(SDC_ADDR_CMD_TIMEOUT);
    assign sd_init_ops[14] = sd_op_read_reg(SDC_ADDR_CLOCK_DIVIDER);
    assign sd_init_ops[15] = sd_op_read_reg(SDC_ADDR_CMD_EVENT_ENABLE);
    assign sd_init_ops[16] = sd_op_read_reg(SDC_ADDR_CMD_EVENT_STATUS);
    assign sd_init_ops[17] = sd_op_read_reg(SDC_ADDR_DATA_EVENT_ENABLE);
    assign sd_init_ops[18] = sd_op_read_reg(SDC_ADDR_DATA_EVENT_STATUS);
    assign sd_init_ops[19] = sd_op_read_reg(SDC_ADDR_BLOCK_SIZE);
    assign sd_init_ops[20] = sd_op_read_reg(SDC_ADDR_BLOCK_COUNT);
    assign sd_init_ops[21] = sd_op_read_reg(SDC_ADDR_DATA_XFER_ADDRESS);
    assign sd_init_ops[22] = sd_op_set_cmd(MMC_CMD_GO_IDLE_STATE, MMC_RSP_NONE, MMC_DATA_XFER_NONE);
    assign sd_init_ops[23] = sd_op_set_reg(SDC_ADDR_ARGUMENT, 0);
    assign sd_init_ops[24] = sd_op_set_cmd(SD_CMD_SEND_IF_COND, MMC_RSP_R3, MMC_DATA_XFER_NONE);
    assign sd_init_ops[25] = sd_op_set_reg(SDC_ADDR_ARGUMENT, 0);
    assign sd_init_ops[26] = sd_op_jump(26);

    wire [41:0] sd_current_init_op = sd_init_ops[sd_init_ops_index];

    reg sd_op_is_sd_cmd;

    always @(*) begin
         if (wb_rst) begin
            sd_op_is_sd_cmd <= 1'b0;
         end else begin
            case (sd_current_init_op[41:40])
                SD_OP_SET_REG,
                SD_OP_READ_REG : sd_op_is_sd_cmd = 1'b1;
                default : sd_op_is_sd_cmd = 1'b0;
            endcase
         end
    end

    always @(*) begin
        if (wb_rst) begin
            sd_init_ops_next_index = 0;
        end else if (sd_current_init_op[41:40] == SD_OP_JUMP) begin
            sd_init_ops_next_index = sd_current_init_op[SD_INIT_OP_COUNT_LOG2 - 1:0];
        end else if (~sd_op_is_sd_cmd | sdc_wb_ack_i) begin
            sd_init_ops_next_index = sd_init_ops_index + 1'b1;
        end else begin
            sd_init_ops_next_index = sd_init_ops_index;
        end
    end

    always @(*) begin
        sdc_wb_sel_o = 4'b1111;

        if (wb_rst) begin
            sdc_wb_we_o = 1'b0;
            sdc_wb_cyc_o = 1'b0;
            sdc_wb_stb_o = 1'b0;
            sdc_wb_adr_o = 0;
            sdc_wb_dat_o = 0;
        end else begin
            sdc_wb_cyc_o = sd_op_is_sd_cmd;
            sdc_wb_stb_o = sd_op_is_sd_cmd;
            sdc_wb_we_o = sd_current_init_op[41:40] == SD_OP_SET_REG;

            case (sd_current_init_op[41:40])
                SD_OP_SET_REG,
                SD_OP_READ_REG : begin
                    sdc_wb_adr_o = sd_init_ops[sd_init_ops_next_index][39:32];
                    sdc_wb_dat_o = sd_init_ops[sd_init_ops_next_index][31:0];
                end

                default : begin
                    sdc_wb_adr_o = 0;
                    sdc_wb_dat_o = 0;
                end
            endcase
        end
    end

    always @(posedge wb_clk) sd_init_ops_index <= sd_init_ops_next_index;

    // assign led_pads = ~led_regs;
    // assign leds = sdc_wb_dat_i[5:0];
    assign leds = sdc_dataout_wb_dat_i[5:0];

endmodule
