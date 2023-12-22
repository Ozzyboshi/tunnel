/******************************************************************************

                            Online C Compiler.
                Code, Compile, Run and Debug C program online.
Write your code in this editor and press "Run" button to compile and execute it.

*******************************************************************************/

#include <stdio.h>
#include <math.h>

#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY(byte)  \
  ((byte) & 0x80 ? '1' : '0'), \
  ((byte) & 0x40 ? '1' : '0'), \
  ((byte) & 0x20 ? '1' : '0'), \
  ((byte) & 0x10 ? '1' : '0'), \
  ((byte) & 0x08 ? '1' : '0'), \
  ((byte) & 0x04 ? '1' : '0'), \
  ((byte) & 0x02 ? '1' : '0'), \
  ((byte) & 0x01 ? '1' : '0') 

// Funzione per convertire un intero in formato Q2.6
unsigned char convertToQ2_6(double value) {
    unsigned char result;
    int intpart = (int) value;
//    printf("Integer part is %d\n",intpart);
    double decpart = value - intpart;
//    printf("Decimal part is %f\n",decpart);
    
    /*if (intpart==3) 	 result = 0b11000000;
    else if (intpart==2) result = 0b10000000;
    else if (intpart==1) result = 0b01000000;
    else 	         result = 0b00000000;*/
    if (intpart>=1) return 0b10000000;
    
    // start of decimal
    double appdecpart = decpart;
    appdecpart*=2;   
    if (appdecpart>=1)
    {
        result |= 0b01000000;
        appdecpart = appdecpart -1;
    }
    
    appdecpart*=2;   
    if (appdecpart>=1)
    {
        result |= 0b00100000;
        appdecpart = appdecpart -1;
    }
    
    appdecpart*=2;
    if (appdecpart>=1)
    {
        result |= 0b00010000;
        appdecpart = appdecpart -1;
    }
    
    appdecpart*=2;   
    if (appdecpart>=1)
    {
        result |= 0b00001000;
        appdecpart = appdecpart -1;
    }
    
    appdecpart*=2;   
    if (appdecpart>=1)
    {
        result |= 0b00000100;
        appdecpart = appdecpart -1;
    }
    
    appdecpart*=2;   
    if (appdecpart>=1)
    {
        result |= 0b00000010;
        appdecpart = appdecpart -1;
    }
    
    appdecpart*=2;   
    if (appdecpart>=1)
    {
        result |= 0b00000001;
        appdecpart = appdecpart -1;
    }
    
    
    
    return result;
}


int main()
{
    for (int i=0;i<=128;i++)
    { 
        double appo = M_PI/128*i;
        unsigned char result = convertToQ2_6(sin(M_PI/2/128*i));
        printf("    dc.b %%%c%c%c%c%c%c%c%c ; Iteration %d , InputValue: %f\n",BYTE_TO_BINARY(result),i,sin(M_PI/2/128*i));

    }

    return 0;
}
