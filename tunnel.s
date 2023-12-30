TEXTURE_SIZE EQU 16

SCREEN_RES_X equ 64
SCREEN_RES_Y equ 64

TEXTURE_WIDTH equ 16
TEXTURE_HEIGHT equ 16

RATIOX EQU 30
RATIOY EQU 4

PRINT_PIXELS MACRO
  ; start first pixel
  ; read transformation table (distance table)
  move.w            (a3)+,d2

  ; read transformation table (rotation table)
  move.w            (a4)+,d4

  ; add shift Y (add frame counter to what was read from the rotation table and perform a %16)
  add.w             d5,d4
  and.w             d7,d4 ; perform %256 module
  ;asl.w             #4,d4
  ;((15*16+10*16) mod 256 )

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
  add.w             d5,d4
  and.w             d7,d4
  ;asl.w             #4,d4

  add.w             d3,d2
  and.w             d0,d2
  add.w             d2,d4
  add.w             d4,d4
  or.w              0(a0,d4.w),d1

; pixel 3 start
  move.w            (a3)+,d2
  move.w            (a4)+,d4
  add.w             d5,d4
  and.w             d7,d4
  ;asl.w             #4,d4

  add.w             d3,d2
  and.w             d0,d2
  add.w             d2,d4
  or.b              0(a1,d4.w),d1

; start of pixel 4
  move.w            (a3)+,d2
  move.w            (a4)+,d4
  add.w             d5,d4
  and.w             d7,d4
  ;asl.w             #4,d4

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
  jmp                 Inizio

  include "AProcessing/libs/rasterizers/globaloptions.s"
  include "AProcessing/libs/math/operations.s"
  include "AProcessing/libs/math/atan2_pi_128.s"
ATAN2_128_QUADRANT: dcb.b 4096,0
  include "atan2_delta_table.i"

  SECTION             CiriCop,CODE_C
EFFECT_FUNCTION:    dc.l      BLURRYTUNNEL

TRANSFORMATION_TABLE_Y:
  dcb.w SCREEN_RES_X*2*SCREEN_RES_Y*2,0
SIN_TABLE:          dcb.w 128*4,0
SIN_TABLE2:         dcb.w 128*4,0

  include lsp.s
  include lsp_cia.s

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

  ; Copperlist creation START
  lea               COPLINES,a0
  moveq             #SCREEN_RES_Y-1,d7
  move.l            #$2BE3FFFE,d0
coploop:
    move.l          d0,(a0)+
    move.l          #$010AFFD8,(a0)+
    add.l           #1*33554432,d0
    move.l          d0,(a0)+
    move.l          #$010A0000,(a0)+
    add.l           #1*16777216,d0
    dbra            d7,coploop
  ; Copperlist creation END

  ; SIN table prepare START
  lea               SIN_Q1_7_UNSIGNED_QUADRANT_1,a0
  lea               SIN_TABLE(PC),a1
  lea               SIN_TABLE2(PC),a2

  ; quadrant 1 - start
  moveq             #128-1,d7
  moveq             #0,d0
sin_quadrant_1:
  moveq             #0,d0
  move.b            (a0)+,d0
  asr.w             #1,d0
  move.w            d0,d1
  bclr              #0,d1
  move.w            d1,(a1)+
  asr.w             #1,d0
  asl.w             #8,d0
  move.w            d0,(a2)+
  dbra              d7,sin_quadrant_1
  ; quadrant 1 - end

  ; quadrant 2 - start
  move.w            #$0040,(a1)+; here d1 holds pi/2
  move.w            #$2000,(a2)+; here d1 holds pi/2
  moveq             #127-1,d7
sin_quadrant_2:
  moveq             #0,d0
  move.b            -(a0),d0
  asr.w             #1,d0
  move.w            d0,d1
  bclr              #0,d1
  move.w            d1,(a1)+
  asr.w             #1,d0
  asl.w             #8,d0
  move.w            d0,(a2)+
  dbra              d7,sin_quadrant_2
  ; quadrant 2 - end

  ; quadrant 3 - start
  lea               SIN_Q1_7_UNSIGNED_QUADRANT_1,a0
  moveq             #128-1,d7
