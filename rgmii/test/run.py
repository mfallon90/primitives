from os.path import abspath, join
from cocotb_test.simulator import run


##########################################
##           TEST SETUP                 ##
##########################################

hdl_dir = abspath('../hdl')
top = "rgmii_rx"
modules = ["test_rgmii_rx"]

def test(top, test):
    run(
        verilog_sources=[
            join(hdl_dir,"rgmii_rx.sv")],
        toplevel=top,
        module=test
    )


##########################################
##              RUN TEST                ##
##########################################


if __name__ == "__main__":
    for module in modules:
        test(top, module)


