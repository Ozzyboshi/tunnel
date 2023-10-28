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