sin_quadrant_3:
  moveq             #0,d0
  move.b            (a0)+,d0
  neg.w             d0
  asr.w             #1,d0
  move.w            d0,d1
  bclr              #0,d1
  move.w            d1,(a1)+
  asr.w             #1,d0
  asl.w             #8,d0
  move.w            d0,(a2)+
  dbra              d7,sin_quadrant_3
  ; quadrant 3 - end

  ; quadrant 4 - start
  move.w            #$FFC0,(a1)+; here d1 holds pi/2
  move.w            #$E000,(a2)+; here d1 holds pi/2
  moveq             #127-1,d7
sin_quadrant_4:
  moveq             #0,d0
  move.b            -(a0),d0
  neg.w             d0
  asr.w             #1,d0
  move.w            d0,d1
  bclr              #0,d1
  move.w            d1,(a1)+
  asr.w             #1,d0
  asl.w             #8,d0
  move.w            d0,(a2)+
  dbra              d7,sin_quadrant_4
  ; quadrant 4 - end

  ; SIN table prepare END

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

  bsr.w             GENERATE_TRANSFORMATION_TABLE_Y

  ; Generate transformation table for distance
  bsr.w             GENERATE_TRANSFORMATION_TABLE_X

  ; Set colors
  move.w            #$222,$dff180
  move.w            #$888,$dff182
  move.w            #$00f,$dff184
  move.w            #$0,$dff186

  ; set modulo

  ; Generate XOR texture (16px X 16px)
  jsr               XOR_TEXTURE

  ;Init LSP and start replay using easy CIA toolbox
	lea		            LSPMusic,a0
	lea		            LSPBank,a1
	suba.l	          a2,a2			; suppose VBR=0 ( A500 )
	moveq	            #0,d0			; suppose PAL machine
	bsr.w		          LSP_MusicDriver_CIA_Start

  moveq             #0,d3 ; reset current time variable
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
  addq              #4,a5

  IFD COLORDEBUG
  move.w #$FF0,$dff180
  ENDC

  ;bra.w     tunnelend

  ; *********************************** Start of tunnel rendering *********************************

  ; Add offset for navigating into the tunnel (ShiftX and ShiftY)
  ; I will use d3 (frame counter) to move from one place to another
  ; SHIFTX START
  move.l            d3,d7
  andi.w            #%111111111,d7 ; Module of 512
  add.w             d7,d7
  lea               SIN_TABLE(PC),a3
  move.w            0(a3,d7.w),d7
  ; SHIFTX END

  ; SHIFTY START
  lea               SIN_TABLE2(PC),a3
  move.l            d3,d0
  add.w             d0,d0
  andi.w            #%111111111,d0 ; Module of 512
  add.w             d0,d0
  move.w            0(a3,d0.w),d0
  add.w             d0,d7
  ; SHIFTY END

  lea               64+32*256+TRANSFORMATION_TABLE_DISTANCE(PC),a3
  adda.w            d7,a3
  lea	              64+32*256+TRANSFORMATION_TABLE_Y(PC),a4
  adda.w            d7,a4

  moveq             #$F,d0

  ; multiply counter by 16
  move.w            d3,d5
  lsl.w             #4,d5

  ; y cycle start
  IFND TUNNEL_SCANLINES
  moveq             #SCREEN_RES_Y-1,d7
  ELSE
  moveq             #TUNNEL_SCANLINES-1,d7
  ENDC
  ori.l             #$FF0000,d7
tunnel_y:

; x cycle start
  ;moveq             #SCREEN_RES_X/4-1,d6
;tunnel_x:
  swap d7
  rept 16
  PRINT_PIXELS
  endr
  swap d7

  ; change scanline
  lea               64*2(a3),a3
  lea               64*2(a4),a4
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
  bsr.w             LSP_MusicDriver_CIA_Stop
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
  clr.w             d0
  clr.w             d1

  ; y cycle start   for(int y = 0; y < texHeight; y++)
  moveq             #TEXTURE_SIZE-1,d7
xor_texture_y:

; x cycle start
  moveq             #TEXTURE_SIZE-1,d6 ; for(int x = 0; x < texWidth; x++)
xor_texture_x:

  ; execute eor
  move.w            d0,d5
  eor.w             d1,d5

  ; if d7 > 127 color is 1
  IF_1_LESS_EQ_2_W_U #TEXTURE_SIZE/2,d5,.notgreater,s
  clr.b             (a4)+
  clr.b             (a2)+
  clr.w             (a3)+
  clr.w             (a5)+
  bra.s             .printpoint
.notgreater:
  move.b            #$F0,(a4)+
  move.b            #$0F,(a2)+
  move.w            #$F000,(a3)+
  move.w            #$0F00,(a5)+
