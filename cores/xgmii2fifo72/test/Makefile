SOURCES=tb_xgmii2fifo72.v $(wildcard ../rtl/*.v)

#all: cversim
all: isim

gtk: all
	gtkwave test.vcd

isim: tb_xgmii2fifo72
	./tb_xgmii2fifo72

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_xgmii2fifo72 verilog.log test.vcd

tb_xgmii2fifo72: $(SOURCES)
	iverilog -o tb_xgmii2fifo72 $(SOURCES)

.PHONY: clean isim cversim gtk
