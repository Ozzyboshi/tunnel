TEXTURE_SIZE EQU 16

SCREEN_RES_X equ 64
SCREEN_RES_Y equ 64

TEXTURE_HEIGHT equ 16

RATIOX EQU 30

PRINT_PIXELS MACRO
  ; start first pixel
  ; read transformation table (distance table)
  move.w            (a3)+,d2

  ; read transformation table (rotation table)
  move.w            (a4)+,d4

  ; add shift Y (add frame counter to what was read from the rotation table and perform a %16)
  add.w             d3,d4
  and.w             d0,d4
  asl.w             #4,d4

  ; add shift x (add frame counter to what was read from the distance table and perform a %16)
  ; frame counter is on the upper part of d7 to save access memory
  add.w             d3,d2
  and.w             d0,d2

  ; now d4 holds the correct offset of the table in the lower word
  add.w             d2,d4
  add.w             d4,d4
  move.w            0(a6,d4.w),d1 ; check if we have to print color 1 or color 2

  ; pixel 2 start
  move.w            (a3)+,d2
  move.w            (a4)+,d4
  add.w             d3,d4
  and.w             d0,d4
  asl.w             #4,d4

  add.w             d3,d2
  and.w             d0,d2
  add.w             d2,d4
  add.w             d4,d4
  or.w              0(a0,d4.w),d1

; pixel 3 start
  move.w            (a3)+,d2
  move.w            (a4)+,d4
  add.w             d3,d4
  and.w             d0,d4
  asl.w             #4,d4

  add.w             d3,d2
  and.w             d0,d2
  add.w             d2,d4
  or.b              0(a1,d4.w),d1

; start of pixel 4
  move.w            (a3)+,d2
  move.w            (a4)+,d4
  add.w             d3,d4
  and.w             d0,d4
  asl.w             #4,d4

  add.w             d3,d2
  and.w             d0,d2
  add.w             d2,d4
  or.b              0(a2,d4.w),d1

; copy 4 leds into bitplane

  move.w            d1,(a5)+
  ENDM


  ; Place addr in d0 and the copperlist pointer addr in a1 before calling
POINTINCOPPERLIST MACRO
  move.w              d5,6(a5)
  swap                d5
  move.w              d5,2(a5)
  ENDM
  jmp Inizio

  include "AProcessing/libs/rasterizers/globaloptions.s"
  include "AProcessing/libs/math/operations.s"
  include "AProcessing/libs/math/atan2_pi_128.s"
  ;include "AProcessing/libs/math/atan2_pi_128.i"
ATAN2_128_QUADRANT: dcb.b 4096,0
  include "atan2_delta_table.i"

  SECTION             CiriCop,CODE_C

CURRENT_X:          dc.w      0
CURRENT_Y:          dc.w      0
EFFECT_FUNCTION:    dc.l      VSHRINK
Inizio:
  bsr.w             Save_all

  lea               $dff000,a6
  move              #$7ff,$96(a6)                                                  ;Disable DMAs
  move              #%1000001110000000,$96(a6)                                     ;Master,Copper,Blitter,Bitplanes
  move              #$7fff,$9a(a6)                                                 ;Disable IRQs
  move              #$e000,$9a(a6)                                                 ;Master and lev6
					;NO COPPER-IRQ!
  moveq             #0,d0
  move              d0,$106(a6)                                                    ;Disable AGA/ECS-stuff
  move              d0,$1fc(a6)

  move.l            #COPPERLIST,$80(a6)                                            ; Copperlist point
  move.w            d0,$88(a6)                                                     ; Copperlist start

  move.w            d0,$1fc(a6)                                                    ; FMODE - NO AGA
  move.w            #$c00,$106(a6)                                                 ; BPLCON3 - NO AGA

  ; ATAN2 table prepare START
  lea               ATAN2_128_QUADRANT_DELTA,a0
  lea               ATAN2_128_QUADRANT,a1
  moveq             #0,d1
  move.w            #4096-1,d7
