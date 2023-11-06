; please use only a3 a5 d7

BLURRYTUNNELDELAY: dc.w 0
BLURRYTUNNELYCOUNTER: dc.w 0
BLURRYTUNNELADDR: dc.l 0

BLURRYTUNNEL:
    cmp.w #100,BLURRYTUNNELDELAY
    beq.s proceedwithblurrytunnel
    addi.w #1,BLURRYTUNNELDELAY
    rts
proceedwithblurrytunnel:
    
    IF_1_GREATER_EQ_2_W_U #SCREEN_RES_Y*3,BLURRYTUNNELYCOUNTER,endblurry,s
    addi.w #1,BLURRYTUNNELYCOUNTER
    move.l BLURRYTUNNELADDR(PC),a5
    cmp.l #0,a5
    bne.s  blurrytunnelnoinit
    SETBITPLANE       0,a5
blurrytunnelnoinit:
    move.l #0,(a5)+
    rept 8
    move.l             #%10101010101010101010101010101010,(a5)+
    endr
    move.l             #0,(a5)+
    move.l             a5,BLURRYTUNNELADDR
    rts
endblurry:
    move.l  #NORMALTUNNEL,EFFECT_FUNCTION
    move.w  #0,BLURRYTUNNELYCOUNTER
    move.w  #0,BLURRYTUNNELDELAY
    move.l  #0,BLURRYTUNNELADDR
    rts