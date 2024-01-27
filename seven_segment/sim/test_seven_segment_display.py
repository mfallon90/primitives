
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
        self.clk_freq_MHz = int(self.dut.CLK_FREQ.value)
        self.period_ns = int(1000/self.clk_freq_MHz)
        cocotb.start_soon(Clock(self.dut.clk, self.period_ns, units='ns').start())

        self.clk = self.dut.clk
        self.reset = self.dut.reset
        self.data_in = self.dut.data_in
        self.data_in_valid = self.dut.data_in_valid
        self.led_out = self.dut.led_out

        self.data_in_valid.value = 0

    async def cycle_reset(self, active_high=True):
        reset_active = 1 if active_high else 0
        reset_inactive = 0 if active_high else 1
        self.reset.setimmediatevalue(reset_active)
        await RisingEdge(self.clk)
        await RisingEdge(self.clk)
        self.reset.value = reset_inactive
        await RisingEdge(self.clk)
        await RisingEdge(self.clk)

    def secs_to_cycles(self, seconds):
        return self.clk_freq_MHz * seconds

    def decode_seven_segment(self):
        decoded_values = [0x03, 0x9F, 0x25, 0x0D, 0x99, 0x49, 0x41, 0x1F, 0x01, 0x09]
        if self.led_out in decoded_values:
            return decoded_values.index(self.led_out)
        return None

    async def drive_value(self, value):
        await RisingEdge(self.clk)
        self.data_in.value = value
        self.data_in_valid.value = 1
        await RisingEdge(self.clk)
        self.data_in_valid.value = 0



@cocotb.test()
async def test_seven_segment_display(dut):
    '''Test for seven segment display'''

    tb = TB(dut)

    cocotb.start_soon(tb.cycle_reset(active_high=True))
    await ClockCycles(tb.clk, 20)

    for _ in range(5):
        number = random.randint(0,9999)
        await tb.drive_value(number)
        await ClockCycles(tb.clk, tb.secs_to_cycles(4))
        # if number > 9:
        #     assert(tb.decode_seven_segment() == None)
        # else:
        #     assert(number == tb.decode_seven_segment())

    dut.log.info('Test done')