loop:
  move.w            (a0)+,d0
  add.w             d1,d0
  move.b            d0,(a1)+
  move.w            d0,d1
  dbra              d7,loop
  ; ATAN2 table prepare END

  ;check
  IFD LOL
  lea               ATAN2_128_QUADRANT,a0
  lea               ATAN2_128_QUADRANT2,a1
  move.w            #4096-1,d7
check:
  move.b (a0)+,d0
  move.b (a1)+,d1
  cmp.b d0,d1
  beq.s ok
  DEBUG 2222
ok:
  dbra d7,check
  ENDC
  ; START preparing bitplane 0, set FF in every byte where the tunnel will be drown
  SETBITPLANE       0,a6
  addq              #4,a6
  ; y cycle start
  move.w            #SCREEN_RES_Y*3,d7
tunnel_y_prepare:

; x cycle start
  moveq             #SCREEN_RES_X/4-1,d6
tunnel_x_prepare:
  move.w            #$FFFF,(a6)+
  ;move.w             #%1010101010101010,(a6)+
  ;move.w            #$FE7F,(a6)+
  dbra              d6,tunnel_x_prepare

  ; change scanline
  lea               8+40*0(a6),a6

  dbra              d7,tunnel_y_prepare
  ; END preparing bitplane 0, set FF in every byte where the tunnel will be drown

  ; Set bpl zero in copperlist
  lea               BPLPTR1,a5
  move.l            SCREEN_PTR_0,d5
  POINTINCOPPERLIST

  jsr               GENERATE_TRANSFORMATION_TABLE_Y

  ; Generate transformation table for distance
  jsr               GENERATE_TRANSFORMATION_TABLE_X

  ; Set colors
  move.w            #$222,$dff180
  move.w            #$888,$dff182
  move.w            #$00f,$dff184
  move.w            #$0,$dff186

  ; set modulo

  ; Generate XOR texture (16px X 16px)
  jsr               XOR_TEXTURE

  moveq             #0,d3 ; reset current time variable
  moveq             #$F,d0
  move.l            #40*256*2*-1,d6

  lea               TEXTURE_DATA(PC),a2
  lea               TEXTURE_DATA_2(PC),a6
  lea               TEXTURE_DATA_3(PC),a1
  lea               TEXTURE_DATA_4(PC),a0

; ******************************* START OF GAME LOOP ****************************
mouse:
  cmpi.b            #$ff,$dff006                                                   ; Are we at line 255?
  bne.s             mouse                                                          ; Wait

  ; Switch Bitplanes for double buffering
  neg.l             d6
  add.l             d6,SCREEN_PTR_1
  SETBITPLANE       1,a5
  addq #4,a5

  IFD COLORDEBUG
  move.w #$FF0,$dff180
  ENDC

  ;bra.w     tunnelend

  ; *********************************** Start of tunnel rendering *********************************
  lea               TRANSFORMATION_TABLE_DISTANCE(PC),a3
  lea	              TRANSFORMATION_TABLE_Y(PC),a4

  ; y cycle start
  IFND TUNNEL_SCANLINES
  moveq             #SCREEN_RES_Y-1,d7
  ELSE
  moveq             #TUNNEL_SCANLINES-1,d7
  ENDC
tunnel_y:

; x cycle start
  ;moveq             #SCREEN_RES_X/4-1,d6
;tunnel_x:

  rept 16
  PRINT_PIXELS
  endr

  ; change scanline
  ;lea               8+40*0(a5),a5
  addq              #8,a5

  dbra              d7,tunnel_y
tunnelend:
  move.l            EFFECT_FUNCTION,a5
  jsr               (a5)

  IFD COLORDEBUG
  move.w            #$000,$dff180
  ENDC

  ; load bitplanes in copperlist

  lea               BPLPTR2,a5
  move.l            SCREEN_PTR_1,d5
  POINTINCOPPERLIST

  ; increment the frame counter for animating
  addq              #1,d3

  ; exit if lmb is pressed
  btst              #6,$bfe001
  bne.w             mouse
