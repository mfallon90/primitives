
import random
import cocotb
import logging
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles


class TB():
    def __init__(self, dut):
        '''
        This function initalizes the testbench, starts the clock
        and sets all input values to their default state

        :param self: Class instance
        :param dut: Top level HDL file
        '''
        self.dut = dut
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)
        self.dut.data_in.value = 0
        self.width = int(self.dut.WIDTH)

        cocotb.start_soon(Clock(self.dut.clk, 10, units='ns').start())

@cocotb.test()
async def test_delay(dut):
    '''Test for delay'''

    tb = TB(dut)

    await ClockCycles(tb.dut.clk, 20)
    num_bytes = 20

    for _ in range(num_bytes):
        await RisingEdge(dut.clk)
        dut.data_in.value = random.randint(0, 2**tb.width-1)

    await ClockCycles(tb.dut.clk, 20)
    dut.log.info('Test done')

