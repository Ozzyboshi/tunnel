; please use only a3 a5 d7

VNORMALDELAY: dc.w 0
VNORMALYCOUNTER: dc.w 0
VNORMALADDR: dc.l 0

VNORMAL:
    cmp.w #100,VNORMALDELAY
    beq.s proceedwithVNORMAL
    addi.w #1,VNORMALDELAY
    rts
proceedwithVNORMAL:
    
    IF_1_GREATER_EQ_2_W_U #SCREEN_RES_Y,VNORMALYCOUNTER,endVNORMAL,s
    addi.w #1,VNORMALYCOUNTER
    move.l VNORMALADDR(PC),a5
    cmp.l #0,a5
    bne.s  VNORMALnoinit
    lea COPLINES+6,a5
VNORMALnoinit:
    move.w #-40,(a5)
    add.l #16,a5
    move.l             a5,VNORMALADDR
    rts
endVNORMAL:
    move.l  #BLURRYTUNNEL,EFFECT_FUNCTION
    move.w  #0,VNORMALYCOUNTER
    move.w  #0,VNORMALDELAY
    move.l  #0,VNORMALADDR
    rts