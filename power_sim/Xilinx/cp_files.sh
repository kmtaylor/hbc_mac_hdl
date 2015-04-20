xilinx_loc=$HOME/Xilinx/Projects/transceiver_power

cp $xilinx_loc/transmitter_tb.ncd ./
cp $xilinx_loc/transmitter_tb.pcf ./
cp $xilinx_loc/netgen/par/transmitter_tb_timesim.vhd ./transmitter_gate_tb.vhd