exit_demo:
  bsr.w             Restore_all
  clr.l             d0
  rts

; Routine to generate a XOR texture
XOR_TEXTURE:
  ;for(int y = 0; y < texHeight; y++)
  ;for(int x = 0; x < texWidth; x++)
  ;{
  ;  texture[y][x] = (x * 256 / texWidth) ^ (y * 256 / texHeight);
  ;}
  lea               TEXTURE_DATA(PC),a2
  lea               TEXTURE_DATA_2(PC),a3
  lea               TEXTURE_DATA_3(PC),a4
  lea               TEXTURE_DATA_4(PC),a5
  clr.w             CURRENT_X
  clr.w             CURRENT_Y

  ; y cycle start   for(int y = 0; y < texHeight; y++)
  moveq             #TEXTURE_SIZE-1,d7
xor_texture_y:

; x cycle start
  moveq             #TEXTURE_SIZE-1,d6 ; for(int x = 0; x < texWidth; x++)
xor_texture_x:

  move.w            CURRENT_X,d0
	move.w            CURRENT_Y,d1

  ; execute eor
  move.w            d0,d5
  eor.w             d1,d5

  ; if d7 > 127 color is 1
  IF_1_LESS_EQ_2_W_U #TEXTURE_SIZE/2,d5,.notgreater,s
  ;STROKE #1
  clr.b             (a4)+
  clr.b             (a2)+
  clr.w             (a3)+
  clr.w             (a5)+
  bra.s             .printpoint
.notgreater:
  ;STROKE #2
  move.b            #$F0,(a4)+
  move.b            #$0F,(a2)+
  move.w            #$F000,(a3)+
  move.w            #$0F00,(a5)+
.printpoint
	;jsr               POINT
  addi.w            #1,CURRENT_X
  dbra              d6,xor_texture_x
  clr.w             CURRENT_X
  addi.w            #1,CURRENT_Y
  dbra              d7,xor_texture_y
  rts

; Routine GENERATE_Y_TRANSFORMATION_TABLE
; This routine reads table TRANSFORMATION_TABLE_Y which is created be the
; "transformationtable.c" and recalculates it using a different shiftY.
; shiftY value must be stored on d6
; the destination table must be stored on a6
GENERATE_Y_TRANSFORMATION_TABLE:
  lea	              TRANSFORMATION_TABLE_Y(PC),a4
  move.w            #SCREEN_RES_X*SCREEN_RES_Y-1,d7
generate_y_transformation_table_loop:
  move.w            (a4)+,d0
  add.w             d6,d0
  andi.w            #$F,d0
  muls.w            #16,d0
  move.w            d0,(a6)+
  dbra              d7,generate_y_transformation_table_loop
  rts

; Routine GENERATE_TRANSFORMATION_TABLE
; This routine generates the precalculated table used for the X axis
; It's just a translation for this C code:
; void generateTransformationTable() {
;   int x, y;
;   for (y = 0; y < height; y++) {
;       for (int x = 0; x < width; x++) {
;           // Calcola la distanza
;           double distance = sqrt((x - width / 2.0) * (x - width / 2.0) + (y - height / 2.0) * (y - height / 2.0));
;           int inverse_distance = (int) (RATIOX * texHeight / distance);
;           int inverse_distance_modded = inverse_distance % texHeight;
;           printf ("X:%d - Y:%d : %f %d %d\n",x,y,distance,inverse_distance,inverse_distance_modded);
;       }
;   }
; }
; Resulting table will be stored att addr TRANSFORMATION_TABLE_DISTANCE
;

GENERATE_TRANSFORMATION_TABLE_X:
  lea               TRANSFORMATION_TABLE_DISTANCE(PC),a0

  ; init x (d0) and y (d1) , for convenience instead starting from 0, we start from -SCREEN_RES_X/2 and we end
  ; at SCREEN_RES/2, same for the Y axys
  move.l            #0*64,d0
  move.l            #0,d1

  ; first cycle - for each Y
  moveq             #SCREEN_RES_Y-1,d7
