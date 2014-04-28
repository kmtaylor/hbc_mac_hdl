SCRAMBLER_TB_OBJS += \
	scrambler.o \
	scrambler_tb.o

SCRAMBLER_SIM_FLAGS += \
	--stop-time=1000ns

USB_TB_OBJS += \
	usb_fifo_interface.o \
	usb_fifo_interface_tb.o

USB_SIM_FLAGS += \
	--stop-time=1000ns

all: usb_fifo_interface_tb scrambler_tb

# Test Benches (Elaboration)
scrambler_tb:  $(SCRAMBLER_TB_OBJS)
	ghdl -e "$@"
	./"$@" $(SCRAMBLER_SIM_FLAGS) --wave="$@".ghw

usb_fifo_interface_tb:  $(USB_TB_OBJS)
	ghdl -e "$@"
	./"$@" $(USB_SIM_FLAGS) --wave="$@".ghw

# Analysis
%.o: ../%.vhd
	ghdl -a "$<"

%_tb.o: ../testbench/%_tb.vhd
	ghdl -a "$<"

# Other Targets
clean:
	ghdl --remove

cleanall:
	rm *.ghw

.PHONY: clean cleanall all
