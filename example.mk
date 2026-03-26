# =============================================================================
# example.mk  —  Shared Makefile fragment for SYM-1 example programs
# Include this from each example's Makefile:
#   TARGET = myprog
#   include ../../example.mk
#
# Remember to set CC65_HOME in your .bashrc file.
#   example:  export CC65_HOME="~/sym1/cc65"
# =============================================================================

#CC65_HOME ?= ~/sym1/cc65

AS = $(CC65_HOME)/bin/ca65
CC = $(CC65_HOME)/bin/cc65
CL = $(CC65_HOME)/bin/cl65
LD = $(CC65_HOME)/bin/ld65
DA = $(CC65_HOME)/bin/da65

ROOT ?= ../..

ASFLAGS = -I $(ROOT)/include -t sym1
LDFLAGS = -C $(ROOT)/sym1.cfg -m $(TARGET).map

OBJDIR  = build
LIBDIR  = $(ROOT)/build

LIBS    = $(LIBDIR)/tui.o \
          $(LIBDIR)/string.o \
          $(LIBDIR)/math.o

PORT    ?= /dev/ttyUSB0
BAUD    ?= 4800
LOAD    ?= 0500

DELAYS  = --byte-delay=1 --char-delay=5 --newline-delay=25

.PHONY: all clean libs upload 

all: libs $(TARGET).bin flatten

libs:
	$(MAKE) -C $(ROOT) libs

$(OBJDIR):
	mkdir -p $(OBJDIR)

$(OBJDIR)/$(TARGET).o: $(TARGET).asm | $(OBJDIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(TARGET).bin: $(OBJDIR)/$(TARGET).o $(LIBS)
	$(LD) $(LDFLAGS) -o $@ $^
	@echo "Built: $@ (`wc -c < $<` bytes)"

clean:
	rm -rf $(OBJDIR) $(TARGET).bin $(TARGET).hex $(TARGET).map $(TARGET).out

# Upload via Supermonitor V1.1 M command (raw binary, no S-records)
# Usage:  make upload PORT=/dev/ttyUSB0 LOAD=0500
upload: $(TARGET).bin
	python3 $(ROOT)/tools/sym1upload.py \
	  --port $(PORT) --baud $(BAUD) --load $(LOAD) $(DELAYS) $<
	@echo python3 $(ROOT)/tools/sym1upload.py \
	  --port $(PORT) --baud $(BAUD) --load $(LOAD) $(DELAYS) $<

# Upload and immediately execute
run: $(TARGET).bin
	python3 $(ROOT)/tools/sym1upload.py \
	  --port $(PORT) --baud $(BAUD) --load $(LOAD) $(DELAYS) --exec $<

flatten:
	hexdump -v -e '1/1 "%02x\n"' $(TARGET).bin > $(basename $(TARGET)).out