.printpoint
  addq              #1,d0
  dbra              d6,xor_texture_x
  clr.w             d0
  addq              #1,d1
  dbra              d7,xor_texture_y
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
  moveq             #SCREEN_RES_Y*2-1,d7
table_precalc_y:

  ; second cycle - for each X
  moveq             #SCREEN_RES_X*2-1,d6
table_precalc_x:

  ; need to save d0 (x) and d1 (y) to preserve their value
  move.l            d0,d2
  move.l            d1,d3

  ;get the division number
  ;move.w            #64*SCREEN_RES_X,d4
  ;lsr.w             #1,d4 ; change here to set X position of the center

  sub.w             #64*64,d2
  muls.w            d2,d2
  lsr.l             #6,d2

  ;move.w            #64*SCREEN_RES_Y,d4
  ;lsr.w             #1,d4

  sub.w             #64*64,d3
  muls.w            d3,d3
  lsr.l             #6,d3

  add.l             d3,d2 ; it is important here to compute long because otherwise 
  lsr.l             #6,d2 ; the get strange bands in the middle of the tunner
  move.l            d2,d3 ; but anyway it could be an idea for an effect

  ;(x - width ) * (x - width ) + (y - height ) * (y - height )
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

GENERATE_TRANSFORMATION_TABLE_Y:
  lea               TRANSFORMATION_TABLE_Y,a1

  ; height / 1 (64.0) into d3
  moveq             #SCREEN_RES_X,d3
  ;divu              #1,d3

  moveq             #SCREEN_RES_Y,d2
  ;divu              #1,d2

  ; cannot keep in d3 the value of x, saving in upper part of d2
  swap              d2
  move.w            d3,d2
  swap              d2

  ; init x (d0) and y (d1) , for convenience instead starting from 0, we start from -SCREEN_RES_X/2 and we end
  ; at SCREEN_RES/2, same for the Y axys

  ; first cycle - for each Y
  moveq             #0,d5 ; Y
  moveq             #SCREEN_RES_Y*2-1,d7
table_y_precalc_y:

  ; second cycle - for each X
  moveq             #0,d4 ; X
  moveq             #SCREEN_RES_X*2-1,d6
table_y_precalc_x:

  ;get atan_distance using Aprocessing
  ;double atan_distance = atan2(y - height / 64.0, x - width / 64.0)/M_PI;

  ; compute y - height / 64.0
  move.w           d5,d0
  subi.w            #SCREEN_RES_Y,d0

  ; compute X - width / 64.0
  move.w           d4,d1
  subi.w           #SCREEN_RES_X,d1

  ;we are ready to call atan2(y,x)/PI
  movem.l          d0/d1,-(sp)
  jsr              ATAN2_PI_128
  movem.l          (sp)+,d0/d1
  asr.w            #3,d3

  ;multiply by texture width and ratioY
  muls             #TEXTURE_WIDTH*RATIOY,d3

  asr.w            #2,d3

  move.w           d3,(a1)+

  addq             #1,d4
  dbra             d6,table_y_precalc_x

  addq             #1,d5
  dbra             d7,table_y_precalc_y
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

TEXTURE_DATA:
  dcb.b TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
TEXTURE_DATA_2:
  dcb.w TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
TEXTURE_DATA_3:
  dcb.b TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
TEXTURE_DATA_4:
  dcb.w TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
TRANSFORMATION_TABLE_DISTANCE:
  dcb.w SCREEN_RES_X*2*SCREEN_RES_Y*2,0
;---------------------------------------------------------------
Saveint:              dc.w 0
SaveDMA:              dc.w 0
SaveIRQ:              dc.l 0
Name:                 dc.b "graphics.library",0
  even

  include "blurryeffect.s"
  include "normaleffect.s"
  include "vshrink.s"
  include "vnormal.s"
  include "noeffect.s"
  include "sin.i"

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

COPLINES: dcb.l 4*64,0
  IFD   LOL
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

  ENDC

  ; Copperlist end
  dc.w       $FFFF,$FFFE                                               ; End of copperlist

  ;include P6112-options.i
  ;include P6112-Play.i
  ;include music_ptr_linkable2.s
  ;incbin tunnel.mod

BASSDRUM2:
  ;incbin bassdrum2.raw
LSPBank:  incbin tunnel.lsbank
LSPMusic:  incbin tunnel.lsmusic

  end

