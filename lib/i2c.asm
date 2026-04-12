;******************************************************************************
;*
;* SYM-1 6502 I2C Bit-Banging Library
;*
;* Description:
;* Provides I2C subroutines for bit-banging on the SYM-1.
;* Updated to include an example for reading the 16-bit DIE_ID register ($0F)
;* from a TMP1075 temperature sensor.
;*
;* Hardware Connections:
;* - SCL to PB0 (VIA $AC00, Bit 0)
;* - SDA to PB1 (VIA $AC00, Bit 1)
;* - Requires 4.7k Ohm pull-up resistors on SCL and SDA.
;* - TMP1075 assumed address: $48 (A0, A1, A2 pins low).
;*
;******************************************************************************

.include "sym1.inc"

;==============================================================================
;  Constants and Memory Definitions
;==============================================================================

; --- 6522 VIA (Versatile Interface Adapter) Registers for User I/O Port
VIA_BASE    = $AC00           ; Base address of the User VIA on SYM-1
VIA_PORTB   = VIA_BASE        ; Port B Data Register (ORA/IRA)
VIA_DDRB    = VIA_BASE+2      ; Port B Data Direction Register

; --- I2C Pin Definitions (Bit masks for Port B)
SCL         = %00000001       ; Bit 0 for the Clock line
SDA         = %00000010       ; Bit 1 for the Data line

; --- TMP1075 Device Constants (Assuming A0=A1=A2=low, address $48)
TMP_ADDR_W  = $90             ; Slave Address $48, shifted left (10010000) for Write
TMP_ADDR_R  = $91             ; Slave Address $48, shifted left + 1 (10010001) for Read
DIE_ID_REG  = $0F             ; Register Pointer for the 16-bit DIE_ID

; --- Masks for Pin Direction Control (Setting to Input mode)
MASK_SCL_SDA_IN = $FC         ; %11111100: Clears bits 0 (SCL) and 1 (SDA)
MASK_SCL_IN     = $FE         ; %11111110: Clears bit 0 (SCL) only
MASK_SDA_IN     = $FD         ; %11111101: Clears bit 1 (SDA) only
        
;==============================================================================
; 
;==============================================================================
.segment "DATA"      
BITCOUNT:    .byte $0         ; Used as a loop counter for 8 bits
I2C_DATA:    .byte $0         ; Temporary storage for byte being sent/received

;==============================================================================
; 
;==============================================================================
.segment "CODE"

.export _I2C_INIT
.export _I2C_START
.export _I2C_STOP
.export _I2C_WRITE_BYTE
.export _I2C_READ_BYTE

;==============================================================================
;  I2C Core Subroutines (Unchanged from original implementation)
;==============================================================================

;------------------------------------------------------------------------------
; I2C_INIT: Initializes the I2C bus lines to the idle state (Input/High).
; Clobbers: A
;------------------------------------------------------------------------------
_I2C_INIT:
            LDA VIA_DDRB
            AND #MASK_SCL_SDA_IN   ; Clear SCL/SDA bits ($FC) to set them as inputs
            STA VIA_DDRB
            RTS

;------------------------------------------------------------------------------
; I2C_START: Generates the I2C Start condition (SDA Hi->Lo while SCL Hi).
; Clobbers: A
;------------------------------------------------------------------------------
_I2C_START:
            JSR SDA_HI        ; Ensure SDA is high
            JSR SCL_HI        ; Ensure SCL is high
            JSR I2C_DELAY_HALF
            JSR SDA_LO        ; Pull SDA low while SCL is high
            JSR I2C_DELAY_HALF
            JSR SCL_LO        ; Pull SCL low to begin transaction
            RTS

;------------------------------------------------------------------------------
; I2C_STOP: Generates the I2C Stop condition (SDA Lo->Hi while SCL Hi).
; Clobbers: A
;------------------------------------------------------------------------------
_I2C_STOP:
            JSR SDA_LO        ; Ensure SDA is low
            JSR SCL_HI        ; Pull SCL high
            JSR I2C_DELAY_HALF
            JSR SDA_HI        ; Pull SDA high while SCL is high
            JSR I2C_DELAY_HALF
            RTS

;------------------------------------------------------------------------------
; I2C_WRITE_BYTE: Writes one byte from the Accumulator to the I2C bus.
; Input: A = Byte to write.
; Output: Carry flag set if NACK, clear if ACK.
; Clobbers: A, X, I2C_DATA, BITCOUNT
;------------------------------------------------------------------------------
_I2C_WRITE_BYTE:
            STA I2C_DATA
            LDX #8
            STX BITCOUNT
WRITE_LOOP:
            ROL I2C_DATA      ; Shift MSB of data into Carry
            BCC WRITE_ZERO
