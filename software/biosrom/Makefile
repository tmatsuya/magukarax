ROM_BIN = ./BIOSROM.ROM
MEM_FILE = biosrom.mem

biosrom.mem: $(ROM_BIN)
	hexdump -v -e '"" 1/4 "%08X\n"' < $(ROM_BIN) > $(MEM_FILE)
#	hexdump -v -e '"" 1/2 "%04X\n"' < $(ROM_BIN) > $(MEM_FILE)
