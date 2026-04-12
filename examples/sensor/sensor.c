//---------------------------------------------------------------------------
// Demo for Dynamic TI TMP1075 Temperature Sensor
//---------------------------------------------------------------------------

#include <sym1.h>
#include <stdlib.h>
#include <6502.h>

//---------------------------------------------------------------------------
// External References
//---------------------------------------------------------------------------
extern void I2C_INIT(void);
extern void I2C_START(void);
extern void I2C_STOP(void);
extern void I2C_WRITE_BYTE(unsigned char reg);
extern unsigned char I2C_READ_BYTE(void);
extern void I2C_SET_ACK(void);
extern void I2C_SET_NACK(void);

extern void Interrupts_Init(void);

//---------------------------------------------------------------------------
// Defines
//---------------------------------------------------------------------------
#define GENERAL_CALL_ADDR       0x00
#define GENERAL_CALL_RESET      0x06

#define TMP1075_ADDR_R          0x91
#define TMP1075_ADDR_W          0x90

#define TMP1075_TEMP            0x00
#define TMP1075_CFGR            0x01
#define TMP1075_CFGR_ONE_SHOT   0x80FF
#define TMP1075_CFGR_RATE_25ms  0x00FF
#define TMP1075_CFGR_RATE_55ms  0x10FF
#define TMP1075_CFGR_RATE_110ms 0x20FF
#define TMP1075_CFGR_RATE_220ms 0x30FF
#define TMP1075_CFGR_FAULT_1    0x00FF
#define TMP1075_CFGR_FAULT_2    0x08FF
#define TMP1075_CFGR_FAULT_3    0x10FF
#define TMP1075_CFGR_FAULT_4    0x18FF 
#define TMP1075_CFGR_POL        0x04FF
#define TMP1075_CFGR_TM         0x02FF
#define TMP1075_CFGR_SHUT_DOWN  0x01FF
#define TMP1075_LLIM            0x02
#define TMP1075_HLIM            0x03
#define TMP1075_DIEID           0x0F

#define TMP1075_DEVICE_ID  0x7500

#define FAILURE   -1
#define SUCCESS    0

// Easy temperature values
#define Temp_15C    0x1F00
#define Temp_16C    0x1000
#define Temp_17C    0x1100
#define Temp_18C    0x1200
#define Temp_19C    0x1300
#define Temp_20C    0x1400
#define Temp_21C    0x1500
#define Temp_22C    0x1600
#define Temp_23C    0x1700
#define Temp_24C    0x1800
#define Temp_25C    0x1900
#define Temp_26C    0x1A00
#define Temp_27C    0x1B00
#define Temp_28C    0x1C00
#define Temp_29C    0x1D00
#define Temp_30C    0x1E00
#define Temp_31C    0x1F00
#define Temp_32C    0x2000

//---------------------------------------------------------------------------
// Variables
//---------------------------------------------------------------------------

union 
{
    unsigned char RegAsBytes [2];
    unsigned short RegAsUShort;
} u;

char buffer[10];

unsigned long temp;
unsigned long cfg;
unsigned long llim;
unsigned long hlim;

//---------------------------------------------------------------------------
// Assume raw temperature, "data", is 0x1490
//   Shift right 4 bits (drop last nibble), so 0x149
//   
//   DEGREES_PER_BIT = 0.0625  (From datasheet)
//   Scale for fixed-notation: 10000 (0x2710)
//   0.0625 * 10000 = 625 == 0x271
//   0x149 * 0x271 = 0x32339 ==> 205625
//   data = 032339 / FIXED_POINT
//   fixed_point.integer = data / FIXED_POINT
//   fixed_point.fraction = data % FIXED_POINT
//   printf("temp: %d.%dC\n", fixed_point.integer, fixed_point.fraction);
//   shows: "temp: 20.56C"
//---------------------------------------------------------------------------

#define DEGREES_PER_BIT  0x271
#define FIXED_POINT      0x64

struct {
    long integer;
    long fraction;    
} fixed_point;

//---------------------------------------------------------------------------
// Print a single hex character
//---------------------------------------------------------------------------
void print_hex_byte(unsigned byte) 
{
    (void) byte;

    asm("jsr $82FA");  // OUTBYT
}

//---------------------------------------------------------------------------
// Print a null-terminated (ASCIIZ) string
//---------------------------------------------------------------------------
void print_string(char * str)
{
    (void) str;

    __asm__ ("      sta $FB     ");  // save str ptr to zero-page variable
    __asm__ ("      stx $FC     ");
    __asm__ ("      ldy #$00    ");
    __asm__ ("@loop:            ");
    __asm__ ("      lda ($FB),y ");
    __asm__ ("      beq @done   ");
    __asm__ ("      jsr $8A47   ");   // OUTCHR
    __asm__ ("      iny         ");
    __asm__ ("      bne @loop   ");
    __asm__ ("@done:            ");
}

