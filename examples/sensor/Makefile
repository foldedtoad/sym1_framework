# =============================================================================
# Makefile
#
# Remember to set CC65_HOME in your .bashrc file.
#   example:  export CC65_HOME="~/sym1/cc65"
# =============================================================================

AS = $(CC65_HOME)/bin/ca65
CC = $(CC65_HOME)/bin/cc65
CL = $(CC65_HOME)/bin/cl65
LD = $(CC65_HOME)/bin/ld65
DA = $(CC65_HOME)/bin/da65

TARGET = sensor

ROOT  ?= ../..

ASFLAGS = -I $(ROOT)/include -t sym1
LDFLAGS = -C $(ROOT)/$(CFG) -m $(OBJDIR)/$(TARGET).map

CFG     = sym1-32k.cfg

OBJDIR  = build
LIBDIR  = $(ROOT)/build

FRAMEWORK = $(LIBDIR)/tui.o \
            $(LIBDIR)/string.o \
            $(LIBDIR)/math.o \
            $(LIBDIR)/i2c.o \
            $(LIBDIR)/irq.o

C_LIBS  = --lib $(CC65_HOME)/lib/sym1.lib

PORT    ?= /dev/ttyUSB0
BAUD    ?= 4800
LOAD    ?= 0500

.PHONY: all clean libs upload 

all: dirs libs $(OBJDIR)/$(TARGET).bin flatten

dirs:
	mkdir -p $(OBJDIR)

# Build the various library modules
libs:
	$(MAKE) -C $(ROOT) libs

$(OBJDIR):
	mkdir -p $(OBJDIR)

$(OBJDIR)/%.o: %.c
	$(CC) -t sym1 -O -o $(OBJDIR)/$(basename $<).asm $<
	$(AS) --cpu 6502 -l $(OBJDIR)/$(basename $<).lst $(OBJDIR)/$(basename $<).asm -o $@ 

$(OBJDIR)/%.o: %.asm	
	$(AS) --cpu 6502 -l $(basename $<).lst $< -o $@ 

$(OBJDIR)/$(TARGET).bin: $(OBJDIR)/$(TARGET).o $(FRAMEWORK)
	$(LD) $(LDFLAGS) -o $@ $^ $(C_LIBS)

clean:
	rm -rf $(OBJDIR)

# Upload via Supermonitor V1.1 M command (raw binary, no S-records)
# Usage:  make upload PORT=/dev/ttyUSB0 LOAD=0500
upload: $(OBJDIR)/$(TARGET).bin
	python3 $(ROOT)/tools/sym1upload.py \
	  --port $(PORT) --baud $(BAUD) --load $(LOAD) $<

# Start a terminal session with the SYM-1
run: $(OBJDIR)/$(TARGET).bin
	putty -serial $(PORT) -sercfg $(BAUD),8,n,1,N

flatten:
	hexdump -v -e '1/1 "%02x\n"' $(TARGET).bin > $(OBJDIR) $(basename $(TARGET)).out