table_precalc_y:

  ; second cycle - for each X
  moveq             #SCREEN_RES_X-1,d6
table_precalc_x:

  ; need to save d0 (x) and d1 (y) to preserve their value
  move.l            d0,d2
  move.l            d1,d3
  
  ;get the division number
  move.w            #64*SCREEN_RES_X,d4
  lsr.w             #2,d4 ; change here to set X position of the center

  sub.w             d4,d2
  muls.w            d2,d2
  lsr.l             #6,d2

  move.w            #64*SCREEN_RES_Y,d4
  lsr.w             #1,d4

  sub.w             d4,d3
  muls.w            d3,d3
  lsr.l             #6,d3
  
  add.l             d3,d2 ; it is important here to compute long because otherwise 
  lsr.l             #6,d2 ; the get strange bands in the middle of the tunner
  move.l            d2,d3 ; but anyway it could be an idea for an effect
  
  ;(x - width / 2.0) * (x - width / 2.0) + (y - height / 2.0) * (y - height / 2.0)
    ; let's start with sqrt calculation

  ; start sqrt execution
  move.w            #-1,d5
qsqrt1:
  addq              #2,d5
  sub.w             d5,d3
  bpl               qsqrt1
  asr.w             #1,d5
  move.w            d5,d3
  ; end sqrt execution
  
 ; sanity check, distance could be zero, we dont want to divide by zero, m68k doesnt like it
  ; if distance is zero let's say distance is 1
  bne.s             distanceok
  moveq             #1,d3
distanceok:

  ; start executing the following C code: int inverse_distance = (int) (RATIOX * texHeight / distance);
  ; divide per texture height
  move.l            #64*RATIOX*TEXTURE_HEIGHT,d2
  divu              d3,d2

  ; get integer part
  lsr.w             #6,d2

  ;get the module
  ext.l             d2
  divu              #TEXTURE_HEIGHT,d2
  swap              d2

  ; write into transformation table
  move.w            d2,(a0)+
  
  addi.w            #1*64,d0
  dbra              d6,table_precalc_x

  add.w             #1*64,d1 ; increment y

  move.l            #0*64,d0
  dbra              d7,table_precalc_y

  rts

HEIGHT_DIVIDER:     dc.w 2
WIDTH_DIVIDER:      dc.w 4
GENERATE_TRANSFORMATION_TABLE_Y:
  lea               TRANSFORMATION_TABLE_Y(PC),a1

  ; height / HEIGHT_DIVIDER (64.0) into d3
  moveq             #SCREEN_RES_X,d3
  divu              WIDTH_DIVIDER,d3

  moveq             #SCREEN_RES_Y,d2
  divu              HEIGHT_DIVIDER,d2

  ; cannot keep in d3 the value of x, saving in upper part of d2
  swap              d2
  move.w            d3,d2
  swap              d2

  ; init x (d0) and y (d1) , for convenience instead starting from 0, we start from -SCREEN_RES_X/2 and we end
  ; at SCREEN_RES/2, same for the Y axys

  ; first cycle - for each Y
  moveq             #0,d5 ; Y
  moveq             #SCREEN_RES_Y-1,d7
table_y_precalc_y:

  ; second cycle - for each X
  moveq             #0,d4 ; X
  moveq             #SCREEN_RES_X-1,d6
table_y_precalc_x:

  ;get atan_distance using Aprocessing
  ;double atan_distance = atan2(y - height / 64.0, x - width / 64.0)/M_PI;

  ; compute y - height / 64.0
  move.w           d5,d0
  sub.w            d2,d0

  ; compute X - width / 64.0
  move.w           d4,d1
  swap             d2
  sub.w            d2,d1
  swap             d2

  ;we are ready to call atan2(y,x)/PI
  movem.l          d0/d1,-(sp)
  jsr              ATAN2_PI_128
  movem.l          (sp)+,d0/d1
  asr.w #3,d3

  ;swap d3
  ;DEBUG 1111
  ;swap d3


  ;multiply by texture width
  asl.w            #4,d3

  ; multiply bt ratioY
  muls             #4,d3

  asr.w #6,d3

  move.w           d3,(a1)+

  addq             #1,d4
  dbra             d6,table_y_precalc_x
  
  addq             #1,d5
  dbra             d7,table_y_precalc_y
  rts

