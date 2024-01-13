
import random
import cocotb
import logging
import sys
sys.path.append("../../../../..")
import test_classes
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import RisingEdge, ClockCycles, FallingEdge

NUM_BITS    = int(cocotb.top.P_NUM_BITS)
CLK_FREQ    = int(cocotb.top.P_CLK_FREQ)
BAUD_RATE   = int(cocotb.top.P_BAUD_RATE)
NUM_STOP    = int(cocotb.top.P_NUM_STOP)
PARITY      = int(cocotb.top.P_PARITY)
NUM_WORDS   = 6
BIT_PRD     = int(1e9/BAUD_RATE)

CLKS_PER_BIT = int(CLK_FREQ*1000000/BAUD_RATE)
CLK_PRD_ns = int(1000/CLK_FREQ)

class TB():
    def __init__(self, dut):
        self.dut = dut
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.sb = Queue()

        self.uart_monitor = test_classes.UartMonitor(self.dut.clk, self.dut.uart_tx, BAUD_RATE, NUM_BITS, NUM_STOP, PARITY, self.sb)
        
        cocotb.start_soon(Clock(dut.clk, CLK_PRD_ns, units='ns').start())

        self.dut.data_in.value = 0
        self.dut.data_in_vld.value = 0

    async def write_word(self):
        data_int = random.randint(0, 2**NUM_BITS-1)

        await self.sb.put(data_int)

        if self.dut.data_in_rdy != 1:
            await RisingEdge(self.dut.data_in_rdy)

        self.dut.data_in_vld.value = 1
        self.dut.data_in.value = data_int
        await RisingEdge(self.dut.clk)
        self.dut.data_in_vld.value = 0
        await FallingEdge(self.dut.clk)


async def cycle_rst_n(rst_n, clk):
    rst_n.setimmediatevalue(0)
    await RisingEdge(clk)
    await RisingEdge(clk)
    rst_n.value = 1
    await RisingEdge(clk)
    await RisingEdge(clk)

 
@cocotb.test()
async def test_uart_transmitter(dut):
    """Test for uart mIDI interface"""

    tb = TB(dut)

    cocotb.start_soon(cycle_rst_n(tb.dut.rst_n, tb.dut.clk))

    await ClockCycles(dut.clk, 1000)


    for _ in range(NUM_WORDS):
        cocotb.start_soon(tb.write_word())
        rd_data = await tb.uart_monitor.get()
        sb_data = await tb.sb.get()
        tb.log.info(f'sent {sb_data}, got {rd_data}')
        assert (rd_data == sb_data)

    dut._log.info('Test done')
