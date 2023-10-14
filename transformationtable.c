#include <stdio.h>
#include <math.h>
#define RATIOX 30
int height = 64;
int width = 64;
int texHeight = 16;
int texWidth = 16;


void generateTransformationTable() {
    int x, y;
    for (y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // Calcola la distanza
            double distance = sqrt((x - width / 2.0) * (x - width / 2.0) + (y - height / 2.0) * (y - height / 2.0));
            int inverse_distance = (int) (RATIOX * texHeight / distance);
            int inverse_distance_modded = inverse_distance % texHeight;
            printf ("X:%d - Y:%d : %f %d %d\n",x,y,distance,inverse_distance,inverse_distance_modded);
        }
    }
}

void main()
{
    generateTransformationTable();
}
