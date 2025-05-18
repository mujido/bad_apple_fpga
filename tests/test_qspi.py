import cocotb
from cocotb.binary import LogicArray
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge


async def slave_receive_bits(dut, count):
    value = 0
    for _ in range(count):
        await FallingEdge(dut.spi_clk_pad)
        dut._log.debug(f"data_out = {dut.data_out.value}")
        value = (value << 1) | dut.data_out.value

    return value


async def slave_send_bits(dut, value, count, qio_mode=False):
    iter_size = 4 if qio_mode else 1

    if not qio_mode:
        dut.data_in.value = LogicArray("ZZZ0")

    for i in range(0, count // iter_size):
        await FallingEdge(dut.spi_clk_pad)

        if qio_mode:
            dut.data_in.value = (value >> 4 * i) & 0xF
        else:
            dut.data_in[0].value = (value >> (7 - i)) & 1


async def master_receive_bits(dut, count, qio_mode=False, delay_cycle=False):
    dut.start.value = 1
    dut.qio_mode.value = qio_mode
    dut.dummy.value = 0
    dut.delay_cycle.value = delay_cycle
    dut.tx_size.value = 0
    dut.rx_size.value = 8

    await FallingEdge(dut.clk)
    dut.start.value = 0
    dut.rx_size.value = 0
    dut.delay_cycle.value = 0

    await RisingEdge(dut.rx_complete)
    return dut.rx_data.value.integer


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


@cocotb.test(timeout_time=100, timeout_unit="ns")
async def test_transmit(dut):
    dut.reset.value = 0
    dut.start.value = 0
    dut.qio_mode.value = 0
    dut.dummy.value = 0
    dut.delay_cycle.value = 0
    dut.tx_data.value = 0
    dut.tx_size.value = 0
    dut.rx_size.value = 0

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    read_task = cocotb.start_soon(slave_receive_bits(dut, 8))

    await Timer(1, "ns")

    await master_send_bits(dut, 0x3B, 8)
    received = await read_task

    dut._log.debug(f"received={received:#02x}")
    assert received == 0x3B

    await RisingEdge(dut.tx_complete)
    await Timer(1, "ns")


@cocotb.test(timeout_time=100, timeout_unit="ns")
async def test_receive(dut):
    dut.reset.value = 0
    dut.start.value = 0
    dut.qio_mode.value = 0
    dut.dummy.value = 0
    dut.delay_cycle.value = 0
    dut.tx_data.value = 0
    dut.tx_size.value = 0
    dut.rx_size.value = 0

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    send_task = cocotb.start_soon(slave_send_bits(dut, 0xC5, 8))

    await Timer(1, "ns")

    # Need to delay by a cycle because the first clock pulse will trigger the transfer, but it won't be available until
    # the next rising clock
    received = await master_receive_bits(dut, 8, delay_cycle=True)
    await send_task
    await Timer(1, "ns")

    dut._log.debug(f"received={received:#02x}")
    assert received == 0xC5