WRITE_ONE:
            JSR SDA_HI        ; Send a '1' bit
            JMP CLOCK_PULSE
WRITE_ZERO:
            JSR SDA_LO        ; Send a '0' bit
CLOCK_PULSE:
            JSR SCL_HI        ; Pulse the clock line
            JSR I2C_DELAY
            JSR SCL_LO
            JSR I2C_DELAY_HALF
            DEC BITCOUNT
            BNE WRITE_LOOP

            ; Check for Acknowledge from slave
            JSR SDA_HI        ; Release data line for slave to control
            JSR SCL_HI
            JSR I2C_DELAY
            LDA VIA_PORTB     ; Read port B
            JSR SCL_LO
            AND #SDA          ; Isolate SDA bit
            BNE NACK_RECEIVED ; If not zero, SDA was high (NACK)
ACK_RECEIVED:
            CLC               ; Clear carry, success
            RTS
NACK_RECEIVED:
            SEC               ; Set carry, failure
            RTS

;------------------------------------------------------------------------------
; I2C_READ_BYTE: Reads one byte from the I2C bus into the Accumulator.
; Input: Carry flag should be set to send a NACK (last byte), clear for ACK (more data).
; Output: A = Byte read from bus.
; Clobbers: A, X, I2C_DATA, BITCOUNT
;------------------------------------------------------------------------------
_I2C_READ_BYTE:
            PHP               ; Preserve NACK/ACK flag on stack
            JSR SDA_HI        ; Set SDA to input to receive data
            LDX #8
            STX BITCOUNT
            LDA #0            ; Clear accumulator to shift bits into
            STA I2C_DATA      ; Initialize data to $00
READ_LOOP:
            JSR SCL_HI        ; Clock high, slave sends data
            JSR I2C_DELAY

            LDA VIA_PORTB     ; Read the port state
            AND #SDA          ; Isolate SDA bit (PB1). A is $00 or $02.
            BEQ BIT_WAS_ZERO  ; If $00, bit was 0

BIT_WAS_ONE:
            SEC               ; Bit was 1, set Carry
            JMP SHIFT_DATA

BIT_WAS_ZERO:
            CLC               ; Bit was 0, clear Carry

SHIFT_DATA:            
            LDA I2C_DATA      ; Load current assembled byte
            ROL A             ;  Rotate left, pulling Carry (new bit) into LSB (bit 0)
            STA I2C_DATA      ; Save the byte

            JSR SCL_LO        ; Clock low, end bit cycle
            JSR I2C_DELAY_HALF
            DEC BITCOUNT
            BNE READ_LOOP

            ; Send ACK or NACK
            PLP               ; Restore NACK/ACK flag from stack
            BCS SEND_NACK     ; If Carry was set, send NACK
SEND_ACK:
            JSR SDA_LO        ; Pull SDA low for ACK
            JMP ACK_CLOCK_OUT
SEND_NACK:
            JSR SDA_HI        ; Let SDA float high for NACK
ACK_CLOCK_OUT:
            JSR SCL_HI
            JSR I2C_DELAY
            JSR SCL_LO
            JSR I2C_DELAY_HALF
            JSR SDA_HI        ; Release SDA back to input state

            LDA I2C_DATA      ; Load final byte into accumulator for return
            RTS

;==============================================================================
;  Low-Level Pin Control and Delay Subroutines
;==============================================================================

SCL_HI:
            LDA VIA_DDRB      ; Set SCL as input
            AND #MASK_SCL_IN  ; Clear bit 0 ($FE)
            STA VIA_DDRB
            RTS
SCL_LO:
            LDA VIA_DDRB      ; Set SCL as output
            ORA #SCL
            STA VIA_DDRB
            LDA VIA_PORTB     ; Set SCL pin low
            AND #MASK_SCL_IN
            STA VIA_PORTB
            RTS
SDA_HI:
            LDA VIA_DDRB      ; Set SDA as input
            AND #MASK_SDA_IN  ; Clear bit 1 ($FD)
            STA VIA_DDRB
            RTS
SDA_LO:
            LDA VIA_DDRB      ; Set SDA as output
            ORA #SDA
            STA VIA_DDRB
            LDA VIA_PORTB     ; Set SDA pin low
            AND #MASK_SDA_IN
            STA VIA_PORTB
            RTS

;------------------------------------------------------------------------------
; I2C_DELAY / I2C_DELAY_HALF: Simple timing delays.
; Clobbers: Y
;------------------------------------------------------------------------------
I2C_DELAY:
            LDY #5           ; Adjust this value to change clock speed
DELAY_LOOP:
            DEY
            BNE DELAY_LOOP
            ; fall through to half delay
I2C_DELAY_HALF:
            LDY #2           ; Short delay
DELAY_LOOP_HALF:
            DEY
            BNE DELAY_LOOP_HALF
            RTS
