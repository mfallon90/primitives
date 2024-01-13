from os.path import abspath, join
from cocotb_test.simulator import run


##########################################
##           TEST SETUP                 ##
##########################################

hdl_dir = abspath('../hdl')
top = "fifo"
modules = ["test_fifo"]

def test(top, test):
    run(
        verilog_sources=[
            join(hdl_dir,"fifo.v"),
            join(hdl_dir,"modn_counter.v"),
            join(hdl_dir,"fifo_bram.v")],
        toplevel=top,
        module=test
    )


##########################################
##              RUN TEST                ##
##########################################


if __name__ == "__main__":
    for module in modules:
        test(top, module)


