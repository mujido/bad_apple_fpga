import cocotb

from cocotb.binary import LogicArray
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge


async def slave_receive_bytes(dut, count: int, word_size: int) -> list[int]:
    values = []
    for _ in range(count):
        value = 0

        for _ in range(word_size):
            await FallingEdge(dut.spi_clk_pad)
            value = (value << 1) | dut.data_out.value

        values.append(value)

    return values


async def slave_send_bytes(dut, values: list[int], word_size: int) -> None:
    dut.data_in.value = LogicArray("ZZZ0")

    for value in values:
        for i in range(0, word_size):
            await FallingEdge(dut.spi_clk_pad)
            dut.data_in[0].value = (value >> (word_size - i - 1)) & 1


async def slave_send_bytes_qio(dut, values: list[int], word_size: int) -> None:
    for value in values:
        for _ in range(0, word_size // 4):
            await FallingEdge(dut.spi_clk_pad)
            dut.data_in.value = (value >> (word_size - 4)) & 0xF
            value <<= 4


async def master_receive_bytes(
    dut, word_size: int, count: int, qio_mode: bool = False, delay_cycle: bool = False
) -> list[int]:
    values = list()

    for i in range(count):
        dut.start.value = 1
        dut.qio_mode.value = qio_mode
        dut.dummy.value = 0
        dut.delay_cycle.value = delay_cycle and i == 0
        dut.tx_size.value = 0
        dut.rx_size.value = word_size

        await FallingEdge(dut.clk)
        await RisingEdge(dut.clk)
        dut.start.value = 0
        dut.rx_size.value = 0
        dut.delay_cycle.value = 0
        dut.qio_mode = False

        await RisingEdge(dut.rx_complete)
        value = dut.rx_data.value
        dut._log.debug(f"{value=}")
        values.append(value.integer)

    return values


async def master_send_bytes(dut, values: list[int], word_size: int) -> None:
    for value in values:
        dut.start.value = 1
        dut.dummy.value = 0
        dut.qio_mode.value = 0
        dut.tx_data.value = value
        dut.tx_size.value = word_size
        dut.rx_size.value = 0

        await FallingEdge(dut.clk)
        await RisingEdge(dut.clk)
        dut.start.value = 0
        dut.tx_data.value = 0
        dut.tx_size.value = 0

        # for i in range(word_size - 1):
        #     await RisingEdge(dut.spi_clk_pad)
        #     assert dut.rx_complete.value == 1
        #     # assert dut.tx_complete.value == 0

        await RisingEdge(dut.tx_complete)
        # assert dut.rx_complete.value == 1
        # assert dut.tx_complete.value == 0


def init_qspi(dut) -> None:
    dut.reset.value = 0
    dut.start.value = 0
    dut.qio_mode.value = 0
    dut.dummy.value = 0
    dut.delay_cycle.value = 0
    dut.tx_data.value = 0
    dut.tx_size.value = 0
    dut.rx_size.value = 0


@cocotb.test(timeout_time=22, timeout_unit="ns")
async def test_transmit_byte(dut):
    init_qspi(dut)

    data = [0x3B]

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    read_task = cocotb.start_soon(slave_receive_bytes(dut, len(data), 8))

    await Timer(1, "ns")

    await master_send_bytes(dut, data, 8)
    received = await read_task

    await Timer(1, "ns")

    formatted = ", ".join([f"{x:#02}" for x in received])
    dut._log.debug(f"received=[{formatted}]")
    assert received == data


@cocotb.test(timeout_time=4100, timeout_unit="ns")
async def test_transmit_array(dut):
    init_qspi(dut)

    data = list(range(0, 256))

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    read_task = cocotb.start_soon(slave_receive_bytes(dut, len(data), 8))

    await Timer(1, "ns")

    await master_send_bytes(dut, data, 8)
    received = await read_task

    await Timer(1, "ns")

    formatted = ", ".join([f"{x:#02}" for x in received])
    dut._log.debug(f"received=[{formatted}]")
    assert received == data


@cocotb.test(timeout_time=22, timeout_unit="ns")
async def test_receive_byte(dut):
    init_qspi(dut)

    data = [0xC5]

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    send_task = cocotb.start_soon(slave_send_bytes(dut, data, 8))

    await Timer(1, "ns")

    # Need to delay by a cycle because the first clock pulse will trigger the transfer, but it won't be available until
    # the next rising clock
    received = await master_receive_bytes(dut, 8, 1, delay_cycle=True)
    await send_task

    await FallingEdge(dut.rx_complete)
    await Timer(1, "ns")

    dut._log.debug(f"received={received}")
    assert received == data


@cocotb.test(timeout_time=4100, timeout_unit="ns")
async def test_receive_array(dut):
    init_qspi(dut)

    data = list(range(0, 256))

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    send_task = cocotb.start_soon(slave_send_bytes(dut, data, 8))

    await Timer(1, "ns")

    # Need to delay by a cycle because the first clock pulse will trigger the transfer, but it won't be available until
    # the next rising clock
    received = await master_receive_bytes(dut, 8, len(data), delay_cycle=True)
    await send_task
    await Timer(1, "ns")

    dut._log.debug(f"received={received}")
    assert received == data


@cocotb.test(timeout_time=34, timeout_unit="ns")
async def test_cmd_receive_byte(dut):
    init_qspi(dut)

    cmd = [0xDC]
    data = [0x3B]

    await Timer(1, "ns")

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    read_cmd_task = cocotb.start_soon(slave_receive_bytes(dut, len(cmd), 8))

    async def response_func():
        await RisingEdge(dut.tx_complete)
        return await cocotb.start_soon(slave_send_bytes(dut, data, 8))

    send_data_task = cocotb.start_soon(response_func())

    await master_send_bytes(dut, cmd, 8)
    received_cmd = await read_cmd_task
    dut._log.debug(f"received_cmd={received_cmd[0]:#02x}")

    received_data = await master_receive_bytes(dut, 8, len(data))
    await send_data_task

    await Timer(1, "ns")

    dut._log.debug(f"received_data={received_data[0]:#02x}")
    assert received_cmd == cmd
    assert received_data == data


@cocotb.test(timeout_time=5000, timeout_unit="ns")
async def test_cmd_receive_array(dut):
    init_qspi(dut)

    cmd = [0x13]
    data = list(range(256))

    await Timer(1, "ns")

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    read_cmd_task = cocotb.start_soon(slave_receive_bytes(dut, len(cmd), 8))

    async def response_func():
        await RisingEdge(dut.tx_complete)
        return await cocotb.start_soon(slave_send_bytes(dut, data, 8))

    send_data_task = cocotb.start_soon(response_func())

    await master_send_bytes(dut, cmd, 8)
    received_cmd = await read_cmd_task
    dut._log.debug(f"received_cmd={received_cmd[0]:#02x}")

    received_data = await master_receive_bytes(dut, 8, len(data))
    await send_data_task

    await Timer(1, "ns")

    dut._log.debug(f"received_data={received_data[0]:#02x}")
    assert received_cmd == cmd
    assert received_data == data


@cocotb.test(timeout_time=34, timeout_unit="ns")
async def test_cmd_receive_byte_qio(dut):
    init_qspi(dut)

    cmd = [0xDC]
    data = [0x3B]

    await Timer(1, "ns")

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    read_cmd_task = cocotb.start_soon(slave_receive_bytes(dut, len(cmd), 8))

    async def response_func():
        await RisingEdge(dut.tx_complete)
        return await cocotb.start_soon(slave_send_bytes_qio(dut, data, 8))

    send_data_task = cocotb.start_soon(response_func())

    await master_send_bytes(dut, cmd, 8)
    received_cmd = await read_cmd_task
    dut._log.debug(f"received_cmd={received_cmd[0]:#02x}")

    received_data = await master_receive_bytes(dut, 8, len(data), qio_mode=True)
    await send_data_task

    await Timer(1, "ns")

    dut._log.debug(f"received_data={received_data[0]:#02x}")
    assert received_cmd == cmd
    assert received_data == data


@cocotb.test(timeout_time=1042, timeout_unit="ns")
async def test_cmd_receive_array_qio(dut):
    init_qspi(dut)

    cmd = [0xDC]
    data = list(range(256))

    await Timer(1, "ns")

    cocotb.start_soon(Clock(dut.clk, 1, units="ns").start())
    read_cmd_task = cocotb.start_soon(slave_receive_bytes(dut, len(cmd), 8))

    async def response_func():
        await RisingEdge(dut.tx_complete)
        return await cocotb.start_soon(slave_send_bytes_qio(dut, data, 8))

    send_data_task = cocotb.start_soon(response_func())

    await master_send_bytes(dut, cmd, 8)
    received_cmd = await read_cmd_task
    dut._log.debug(f"received_cmd={received_cmd[0]:#02x}")

    received_data = await master_receive_bytes(dut, 8, len(data), qio_mode=True)
    await send_data_task

    await Timer(1, "ns")

    dut._log.debug(f"received_data={received_data[0]:#02x}")
    assert received_cmd == cmd
    assert received_data == data
