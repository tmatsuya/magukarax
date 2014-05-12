SOURCES=tb_fifo72toxgmii.v $(wildcard ../rtl/*.v)

#all: cversim
all: isim

gtk: all
	gtkwave test.vcd

isim: tb_fifo72toxgmii
	./tb_fifo72toxgmii

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_fifo72toxgmii verilog.log test.vcd

tb_fifo72toxgmii: $(SOURCES)
	iverilog -o tb_fifo72toxgmii $(SOURCES)

.PHONY: clean isim cversim gtk
