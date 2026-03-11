# =============================================================================
# example.mk  —  Shared Makefile fragment for SYM-1 example programs
# Include this from each example's Makefile:
#   TARGET = myprog
#   include ../../example.mk
# =============================================================================

ROOT    ?= ../..
AS      = ca65
LD      = ld65
ASFLAGS = -I $(ROOT)/include -t none
LDFLAGS = -C $(ROOT)/sym1.cfg -m $(TARGET).map

OBJDIR  = build
LIBDIR  = $(ROOT)/build

LIBS    = $(LIBDIR)/tui.o \
          $(LIBDIR)/string.o \
          $(LIBDIR)/math.o

PORT    ?= /dev/ttyUSB0
BAUD    ?= 9600

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
