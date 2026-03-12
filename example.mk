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

.PHONY: all clean upload libs

all: libs $(TARGET).hex

libs:
	$(MAKE) -C $(ROOT) libs

$(OBJDIR):
	mkdir -p $(OBJDIR)

$(OBJDIR)/$(TARGET).o: $(TARGET).asm | $(OBJDIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(TARGET).bin: $(OBJDIR)/$(TARGET).o $(LIBS)
	$(LD) $(LDFLAGS) -o $@ $^

$(TARGET).hex: $(TARGET).bin
	python3 $(ROOT)/tools/bin2srec.py --load $$(python3 -c \
	  "import subprocess,re; \
	   out=subprocess.check_output(['grep','STARTADDRESS','$(ROOT)/sym1.cfg']).decode(); \
	   print(int(re.search(r'default\\s*=\\s*(\\$$[0-9A-Fa-f]+)',out).group(1).lstrip('$$'),16) if re.search(r'default\\s*=\\s*(\\$$[0-9A-Fa-f]+)',out) else 0x0500)") \
	  $< > $@
	@echo "Built: $@ (`wc -c < $<` bytes)"

clean:
	rm -rf $(OBJDIR) $(TARGET).bin $(TARGET).hex $(TARGET).map

upload: $(TARGET).hex
	python3 $(ROOT)/tools/sym1upload.py --port $(PORT) --baud $(BAUD) $<

flatten:
	hexdump -v -e '1/1 "%02x\n"' $(TARGET).bin > $(basename $(TARGET)).out
