TEXTURE_SIZE EQU 16

SCREEN_RES_X equ 64
SCREEN_RES_Y equ 64

TEXTURE_HEIGHT equ 16

RATIOX EQU 30


  ; Place addr in d0 and the copperlist pointer addr in a1 before calling
POINTINCOPPERLIST MACRO
  move.w              d0,6(a1)
  swap                d0
  move.w              d0,2(a1)
  ENDM
  jmp Inizio

  include "AProcessing/libs/rasterizers/globaloptions.s"
  include "AProcessing/libs/math/operations.s"

  SECTION             CiriCop,CODE_C

CURRENT_X:            dc.w      0
CURRENT_Y:            dc.w      0
FRAME_COUNTER:        dc.w      0

Inizio:
  bsr.w               Save_all

  lea                 $dff000,a6
  move                #$7ff,$96(a6)                                                  ;Disable DMAs
  move                #%1000011111100000,$96(a6)                                     ;Master,Copper,Blitter,Bitplanes
  move                #$7fff,$9a(a6)                                                 ;Disable IRQs
  move                #$e000,$9a(a6)                                                 ;Master and lev6
					;NO COPPER-IRQ!
  moveq               #0,d0
  move                d0,$106(a6)                                                    ;Disable AGA/ECS-stuff
  move                d0,$1fc(a6)

  move.l              #COPPERLIST,$80(a6)                                            ; Copperlist point
  move.w              d0,$88(a6)                                                     ; Copperlist start

  move.w              d0,$1fc(a6)                                                    ; FMODE - NO AGA
  move.w              #$c00,$106(a6)                                                 ; BPLCON3 - NO AGA

  jsr GENERATE_TRANSFORMATION_TABLE

; START OF MAIN LOOP
mouse:
  cmpi.b              #$ff,$dff006                                                   ; Siamo alla linea 255?
  ;bne.s               mouse                                                          ; Se non ancora, non andare avanti
;.loop; Wait for vblank
;	move.l $dff004,d0
;	and.l #$1ff00,d0
;	cmp.l #303<<8,d0
;	bne.b .loop


Aspetta:
  cmpi.b            #$ff,$dff006                                                   ; Siamo alla linea 255?
  ;beq.s             Aspetta
  
  neg.l             SCREEN_OFFSET
  move.l            SCREEN_OFFSET,d1
  move.l            SCREEN_PTR_0,SCREEN_PTR_OTHER_0
  move.l            SCREEN_PTR_1,SCREEN_PTR_OTHER_1
  add.l             d1,SCREEN_PTR_0
  add.l             d1,SCREEN_PTR_1  
  
  move.w #$F00,$dff180

  lea       TEXTURE_DATA,a2
  clr.w     CURRENT_X
  clr.w     CURRENT_Y

  ; y cycle start
  moveq     #TEXTURE_SIZE-1,d7
xor_texture_y:

; x cycle start
  moveq     #TEXTURE_SIZE-1,d6
xor_texture_x:

  move.w            CURRENT_X,d0
	move.w            CURRENT_Y,d1

  ; execute eor
  move.w    d0,d5
  eor.w     d1,d5

  ; if d7 > 127 color is 1
  IF_1_LESS_EQ_2_W_U #TEXTURE_SIZE/2,d5,.notgreater,s
  STROKE #1
  clr.w (a2)+
  bra.s .printpoint
.notgreater:
  STROKE #2
  move.w #$FFFF,(a2)+
.printpoint
	jsr               POINT
  addi.w            #1,CURRENT_X
  dbra              d6,xor_texture_x
  clr.w             CURRENT_X
  addi.w            #1,CURRENT_Y
  dbra              d7,xor_texture_y
  move.w #$0F0,$dff180

  ; star drawing the tunnel
  ;bra.w     tunnelend
  lea       TEXTURE_DATA,a2
    lea      TRANSFORMATION_TABLE_DISTANCE,a3

  DEBUG  7777
  clr.w     CURRENT_X
  clr.w     CURRENT_Y

  ; y cycle start
  moveq     #SCREEN_RES_Y-1,d7
tunnel_y:

; x cycle start
  moveq     #SCREEN_RES_X-1,d6
