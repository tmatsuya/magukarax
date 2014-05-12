SOURCES=$(wildcard *.v) \
	$(wildcard ../rtl/measure.v) \
	$(wildcard ../../crc32/rtl/*.v) \
	$(wildcard ../../sfifo/rtl/*.v) \
	$(wildcard ../../xgmii2fifo72/rtl/*.v)

#all: cversim
all: isim

gtk: all
	gtkwave test.vcd

wave: all
	gtkwave wave_files/send_phy1.gtkw

isim: tb_system
	./tb_system

lint: $(SOURCES) lint.vh
	verilator --lint-only --top-module ethpipe_mid lint.vh $(SOURCES)

lint-all: $(SOURCES) lint.vh
	verilator --lint-only -Wall --top-module ethpipe_mid lint.vh $(SOURCES)

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_system verilog.log test.vcd

tb_system: $(SOURCES)
	iverilog -o tb_system $(SOURCES)

.PHONY: clean isim cversim gtk
