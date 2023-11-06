; please use only a3 a5 d7

NORMALTUNNELDELAY: dc.w 0
NORMALTUNNELYCOUNTER: dc.w 0
NORMALTUNNELADDR: dc.l 0

NORMALTUNNEL:
    cmp.w #100,NORMALTUNNELDELAY
    beq.s proceedwithNORMALtunnel
    addi.w #1,NORMALTUNNELDELAY
    rts
proceedwithNORMALtunnel:
    
    IF_1_GREATER_EQ_2_W_U #SCREEN_RES_Y*3,NORMALTUNNELYCOUNTER,endNORMAL,s
    addi.w #1,NORMALTUNNELYCOUNTER
    move.l NORMALTUNNELADDR(PC),a5
    cmp.l #0,a5
    bne.s  NORMALtunnelnoinit
    SETBITPLANE       0,a5
NORMALtunnelnoinit:
    move.l #0,(a5)+
    rept 8
    move.l             #$FFFFFFFF,(a5)+
    endr
    move.l             #0,(a5)+
    move.l             a5,NORMALTUNNELADDR
    rts
endNORMAL:
    move.l  #VSHRINK,EFFECT_FUNCTION
    move.w  #0,NORMALTUNNELYCOUNTER
    move.w  #0,NORMALTUNNELDELAY
    move.l  #0,NORMALTUNNELADDR
    rts