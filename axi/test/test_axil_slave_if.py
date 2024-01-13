
import random
import cocotb
import logging
from cocotbext.axi import AxiLiteBus, AxiLiteMaster
from cocotb.queue import Queue
from cocotb.clock import Clock
from cocotb.triggers import First, RisingEdge, ClockCycles, Timer, FallingEdge, Combine

class TB():
    def __init__(self, dut, prd):
        self.dut = dut
        self.log = logging.getLogger("cocotb.tb")
        self.log.setLevel(logging.DEBUG)

        self.rw_sb = []
        self.ro_sb = []

        for _ in range(P_NUM_RW_REG):
            self.rw_sb.append(Queue())

        for _ in range(P_NUM_RO_REG):
            self.ro_sb.append(Queue())

        self.axim = AxiLiteMaster(AxiLiteBus.from_prefix(dut, "s_axi"), dut.s_axi_aclk, 
                                    dut.s_axi_aresetn, reset_active_level=False)
        
        self.ro_reg = [self.dut.reg_2_data, self.dut.reg_3_data]
        
        cocotb.start_soon(Clock(dut.s_axi_aclk, prd, units='ns').start())

        # set all signals to zero
        self.dut.s_axi_awaddr.value = 0
        self.dut.s_axi_awprot.value = 0
        self.dut.s_axi_awvalid.value = 0
        self.dut.s_axi_wdata.value = 0
        self.dut.s_axi_wstrb.value = 0
        self.dut.s_axi_wvalid.value = 0
        self.dut.s_axi_bready.value = 0
        self.dut.s_axi_araddr.value = 0
        self.dut.s_axi_arprot.value = 0
        self.dut.s_axi_arvalid.value = 0
        self.dut.s_axi_rready.value = 0
        for reg in self.ro_reg:
            reg.value = 0

    # Method to write to registers and scoreboard via axi
    async def axi_write(self, addr, data):
        await self.rw_sb[int(addr/NUM_BYTES)].put(data)
        await self.axim.write(addr,data)

    # Method to read from registers via axi, pop from scoreboard, and compare
    async def axi_read(self, addr):
        rd_data = await self.axim.read(addr, NUM_BYTES)
        sb_data = await self.rw_sb[int(addr/NUM_BYTES)].get()
        assert rd_data.data == sb_data

    # Method to write to registers and scoreboard via pl
    async def pl_write(self, addr, data):
        await self.ro_sb[int(addr/NUM_BYTES)-P_NUM_RW_REG].put(data)
        await RisingEdge(self.dut.s_axi_aclk)
        self.ro_reg[int(addr/NUM_BYTES)-P_NUM_RW_REG].value = data
        await RisingEdge(self.dut.s_axi_aclk)

    # Method to read from registers via pl, pop from scoreboard, and compare
    async def pl_read(self, addr):
        await FallingEdge(self.dut.s_axi_aclk)
        rd_data = self.ro_reg[int(addr/NUM_BYTES)-P_NUM_RW_REG].value
        sb_data = await self.ro_sb[int(addr/NUM_BYTES)-P_NUM_RW_REG].get()
        assert rd_data == sb_data

    # Method to continuously read and write from AXI registers
    async def axi_rw(self, num_loops):
        for _ in range(num_loops):
            addr = random.randint(0, P_NUM_RW_REG-1)*NUM_BYTES
            data = (random.randint(0, 2**P_DATA_WIDTH-1)).to_bytes(NUM_BYTES, byteorder='big')
            await self.axi_write(addr,data)
            await self.axi_read(addr)
            await ClockCycles(self.dut.s_axi_aclk, random.randint(5,20))
    
    # Method to continuously read and write from pl registers
    async def pl_rw(self, num_loops):
        for _ in range(num_loops):
            addr = random.randint(P_NUM_RW_REG, NUM_REG-1)*NUM_BYTES
            data = random.randint(0, 2**P_DATA_WIDTH-1)
            await self.pl_write(addr,data)
            await self.pl_read(addr)
            await ClockCycles(self.dut.s_axi_aclk, random.randint(5,20))

async def cycle_rst_n(rst_n, clk):
    rst_n.setimmediatevalue(0)
    await RisingEdge(clk)
    await RisingEdge(clk)
    rst_n.value = 1
    await RisingEdge(clk)
    await RisingEdge(clk)

PRD         = 10
NUM_LOOPS   = 100

# Declare parameter values
P_DATA_WIDTH = int(cocotb.top.P_DATA_WIDTH)
P_NUM_RW_REG = int(cocotb.top.P_NUM_RW_REG)
P_NUM_RO_REG = int(cocotb.top.P_NUM_RO_REG)
P_ADDR_WIDTH = int(cocotb.top.P_ADDR_WIDTH)
NUM_REG = P_NUM_RW_REG + P_NUM_RO_REG
NUM_BYTES = int(P_DATA_WIDTH/8)

async def test(num_loops):
    for _ in range(num_loops):
        print("help")
        await Timer(20, 'ns')


@cocotb.test()
async def test_async_fifo(dut):
    """Test for asynchronous fifo"""

    # Declare testbench and scoreboard
    tb = TB(dut, PRD)

    # Reset design
    cocotb.start_soon(cycle_rst_n(dut.s_axi_aresetn, dut.s_axi_aclk))

    # Wait some arbitrary time
    await ClockCycles(dut.s_axi_aclk, 100)

    axi_rw_task = cocotb.start_soon(tb.axi_rw(NUM_LOOPS))
    pl_rw_task = cocotb.start_soon(tb.pl_rw(NUM_LOOPS))

    done = Combine(axi_rw_task, pl_rw_task)
    await First(done, Timer(500, 'us'))

    # Wait some arbitrary time
    await ClockCycles(dut.s_axi_aclk, 100)

    dut._log.info('Test done')

