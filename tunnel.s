TEXTURE_SIZE EQU 16

SCREEN_RES_X equ 64
SCREEN_RES_Y equ 64

TEXTURE_HEIGHT equ 16

RATIOX EQU 30


  ; Place addr in d0 and the copperlist pointer addr in a1 before calling
POINTINCOPPERLIST MACRO
  move.w              d5,6(a1)
  swap                d5
  move.w              d5,2(a1)
  ENDM
  jmp Inizio

  include "AProcessing/libs/rasterizers/globaloptions.s"
  include "AProcessing/libs/math/operations.s"

  SECTION             CiriCop,CODE_C

CURRENT_X:            dc.w      0
CURRENT_Y:            dc.w      0
;FRAME_COUNTER:        dc.w      0

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

  ; START preparing bitplane 0, set FF in every byte where the tunnel will be drown
  SETBITPLANE       0,a6
  ; y cycle start
  move.w             #SCREEN_RES_Y*3-1,d7
tunnel_y_prepare:

; x cycle start
  moveq             #SCREEN_RES_X/4-1,d6
tunnel_x_prepare:
  move.w            #$FFFF,(a6)+
  dbra              d6,tunnel_x_prepare

  ; change scanline
  lea               8+40*0(a6),a6

  dbra              d7,tunnel_y_prepare
  ; END preparing bitplane 0, set FF in every byte where the tunnel will be drown

  ; Set bpl zero in copperlist
  lea               BPLPTR1,a1
  move.l            SCREEN_PTR_0,d5
  POINTINCOPPERLIST

  ; Generate transformation table for distance
  jsr               GENERATE_TRANSFORMATION_TABLE

  ; Set colors
  move.w            #$222,$dff180
  move.w            #$F00,$dff182
  move.w            #$0F0,$dff184
  move.w            #$00F,$dff186

  ; Generate XOR texture (16px X 16px)
  jsr               XOR_TEXTURE

  moveq             #0,d3 ; reset current time variable


; ******************************* START OF GAME LOOP ****************************
mouse:
  cmpi.b              #$ff,$dff006                                                   ; Are we at line 255?
  bne.s               mouse                                                          ; Wait
;.loop; Wait for vblank
;	move.l $dff004,d0
;	and.l #$1ff00,d0
;	cmp.l #303<<8,d0
;	bne.b .loop


Aspetta:
  cmpi.b            #$ff,$dff006                                                    ; Wait for exiting line 255
  beq.s             Aspetta

  ;bra.w tunnelend  ; skip tunnel rendering
  
  ; Switch Bitplanes for double buffering
  neg.l             SCREEN_OFFSET
  move.l            SCREEN_OFFSET,d5
  ;move.l            SCREEN_PTR_0,SCREEN_PTR_OTHER_0
  move.l            SCREEN_PTR_1,SCREEN_PTR_OTHER_1
  ;add.l             d5,SCREEN_PTR_0
  add.l             d5,SCREEN_PTR_1
  
  IFD COLORDEBUG
  move.w #$FF0,$dff180
  ENDC

  
  ;bra.w     tunnelend

  ; *********************************** Start of tunnel rendering *********************************
  lea               TEXTURE_DATA(PC),a2
  lea               TRANSFORMATION_TABLE_DISTANCE(PC),a3
  lea	              TRASFORMATION_TABLE_Y(PC),a4


  ;SETBITPLANE       0,a6
  SETBITPLANE       1,a5
  ;move.l  SCREEN_PTR_0,a6
  moveq             #$1e,d5

  ; y cycle start
  moveq              #SCREEN_RES_Y-1,d7
  ;moveq             #28,d7
tunnel_y:

; x cycle start
  moveq             #SCREEN_RES_X/4-1,d6
tunnel_x:

  ; start first pixel
  ; read transformation table (distance table)
  move.w            (a3)+,d2

  ; read transformation table (rotation table)
  move.w            (a4)+,d4

  ; add shift x (add frame counter to what was read from the distance table and perform a %16)
  ;add.w             FRAME_COUNTER,d2
  ; frame counter is on the upper part of d7 to save access memory
  add.w             d3,d2
  and.w             d5,d2

  ; now d4 holds the correct offset of the table in the lower word
  add.w             d2,d4

  moveq             #$0,d1

  tst.w             0(a2,d4.w) ; check if we have to print color 1 or color 2
  beq.s             pixel_1_done ; if color 1 has to be printed on screen

  move.w            #$F000,d1

pixel_1_done:

  ; pixel 2 start
  move.w            (a3)+,d2
  move.w            (a4)+,d4
  add.w             d3,d2
  and.w             d5,d2
  add.w             d2,d4
  tst.w             0(a2,d4.w)
  beq.s             pixel_2_done
  ori.w             #$0F00,d1
pixel_2_done:

