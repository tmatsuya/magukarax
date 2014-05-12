SOURCES=tb_lookupmac.v $(wildcard ../rtl/*.v)

#all: cversim
all: isim

gtk: all
	gtkwave test.vcd

isim: tb_lookupmac
	./tb_lookupmac

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_lookupmac verilog.log test.vcd

tb_lookupmac: $(SOURCES)
	iverilog -o tb_lookupmac $(SOURCES)

.PHONY: clean isim cversim gtk
