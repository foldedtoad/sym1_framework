# SYM-1 Memory Map Reference

## On-Board RAM: $0000–$0FFF (4096 bytes)

| Address Range | Size   | Purpose                                    |
|---------------|--------|--------------------------------------------|
| $0000–$00DF   | 224 B  | Zero page — **user code** (free)           |
| $00E0–$00FF   | 32 B   | Zero page — **framework reserved** (TUI/math/string state) |
| $0100–$01FF   | 256 B  | Hardware stack (shared with monitor)       |
| $0200–$04FF   | 768 B  | Frame buffer / TUI scratch area            |
| $0500–$0BFF   | 1792 B | **User program code & data**               |
| $0C00–$0EFF   | 768 B  | TUI library (resident routines)            |
| $0F00–$0FFF   | 256 B  | BSS overflow / runtime variables           |

## ROM / I/O: $8000+

| Address Range | Size  | Purpose                             |
|---------------|-------|-------------------------------------|
| $8000–$9FFF   | 8K    | Supermonitor V1.1 ROM               |
| $A000–$A003   | 4 B   | 6532 RIOT (timer / parallel I/O)    |
| $A400–$A40F   | 16 B  | 6522 VIA (versatile interface)      |
| $A800–$A803   | 4 B   | 6551 ACIA (serial / TTL console)    |

## Zero Page Framework Layout ($E0–$FF)

| Address | Symbol     | Use                              |
|---------|------------|----------------------------------|
| $E0     | TUI_COL    | Current cursor column (0–79)     |
| $E1     | TUI_ROW    | Current cursor row (0–23)        |
| $E2     | TUI_ATTR   | Current attribute byte           |
| $E3     | TUI_FLAGS  | TUI internal flags               |
| $E4     | PTR_LO     | General 16-bit pointer (low)     |
| $E5     | PTR_HI     | General 16-bit pointer (high)    |
| $E6     | PTR2_LO    | Second pointer (low)             |
| $E7     | PTR2_HI    | Second pointer (high)            |
| $E8     | SCRATCH0   | Scratch register 0               |
| $E9     | SCRATCH1   | Scratch register 1               |
| $EA     | SCRATCH2   | Scratch register 2               |
| $EB     | SCRATCH3   | Scratch register 3               |
| $EC     | MATH_A_LO  | Math operand A (low)             |
| $ED     | MATH_A_HI  | Math operand A (high)            |
| $EE     | MATH_B_LO  | Math operand B (low)             |
| $EF     | MATH_B_HI  | Math operand B (high)            |
| $F0     | MATH_R_LO  | Math result (low)                |
| $F1     | MATH_R_HI  | Math result (high)               |
| $F2     | STR_LEN    | String length result             |
| $F3     | STR_TMP    | String temp byte                 |
| $F4–$FF | —          | Reserved / user extension        |

## Fitting Code into 4K: Tips

1. **Put constants in RODATA** — they don't need to be in ZP.
2. **Use the TUI library as a base** — don't copy its routines into your code.
3. **Share SCRATCH0–3** — they're caller-saved; callee may clobber them.
4. **Avoid inline strings** — put all `.byte` string literals in `RODATA`.
5. **Use 8-bit counters** where 16-bit isn't needed.
6. **Short subroutines** — a 6-byte JSR+RTS pair costs less than repeated inline code past ~3 repetitions.
7. **Check your `.map` file** — ld65 generates a map showing exact sizes.
