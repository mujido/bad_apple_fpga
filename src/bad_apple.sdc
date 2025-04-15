//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.01 
//Created Time: 2025-04-13 23:45:33
create_clock -name XTAL_IN -period 37.037 -waveform {0 18.518} [get_ports {clock_27_pad}]
create_generated_clock -name SYS_CLK -source [get_ports {clock_27_pad}] -master_clock XTAL_IN -divide_by 7 -multiply_by 26 [get_nets {clk_100}]
create_generated_clock -name SDIO_HIGHFREQ -source [get_nets {clk_50}] -master_clock SDIO_BASE_CLK -divide_by 2 [get_regs {sd_master/sd_controller0/clock_divider0/SD_CLK_O_s2}]
create_generated_clock -name SDIO_BASE_CLK -source [get_nets {clk_100}] -master_clock SYS_CLK -divide_by 2 [get_nets {clk_50}]
create_generated_clock -name SDIO_CLK_PIN -source [get_regs {sd_master/sd_controller0/clock_divider0/SD_CLK_O_s2}] -master_clock SDIO_HIGHFREQ -divide_by 1 -add [get_ports {sdio_clk_pad}]