//---------------------------------------------------------------------------
// Print the value of a 16-bit value
//---------------------------------------------------------------------------
void Print_Reg16(char * label, unsigned short value)
{
    print_string(label); 
    itoa(value, buffer, 16); 
    print_string(buffer);  
    print_string("\n\r");
}

//---------------------------------------------------------------------------
// Convert and Print a temperature type value
//---------------------------------------------------------------------------
void Print_Temperature(char * label, unsigned long value)
{
    value >>= 4;
    value *= DEGREES_PER_BIT;
    value /= FIXED_POINT;

    fixed_point.integer  = value / FIXED_POINT;
    fixed_point.fraction = value % FIXED_POINT;

    print_string(label); 
    itoa(fixed_point.integer, buffer, 10); 
    print_string(buffer); 
    print_string("."); 
    itoa(fixed_point.fraction, buffer, 10);
    print_string(buffer); 
    print_string("C\n\r"); 
}

//---------------------------------------------------------------------------
// 
//---------------------------------------------------------------------------

#define DATA_CONT   __asm__("clc") // Continue and ACK this byte transaction
#define DATA_LAST   __asm__("sec") // Last and NACK this byte transaction

//---------------------------------------------------------------------------
// Read a device 16-bit register
//---------------------------------------------------------------------------
unsigned short Read_Reg16(unsigned char reg)
{
    I2C_START();
    I2C_WRITE_BYTE(TMP1075_ADDR_W);
    I2C_WRITE_BYTE(reg);

    I2C_START();
    I2C_WRITE_BYTE(TMP1075_ADDR_R);
    DATA_CONT;
    u.RegAsBytes[1] = I2C_READ_BYTE();   // note endian-ness here
    DATA_LAST;
    u.RegAsBytes[0] = I2C_READ_BYTE();

    I2C_STOP();

    return u.RegAsUShort;
}

//---------------------------------------------------------------------------
// Write to a device's 16-bit register
//---------------------------------------------------------------------------
void Write_Reg16(unsigned char reg, unsigned value)
{
    u.RegAsUShort = value;

    I2C_START();
    I2C_WRITE_BYTE(TMP1075_ADDR_W);
    I2C_WRITE_BYTE(reg);

    DATA_CONT;
    I2C_WRITE_BYTE(u.RegAsBytes[1]);   // note endian-ness here
    DATA_LAST;
    I2C_WRITE_BYTE(u.RegAsBytes[0]);
    I2C_STOP();
}

//---------------------------------------------------------------------------
// 
//---------------------------------------------------------------------------
void Interrupt_Callback(void)
{
    temp = Read_Reg16(TMP1075_TEMP);
    
    Print_Temperature("temp: ", temp);
}

//---------------------------------------------------------------------------
// Write general-call reset to reset device (See SMBus std. for details)
//---------------------------------------------------------------------------
void TMP1075_Reset(void)
{
    I2C_START();
    I2C_WRITE_BYTE(GENERAL_CALL_ADDR);
    DATA_CONT;
    I2C_WRITE_BYTE(GENERAL_CALL_RESET); 
    DATA_LAST;
    I2C_STOP();
}

//---------------------------------------------------------------------------
// Initialize Interrupts and I2C driver, with check for device ID.
//---------------------------------------------------------------------------
int Initialize(void)
{
    I2C_INIT();

    TMP1075_Reset();

    Interrupts_Init();

    return (Read_Reg16(TMP1075_DIEID) == TMP1075_DEVICE_ID)? SUCCESS:FAILURE;
}

//---------------------------------------------------------------------------
// Main application
//---------------------------------------------------------------------------
int main(void)
{
    print_string("Built "__DATE__" "__TIME__"\n\r");

    if (Initialize() == SUCCESS) {

        temp = Read_Reg16(TMP1075_TEMP);
        cfg  = Read_Reg16(TMP1075_CFGR);
        llim = Read_Reg16(TMP1075_LLIM);
        hlim = Read_Reg16(TMP1075_HLIM);

        Print_Temperature("llim: ", llim);
        Print_Temperature("hlim: ", hlim);
        Print_Temperature("temp: ", temp);

        cfg = TMP1075_CFGR_TM;
        Write_Reg16(TMP1075_CFGR, cfg);
        cfg  = Read_Reg16(TMP1075_CFGR);       
        Print_Reg16("cfg: 0x", cfg);

        llim = Temp_25C; 
        Write_Reg16(TMP1075_LLIM, llim);
        llim  = Read_Reg16(TMP1075_LLIM);       
        Print_Temperature("llim: ", llim);

        hlim = Temp_30C; 
        Write_Reg16(TMP1075_HLIM, hlim);
        hlim  = Read_Reg16(TMP1075_HLIM);       
        Print_Temperature("hlim: ", hlim);
    }

    return 0;
}