POINTINCOPPERLIST_FUNCT:
  POINTINCOPPERLIST
  rts

;---------------------------------------------------------------
Save_all:
  move.b            #$87,$bfd100                                                   ; stop drive
  move.l            $00000004,a6
  jsr               -132(a6)
  move.l            $6c,SaveIRQ
  move.w            $dff01c,Saveint
  or.w              #$c000,Saveint
  move.w            $dff002,SaveDMA
  or.w              #$8100,SaveDMA

  move.l	          4.w,a6		; ExecBase in A6
  JSR	              -$84(a6)	; FORBID - Disabilita il Multitasking
  JSR	              -$78(A6)	; DISABLE - Disabilita anche gli interrupt
				;	    del sistema operativo
  ; set new intena
  MOVE.L	          #$7FFF7FFF,$dff09A	; DISABILITA GLI INTERRUPTS & INTREQS

  rts
Restore_all:
  move.l            SaveIRQ,$6c
  move.w            #$7fff,$dff09a
  move.w            Saveint,$dff09a
  move.w            #$7fff,$dff096
  move.w            SaveDMA,$dff096
  move.l            $00000004,a6
  lea               Name,a1
  moveq             #0,d0
  jsr               -552(a6)
  move.l            d0,a0
  move.l            38(a0),$dff080
  clr.w             $dff088
  move.l            d0,a1
  jsr               -414(a6)
  jsr               -138(a6)
  rts


TRANSFORMATION_TABLE_DISTANCE:
  dcb.w SCREEN_RES_X*SCREEN_RES_Y,0

TEXTURE_DATA:
  dcb.b TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
TEXTURE_DATA_2:
  dcb.w TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
TEXTURE_DATA_3:
  dcb.b TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
TEXTURE_DATA_4:
  dcb.w TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
;---------------------------------------------------------------
Saveint:              dc.w 0
SaveDMA:              dc.w 0
SaveIRQ:              dc.l 0
Name:                 dc.b "graphics.library",0
  even

TRANSFORMATION_TABLE_Y:   dcb.w SCREEN_RES_X*SCREEN_RES_Y,0

  include "blurryeffect.s"
  include "normaleffect.s"
  include "vshrink.s"
  include "vnormal.s"
  include "noeffect.s"

	include "AProcessing/libs/rasterizers/processing_bitplanes_fast.s"

;----------------------------------------------------------------

; **************************************************************************
; *				SUPER COPPERLIST			   *
; **************************************************************************

; Single playfield mode
COPSET2BPL MACRO
  dc.w       $100
  dc.w       %0010001000000000
  ENDM

  SECTION    GRAPHIC,DATA_C

COPPERLIST:

; other stuff
  dc.w       $8e,$2c81                                                 ; DiwStrt	(registri con valori normali)
  dc.w       $90,$2cc1                                                 ; DiwStop
  dc.w       $92,$0038                                                 ; DdfStart
  dc.w       $94,$00d0                                                 ; DdfStop
  dc.w       $102,0

  ;dc.w	$0180,$000	; color0 - SFONDO
	;dc.w	$0182,$f00	; color1 - SCRITTE
	;dc.w	$0184,$0f0	; color2 - SCRITTE
	;dc.w	$0186,$00f	; color3 - SCRITTE
  dc.w       $104,$0000

  dc.w       $108,0                                                    ; Bpl1Mod
  dc.w       $10a,0

  COPSET2BPL

; Bitplanes Pointers
BPLPTR1:
  dc.w       $e0,$0000,$e2,$0000                                       ;first	 bitplane - BPL0PT
BPLPTR2:
  dc.w       $e4,$0000,$e6,$0000                                       ;second bitplane - BPL1PT

