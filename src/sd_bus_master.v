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

    localparam MMC_DATA_XFER_NONE  = 2'b00;
    localparam MMC_DATA_XFER_READ  = 2'b01;
    localparam MMC_DATA_XFER_WRITE = 2'b10;

    localparam SD_BUS_STATE_INIT_SD_MODULE = 4'd0;
    localparam SD_BUS_STATE_VERIFY = 4'd1;
    localparam SD_BUS_STATE_INIT_CARD = 4'd2;
    localparam SD_BUS_STATE_INIT_SD_MODULE_FAILED = 4'd14;
    localparam SD_BUS_STATE_END = 4'd15;

    reg [3:0] sd_bus_state = 0;
    reg [5:0] led_regs;

    task sdc_bus_idle();
        begin
            sdc_wb_we_o <= 1'b0;
            sdc_wb_cyc_o <= 1'b0;
            sdc_wb_stb_o <= 1'b0;
        end
    endtask

    function automatic [31:0] sd_cmd(input [5:0] opcode, input [3:0] response_type, input [1:0] data_xfer_direction);
        sd_cmd = {opcode, 1'b0, data_xfer_direction, response_type};
    endfunction

    function automatic [39:0] sdc_op(
        input [7:0] sdc_addr,
        input [31:0] reg_value
    );
        sdc_op = {sdc_addr, reg_value};
    endfunction

    localparam SD_INIT_OP_COUNT = 4'd11;
    localparam SD_INIT_OP_COUNT_LOG2 = 4;
    reg [SD_INIT_OP_COUNT_LOG2 - 1:0] sd_init_ops_index;
    wire [SD_INIT_OP_COUNT_LOG2 - 1:0] sd_init_ops_next_index = sd_init_ops_index + 1'b1;

    wire [40:0] sd_init_ops[SD_INIT_OP_COUNT - 1:0];
    assign sd_init_ops[0] = sdc_op(SDC_ADDR_DATA_TIMEOUT, SDC_CONFIG_TIMEOUT);
    assign sd_init_ops[1] = sdc_op(SDC_ADDR_CONTROL, 1'b1);
    assign sd_init_ops[2] = sdc_op(SDC_ADDR_CMD_TIMEOUT, SDC_CONFIG_TIMEOUT);
    assign sd_init_ops[3] = sdc_op(SDC_ADDR_CLOCK_DIVIDER, LOWFREQ_CLK_DIVIDER);
    assign sd_init_ops[4] = sdc_op(SDC_ADDR_CMD_EVENT_ENABLE, 0);
    assign sd_init_ops[5] = sdc_op(SDC_ADDR_CMD_EVENT_STATUS, 0);
    assign sd_init_ops[6] = sdc_op(SDC_ADDR_DATA_EVENT_ENABLE, 0);
    assign sd_init_ops[7] = sdc_op(SDC_ADDR_DATA_EVENT_STATUS, 0);
    assign sd_init_ops[8] = sdc_op(SDC_ADDR_BLOCK_SIZE, 511);
    assign sd_init_ops[9] = sdc_op(SDC_ADDR_BLOCK_COUNT, 0);
    assign sd_init_ops[10] = sdc_op(SDC_ADDR_DATA_XFER_ADDRESS, 0);

    always @(posedge wb_clk) begin
        if (wb_rst) begin
            sd_bus_state <= SD_BUS_STATE_INIT_SD_MODULE;
            sdc_wb_dat_o <= 0;
            sdc_wb_we_o <= 1'b0;
            sdc_wb_sel_o <= 4'b0000;
            sdc_wb_cyc_o <= 1'b0;
            sdc_wb_stb_o <= 1'b0;
            sdc_wb_adr_o <= 0;
            led_regs <= 6'd0;
            sd_init_ops_index <= 'd0;
        end else if (sd_bus_state == SD_BUS_STATE_INIT_SD_MODULE) begin
            sdc_wb_we_o <= 1'b1;
            sdc_wb_sel_o <= 4'b1111;
            sdc_wb_cyc_o <= 1'b1;
            sdc_wb_stb_o <= 1'b1;
            sdc_wb_adr_o <= sd_init_ops[sd_init_ops_next_index][39:32];
            sdc_wb_dat_o <= sd_init_ops[sd_init_ops_next_index][31:0];

            if (sd_init_ops_next_index < SD_INIT_OP_COUNT) begin
                sd_init_ops_index <= sd_init_ops_next_index;
            end else begin
                sdc_wb_adr_o <= sd_init_ops[0][39:32];
                sdc_wb_dat_o <= 0;
                sdc_wb_we_o <= 1'b0;
                sd_bus_state <= SD_BUS_STATE_VERIFY;
            end
        end else if (sd_bus_state == SD_BUS_STATE_VERIFY) begin
            if (sdc_wb_ack_i) begin
                if (sdc_wb_adr_o < SDC_ADDR_DATA_XFER_ADDRESS) begin
                    sdc_wb_adr_o <= sdc_wb_adr_o != SDC_ADDR_BLOCK_COUNT ? sdc_wb_adr_o + 3'd4 : SDC_ADDR_DATA_XFER_ADDRESS;
                end else begin
                    sdc_bus_idle();
                    sd_bus_state <= SD_BUS_STATE_END;
                    // sdc_wb_adr_o <= sd_cmd(MMC_CMD_GO_IDLE_STATE, MMC_RSP_NONE, MMC_DATA_XFER_NONE);
                end
            end
        // end else if (sd_bus_state == SD_BUS_STATE_INIT_CARD) begin
        //             sdc_wb_we_o <= 1'b1;
        //             sdc_wb_adr_o <= SDC_ADDR_COMMAND;
        //             sdc_wb_dat_o <=

        //     if (sdc_wb_ack_i) begin
        //         if (sdc_wb_adr_o == SDC_ADDR_COMMAND) begin
        //             sdc_wb_adr_o <= SDC_ADDR_ARGUMENT;
        //             sdc_wb_dat_o <= 0;
        //         end else begin
        //             sd_bus_state <= SDC_BUS_STATE_CMD_OP_COND;
        //             sdc_wb_adr_o <= 0;
        //         end
        //     end
        // end else if (sd_bus_state == SD_BUS_STATE_CMD_OP_COND) begin
        //     if (!sdc_wb_ack_i) begin
        //         case ((sdc_wb_adr_o))
        //     sdc_wb_dat_o <= sd_cmd(MMC_CMD_SEND_OP_COND, MMC_RSP_R3, MMC_DATA_XFER_NONE);
        //     if (sdc_wb_ack_i) begin
        //         if (sdc_wb_adr_o == SDC_ADDR_COMMAND) begin
        //             sdc_wb_adr_o <= SDC_ADDR_ARGUMENT;
        //             sdc_wb_dat_o <= 0;
        //         end else begin
        //             sd_bus_state <= SDC_BUS_STATE_CMD_OP_COND;
        //             sdc_wb_adr_o <= SDC_ADDR_COMMAND;
        //             sdc_wb_dat_o <= sd_cmd(MMC_CMD_SEND_OP_COND, MMC_RSP_R3, MMC_DATA_XFER_NONE);
        //         end
        //     end
        // end
        end
    end

    // assign led_pads = ~led_regs;
    // assign leds = sdc_wb_dat_i[5:0];
    assign leds = sdc_dataout_wb_dat_i[5:0];

endmodule
