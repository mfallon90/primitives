from os.path import abspath, join
from cocotb_test.simulator import run


##########################################
##           TEST SETUP                 ##
##########################################

hdl_dir = abspath('../hdl')
top = "eth_rx_fsm"
modules = ["test_eth_rx_fsm"]

def test(top, test):
    run(
        verilog_sources=[
            join(hdl_dir,"eth_rx_fsm.sv")],
        toplevel=top,
        module=test
    )


##########################################
##              RUN TEST                ##
##########################################


if __name__ == "__main__":
    for module in modules:
        test(top, module)


