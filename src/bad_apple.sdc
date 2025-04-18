//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.01 
//Created Time: 2025-04-16 20:02:40
create_clock -name XTAL_IN -period 37.037 -waveform {0 18.518} [get_ports {clock_27_pad}]
create_generated_clock -name SYS_CLK -source [get_ports {clock_27_pad}] -master_clock XTAL_IN -divide_by 7 -multiply_by 26 [get_nets {clk_100}]
create_generated_clock -name SDIO_CLK -source [get_nets {clk_100}] -master_clock SYS_CLK -divide_by 4 [get_pins {sd_master/sd_controller0/clock_divider0/SD_CLK_O_s2/Q sdio_clk_pad_obuf/O}]
set_false_path -from [get_clocks {SYS_CLK}] -to [get_clocks {SDIO_CLK}] 
set_false_path -from [get_clocks {SDIO_CLK}] -through [get_pins {sd_master/sd_controller0/clock_divider0/n33_s3/I0}] -to [get_clocks {SYS_CLK}] 
