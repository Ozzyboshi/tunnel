; please use only a3 a5 d7

VSHRINKDELAY: dc.w 0
VSHRINKYCOUNTER: dc.w 0
VSHRINKADDR: dc.l 0

VSHRINK:
    cmp.w #100,VSHRINKDELAY
    beq.s proceedwithVSHRINK
    addi.w #1,VSHRINKDELAY
    rts
proceedwithVSHRINK:
    
    IF_1_GREATER_EQ_2_W_U #SCREEN_RES_Y,VSHRINKYCOUNTER,endVSHRINK,s
    addi.w #1,VSHRINKYCOUNTER
    move.l VSHRINKADDR(PC),a5
    cmp.l #0,a5
    bne.s  VSHRINKnoinit
    lea COPLINES+6,a5
VSHRINKnoinit:
    move.w #0,(a5)
    add.l #16,a5
    move.l             a5,VSHRINKADDR
    rts
endVSHRINK:
    move.l  #VNORMAL,EFFECT_FUNCTION
    move.w  #0,VSHRINKYCOUNTER
    move.w  #0,VSHRINKDELAY
    move.l  #0,VSHRINKADDR
    rts