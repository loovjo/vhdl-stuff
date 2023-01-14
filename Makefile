out = ./build

YOSYSFLAGS = -qQ -e '.*'
NEXTPNRFLAGS = --quiet --up5k --package sg48

upload-blink: $(out)/blink.bin
	sudo iceprog $(out)/blink.bin

upload-spin: $(out)/spin.bin
	sudo iceprog $(out)/spin.bin

upload-uart: $(out)/uart.bin
	sudo iceprog $(out)/uart.bin

build: $(out)/blink.bin

clean:
	rm -rf $(out)

$(out)/blink.json: blink.v
	mkdir -p $(out)/build

	yosys $(YOSYSFLAGS) -p "synth_ice40 -top blink -json $(out)/build/blink.json" blink.v
blink.json: $(out)/blink.json

$(out)/blink.bin: $(out)/blink.json leds.pcf
	mkdir -p $(out)/build

	nextpnr-ice40 $(NEXTPNRFLAGS) --pcf leds.pcf --json $(out)/build/blink.json --asc $(out)/build/blink.asc
	icepack $(out)/build/blink.asc $(out)/blink.bin
blink.bin: $(out)/blink.bin

$(out)/spin.json: spin.vhdl
	mkdir -p $(out)/build

	yosys $(YOSYSFLAGS) -m ghdl -p "ghdl spin.vhdl -e ; synth_ice40 -top leds -json $(out)/build/spin.json"
spin.json: $(out)/spin.json

$(out)/spin.bin: $(out)/spin.json leds.pcf
	mkdir -p $(out)/build

	nextpnr-ice40 $(NEXTPNRFLAGS) --pcf leds.pcf --json $(out)/build/spin.json --asc $(out)/build/spin.asc
	icepack $(out)/build/spin.asc $(out)/spin.bin
spin.bin: $(out)/spin.bin

$(out)/uart.json: uart.vhdl
	mkdir -p $(out)/build

	yosys $(YOSYSFLAGS) -m ghdl -p "ghdl uart.vhdl -e ; synth_ice40 -top uart -json $(out)/build/uart.json"
uart.json: $(out)/uart.json

$(out)/uart.bin: $(out)/uart.json leds.pcf
	mkdir -p $(out)/build

	nextpnr-ice40 $(NEXTPNRFLAGS) --pcf leds.pcf --json $(out)/build/uart.json --asc $(out)/build/uart.asc
	icepack $(out)/build/uart.asc $(out)/uart.bin
uart.bin: $(out)/uart.bin
