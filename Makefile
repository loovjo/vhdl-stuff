CWD = $(shell pwd)
out = $(CWD)/build

YOSYSFLAGS = -qQ -e '.*'
NEXTPNRFLAGS = --quiet --up5k --package sg48

upload-uart: $(out)/uart.bin
	sudo iceprog $(out)/uart.bin

build: $(out)/blink.bin

clean:
	rm -rf $(out)

$(out)/uart.json: uart_common.vhdl uart_sender.vhdl uart_user.vhdl
	mkdir -p $(out)/build

	cd $(out)/build ; ghdl -a $(CWD)/uart_common.vhdl
	cd $(out)/build ; ghdl -a $(CWD)/uart_sender.vhdl
	cd $(out)/build ; ghdl -a $(CWD)/uart_user.vhdl

	cd $(out)/build ; yosys $(YOSYSFLAGS) -m ghdl -p "ghdl UART_User ; synth_ice40 -top UART_User -json $(out)/build/uart.json"
uart.json: $(out)/uart.json

$(out)/uart.bin: $(out)/uart.json leds.pcf
	mkdir -p $(out)/build

	nextpnr-ice40 $(NEXTPNRFLAGS) --pcf leds.pcf --json $(out)/build/uart.json --asc $(out)/build/uart.asc
	icepack $(out)/build/uart.asc $(out)/uart.bin
uart.bin: $(out)/uart.bin
