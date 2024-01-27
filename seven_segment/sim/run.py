import os
import cocotb_test.simulator
import sys


##########################################
##           TEST SETUP                 ##
##########################################

root = os.path.abspath('.')
hdl_dir = os.path.join(root, 'hdl')
sim_dir = os.path.join(root, 'sim')

top = "seven_segment_display"
modules = ["test_seven_segment_display"]

def test(top, test):
    os.chdir(sim_dir)
    cocotb_test.simulator.run(
        verilog_sources=[
            os.path.join(hdl_dir,"seven_segment_display.sv"),
            os.path.join(hdl_dir,"double_dabble.sv"),
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

