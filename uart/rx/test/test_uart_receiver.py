
import random
import cocotb
import logging
import sys
sys.path.append("../../../../..")
import test_classes
from cocotb.clock import Clock
from cocotb.queue import Queue
from cocotb.triggers import Timer, RisingEdge, ClockCycles, First, Combine


NUM_BITS    = int(cocotb.top.P_NUM_BITS)
CLK_FREQ    = int(cocotb.top.P_CLK_FREQ)
BAUD_RATE   = int(cocotb.top.P_BAUD_RATE)
NUM_STOP    = int(cocotb.top.P_NUM_STOP)
PARITY      = int(cocotb.top.P_PARITY)
NUM_WORDS   = 20

CLKS_PER_BIT = int(CLK_FREQ*1000000/BAUD_RATE)
CLK_PRD_ns = int(1000/CLK_FREQ)

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
        self.dut.uart_word_rdy.value = 1
        
        cocotb.start_soon(Clock(dut.clk, CLK_PRD_ns, units='ns').start())

        self.uart_driver = test_classes.UartDriver(self.dut.clk, self.dut.uart_rx, BAUD_RATE, NUM_BITS, NUM_STOP, PARITY, self.sb)

    async def uart_check(self):
        '''
        Method to check data against scoreboard
        '''
        await RisingEdge(self.dut.uart_word_vld)
        uart_word = self.dut.uart_word
        sb_word = await self.sb.get()
        self.log.info(f'Sent {int(sb_word)}, Received {int(uart_word)}')
        assert (uart_word == sb_word)


async def cycle_rst_n(rst_n, clk):
    rst_n.setimmediatevalue(0)
    await RisingEdge(clk)
    await RisingEdge(clk)
    rst_n.value = 1
    await RisingEdge(clk)
    await RisingEdge(clk)



 
@cocotb.test()
async def test_uart_receiver(dut):
    '''Test for UART receiver'''

    tb = TB(dut)

    cocotb.start_soon(cycle_rst_n(tb.dut.rst_n, tb.dut.clk))

    await ClockCycles(dut.clk, 1000)

    for _ in range(NUM_WORDS):
        send_op = cocotb.start_soon(tb.uart_driver.send())
        check_op = cocotb.start_soon(tb.uart_check())
        done = Combine(send_op, check_op)
        await First(done, Timer(500, 'us'))


    await ClockCycles(dut.clk, 10000)
    dut._log.info('Test done')