COPLINES:
  ; line 1
  dc.w       $2bE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $2dE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

  ; line 2
  dc.w       $2eE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $30E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

  ; line 3
  dc.w       $31E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $33E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

  ; line 4
  dc.w       $34E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $36E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

  ; line 5
  dc.w       $37E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $39E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

    ; line 6
  dc.w       $3AE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $3CE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

    ; line 7
  dc.w       $3DE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $3FE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

    ; line 8
  dc.w       $40E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $42E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

    ; line 9
  dc.w       $43E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $45E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

    ; line 10
  dc.w       $46E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $48E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

      ; line 11
  dc.w       $49E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $4BE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

      ; line 12
  dc.w       $4CE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $4EE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

      ; line 14
  dc.w       $4FE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $51E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

      ; line 15
  dc.w       $52E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $54E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

     ; line 16
  dc.w       $55E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $57E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

     ; line 17
  dc.w       $58E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $5AE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

     ; line 18
  dc.w       $5BE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $5DE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

     ; line 19
  dc.w       $5EE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $60E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

     ; line 20
  dc.w       $61E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $63E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

     ; line 21
  dc.w       $64E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $66E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

     ; line 22
  dc.w       $67E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $69E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

     ; line 23
  dc.w       $6AE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $6CE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

     ; line 24
  dc.w       $6DE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $6FE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

     ; line 25
  dc.w       $70E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $72E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

       ; line 26
  dc.w       $73E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $75E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

         ; line 27
  dc.w       $76E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $78E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

         ; line 28
  dc.w       $79E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $7BE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

         ; line 29
  dc.w       $7CE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $7EE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

         ; line 30
  dc.w       $7FE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $81E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

           ; line 31
  dc.w       $82E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $84E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

           ; line 32
  dc.w       $85E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $87E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

           ; line 33
  dc.w       $88E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $8AE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

           ; line 34
  dc.w       $8BE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $8EE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

           ; line 35
  dc.w       $8FE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $91E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

             ; line 36
  dc.w       $92E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $94E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

             ; line 37
  dc.w       $95E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $97E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

               ; line 38
  dc.w       $98E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $9AE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

               ; line 39
  dc.w       $9BE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $9DE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

               ; line 40
  dc.w       $9EE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $A0E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                 ; line 41
  dc.w       $A1E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $A3E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                  ; line 42
  dc.w       $A4E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $A6E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                    ; line 43
  dc.w       $A7E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $A9E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                     ; line 44
  dc.w       $AAE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $ACE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                       ; line 45
  dc.w       $ADE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $AFE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                         ; line 46
  dc.w       $B0E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $B2E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                           ; line 47
  dc.w       $B3E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $B5E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                           ; line 48
  dc.w       $B6E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $B8E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                           ; line 49
  dc.w       $B9E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $BBE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                           ; line 50
  dc.w       $BCE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $BEE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                             ; line 51
  dc.w       $BFE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $C1E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                             ; line 52
  dc.w       $C2E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $C4E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                             ; line 53
  dc.w       $C5E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $C7E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                             ; line 54
  dc.w       $C8E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $CAE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                             ; line 55
  dc.w       $CBE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $CEE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                               ; line 56
  dc.w       $CFE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $D1E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                               ; line 57
  dc.w       $D2E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $D4E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                               ; line 58
  dc.w       $D5E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $D7E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                               ; line 59
  dc.w       $D8E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $DAE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                               ; line 60
  dc.w       $DBE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $DEE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                               ; line 61
  dc.w       $DFE3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $E1E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                               ; line 62
  dc.w       $E2E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $E4E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                               ; line 63
  dc.w       $E5E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $E7E3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0

                               ; line 64
  dc.w       $E8E3,$FFFE
  ;dc.w       $180,$fff
  dc.w       $10a,-40
  dc.w       $EAE3,$FFFE
  ;dc.w       $180,0
  dc.w       $10a,0



  ; Copperlist end
  dc.w       $FFFF,$FFFE                                               ; End of copperlist

  end

