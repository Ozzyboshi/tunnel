#include <stdio.h>
#include <math.h>
#define RATIOX 30

#define RATIOY 4

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

void generateTransformationTableY()
{
    int x, y;
    for (y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
            // Calcola la distanza var angle = (int)(currentSliderRatioYValue * texWidth * atan2(y - height / 2.0, x - width / 2.0) / PI);
            double atan_distance = atan2(y - height / 64.0, x - width / 64.0)/M_PI;
            //int inverse_distance_modded = inverse_distance % texHeight;
            printf ("TransformY X:%d - Y:%d : %f\n",x,y,RATIOY*texWidth*atan_distance);
            double result = RATIOY*texWidth*atan_distance;
            int result2 = (int)result;
            int result3 = result2&0xF;
            result3*=16;
            printf("    dc.w %d\n",(int)result2);
        }
    }
}

void main()
{
    printf("Generating X transformation table");
    generateTransformationTable();
    printf("Generating Y transformation table");
    generateTransformationTableY();
}
