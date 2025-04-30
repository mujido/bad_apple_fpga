.phony: all clean

TB_FILES = \
	clock_divider_pow2_tb.v \
	sd_bus_master_tb.v \
	sd_test_tb.v \
	spi_tx_tb.v

VVP_FILES = $(TB_FILES:.v=.vvp)
VCD_FILES = $(TB_FILES:.v=.vcd)

all: $(VCD_FILES)

sd_bus_master_tb.vcd: ../src/sd_bus_master.v ../src/sd_fsm.v

clean:
	rm -f $(VVP_FILES) $(VCD_FILES)

SD_CONTROLLER_SRC = ../thirdparty/SD-card-controller/rtl/verilog

%.vvp: %.v
	iverilog -y ../src -y $(SD_CONTROLLER_SRC) -I $(SD_CONTROLLER_SRC) -o $@ $<

%.vcd: %.vvp
	vvp $< -fst
