from os.path import abspath, join
from cocotb_test.simulator import run


##########################################
##           TEST SETUP                 ##
##########################################

hdl_dir = abspath('../hdl')
top = "async_fifo"
modules = ["test_async_fifo"]

def test(top, test):
    run(
        verilog_sources=[
            join(hdl_dir,"async_fifo.v"),
            join(hdl_dir,"bin_gry_ctr.v"),
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


