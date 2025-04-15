//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.01 
//Created Time: 2025-04-15 17:03:21
create_clock -name XTAL_IN -period 37.037 -waveform {0 18.518} [get_ports {clock_27_pad}]
create_generated_clock -name SYS_CLK -source [get_ports {clock_27_pad}] -master_clock XTAL_IN -divide_by 7 -multiply_by 26 [get_pins {pll0/rpll_inst/CLKOUT}]
create_generated_clock -name SDIO_BASE_CLK -source [get_ports {clock_27_pad}] -master_clock XTAL_IN -divide_by 7 -multiply_by 13 [get_pins {pll0/rpll_inst/CLKOUTD}]
create_generated_clock -name SDIO_HIGHFREQ_CLK -source [get_nets {clk_50}] -master_clock SDIO_BASE_CLK -divide_by 2 [get_nets {sdio_clk_pad_d}]
