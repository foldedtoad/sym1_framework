# SYM-1 Supermonitor V1.1 — Reference

## Overview

The Supermonitor is the ROM-resident operating environment for the SYM-1.
It lives at **$8000–$9FFF** and provides:

- A command-line interface via the 6551 ACIA (TTL serial)
- A published jump table for calling I/O routines from user code
- Motorola S-record loader (the `L` command)
- Simple assembler/disassembler, memory examine/modify, register display

---

## Jump Table (ROM entry points)

All entry points are stable across Supermonitor revisions.
Call these with `JSR`.

| Label    | Address | Description                                     |
|----------|---------|-------------------------------------------------|
| `MONIN`  | `$8000` | Read one character from serial (blocking). Returns in A. |
| `MONOUT` | `$8004` | Write character in A to serial (blocking until ACIA ready). |
| `MONITR` | `$8008` | Warm-start the monitor (does not return). Use as program exit. |
| `MONRDL` | `$800C` | Read a full line into the monitor's internal buffer. |
| `MONPRT` | `$8010` | Print NUL-terminated string. X=low byte, Y=high byte of address. |
| `MONHEX` | `$8014` | Print A as two uppercase hex digits to serial. |
| `MONCRFL`| `$8018` | Print a CR (`$0D`) followed by LF (`$0A`). |

> **Note:** `MONPRT` uses X for the low byte and Y for the high byte of the
> string address — *not* the usual 6502 convention of Y:X.  Always use the
> `PRINT_STR` macro which handles this correctly.

### Register Preservation

The Supermonitor routines do **not** guarantee preservation of X and Y.
Wrap calls with `PUSH_AXY` / `POP_AXY` macros when you need them intact.
`MONOUT` and `MONIN` generally preserve X and Y in V1.1 but this is
not documented behaviour — don't rely on it.

---

## Monitor Commands (interactive)

| Command         | Description                                       |
|-----------------|---------------------------------------------------|
| `M addr`        | Examine/modify memory at `addr` (hex, no `$`)    |
| `R`             | Display CPU registers                             |
| `G addr`        | Go (execute) at `addr`                           |
| `L`             | Load S-records from serial line                  |
| `S addr1 addr2` | S-record dump of memory range to serial          |
| `A addr`        | Mini-assembler starting at `addr`                |
| `D addr`        | Disassemble at `addr`                            |
| `B addr`        | Set breakpoint at `addr`                         |
| `P`             | Proceed (continue from breakpoint)               |

### Notes on the `L` (Load) Command

1. Enter `L` at the monitor prompt.
2. The monitor echoes nothing — just start sending S-records.
3. Records must end with CR (`$0D`).  LF is optional.
4. The S9 end record causes the monitor to return to its prompt.
5. Send records at **no faster than 9600 baud** with at least **50 ms**
   between records to avoid the ACIA receive FIFO overrunning.
6. After load, use `G 0500` (or your load address) to execute.

---

## Zero Page Usage by Supermonitor

The Supermonitor uses zero-page locations **$00–$DF** internally during
command processing.  When your program is running (after the JSR), the
monitor is not actively using these, but on return to the monitor (via
`JMP MONITR`) they will be overwritten.

**Framework convention:** User zero page $00–$DF, Framework $E0–$FF.

---

## Stack Considerations

The hardware stack at $0100–$01FF is shared between your code and the
Supermonitor.  When you call `JSR MONITR` (exit), the monitor resets
its own stack pointer.  Ensure your stack usage fits comfortably — the
TUI library uses at most 6 stack bytes per nested call (3 JSR return
addresses).

---

## 6551 ACIA Serial Settings

The Supermonitor initialises the ACIA at startup for **9600 baud, 8N1**.
Your code must not change the ACIA baud rate if you intend to use the
Supermonitor I/O routines.  If you write directly to the ACIA, restore
the settings before returning to the monitor.

Direct ACIA I/O (bypassing Supermonitor) can be faster but you must poll
`ACIA_STATUS` bit 4 (TDRE) before writing and bit 3 (RDRF) before reading.
