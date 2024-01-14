;----------------------------------------------------------------------------
;
; Generated with Aklang2Asm V1.1, by Dan/Lemon. 2021-2022.
;
; Based on Alcatraz Amigaklang rendering core. (c) Jochen 'Virgill' Feldkötter 2020.
;
; What's new in V1.1?
; - Instance offsets fixed in ADSR operator
; - Incorrect shift direction fixed in OnePoleFilter operator
; - Loop Generator now correctly interleaved with instrument generation
; - Fine progress includes loop generation, and new AK_FINE_PROGRESS_LEN added
; - Reverb large buffer instance offsets were wrong, causing potential buffer overrun
;
; Call 'AK_Generate' with the following registers set:
; a0 = Sample Buffer Start Address
; a1 = 0 Bytes Temporary Work Buffer Address (can be freed after sample rendering complete)
; a2 = External Samples Address (need not be in chip memory, and can be freed after sample rendering complete)
; a3 = Rendering Progress Address (2 modes available... see below)
;
; AK_FINE_PROGRESS equ 0 = rendering progress as a byte (current instrument number)
; AK_FINE_PROGRESS equ 1 = rendering progress as a long (current sample byte)
;
;----------------------------------------------------------------------------

AK_USE_PROGRESS			equ 0
AK_FINE_PROGRESS		equ 1
AK_FINE_PROGRESS_LEN	equ 20638
AK_SMP_LEN				equ 16542
AK_EXT_SMP_LEN			equ 0

AK_Generate:

				lea		AK_Vars(pc),a5

				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						move.b	#-1,(a3)
					else
						move.l	#0,(a3)
					endif
				endif

				; Create sample & external sample base addresses
				lea		AK_SmpLen(a5),a6
				lea		AK_SmpAddr(a5),a4
				move.l	a0,d0
				moveq	#31-1,d7
.SmpAdrLoop		move.l	d0,(a4)+
				add.l	(a6)+,d0
				dbra	d7,.SmpAdrLoop
				move.l	a2,d0
				moveq	#8-1,d7
.ExtSmpAdrLoop	move.l	d0,(a4)+
				add.l	(a6)+,d0
				dbra	d7,.ExtSmpAdrLoop

;----------------------------------------------------------------------------
; Instrument 1 - DrumBass
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst1Loop
				; v1 = osc_tri(0, 300, 74)
				add.w	#300,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0
				bge.s	.TriNoInvert_1_1
				not.w	d0
.TriNoInvert_1_1
				sub.w	#16384,d0
				add.w	d0,d0
				muls	#74,d0
				asr.l	#7,d0

				; v2 = osc_sine(1, 308, 57)
				add.w	#308,AK_OpInstance+2(a5)
				move.w	AK_OpInstance+2(a5),d1
				sub.w	#16384,d1
				move.w	d1,d5
				bge.s	.SineNoAbs_1_2
				neg.w	d5
