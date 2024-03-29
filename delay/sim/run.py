import os
import cocotb_test.simulator
import sys


##########################################
##           TEST SETUP                 ##
##########################################

root = os.path.abspath('.')
hdl_dir = os.path.join(root, 'hdl')
sim_dir = os.path.join(root, 'sim')

top = "delay"
modules = ["test_delay"]

def test(top, test):
    os.chdir(sim_dir)
    cocotb_test.simulator.run(
        verilog_sources=[
            os.path.join(hdl_dir,"delay.sv"),
        ],
        toplevel=top,
        module=test
    )


##########################################
##              RUN TEST                ##
##########################################


if __name__ == "__main__":
    for module in modules:
        test(top, module)

