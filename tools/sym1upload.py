#!/usr/bin/env python3
"""
sym1upload.py  —  Upload binary to SYM-1 Supermonitor V1.1.

SUPERMONITOR V1.1 COMMAND PROTOCOL (confirmed by error analysis):

  The M command takes NO address argument.  Sending 'M 0500' produces
  error ER 13 (extra characters after command).

  Correct sequence:
    1. Send the address as a bare 4-digit hex number + CR
       This sets the monitor's current address pointer.
         e.g.  '0500\r'
    2. The monitor responds with the address and current byte value:
         '0500- XX'  (where XX is the current contents)
    3. Send 'M\r' to enter memory modify mode at the current address.
    4. Monitor shows the address and waits for a hex byte value.
    5. For each byte: send 2 hex digits + Space  e.g. 'A9 '
       Monitor stores the byte, advances to next address, shows next value.
    6. Send '.\r' to exit modify mode.
    7. Optionally send 'G 0500\r' to execute.

  The CTRL-S (0x13) seen in previous responses was the monitor sending
  XON/XOFF flow control to the host — it appears in the monitor's own
  output between the echoed command and the error message. It is NOT
  a corrupted byte from our transmission.

  Port is set to raw termios mode to prevent the Linux kernel tty layer
  from interfering with byte values in either direction.

Usage:
  python3 sym1upload.py [options] <file.bin>

Options:
  --port      PORT   Serial port          (default: /dev/ttyUSB0)
  --baud      BAUD   Baud rate            (default: 4800)
  --load      ADDR   Load address in hex  (default: 0500)
  --exec             Execute after load
  --exec-addr ADDR   Execution address    (default: same as --load)
  --char-delay MS    Delay between characters in ms, matches minicom 'Character tx delay' (default: 5)
  --newline-delay MS  Extra delay after CR in ms, matches minicom 'Newline tx delay' (default: 25)
  --byte-delay MS    Delay after each byte in ms (default: 50)
  --verbose          Show all serial I/O
  --dry-run          Show what would be sent without opening port
"""

import argparse
import sys
import time
import termios

try:
    import serial
except ImportError:
    print("ERROR: pyserial not installed.  Run:  pip3 install pyserial")
    sys.exit(1)


def set_raw(fd, baud):
    """
    Force the serial fd to completely raw mode via termios.
    Clears all input/output processing, echo, signals, and flow control.
    """
    baud_map = {
        1200:  termios.B1200,
        2400:  termios.B2400,
        4800:  termios.B4800,
        9600:  termios.B9600,
        19200: termios.B19200,
    }
    baud_const = baud_map.get(baud, termios.B4800)

    attrs = termios.tcgetattr(fd)
    attrs[0] = 0                                              # iflag: no input processing
    attrs[1] = 0                                              # oflag: no output processing
    attrs[2] = baud_const | termios.CS8 | termios.CREAD | termios.CLOCAL
    attrs[3] = 0                                              # lflag: raw, no echo
    attrs[4] = baud_const                                     # ispeed
    attrs[5] = baud_const                                     # ospeed
    termios.tcsetattr(fd, termios.TCSANOW, attrs)


def drain(port, timeout=0.3, verbose=False):
    """Read and return all pending bytes within timeout."""
    buf = b''
    port.timeout = 0.05
    deadline = time.time() + timeout
    while time.time() < deadline:
        chunk = port.read(64)
        if chunk:
            buf += chunk
            deadline = time.time() + timeout
    port.timeout = 1.0
    if verbose and buf:
        display = buf.replace(b'\r', b'<CR>').replace(b'\n', b'<LF>')
        display = display.replace(b'\x13', b'<XOFF>').replace(b'\x11', b'<XON>')
        print(f"    rx: {display}")
    return buf


def send(port, data, char_delay_s=0.0, newline_delay_s=0.0, verbose=False):
    """
    Send bytes one character at a time with per-character and per-CR delays.
    Matches minicom's 'Character tx delay' and 'Newline tx delay' settings
    (minicom CTRL-A T).  Every byte gets char_delay_s; CR bytes additionally
    get newline_delay_s on top (total CR delay = char_delay_s + newline_delay_s).
    """
    if isinstance(data, str):
        data = data.encode('ascii')
    if verbose:
        display = data.replace(b'\r', b'<CR>').replace(b'\n', b'<LF>')
        print(f"    tx: {display}")
    for byte in data:
        port.write(bytes([byte]))
        port.flush()
        if byte == 0x0D and newline_delay_s > 0:
            time.sleep(newline_delay_s)   # extra pause after CR
        elif char_delay_s > 0:
            time.sleep(char_delay_s)


