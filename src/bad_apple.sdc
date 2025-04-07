//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11.01 
//Created Time: 2025-03-22 14:23:57
create_clock -name SYS_CLK -period 37.037 -waveform {0 18.518} [get_ports {CLOCK_27}]
//create_generated_clock -name LED_CLOCK -source [get_ports {CLOCK_27}] -master_clock SYS_CLK -divide_by 6745000 [get_nets {led_clock}]
