; =============================================================================
; sym1.inc  —  SYM-1 SBC Hardware & Supermonitor V1.1 Equates
; =============================================================================
; Target: SYM-1 with 4K RAM, Supermonitor V1.1
; Assembler: ca65 (cc65 toolchain)
; =============================================================================

OUTCHR   = $8A47     ; Output character
WARM     = $8003     ; Monitor entry
INTCHR   = $8A58     ; Input character without case conversion 
RESET    = $8B4A     ; Hard reset

MONIN   = INTCHR
MONOUT  = OUTCHR
MONITR  = RESET

.IF 0
; -----------------------------------------------------------------------------
; Supermonitor V1.1 Jump Table  (ROM at $8000)
; -----------------------------------------------------------------------------
MONIN   = $8000         ; Input one char from console  → A = char (blocks)
MONOUT  = $8004         ; Output one char to console   ← A = char to print
MONITR  = $8008         ; Enter monitor (warm start / "exit to monitor")
MONRDL  = $800C         ; Read a line into monitor buffer
MONPRT  = $8010         ; Print NUL-terminated string (ptr in X:Y lo:hi)
MONHEX  = $8014         ; Print A as two hex digits
MONCRFL = $8018         ; Print CR/LF pair
MONCRLF = $8018         ; alias

; Input status — poll before calling MONIN if you want non-blocking
; Read ACIA status register directly (see ACIA equates below)
.ENDIF

; -----------------------------------------------------------------------------
; SYM-1 Memory Map
; -----------------------------------------------------------------------------
RAM_START   = $0000
RAM_END     = $0FFF     ; 4K on-board RAM
ROM_START   = $8000     ; Supermonitor ROM
IO_BASE     = $A000     ; I/O region

; -----------------------------------------------------------------------------
; 6532 RIOT  (System timer / parallel I/O)
; -----------------------------------------------------------------------------
RIOT_PA     = $A000     ; Port A data
RIOT_DDRA   = $A001     ; Port A data direction  (1=output)
RIOT_PB     = $A002     ; Port B data
RIOT_DDRB   = $A003     ; Port B data direction
RIOT_TIMER  = $A004     ; Read: elapsed timer / Write: set timer ÷1
RIOT_T8     = $A005     ; Set timer ÷8
RIOT_T64    = $A006     ; Set timer ÷64
RIOT_T1024  = $A007     ; Set timer ÷1024

; -----------------------------------------------------------------------------
; 6551 ACIA  (Asynchronous Communications Interface — TTL serial)
; -----------------------------------------------------------------------------
ACIA_DATA   = $A800     ; Transmit/Receive data register
ACIA_STATUS = $A801     ; Status register (read)
ACIA_CMD    = $A802     ; Command register (write)
ACIA_CTRL   = $A803     ; Control register (write)

; ACIA Status bits
ACIA_IRQ    = %10000000 ; Interrupt flag
ACIA_DSR    = %01000000 ; Data Set Ready
ACIA_DCD    = %00100000 ; Data Carrier Detect
ACIA_TDRE   = %00010000 ; Transmit Data Register Empty (ready to send)
ACIA_RDRF   = %00001000 ; Receive Data Register Full  (char available)
ACIA_OVRN   = %00000100 ; Overrun error
ACIA_FE     = %00000010 ; Framing error
ACIA_PE     = %00000001 ; Parity error

; ACIA Control — 4800 baud, 8N1, external clock:
;   $16 = baud 4800 (with 1.8432 MHz crystal), 8 data bits, 1 stop bit
ACIA_4800_8N1 = $16

; -----------------------------------------------------------------------------
; Zero Page — Framework Reserved  ($E0–$FF)
; User code may freely use $00–$DF
; -----------------------------------------------------------------------------
ZP_BASE     = $E0       ; Start of framework zero-page area

; TUI cursor & state
TUI_COL     = $E0       ; Current cursor column  (0–79)
TUI_ROW     = $E1       ; Current cursor row     (0–23)
TUI_ATTR    = $E2       ; Current attribute byte  (see tui.inc)
TUI_FLAGS   = $E3       ; Internal TUI flags

; General-purpose 16-bit pointer (used by string/TUI routines)
PTR_LO      = $E4
PTR_HI      = $E5
PTR2_LO     = $E6
PTR2_HI     = $E7

; Scratch registers
SCRATCH0    = $E8
SCRATCH1    = $E9
SCRATCH2    = $EA
SCRATCH3    = $EB

; Math helpers (see math.asm)
MATH_A_LO   = $EC
MATH_A_HI   = $ED
MATH_B_LO   = $EE
MATH_B_HI   = $EF
MATH_R_LO   = $F0
MATH_R_HI   = $F1

; String helpers
STR_LEN     = $F2       ; Length result from str_len
STR_TMP     = $F3

ROW_COUNT   = $F4
X_VALUE     = $F5
Y_VALUE     = $F6
W_VALUE     = $F7
H_VALUE     = $F8

; Reserved $F4–$FF for future use / user extension
