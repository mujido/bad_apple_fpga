module sd_bus_master #(
    parameter LOWFREQ_CLK_DIVIDER = 1,
    parameter HIGHFREQ_CLK_DIVIDER = 1
) (
    input wire clk,
    input wire reset,

    inout wire [3:0] sdio_data,
    inout wire sdio_cmd,
    output wire sdio_clk,
    output wire [5:0] leds
);

    // Wishbone bus registers
    wire wb_clk = clk;
    reg wb_rst;

    reg [31:0] sdc_dat_o;
    wire [31:0] sdc_dat_i;
    reg [7:0] sdc_adr_o;
    reg [3:0] sdc_sel_o;
    reg sdc_we_o;
    reg sdc_cyc_o;
    reg sdc_stb_o;
    wire sdc_ack_i;

    sdc_controller sd_controller0(
        .wb_clk_i(wb_clk),
        .wb_rst_i(wb_rst),
        .wb_dat_i(sdc_dat_o),
        .wb_dat_o(sdc_dat_i),
        .wb_adr_i(sdc_adr_o),
        .wb_sel_i(sdc_sel_o),
        .wb_we_i(sdc_we_o),
        .wb_stb_i(sdc_stb_o),
        .wb_cyc_i(sdc_cyc_o),
        .wb_ack_o(sdc_ack_i)
        // .m_wb_adr_o(wbm_sdm_adr_o),
        // .m_wb_sel_o(wbm_sdm_sel_o),
        // .m_wb_we_o(wbm_sdm_we_o),
        // .m_wb_dat_o(wbm_sdm_dat_o),
        // .m_wb_dat_i(wbm_sdm_dat_i),
        // .m_wb_cyc_o(wbm_sdm_cyc_o),
        // .m_wb_stb_o(wbm_sdm_stb_o),
        // .m_wb_ack_i(wbm_sdm_ack_i),
        // .m_wb_cti_o(wbm_sdm_cti_o),
        // .m_wb_bte_o(wbm_sdm_bte_o),
        sd_cmd_dat_i(sd_cmd),
        .sd_cmd_out_o(cmdIn),
        // .sd_cmd_oe_o(sd_cmd_oe),
        // .sd_dat_dat_i(sd_dat),
        // .sd_dat_out_o(datIn),
        // .sd_dat_oe_o( sd_dat_oe),
        // .sd_clk_o_pad(sd_clk_pad_o),
        // .sd_clk_i_pad(wb_clk),
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

    localparam TOP_STATE_INIT = 4'd0;
    localparam TOP_STATE_VERIFY = 4'd1;
    localparam TOP_STATE_INIT_FAILED = 4'd14;
    localparam TOP_STATE_END = 4'd15;

    reg [3:0] top_state = 0;
    reg [5:0] led_regs;

    task sdc_bus_idle();
        begin
            sdc_we_o <= 1'b0;
            sdc_cyc_o <= 1'b0;
            sdc_stb_o <= 1'b0;
        end
    endtask

    // task sdc_init_register_and_verify(
    //     input integer reg_size,
    //     input [31:0] reg_addr,
    //     input [31:0] value,
    //     input [7:0] next_addr
    // );
    //     begin
    //         if (top_state == TOP_STATE_INIT) begin
    //             if (!sdc_stb_o) begin
    //                 sdc_dat_o[reg_size - 1:0] <= value;
    //                 sdc_we_o <= 1'b1;
    //                 sdc_sel_o <= 4'b0111;
    //                 sdc_cyc_o <= 1'b1;
    //                 sdc_stb_o <= 1'b1;
    //             end else if (sdc_ack_i) begin
    //                 top_state <= TOP_STATE_VERIFY;
    //                 sdc_we_o <= 1'b0;
    //             end
    //         end else begin
    //             if (sdc_ack_i) begin
    //                 if (sdc_dat_i[reg_size - 1:0] == value) begin
    //                     top_state <= TOP_STATE_INIT;
    //                     sdc_adr_o <= next_addr;

    //                 led_regs <= sdc_dat_i;
    //                 top_state <= TOP_STATE_END;
    //             end
    //         end
    //     end
    // endtask



    always @(posedge wb_clk) begin
        if (wb_rst) begin
            top_state <= TOP_STATE_INIT;
            sdc_dat_o <= 0;
            sdc_we_o <= 1'b0;
            sdc_sel_o <= 4'b0000;
            sdc_cyc_o <= 1'b0;
            sdc_stb_o <= 1'b0;
            sdc_adr_o <= 0;
            led_regs <= 6'd0;
        end else if (top_state == TOP_STATE_INIT) begin
            if (!sdc_stb_o) begin
                // Begin write cycle
                sdc_we_o <= 1'b1;
                sdc_sel_o <= 4'b0111;
                sdc_cyc_o <= 1'b1;
                sdc_stb_o <= 1'b1;
                sdc_adr_o <= SDC_ADDR_DATA_TIMEOUT;
                sdc_dat_o <= SDC_CONFIG_TIMEOUT;
            end

            if (sdc_ack_i) begin
                // Previous write complete. Move to next.
                case (sdc_adr_o)
                    SDC_ADDR_DATA_TIMEOUT : begin
                        sdc_adr_o <= SDC_ADDR_CONTROL;
                        sdc_dat_o <= 1'b1;
                    end

                    SDC_ADDR_CONTROL : begin
                        sdc_adr_o <= SDC_ADDR_CMD_TIMEOUT;
                        sdc_dat_o <= SDC_CONFIG_TIMEOUT;
                    end

                    SDC_ADDR_CMD_TIMEOUT : begin
                        sdc_adr_o <= SDC_ADDR_CLOCK_DIVIDER;
                        sdc_dat_o <= LOWFREQ_CLK_DIVIDER;
                    end

                    SDC_ADDR_CLOCK_DIVIDER : begin
                        // disable command interrupts
                        sdc_adr_o <= SDC_ADDR_CMD_EVENT_ENABLE;
                        sdc_dat_o <= 0;
                    end

                    SDC_ADDR_CMD_EVENT_ENABLE : begin
                        // disable data interrupts
                        sdc_adr_o <= SDC_ADDR_DATA_EVENT_ENABLE;
                        sdc_dat_o <= 0;
                    end

                    SDC_ADDR_DATA_EVENT_ENABLE : begin
                        // clear command interrupt flags
                        sdc_adr_o <= SDC_ADDR_CMD_EVENT_STATUS;
                        sdc_dat_o <= 0;
                    end

                    SDC_ADDR_CMD_EVENT_STATUS : begin
                        // clear data interrupt flags
                        sdc_adr_o <= SDC_ADDR_DATA_EVENT_STATUS;
                        sdc_dat_o <= 0;
                    end

                    SDC_ADDR_DATA_EVENT_STATUS : begin
                        sdc_adr_o <= SDC_ADDR_BLOCK_SIZE;
                        sdc_dat_o <= 511;
                    end

                    SDC_ADDR_BLOCK_SIZE : begin
                        sdc_adr_o <= SDC_ADDR_BLOCK_COUNT;
                        sdc_dat_o <= 0;
                    end

                    SDC_ADDR_BLOCK_COUNT : begin
                        sdc_adr_o <= SDC_ADDR_DATA_XFER_ADDRESS;
                        sdc_dat_o <= 0;
                    end

                    SDC_ADDR_DATA_XFER_ADDRESS : begin
                        top_state <= TOP_STATE_VERIFY;
                        sdc_we_o <= 1'b0;
                    end
                endcase
            end
        end else if (top_state == TOP_STATE_VERIFY) begin
            if (sdc_ack_i) begin
                if (sdc_adr_o <= SDC_ADDR_DATA_XFER_ADDRESS) begin
                    sdc_adr_o <= sdc_adr_o != SDC_ADDR_BLOCK_COUNT ? sdc_adr_o + 4 : SDC_ADDR_DATA_XFER_ADDRESS;
                end else begin
                    sdc_bus_idle();
                    top_state <= TOP_STATE_END;
                end
            end
        end
    end

    // assign led_pads = ~led_regs;
    assign leds = sdc_dat_i;

endmodule