tunnel_x:

  move.w    CURRENT_X,d0
	move.w    CURRENT_Y,d1

  ; read transformation table
  move.w    (a3)+,d2

  ; add shift x

  add.w    FRAME_COUNTER,d2
  andi.w   #$F,d2

  ; mult by 2 because each point on the texture is represented by 2 bytes
  lsl.w     #1,d2

  ; read pixel [d1][d2]
  
  move.w    d1,d4
  andi.w    #$F,d4 ; module %16
  ;mulu      #TEXTURE_HEIGHT*2,d4 ; d4 holds y offset
  lsl.w      #5,d4
  
  add.w     d2,d4
  ;DEBUG 1234

  move.w    0(a2,d4.w),d3
  tst.w d3
  beq.s     tunnel_pixel_0
  STROKE #2
  bra.s     print_tunnel_pixel
tunnel_pixel_0:
  DEBUG 4321
  STROKE #1

print_tunnel_pixel:
  move.w    CURRENT_X,d0
	move.w    CURRENT_Y,d1
  add.w #100,d0
  add.w #100,d1
  jsr               POINT_FORCE


  addi.w    #1,CURRENT_X
  dbra      d6,tunnel_x
  clr.w     CURRENT_X
  addi.w    #1,CURRENT_Y
  dbra      d7,tunnel_y

tunnelend:
    move.w #$000,$dff180


  

  lea               BPLPTR1,a1
  move.l            SCREEN_PTR_0,d0
  POINTINCOPPERLIST

  lea               BPLPTR2,a1
  move.l            SCREEN_PTR_1,d0
  POINTINCOPPERLIST


  add.w             #1,FRAME_COUNTER

  btst              #6,$bfe001                                                     ; tasto sinistro del mouse premuto?
  bne.w             mouse                                                          ; se no, torna a mouse:
exit_demo:
  bsr.w               Restore_all
  clr.l               d0
  rts                                                                                ; USCITA DAL PROGRAMMA
GENERATE_TRANSFORMATION_TABLE:
  * var distance = int(currentSliderRatioXValue * texHeight / dist(x,y,width/2,height/2)) % texHeight;

  lea      TRANSFORMATION_TABLE_DISTANCE,a0

    ; init x (d0) and y (d0)
    move.w  #SCREEN_RES_X,d0
    lsr.w   #1,d0
    neg.w   d0
    move.w  #SCREEN_RES_Y,d1
    lsr.w   #1,d1
    neg.w   d1

    ; first cycle - for each Y
    moveq   #SCREEN_RES_Y-1,d7
table_precalc_y:

    ; second cycle - for each X
    moveq   #SCREEN_RES_X-1,d6
table_precalc_x:

    move.w  d0,d2
    move.w  d1,d3

    muls    d2,d2
    muls    d3,d3

    add.w   d2,d3

    ; start sqrt execution
    move.w  #-1,d5
qsqrt1:
    addq    #2,d5
    sub.w   d5,d3
    bpl     qsqrt1
    asr.w   #1,d5
    move.w  d5,d3
    ; end sqrt execution

    ; if distance is zero let's say distance is 1
    bne.s   distanceok
    moveq   #1,d3
distanceok:
    ; divide per texture height
    move.l  #256*RATIOX*TEXTURE_HEIGHT,d2
    tst.w   d3
    bne.s   nodistancezero
    nop
nodistancezero:
    divu    d3,d2

    ; get integer part
    lsr.w   #8,d2

    ;get the module
    ext.l   d2
    divu    #TEXTURE_HEIGHT,d2
    swap    d2

    ; write into transformation table
    move.w  d2,(a0)+
    DEBUG 7777

    addq    #1,d0 ; increment x
    dbra    d6,table_precalc_x ; next x iteration

    addq    #1,d1 ; increment y
    ;clr.w   d0 ; reset x
    ;dream
    move.w  #SCREEN_RES_X/2*-1,d0
    dbra    d7,table_precalc_y


    rts

POINTINCOPPERLIST_FUNCT:
  POINTINCOPPERLIST
  rts

POINT_FORCE:

  bsr.w                                    point_execute_transformation

	; start plot routine
  lea                                      PLOTREFS,a1
  add.w                                    d1,d1
  move.w                                   0(a1,d1.w),d1
  move.w                                   d0,d4
  lsr.w                                    #3,d4
  add.w                                    d4,d1
  not.b                                    d0
  btst.b                                   #0,STROKE_DATA
  beq.s                                    point_force_no_bpl_0
  SETBITPLANE                              0,a0
  bset                                     d0,(a0,d1.w)
  bra.s                                    point_force_no_bpl_00
