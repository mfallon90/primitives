
import random
import cocotb
import logging
from cocotb.queue import Queue
from cocotb.clock import Clock
from cocotb.triggers import First, RisingEdge, ClockCycles, with_timeout, Timer, FallingEdge, Combine

class TB():
    def __init__(self, dut):
        self.dut = dut
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.sb = Queue()

        cocotb.start_soon(Clock(dut.clk, 10, units='ns').start())
        self.dut.wr_data.value = 0
        self.dut.wr_vld.value = 0
        self.dut.rd_rdy.value = 0


    # This method waits for a wr_vld and wr_rdy
    # handshake before writing a random word to
    # the FIFO and storing it in the scoreboard
    async def write_fifo(self):            
        data = random.randint(0,255)

        self.dut.wr_vld.value = 1
        self.dut.wr_data.value = data

        await FallingEdge(self.dut.clk)
        if (self.dut.wr_rdy != 1):
            await First(RisingEdge(self.dut.wr_rdy), Timer(10, 'us'))
            if (self.dut.wr_rdy != 1):
                return

        await RisingEdge(self.dut.clk)

        self.dut.wr_vld.value = 0
        self.dut.wr_data.value = 0
        await self.sb.put(data)

    # This method calls the write_fifo method
    # in order to fill the FIFO
    async def write_mult(self, num=1):
        for _ in range(num):
            await self.write_fifo()
            await ClockCycles(self.dut.clk, 1)

    # This method calls the write_fifo method
    # in order to fill the FIFO
    async def write_mult_delay(self, num=1, wait=15):
        for _ in range(num):
            delay = random.randint(0,wait)
            await self.write_fifo()
            await ClockCycles(self.dut.clk, delay)

    # This method calls the write_fifo method
    # in order to fill the FIFO
    async def fill_fifo(self, num=1):
        while self.dut.wr_rdy == 1:
            await self.write_fifo()

    async def read_fifo(self):

        self.dut.rd_rdy.value = 1

        await FallingEdge(self.dut.clk)

        if (self.dut.rd_vld != 1):
            await First(RisingEdge(self.dut.rd_vld), Timer(10, 'us'))
            if (self.dut.rd_vld != 1):
                 return 0

        rd_data = self.dut.rd_data
        await RisingEdge(self.dut.clk)
        self.dut.rd_rdy.value = 0

        sb_data = await with_timeout(self.sb.get(), 10, 'us')
        print(f'{int(rd_data)} = {sb_data}')
        assert rd_data == sb_data

    # This method repeatedly calls read_fifo
    async def read_mult(self, num=1):
        if (self.dut.rd_vld != 1):
            await with_timeout(RisingEdge(self.dut.rd_vld), 10, 'us')

        for _ in range(num):
            await self.read_fifo()

    # This method repeatedly calls read_fifo
    async def read_mult_delay(self, num=1, wait=15):
        if (self.dut.rd_vld != 1):
            await with_timeout(RisingEdge(self.dut.rd_vld), 10, 'us')

        for _ in range(num):
            delay = random.randint(0,wait)
            await self.read_fifo()
            await ClockCycles(self.dut.clk, delay)

    # This method repeatedly calls read_fifo until
    # the FIFO is empty
    async def empty_fifo(self):
        if (self.dut.rd_vld != 1):
            await with_timeout(RisingEdge(self.dut.rd_vld), 10, 'us')

        while self.dut.rd_vld == 1:
            await self.read_fifo()


async def cycle_rst_n(rst_n, clk):
    rst_n.setimmediatevalue(0)
    await RisingEdge(clk)
    await RisingEdge(clk)
    rst_n.value = 1
    await RisingEdge(clk)
    await RisingEdge(clk)

NUM_LOOPS   = 100

# Declare parameter values
FIFO_DEPTH = int(cocotb.top.P_DEPTH)
FIFO_WIDTH = int(cocotb.top.P_WIDTH)

async def test(num_loops):
    for _ in range(num_loops):
        print("help")
        await Timer(20, 'ns')


@cocotb.test()
async def test_fifo(dut):
    """Test for asynchronous fifo"""

    # Declare testbench and scoreboard
    tb = TB(dut)

    # Reset design
    cocotb.start_soon(cycle_rst_n(dut.rst_n, dut.clk))

    # Wait some arbitrary time
    await ClockCycles(dut.clk, 100)

    # write_task = cocotb.start_soon(tb.write_mult_delay(NUM_LOOPS))
    # read_task = cocotb.start_soon(tb.read_mult_delay(NUM_LOOPS))
    # done = Combine(write_task, read_task)
    # await First(done, Timer(50, 'us'))

    await tb.write_mult(50)

    await ClockCycles(dut.clk, 100)
    dut._log.info('Test done')

