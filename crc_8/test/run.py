from os.path import abspath, join
from cocotb_test.simulator import run


##########################################
##           TEST SETUP                 ##
##########################################

hdl_dir = abspath('../hdl')
top = "delay"
modules = ["test_delay"]

def test(top, test):
    run(
        verilog_sources=[
            join(hdl_dir,"delay.sv")],
        toplevel=top,
        module=test
    )


##########################################
##              RUN TEST                ##
##########################################


if __name__ == "__main__":
    for module in modules:
        test(top, module)


