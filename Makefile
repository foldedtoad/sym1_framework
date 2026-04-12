# =============================================================================
# Makefile  —  SYM-1 6502 Assembly Framework Top-Level Build
# =============================================================================
# Requires: ca65, ld65 (cc65 toolchain), Python 3 + pyserial
#
# Usage:
#   make libs          Build all library objects
#   make               Same as make libs
#   make clean         Remove all build artifacts
#   make PORT=/dev/ttyUSB0 upload TARGET=examples/hello/hello.hex
#
# Remember to set CC65_HOME in your .bashrc file.
#   example:  export CC65_HOME="~/sym1/cc65"
# =============================================================================

AS = $(CC65_HOME)/bin/ca65
CC = $(CC65_HOME)/bin/cc65
CL = $(CC65_HOME)/bin/cl65
LD = $(CC65_HOME)/bin/ld65
DA = $(CC65_HOME)/bin/da65

ASFLAGS = -t none -I include
LDFLAGS = -C sym1.cfg

LIBDIR  = lib
OBJDIR  = build

LIBS    = $(OBJDIR)/tui.o \
          $(OBJDIR)/string.o \
          $(OBJDIR)/math.o \
          $(OBJDIR)/i2c.o \
          $(OBJDIR)/irq.o

PORT    ?= /dev/ttyUSB0
BAUD    ?= 4800

.PHONY: all libs clean upload dirs examples

all: dirs libs

dirs:
	mkdir -p $(OBJDIR)

libs: dirs $(LIBS)

$(OBJDIR)/tui.o: $(LIBDIR)/tui.asm include/sym1.inc include/macros.inc include/tui.inc
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJDIR)/string.o: $(LIBDIR)/string.asm include/sym1.inc include/macros.inc
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJDIR)/math.o: $(LIBDIR)/math.asm include/sym1.inc include/macros.inc
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJDIR)/i2c.o: $(LIBDIR)/i2c.asm include/sym1.inc include/macros.inc
	$(AS) $(ASFLAGS) -o $@ $<

$(OBJDIR)/irq.o: $(LIBDIR)/irq.asm include/sym1.inc include/macros.inc
	$(AS) $(ASFLAGS) -o $@ $<	

# Build all examples
examples:
	$(MAKE) -C examples/hello
	$(MAKE) -C examples/tui_demo
	$(MAKE) -C examples/sensor

clean:
	rm -rf $(OBJDIR)
	$(MAKE) -C examples/hello    clean 2>/dev/null || true
	$(MAKE) -C examples/tui_demo clean 2>/dev/null || true
	$(MAKE) -C examples/sensor   clean 2>/dev/null || true

# Upload a .hex file to the SYM-1
# Usage: make upload TARGET=path/to/file.hex
upload:
	python3 tools/sym1upload.py --port $(PORT) --baud $(BAUD) $(TARGET)

# Show memory usage for an object
size:
	@size $(TARGET) 2>/dev/null || objdump -h $(TARGET) 2>/dev/null || \
	 echo "Install binutils for size info"
