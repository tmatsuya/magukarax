SOURCES=tb_forwarder.v ../rtl/forwarder.v
#	$(wildcard ../../../cores/asfifo/rtl/*.v)

#all: cversim
all: phy_test.hex isim

gtk: all
	gtkwave test.vcd

isim: tb_forwarder
	./tb_forwarder

phy_test.hex: phy_ping.hex phy_telnet.hex
	./gmii2xgmii.awk < phy_ping.hex > tmp0 
	./gmii2xgmii.awk < phy_telnet.hex > tmp1 
	cat phy_idle.hex tmp0 phy_idle.hex tmp1 phy_idle.hex > phy_test.hex
	rm tmp0 tmp1

cversim: $(SOURCES)
	cver $(SOURCES)

clean:
	rm -f tb_forwarder verilog.log test.vcd phy_test.hex

tb_forwarder: $(SOURCES)
	iverilog -o tb_forwarder $(SOURCES)

.PHONY: clean isim cversim gtk
