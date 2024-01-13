from os.path import abspath, join
from cocotb_test.simulator import run


##########################################
##           TEST SETUP                 ##
##########################################

hdl_dir = abspath('../hdl')
top = "axil_slave_if"
modules = ["test_axil_slave_if"]

def test(top, test):
    run(
        verilog_sources=[
            join(hdl_dir,"axil_slave_if.v")],
        toplevel=top,
        module=test
    )


##########################################
##              RUN TEST                ##
##########################################


if __name__ == "__main__":
    for module in modules:
        test(top, module)


