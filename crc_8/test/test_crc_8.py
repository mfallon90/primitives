
import random
import cocotb
import logging
import sys
sys.path.append("../../../..")
import test_classes
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import Timer, RisingEdge, ClockCycles, FallingEdge

DEST    = b'\x01\x00\x5E\x28\x64\x01'
SRC     = b'\x2C\xFA\xA2\xA7\x4F\x81'
TYPE    = b'\x08\x00'
DATA1   = b'\x46\xC0\x00\x20\xC6\xC9\x00\x00'
DATA2   = b'\x01\x02\xF4\xE6\x82\xBF\xA0\xFE'
DATA3   = b'\xE0\xA8\x64\x01\x94\x04\x00\x00'
DATA4   = b'\x11\x0A\xAA\x4B\xE0\xA8\x64\x01'
DATA5   = b'\x00\x00\x00\x00\x00\x00\x00\x00'
DATA6   = b'\x00\x00\x00\x00\x00\x00'
CRC     = b'\xD0\x1D\x41\x1B'

PACKET = DEST+SRC+TYPE+DATA1+DATA2+DATA3+DATA4+DATA5+DATA6+CRC

print(type(PACKET))
print(PACKET)

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
        self.sb = Queue()

        self.dut.data_in.value = 0
        self.dut.data_in_vld.value = 0
        self.dut.byte_in_vld.value = 0

        cocotb.start_soon(Clock(self.dut.clk, 10, units='ns').start())

    async def send_data(self, data_in):

        for byte in data_in:
            self.dut.data_in_vld.value = 1
            self.dut.data_in.value = byte
            await FallingEdge(self.dut.byte_in_vld)

            self.dut.data_in_vld.value = 0
            self.dut.data_in.value = 0

    async def toggle_byte_vld(self):
        while(True):
            await RisingEdge(self.dut.clk)
            self.dut.byte_in_vld.value = 1
            await RisingEdge(self.dut.clk)
            self.dut.byte_in_vld.value = 0


async def cycle_rst_n(rst_n, clk):
    rst_n.setimmediatevalue(0)
    await RisingEdge(clk)
    await RisingEdge(clk)
    rst_n.value = 1
    await RisingEdge(clk)
    await RisingEdge(clk)

 
@cocotb.test()
async def test_rmii_rx(dut):
    '''Test for crc 8'''

    tb = TB(dut)

    cocotb.start_soon(cycle_rst_n(tb.dut.rst_n, tb.dut.clk))

    cocotb.start_soon(tb.toggle_byte_vld())

    await ClockCycles(tb.dut.clk, 100)

    await FallingEdge(tb.dut.byte_in_vld)
    await cocotb.start_soon(tb.send_data(PACKET))

    await ClockCycles(tb.dut.clk, 100)
    dut._log.info('Test done')

