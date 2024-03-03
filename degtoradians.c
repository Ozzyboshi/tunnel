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
  
  

unsigned char convertToQ2_6(double value) {
    unsigned char result;
    int intpart = (int) value;
//    printf("Integer part is %d\n",intpart);
    double decpart = value - intpart;
//    printf("Decimal part is %f\n",decpart);
    
    if (intpart==3) 	 result = 0b11000000;
    else if (intpart==2) result = 0b10000000;
    else if (intpart==1) result = 0b01000000;
    else 	         result = 0b00000000;
    
    // start of decimal
    double appdecpart = decpart;
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

// Funzione per convertire un intero in formato Q2.6
unsigned char convertToQ0_8(double value) {
    unsigned char result;
    int intpart = (int) value;
//    printf("Integer part is %d\n",intpart);
    double decpart = value - intpart;
//    printf("Decimal part is %f\n",decpart);
    
    /*if (intpart==3) 	 result = 0b11000000;
    else if (intpart==2) result = 0b10000000;
    else if (intpart==1) result = 0b01000000;
    else 	      */   result = 0b00000000;
    
    // start of decimal
    double appdecpart = decpart*2;
    appdecpart*=2;
    if (appdecpart>=1)
    {
        result |= 0b10000000;
        appdecpart = appdecpart -1;
    }
    
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



int main() {
    int grado;
    double radiante;

    printf("Grado\tRadiante\n");
    for(grado = 0; grado <= 90; grado++) {
        radiante = grado * (M_PI / 180) / M_PI;
        unsigned char result = convertToQ0_8(radiante);
        printf("dc.b %%%c%c%c%c%c%c%c%c ; %d deg / %.6f\n",BYTE_TO_BINARY(result), grado, radiante);
    }

    return 0;
}