def upload(port, data, load_addr, delay_s, char_delay_s=0.0, newline_delay_s=0.0, verbose=False):
    """
    Upload binary data using the correct V1.1 protocol:
      1. Send bare address to set address pointer
      2. Send 'M' to enter modify mode
      3. Stream ASCII hex pairs
      4. Send '.' to exit
    """
    total = len(data)
    print(f"  Uploading {total} bytes to ${load_addr:04X}–${load_addr+total-1:04X}")
    print()

    # Step 1: Enter memory modify mode with bare 'm'
    print(f"  Step 1: Enter modify mode  → 'm'")
    send(port, "m", char_delay_s=char_delay_s, newline_delay_s=newline_delay_s, verbose=verbose)
    time.sleep(0.3)
    response = drain(port, timeout=0.4, verbose=verbose)

    # Step 2: Set address pointer by sending bare 4-digit hex address + CR
    addr_cmd = f"{load_addr:04X}\r"
    print(f"  Step 2: Set address pointer → '{addr_cmd.strip()}'")
    send(port, addr_cmd, char_delay_s=char_delay_s, newline_delay_s=newline_delay_s, verbose=verbose)
    time.sleep(0.3)
    response = drain(port, timeout=0.4, verbose=verbose)
    if verbose:
        print(f"    (address set response: {response!r})")

    if b'ER' in response:
        print(f"  ERROR: Monitor rejected M command: {response!r}")
        print()
        print("  The monitor must be at the '.' prompt before uploading.")
        print("  Try pressing CR on the SYM-1 keyboard to get the prompt,")
        print("  then run the upload again.")
        return False

    if verbose:
        print(f"    (modify mode response: {response!r})")
    print(f"  Modify mode entered. Streaming {total} bytes as ASCII hex...")
    print()

    print(f"delay_s: {delay_s}")
    
    # Step 3: Stream bytes as ASCII hex pairs with trailing space
    errors = 0
    for i, val in enumerate(data):
        hex_pair = f"{val:02X} "
        send(port, hex_pair, char_delay_s=char_delay_s, newline_delay_s=newline_delay_s, verbose=verbose)
        time.sleep(delay_s)

        r = drain(port, timeout=0.02, verbose=False)
        if verbose and r:
            display = r.replace(b'\r',b'<CR>').replace(b'\n',b'<LF>')
            display = display.replace(b'\x13',b'<XOFF>').replace(b'\x11',b'<XON>')
            print(f"    rx: {display}")
        if b'ER' in r:
            errors += 1
            print(f"\n  ERROR at byte {i+1} (${load_addr+i:04X} = {val:02X}): {r!r}")

        if not verbose:
            if (i + 1) % 64 == 0 or i == total - 1:
                pct = (i + 1) * 100 // total
                bar  = '#' * (pct // 5) + '.' * (20 - pct // 5)
                rem  = (total - i - 1) * delay_s
                print(f"\r  [{bar}] {pct:3d}%  {i+1}/{total}  ~{rem:.0f}s remaining  ",
                      end='', flush=True)

    print()

    # Step 4: Exit modify mode
    print("  Exiting modify mode...")
    send(port, ".\r", char_delay_s=char_delay_s, newline_delay_s=newline_delay_s, verbose=verbose)
    time.sleep(0.2)
    drain(port, timeout=0.3, verbose=verbose)

    if errors:
        print(f"  WARNING: {errors} error(s) during upload.")
        print(f"  Consider increasing --byte-delay and retrying.")
    else:
        print("  Upload complete — no errors.")

    return errors == 0


def main():
    parser = argparse.ArgumentParser(
        description='Upload binary to SYM-1 Supermonitor V1.1'
    )
    parser.add_argument('input',
        help='Input binary file (.bin)')
    parser.add_argument('--port', default='/dev/ttyUSB0',
        help='Serial port (default: /dev/ttyUSB0)')
    parser.add_argument('--baud', type=int, default=4800,
        help='Baud rate (default: 4800)')
    parser.add_argument('--load', default='0500',
        help='Load address in hex (default: 0500)')
    parser.add_argument('--exec', dest='execute', action='store_true',
        help='Execute after upload')
    parser.add_argument('--exec-addr', default=None,
        help='Execution address in hex (default: same as --load)')
    parser.add_argument('--char-delay', type=int, default=5,
        help='Delay between characters in ms — minicom Character tx delay (default: 5)')
    parser.add_argument('--newline-delay', type=int, default=25,
        help='Extra delay after CR in ms — minicom Newline tx delay (default: 25)')
    parser.add_argument('--byte-delay', type=int, default=50,
        help='Delay after each byte in ms (default: 50)')
    parser.add_argument('--verbose', action='store_true',
        help='Show all serial I/O')
    parser.add_argument('--dry-run', action='store_true',
        help='Show what would be sent without opening port')
    args = parser.parse_args()

    try:
        load_addr = int(args.load, 16)
    except ValueError:
        print(f"ERROR: Invalid load address: {args.load!r}")
        sys.exit(1)

    exec_addr = load_addr
    if args.exec_addr:
        try:
            exec_addr = int(args.exec_addr, 16)
        except ValueError:
            print(f"ERROR: Invalid exec address: {args.exec_addr!r}")
            sys.exit(1)

    try:
        with open(args.input, 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print(f"ERROR: File not found: {args.input!r}")
        sys.exit(1)

    delay_s         = args.byte_delay / 1000.0
    char_delay_s    = args.char_delay / 1000.0
    newline_delay_s = args.newline_delay / 1000.0

    est_time = len(data) * delay_s

    print(f"SYM-1 Supermonitor V1.1 Uploader")
    print(f"  File      : {args.input}  ({len(data)} bytes)")
    print(f"  Load addr : ${load_addr:04X}")
    if args.execute:
        print(f"  Exec addr : ${exec_addr:04X}")
    print(f"  Port      : {args.port}  @ {args.baud} baud")
    print(f"  Char delay : {args.char_delay} ms")
    print(f"  NL delay   : {args.newline_delay} ms")
    print(f"  Byte delay : {args.byte_delay} ms")
    print(f"  Est. time : {est_time:.0f}s  ({est_time/60:.1f} min)")
    print()

    if args.dry_run:
        print("[dry run] Sequence that would be sent:")
        print(f"  '{load_addr:04X}\\r'          ← set address pointer")
        print(f"  'm\\r'                 ← enter modify mode")
        preview = ''.join(f'{b:02X} ' for b in data[:12])
        print(f"  '{preview}...'  ← {len(data)} bytes as ASCII hex pairs")
        print(f"  '.\\r'                 ← exit modify mode")
        if args.execute:
            print(f"  'g {exec_addr:04X}\\r'          ← execute")
        return

    try:
        port = serial.Serial(
            args.port,
            baudrate=args.baud,
            bytesize=8,
            parity='N',
            stopbits=1,
            timeout=1.0,
            xonxoff=False,
            rtscts=False,
            dsrdtr=False,
        )
    except serial.SerialException as e:
        print(f"ERROR opening {args.port}: {e}")
        print("  Check: ls /dev/ttyUSB*  and  sudo usermod -aG dialout $USER")
        sys.exit(1)

    try:
        # Force raw mode — bypass all kernel tty processing
        set_raw(port.fileno(), args.baud)
        print("Port set to raw mode (kernel tty processing disabled).")
        print()

        # Wake monitor
        print("Waking monitor...")
        send(port, "\r", verbose=args.verbose)
        time.sleep(0.3)
        response = drain(port, timeout=0.5, verbose=args.verbose)
        if b'.' not in response:
            send(port, "\r", verbose=args.verbose)
            time.sleep(0.4)
            response = drain(port, timeout=0.5, verbose=args.verbose)

        if b'.' in response:
            print("  Monitor prompt received.")
        else:
            print(f"  WARNING: No '.' prompt (got: {response!r})")
            print("  Ensure SYM-1 is at monitor prompt and try again.")
        print()

        ok = upload(port, data, load_addr, delay_s, char_delay_s=char_delay_s, newline_delay_s=newline_delay_s, verbose=args.verbose)

        if args.execute and ok:
            print()
            print(f"Executing at 'g ${exec_addr:04X}'...")
            send(port, f"g", verbose=args.verbose)
            send(port, f"{exec_addr:04X}\r", verbose=args.verbose)
            time.sleep(0.2)
            drain(port, timeout=0.3, verbose=args.verbose)

        print()
        print("Done." if ok else "Completed with errors.")
        sys.exit(0 if ok else 1)

    except serial.SerialException as e:
        print(f"\nSerial error: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nAborted — sending '.' to exit modify mode...")
        try:
            port.write(b'.\r')
            port.flush()
        except Exception:
            pass
        sys.exit(1)
    finally:
        port.close()


if __name__ == '__main__':
    main()
