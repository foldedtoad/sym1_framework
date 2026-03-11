#!/usr/bin/env python3
"""
bin2srec.py  —  Convert a raw binary file to Motorola S-record format.

Usage:
  python3 bin2srec.py --load <hex_addr> <input.bin> > output.hex

Options:
  --load ADDR    Load (start) address in hex  (default: 0500)
  --exec ADDR    Execution address for S9 record  (default: same as --load)
  input          Input binary file

Output goes to stdout (redirect to .hex file).
"""

import sys
import os
sys.path.insert(0, os.path.dirname(__file__))
from sym1upload import binary_to_srec, bin2srec_main

if __name__ == '__main__':
    bin2srec_main()
