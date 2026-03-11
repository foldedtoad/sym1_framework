#!/usr/bin/env python3
"""
sym1upload.py  —  Upload a binary or S-record file to the SYM-1 via serial.

The SYM-1 Supermonitor V1.1 accepts Motorola S-record (SREC) format through
its 'L' (Load) command.  This script:
  1. Opens the serial port
  2. Sends a CR to wake the monitor
  3. Issues the 'L' command
  4. Streams S19 records line by line (with pacing to avoid overrun)
  5. Optionally sends 'G <addr>' to execute the loaded program

Usage:
  python3 sym1upload.py [options] <file.hex | file.bin>

Options:
  --port    PORT    Serial port  (default: /dev/ttyUSB0)
  --baud    BAUD    Baud rate    (default: 9600)
  --exec            Auto-execute after load (sends G command)
  --addr    ADDR    Execution start address in hex (default: 0500)
  --delay   MS      Inter-record delay ms (default: 50)
  --input   FILE    Input file (.hex = S-records, .bin = raw binary)
  --load    ADDR    Load address for raw binary (hex, default: 0500)
  --verbose         Show monitor responses
"""

import argparse
import sys
import time
import struct
import os

try:
    import serial
except ImportError:
    print("ERROR: pyserial not installed.  Run:  pip install pyserial")
    sys.exit(1)


# ---------------------------------------------------------------------------
# S-record generation from raw binary
# ---------------------------------------------------------------------------

def checksum(data: bytes) -> int:
    """Motorola S-record checksum: one's complement of sum of all bytes."""
    return (~sum(data)) & 0xFF


def make_s1_record(address: int, data: bytes) -> str:
    """Create an S1 record (16-bit address) for up to 32 data bytes."""
    # byte count = len(data) + 2 (addr bytes) + 1 (checksum)
    byte_count = len(data) + 3
    payload = bytes([byte_count, (address >> 8) & 0xFF, address & 0xFF]) + data
    cs = checksum(payload)
    return "S1" + payload.hex().upper() + f"{cs:02X}"


def make_s9_record(start_address: int) -> str:
    """Create an S9 record (end of file, with execution address)."""
    byte_count = 3  # 2 addr + 1 checksum
    payload = bytes([byte_count, (start_address >> 8) & 0xFF, start_address & 0xFF])
    cs = checksum(payload)
    return "S9" + payload.hex().upper() + f"{cs:02X}"


def binary_to_srec(data: bytes, load_address: int, exec_address: int = None) -> list:
    """Convert raw binary to list of S-record strings."""
    records = ["S0030000FC"]   # S0 header record
    CHUNK = 16                 # bytes per record (keep short for 6551 FIFO)
    for offset in range(0, len(data), CHUNK):
        chunk = data[offset:offset + CHUNK]
        addr = load_address + offset
        if addr > 0xFFFF:
            print(f"ERROR: Address ${addr:04X} exceeds 16-bit range", file=sys.stderr)
            sys.exit(1)
        records.append(make_s1_record(addr, chunk))
    records.append(make_s9_record(exec_address or load_address))
    return records


def load_file(path: str, load_address: int) -> list:
    """Load a file and return list of S-record strings."""
    ext = os.path.splitext(path)[1].lower()
    if ext in ('.hex', '.s19', '.srec', '.mot'):
        with open(path, 'r') as f:
            return [line.strip() for line in f if line.strip()]
    else:
        # Treat as raw binary
        with open(path, 'rb') as f:
            data = f.read()
        print(f"  Binary: {len(data)} bytes, loading at ${load_address:04X}")
        return binary_to_srec(data, load_address)


# ---------------------------------------------------------------------------
# SYM-1 Supermonitor communication
# ---------------------------------------------------------------------------

def sym1_readline(port: serial.Serial, timeout: float = 2.0) -> str:
    """Read a line from the monitor (CR or LF terminated)."""
    buf = b''
    deadline = time.time() + timeout
    while time.time() < deadline:
        b = port.read(1)
        if b:
            buf += b
            if b in (b'\r', b'\n'):
                break
    return buf.decode('ascii', errors='replace').strip()


def sym1_send(port: serial.Serial, text: str, verbose: bool = False):
    """Send a string to the monitor."""
    if verbose:
        print(f"  TX: {text!r}")
    port.write((text + '\r').encode('ascii'))
    port.flush()