point_force_no_bpl_0:
  SETBITPLANE                              0,a0
  bclr                                     d0,(a0,d1.w)
point_force_no_bpl_00:
  btst.b                                   #1,STROKE_DATA
  beq.s                                    point_force_no_bpl_1
  SETBITPLANE                              1,a0
  bset                                     d0,(a0,d1.w)
  rts
point_force_no_bpl_1:
  SETBITPLANE                              1,a0
  bclr                                     d0,(a0,d1.w)
  rts

;---------------------------------------------------------------
Save_all:
  move.b              #$87,$bfd100                                                   ; stop drive
  move.l              $00000004,a6
  jsr                 -132(a6)
  move.l              $6c,SaveIRQ
  move.w              $dff01c,Saveint
  or.w                #$c000,Saveint
  move.w              $dff002,SaveDMA
  or.w                #$8100,SaveDMA

  move.l	4.w,a6		; ExecBase in A6
  JSR	-$84(a6)	; FORBID - Disabilita il Multitasking
  JSR	-$78(A6)	; DISABLE - Disabilita anche gli interrupt
				;	    del sistema operativo
  ; set new intena
  MOVE.L	#$7FFF7FFF,$dff09A	; DISABILITA GLI INTERRUPTS & INTREQS

  rts
Restore_all:
  move.l              SaveIRQ,$6c
  move.w              #$7fff,$dff09a
  move.w              Saveint,$dff09a
  move.w              #$7fff,$dff096
  move.w              SaveDMA,$dff096
  move.l              $00000004,a6
  lea                 Name,a1
  moveq               #0,d0
  jsr                 -552(a6)
  move.l              d0,a0
  move.l              38(a0),$dff080
  clr.w               $dff088
  move.l              d0,a1
  jsr                 -414(a6)
  jsr                 -138(a6)
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

; Sprites pointer init
SpritePointers:
Sprite0pointers:
  dc.w       $120,$0000,$122,$0000

Sprite1pointers:
  dc.w       $124,$0000,$126,$0000

Sprite2pointers:
  dc.w       $128,$0000,$12a,$0000

Sprite3pointers:
  dc.w       $12c,$0000,$12e,$0000

Sprite4pointers:
  dc.w       $130,$0000,$132,$0000

Sprite5pointers:
  dc.w       $134,$0000,$136,$0000

Sprite6pointers;
  dc.w       $138,$0000,$13a,$0000

Sprite7pointers:
  dc.w       $13c,$0000,$13e,$0000

; other stuff
  dc.w       $8e,$2c81                                                 ; DiwStrt	(registri con valori normali)
  dc.w       $90,$2cc1                                                 ; DiwStop
  dc.w       $92,$0038                                                 ; DdfStart
  dc.w       $94,$00d0                                                 ; DdfStop
  dc.w       $102,0

  dc.w	$0180,$000	; color0 - SFONDO
	dc.w	$0182,$f00	; color1 - SCRITTE
	dc.w	$0184,$0f0	; color2 - SCRITTE
	dc.w	$0186,$00f	; color3 - SCRITTE
  dc.w  $104,$0000

  dc.w       $108,0                                                    ; Bpl1Mod
  dc.w       $10a,0

  COPSET2BPL

; Bitplanes Pointers
BPLPTR1:
  dc.w       $e0,$0000,$e2,$0000                                       ;first	 bitplane - BPL0PT
BPLPTR2:
  dc.w       $e4,$0000,$e6,$0000                                       ;second bitplane - BPL1PT
BPLPTR3:
  dc.w       $e8,$0000,$ea,$0000                                       ;third	 bitplane - BPL2PT
BPLPTR4:
  dc.w       $ec,$0000,$ee,$0000                                       ;fourth bitplane - BPL3PT
BPLPTR5:
  dc.w       $f0,$0000,$f2,$0000                                       ;fifth	 bitplane - BPL4PT

  ; Copperlist end
  dc.w       $FFFF,$FFFE                                               ; End of copperlist

  end