.SineNoAbs_1_2
				move.w	#32767,d6
				sub.w	d5,d6
				muls	d6,d1
				swap	d1
				asl.w	#3,d1
				muls	#57,d1
				asr.l	#7,d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_1_3
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_1_3

				; v3 = envd(3, 13, 0, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d2
				swap	d2
				sub.l	#381184,d5
				bgt.s   .EnvDNoSustain_1_4
				moveq	#0,d5
.EnvDNoSustain_1_4
				move.l	d5,AK_EnvDValue+0(a5)

				; v1 = mul(v1, v3)
				muls	d2,d0
				add.l	d0,d0
				swap	d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+0(a5),d7
				blt		.Inst1Loop

;----------------------------------------------------------------------------
; Instrument 2 - colombia_lead_high
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst2Loop
				; v1 = osc_tri(0, 2000, 92)
				add.w	#2000,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0
				bge.s	.TriNoInvert_2_1
				not.w	d0
.TriNoInvert_2_1
				sub.w	#16384,d0
				add.w	d0,d0
				muls	#92,d0
				asr.l	#7,d0

				; v2 = osc_tri(1, 2014, 92)
				add.w	#2014,AK_OpInstance+2(a5)
				move.w	AK_OpInstance+2(a5),d1
				bge.s	.TriNoInvert_2_2
				not.w	d1
.TriNoInvert_2_2
				sub.w	#16384,d1
				add.w	d1,d1
				muls	#92,d1
				asr.l	#7,d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_2_3
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_2_3

				; v2 = osc_saw(3, 4000, 72)
				add.w	#4000,AK_OpInstance+4(a5)
				move.w	AK_OpInstance+4(a5),d1
				muls	#72,d1
				asr.l	#7,d1

				; v1 = add(v1, v2)
				add.w	d1,d0
				bvc.s	.AddNoClamp_2_5
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_2_5

				; v2 = envd(5, 8, 0, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#931840,d5
				bgt.s   .EnvDNoSustain_2_6
				moveq	#0,d5
.EnvDNoSustain_2_6
				move.l	d5,AK_EnvDValue+0(a5)

				; v2 = mul(v2, 64)
				muls	#64,d1
				add.l	d1,d1
				swap	d1

				; v2 = add(v2, 10)
				add.w	#10,d1
				bvc.s	.AddNoClamp_2_8
				spl		d1
				ext.w	d1
				eor.w	#$7fff,d1
.AddNoClamp_2_8

				; v1 = sv_flt_n(8, v1, v2, 127, 2)
				move.w	AK_OpInstance+AK_BPF+6(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	d1,d5
				move.w	AK_OpInstance+AK_LPF+6(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_2_9
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_2_9
				move.w	d4,AK_OpInstance+AK_LPF+6(a5)
				muls	#127,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_2_9
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_2_9
.NoClampMaxHPF_2_9
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_2_9
				move.w	#-32768,d5
.NoClampMinHPF_2_9
				move.w	d5,AK_OpInstance+AK_HPF+6(a5)
				asr.w	#7,d5
				muls	d1,d5
				add.w	AK_OpInstance+AK_BPF+6(a5),d5
				bvc.s	.NoClampBPF_2_9
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_2_9
				move.w	d5,AK_OpInstance+AK_BPF+6(a5)
				move.w	d5,d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+4(a5),d7
				blt		.Inst2Loop

				movem.l a0-a1,-(sp)	;Stash sample base address & large buffer address for loop generator

;----------------------------------------------------------------------------
; Instrument 2 - Loop Generator (Offset: 4096 Length: 4096
;----------------------------------------------------------------------------

				move.l	#4096,d7
				move.l	AK_SmpAddr+4(a5),a0
				lea		4096(a0),a0
				move.l	a0,a1
				sub.l	d7,a1
				moveq	#0,d4
				move.l	#32767<<8,d5
				move.l	d5,d0
				divs	d7,d0
				bvc.s	.LoopGenVC_1
				moveq	#0,d0
.LoopGenVC_1
				moveq	#0,d6
				move.w	d0,d6
.LoopGen_1
				move.l	d4,d2
				asr.l	#8,d2
				move.l	d5,d3
				asr.l	#8,d3
				move.b	(a0),d0
				move.b	(a1)+,d1
				ext.w	d0
				ext.w	d1
				muls	d3,d0
				muls	d2,d1
				add.l	d1,d0
				add.l	d0,d0
				swap	d0
				move.b	d0,(a0)+
				add.l	d6,d4
				sub.l	d6,d5

				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif

				subq.l	#1,d7
				bne.s	.LoopGen_1

				movem.l (sp)+,a0-a1	;Restore sample base address & large buffer address after loop generator


;----------------------------------------------------------------------------

				; Clear first 2 bytes of each sample
				lea		AK_SmpAddr(a5),a6
				moveq	#0,d0
				moveq	#31-1,d7
.SmpClrLoop		move.l	(a6)+,a4
				move.b	d0,(a4)+
				move.b	d0,(a4)+
				dbra	d7,.SmpClrLoop

				rts

;----------------------------------------------------------------------------

AK_ResetVars:
				moveq   #0,d1
				moveq   #0,d2
				moveq   #0,d3
				moveq   #0,d0
				lea		AK_OpInstance(a5),a6
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l  #32767<<16,(a6)+
				rts

;----------------------------------------------------------------------------

				rsreset
AK_LPF			rs.w	1
AK_HPF			rs.w	1
AK_BPF			rs.w	1
				rsreset
AK_CHORD1		rs.l	1
AK_CHORD2		rs.l	1
AK_CHORD3		rs.l	1
				rsreset
AK_SmpLen		rs.l	31
AK_ExtSmpLen	rs.l	8
AK_SmpAddr		rs.l	31
AK_ExtSmpAddr	rs.l	8
AK_OpInstance	rs.w    6
AK_EnvDValue	rs.l	1
AK_VarSize		rs.w	0

AK_Vars:
				dc.l	$0000209e		; Instrument 1 Length 
				dc.l	$00002000		; Instrument 2 Length 
				dc.l	$00000000		; Instrument 3 Length 
				dc.l	$00000000		; Instrument 4 Length 
				dc.l	$00000000		; Instrument 5 Length 
				dc.l	$00000000		; Instrument 6 Length 
				dc.l	$00000000		; Instrument 7 Length 
				dc.l	$00000000		; Instrument 8 Length 
				dc.l	$00000000		; Instrument 9 Length 
				dc.l	$00000000		; Instrument 10 Length 
				dc.l	$00000000		; Instrument 11 Length 
				dc.l	$00000000		; Instrument 12 Length 
				dc.l	$00000000		; Instrument 13 Length 
				dc.l	$00000000		; Instrument 14 Length 
				dc.l	$00000000		; Instrument 15 Length 
				dc.l	$00000000		; Instrument 16 Length 
				dc.l	$00000000		; Instrument 17 Length 
				dc.l	$00000000		; Instrument 18 Length 
				dc.l	$00000000		; Instrument 19 Length 
				dc.l	$00000000		; Instrument 20 Length 
				dc.l	$00000000		; Instrument 21 Length 
				dc.l	$00000000		; Instrument 22 Length 
				dc.l	$00000000		; Instrument 23 Length 
				dc.l	$00000000		; Instrument 24 Length 
				dc.l	$00000000		; Instrument 25 Length 
				dc.l	$00000000		; Instrument 26 Length 
				dc.l	$00000000		; Instrument 27 Length 
				dc.l	$00000000		; Instrument 28 Length 
				dc.l	$00000000		; Instrument 29 Length 
				dc.l	$00000000		; Instrument 30 Length 
				dc.l	$00000000		; Instrument 31 Length 
				dc.l	$00000000		; External Sample 1 Length 
				dc.l	$00000000		; External Sample 2 Length 
				dc.l	$00000000		; External Sample 3 Length 
				dc.l	$00000000		; External Sample 4 Length 
				dc.l	$00000000		; External Sample 5 Length 
				dc.l	$00000000		; External Sample 6 Length 
				dc.l	$00000000		; External Sample 7 Length 
				dc.l	$00000000		; External Sample 8 Length 
				ds.b	AK_VarSize-AK_SmpAddr

;----------------------------------------------------------------------------