def sym1_wake(port: serial.Serial, verbose: bool):
    """Send a CR and wait for monitor prompt."""
    port.write(b'\r')
    time.sleep(0.2)
    resp = port.read(port.in_waiting).decode('ascii', errors='replace')
    if verbose:
        print(f"  Wake response: {resp!r}")


def upload(args):
    print(f"SYM-1 Uploader")
    print(f"  Port  : {args.port}")
    print(f"  Baud  : {args.baud}")
    print(f"  File  : {args.input}")

    records = load_file(args.input, int(args.load, 16))
    # Count only data records (S1/S2/S3)
    data_records = [r for r in records if r.startswith(('S1', 'S2', 'S3'))]
    print(f"  Records: {len(data_records)} data  +  overhead")

    with serial.Serial(
        args.port,
        baudrate=args.baud,
        bytesize=8,
        parity='N',
        stopbits=1,
        timeout=2
    ) as port:
        print("\nConnecting to SYM-1...")
        sym1_wake(port, args.verbose)

        # Enter load mode
        sym1_send(port, 'L', args.verbose)
        time.sleep(0.1)
        if args.verbose:
            print(f"  Monitor response: {port.read(port.in_waiting)!r}")

        print(f"Uploading {len(records)} records...")
        for i, rec in enumerate(records):
            port.write((rec + '\r').encode('ascii'))
            port.flush()
            # Pacing: wait for inter-record delay
            time.sleep(args.delay / 1000.0)
            # Echo checking (optional)
            if args.verbose and port.in_waiting:
                echo = port.read(port.in_waiting).decode('ascii', errors='replace')
                print(f"  [{i+1:4d}/{len(records)}] {rec[:20]}…  echo: {echo!r}")
            elif (i + 1) % 16 == 0:
                pct = (i + 1) * 100 // len(records)
                bar = '#' * (pct // 5) + '.' * (20 - pct // 5)
                print(f"\r  [{bar}] {pct:3d}%  record {i+1}/{len(records)}", end='', flush=True)

        print(f"\r  [{'#'*20}] 100%  {len(records)} records sent          ")

        # Brief pause for monitor to process S9
        time.sleep(0.3)
        resp = port.read(port.in_waiting).decode('ascii', errors='replace')
        if args.verbose:
            print(f"  Final response: {resp!r}")

        # Optionally execute
        if args.exec:
            exec_addr = args.addr.upper()
            print(f"\nExecuting at ${exec_addr}...")
            sym1_send(port, f'G {exec_addr}', args.verbose)

    print("Done.")


# ---------------------------------------------------------------------------
# bin2srec convenience (also usable as standalone)
# ---------------------------------------------------------------------------

def bin2srec_main():
    """Called when invoked as bin2srec.py"""
    import argparse as ap
    p = ap.ArgumentParser(description='Convert binary to Motorola S-records')
    p.add_argument('input', help='Input binary file')
    p.add_argument('--load', default='0500', help='Load address (hex)')
    args = p.parse_args()
    records = binary_to_srec(
        open(args.input, 'rb').read(),
        int(args.load, 16)
    )
    for r in records:
        print(r)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(
        description='Upload S-records or binary to SYM-1 via Supermonitor'
    )
    parser.add_argument('input', help='Input file (.hex/.s19/.bin)')
    parser.add_argument('--port',    default='/dev/ttyUSB0', help='Serial port')
    parser.add_argument('--baud',    type=int, default=9600,  help='Baud rate')
    parser.add_argument('--exec',    action='store_true',     help='Execute after load')
    parser.add_argument('--addr',    default='0500',          help='Execution address (hex)')
    parser.add_argument('--load',    default='0500',          help='Binary load address (hex)')
    parser.add_argument('--delay',   type=int, default=50,    help='Inter-record delay (ms)')
    parser.add_argument('--verbose', action='store_true',     help='Verbose output')
    args = parser.parse_args()

    try:
        upload(args)
    except serial.SerialException as e:
        print(f"\nSerial error: {e}", file=sys.stderr)
        print("Check that the port exists and you have permission to access it.")
        print("  Linux:  sudo usermod -aG dialout $USER  (then re-login)")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nAborted.")
        sys.exit(0)


if __name__ == '__main__':
    # Allow use as bin2srec if invoked that way
    if os.path.basename(sys.argv[0]) == 'bin2srec.py':
        bin2srec_main()
    else:
        main()
