USB_TB_OBJS += \
	usb_fifo_interface.o \
	usb_fifo_interface_tb.o

USB_SYNTH_FLAGS += \
	--stop-time=1000ns

# All Target
all: usb_fifo_interface_tb

# Tool invocations
usb_fifo_interface_tb:  $(USB_TB_OBJS)
	ghdl -e "$@"
	./"$@" $(USB_SYNTH_FLAGS) --wave="$@".ghw

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
