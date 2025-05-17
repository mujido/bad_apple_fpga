import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge, with_timeout

async def slave_receive_bits(dut, count):
    value = 0
    for i in range(count):
        await FallingEdge(dut.spi_clk_pad)
        dut._log.debug(f"data_out = {dut.data_out.value}")
        value = (value << 1) | dut.data_out.value

    return value

async def master_send_bits(dut, value, count):
    dut.start.value = 1
    dut.qio_mode.value = 0
    dut.dummy.value = 0
    dut.tx_data.value = value
    dut.tx_size.value = 8
    dut.rx_size.value = 0

    await FallingEdge(dut.clk)
    dut.start.value = 0
    dut.tx_data.value = 0
    dut.tx_size.value = 0

    for i in range(8):
        await RisingEdge(dut.clk)
        assert dut.rx_complete.value == 1
        assert dut.tx_complete.value == 0

@cocotb.test(timeout_time=100, timeout_unit='ns')
async def test_transmit(dut):
    dut.reset.value = 0
    dut.start.value = 0
    dut.qio_mode.value = 0
    dut.dummy.value = 0
    dut.tx_data.value = 0
    dut.tx_size.value = 0
    dut.rx_size.value = 0

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    read_task = cocotb.start_soon(slave_receive_bits(dut, 8))

    await Timer(1, 'ns')

    await master_send_bits(dut, 0x3b, 8)
    received = await read_task

    dut._log.debug(f"received={received:#02x}")
    assert received == 0x3b

    await RisingEdge(dut.tx_complete)
    await Timer(1, 'ns')
