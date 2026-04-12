;
; sym1_ext.inc - SYM-1 Extension and other related items
;

; SYM-1 SuperMonitor (v1.1) routines entry points
OUTSZ  := $8319      ; Print pointer
OBCRLF := $834A      ; Output byte with CR/LF to console
CRLF   := $834D      ; Output just CR/LF to console

USRENT := $8035      ; User Interrupt generation (pseudo-IRQ)

OR3A   := $AC01      ; Write-Protect RAM, Debug On/Off, I/O-3A
DDR3A  := $AC03      ; Data-Direction Register for 3A
UIRQVC := $A678      ; User non-break IRQ after Monitor

; VIA IFR Bit Masks
IFR_CA2      = %00000001      ; Bit 0 of IFR is CA2 Active Edge
IFR_CA1      = %00000010      ; Bit 1 of IFR is CA1 Active Edge
IFR_SHIFT    = %00000100      ; Bit 2 Complete 8 Shifts
IFR_CB2      = %00001000      ; Bit 3 of IFR is CB2 Active Edge
IFR_CB1      = %00010000      ; Bit 4 of IFR is CB1 Active Edge
IFR_TIMER2   = %00100000      ; Bit 5 of IFR is Timer 2
IFR_TIMER1   = %01000000      ; Bit 6 of IFR is Timer 1
IFR_ENABLE   = %10000000      ; Bit 7 of IFR is Any Enabled Interrupt

; VIA IER Bit Masks
IER_CA2_DIS   = %11111110      ; Bit 0 of IER is CA2 Interrupt Disable
IER_CA2_ENA   = %00000001      ; Bit 0 of IER is CA2 Interrupt Enable
IER_CA1_DIS   = %11111101      ; Bit 1 of IER is CA1 Interrupt Disable
IER_CA1_ENA   = %00000010      ; Bit 1 of IER is CA1 Interrupt Enable
IER_SHIFT_DIS = %11111011      ; Bit 2 of IER is CA1 Interrupt Disable
IER_SHIFT_ENA = %00000100      ; Bit 2 of IER is CA1 Interrupt Enable
IER_CB2_DIS   = %11110111      ; Bit 3 of IER is CB2 Interrupt Disable
IER_CB2_ENA   = %00001000      ; Bit 3 of IER is CB2 Interrupt Enable
IER_CB1_DIS   = %11101111      ; Bit 4 of IER is CB1 Interrupt Disable
IER_CB1_ENA   = %00010000      ; Bit 4 of IER is CB1 Interrupt Enable
IER_TIM2_DIS  = %11011111      ; Bit 5 of IER is Timer 2 Interrupt Disable
IER_TIM2_ENA  = %00100000      ; Bit 5 of IER is Timer 2 Interrupt Enable
IER_TIM1_DIS  = %10111111      ; Bit 6 of IER is Timer 1 Interrupt Disable
IER_TIM1_ENA  = %01000000      ; Bit 6 of IER is Timer 1 Interrupt Enable
IER_DISABLE   = %01111111      ; Bit 7 of IER is Disable flag
IER_ENABLE    = %10000000      ; Bit 7 of IER is Enable flag

;
; VIA PCR flags
;
PCR_CA1_NAE     = %00000000   ; Negative Active Edge
PCR_CA1_PAE     = %00000001   ; Positive Active Edge
PCR_CA2_INAE    = %00000000   ; Input Negative Active Edge
PCR_CA2_IIINE   = %00000010   ; Input Independent Interrupt Negative Edge
PCR_CA2_IPAE    = %00000100   ; Input Positive Active Edge
PCR_CA2_IIIPE   = %00000110   ; Independent Interrupt Input Positive Edge
PCR_CA2_HSO     = %00001000   ; Handshake Output
PCR_CA2_PO      = %00001010   ; Pulse Output
PCR_CA2_LO      = %00001100   ; Low Output
PCR_CA2_HO      = %00001110   ; High Output

PCR_CB1_NAE     = %00000000   ; Input Negative Active Edge
PCR_CB1_PAE     = %00010000   ; Input Positive Active Edge
PCR_CB2_INAE    = %00000000   ; Input Negative Active Edge
PCR_CB2_IIINE   = %00100000   ; Input Independent Interrupt Negative Edge
PCR_CB2_IPAE    = %01000000   ; Input Positive Active Edge
PCR_CB2_IIIPE   = %01100000   ; Independent Interrupt Input Positive Edge
PCR_CB2_HSO     = %10000000   ; Handshake Output
PCR_CB2_PO      = %10100000   ; Pulse Output
PCR_CB2_LO      = %11000000   ; Low Output
PCR_CB2_HO      = %11100000   ; High Output