; pixel 3 start
  move.w            (a3)+,d2
  move.w            (a4)+,d4
  add.w             d3,d2
  and.w             d5,d2
  add.w             d2,d4
  tst.w             0(a2,d4.w)
  beq.s             pixel_3_done
printcolor3_even:
  ori.w             #$00F0,d1
pixel_3_done:

; start of pixel 4
  move.w            (a3)+,d2
  move.w            (a4)+,d4
  add.w             d3,d2
  and.w             d5,d2
  add.w             d2,d4
  tst.w             0(a2,d4.w)
  beq.s             pixel_4_done
  ori.w             #$F,d1
pixel_4_done:

print_pixel:
  move.w            d1,(a5)+

  dbra              d6,tunnel_x

  ; change scanline
  lea               8+40*2(a5),a5
  ;lea               8+40*2(a6),a6

  dbra              d7,tunnel_y
tunnelend:

  IFD COLORDEBUG
  move.w            #$000,$dff180
  ENDC

  ; load bitplanes in copperlist

  lea               BPLPTR2,a1
  move.l            SCREEN_PTR_1,d5
  POINTINCOPPERLIST

  ; increment the frame counter for animating
  ;add.w             #1,FRAME_COUNTER
  addq               #1,d3

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
  clr.w             (a2)+
  bra.s             .printpoint
.notgreater:
  ;STROKE #2
  move.w            #$FFFF,(a2)+
.printpoint
	;jsr               POINT
  addi.w            #1,CURRENT_X
  dbra              d6,xor_texture_x
  clr.w             CURRENT_X
  addi.w            #1,CURRENT_Y
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
GENERATE_TRANSFORMATION_TABLE:
  lea               TRANSFORMATION_TABLE_DISTANCE(PC),a0

  ; init x (d0) and y (d1) , for convenience instead starting from 0, we start from -SCREEN_RES_X/2 and we and
  ; at SCREEN_RES/2, same for the Y axys
  move.w            #SCREEN_RES_X/2*-1,d0
  move.w            #SCREEN_RES_Y/2*-1,d1

  ; first cycle - for each Y
  moveq             #SCREEN_RES_Y-1,d7
table_precalc_y:

  ; second cycle - for each X
  moveq             #SCREEN_RES_X-1,d6
table_precalc_x:

  move.w            d0,d2
  move.w            d1,d3

  muls              d2,d2
  muls              d3,d3

  add.w             d2,d3

  ; now d3 hold the result of (x - width / 2.0) * (x - width / 2.0) + (y - height / 2.0) * (y - height / 2.0)
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

  ; here d3 holds sqrt(distance)

  ; sanity check, distance could be zero, we dont want to divide by zero, m68k doesnt like it
  ; if distance is zero let's say distance is 1
  bne.s             distanceok
  moveq             #1,d3
distanceok:

  ; start executing the following C code: int inverse_distance = (int) (RATIOX * texHeight / distance);
  ; divide per texture height
  move.l            #256*RATIOX*TEXTURE_HEIGHT,d2
  divu              d3,d2

  ; get integer part
  lsr.w             #8,d2

  ;get the module
  ext.l             d2
  divu              #TEXTURE_HEIGHT,d2
  swap              d2

  ; write into transformation table
  move.w            d2,(a0)+

  addq              #1,d0 ; increment x
  dbra              d6,table_precalc_x ; next x iteration

  addq              #1,d1 ; increment y
  ;clr.w            d0 ; reset x
  ;dream
  move.w            #SCREEN_RES_X/2*-1,d0
  dbra              d7,table_precalc_y

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
  dcb.w TEXTURE_HEIGHT*TEXTURE_HEIGHT,0

;---------------------------------------------------------------
Saveint:              dc.w 0
SaveDMA:              dc.w 0
SaveIRQ:              dc.l 0
Name:                 dc.b "graphics.library",0
  even

TRASFORMATION_TABLE_Y:
	include "transformationtableY2.raw"

	include "AProcessing/libs/matrix/matrixcommon.s"
	include "AProcessing/libs/matrix/matrix.s"
	include "AProcessing/libs/matrix/point.s"
	include "AProcessing/libs/rasterizers/point.s"
	include "AProcessing/libs/rasterizers/processing_bitplanes_fast.s"
	include "AProcessing/libs/rasterizers/processing_table_plotrefs.s"

;----------------------------------------------------------------

; **************************************************************************
; *				SUPER COPPERLIST			   *
; **************************************************************************

; Single playfield mode
COPSET2BPL MACRO
  dc.w       $100
  dc.w       %0010001000000000
  ENDM

COPSET3BPL MACRO
  dc.w       $100
  dc.w       %0011001000000000
  ENDM

; Double playfield modes
COPSET23BPL MACRO
  dc.w       $100
  dc.w       $5600
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

  ; Copperlist end
  dc.w       $FFFF,$FFFE                                               ; End of copperlist

  end

