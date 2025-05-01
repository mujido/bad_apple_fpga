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
    reg wb_rst = 0;

    wire [31:0] sdc_wb_dat_o;
    wire [31:0] sdc_wb_dat_i;
    wire [7:0] sdc_wb_adr_o;
    wire [3:0] sdc_wb_sel_o;
    wire sdc_wb_we_o;
    wire sdc_wb_cyc_o;
    wire sdc_wb_stb_o;
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

    always @(posedge wb_clk) wb_rst <= reset;

    sd_fsm #(
        .LOWFREQ_CLK_DIVIDER(LOWFREQ_CLK_DIVIDER),
        .HIGHFREQ_CLK_DIVIDER(HIGHFREQ_CLK_DIVIDER)
    ) fsm (
        .wb_clk_i(wb_clk),
        .wb_rst_i(wb_rst),
        .sdc_wb_dat_o(sdc_wb_dat_o),
        .sdc_wb_dat_i(sdc_wb_dat_i),
        .sdc_wb_adr_o(sdc_wb_adr_o),
        .sdc_wb_sel_o(sdc_wb_sel_o),
        .sdc_wb_we_o(sdc_wb_we_o),
        .sdc_wb_cyc_o(sdc_wb_cyc_o),
        .sdc_wb_stb_o(sdc_wb_stb_o),
        .sdc_wb_ack_i(sdc_wb_ack_i)
    );

    // assign led_pads = ~led_regs;
    // assign leds = sdc_wb_dat_i[5:0];
    assign leds = sdc_dataout_wb_dat_i[5:0];

endmodule
