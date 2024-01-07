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

#define FILENAME "ozzydrums.raw"
void main()
{
    unlink(FILENAME);

    for (int t=0;t<4000;t++)
    {
        //128-(t>>(t%64?4:3)|(t%128?t>>3:t>>3|t>>9))
        // signed 8000hz
        //char o = 128-(t>>(t%64?4:3)|(t%128?t>>3:t>>3|t>>9));
        // signed 2000hz
        //char o = t%1024/32<16? t%32?127-(t%1024/1):-128+(t%1024/8) :127;
        char o = (sin(sqrt(t%4096) * 2) * 3 + sin(sqrt(t%4096 * 1 + 50) * 12) * .9)*25;
        o = (sin(sqrt(t%4096) * 2) * 3 + sin(sqrt(t%4096 * 1 + 50) * 12))*25;
        //char o = (sin(sqrt(t%4096) * 0.125) * 3 + sin(sqrt(t%4096 * 1 + 50) * 12) * .9)*25;
        //printf("%d -> primo operando %f secondo operando %f risultato %d\n",t,sin(sqrt(t%4096) * 2) * 3,sin(sqrt(t%4096 * 1 + 50) * 12),o);
        printf("dc.b %%%c%c%c%c%c%c%c%c ; InputValue: %d\n",BYTE_TO_BINARY(o),o);
        FILE *file = fopen(FILENAME, "ab");
        fwrite(&o,1,1,file);
        fclose(file);
    }
    
}