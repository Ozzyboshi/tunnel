GENERATE_TRANSFORMATION_TABLE_SIMPLE:
  lea               TRANSFORMATION_TABLE_DISTANCE(PC),a0

  ; init x (d0) and y (d1) , for convenience instead starting from 0, we start from -SCREEN_RES_X/2 and we end
  ; at SCREEN_RES/2, same for the Y axys
  move.w            #SCREEN_RES_X/2*-1,d0
  move.w            #SCREEN_RES_Y/2*-1,d1

  ; first cycle - for each Y
  moveq             #SCREEN_RES_Y-1,d7
table_precalc_y:

  ; second cycle - for each X
  moveq             #SCREEN_RES_X-1,d6
table_precalc_x:

  ; need to save d0 (x) and d1 (y) to preserve their value
  move.w            d0,d2
  move.w            d1,d3

  ;asr.w #5,d2
  ;asr.w #5,d3

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
  DEBUG 1111
  move.w            d2,(a0)+

  addq              #1,d0 ; increment x
  dbra              d6,table_precalc_x ; next x iteration

  addq              #1,d1 ; increment y
  ;clr.w            d0 ; reset x
  ;dream
  move.w            #SCREEN_RES_X/2*-1,d0
  dbra              d7,table_precalc_y

  rts