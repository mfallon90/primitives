from os.path import abspath, join
from cocotb_test.simulator import run


##########################################
##           TEST SETUP                 ##
##########################################

hdl_dir = abspath('../hdl')
top = "rmii_rx"
modules = ["test_rmii_rx"]

def test(top, test):
    run(
        verilog_sources=[
            join(hdl_dir,"rmii_rx.sv")],
        toplevel=top,
        module=test
    )


##########################################
##              RUN TEST                ##
##########################################


if __name__ == "__main__":
    for module in modules:
        test(top, module)


