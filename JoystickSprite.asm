Mode				equ &bc0e
CLS				equ &bc14
PrintChar		equ &bb5a
WaitChar			equ &bb06
Ink				equ &bc32 ;(a,b,c)
Border			equ &bc38 ;(b,c)
Pen				equ &bb90 ;(in: A=foreground color 0..15)
Fill				equ &bc44 
TextCursor		equ &bb75 ;(h=x,l=y,a=rollcount)
MoveCursor		equ &bb8a ;(h=x,l=y)
ScrNextLine 		equ &BC26	;out: HL=HL+800h, or HL=HL+50h-3800h (or so)
ScrDotPosition 	equ &BC1D ;in: DE=x, HL=y, out: HL=vram addr, C=mask, DE, B
WaitFlyback		equ &BD19 ;wait until/unless PIO.Port B bit0=1 (vsync)
ReadKey	 		equ &bb1b
Linefrom			equ &bbf6  ;in: de=x, hl=y  ;\draw line from current coordinate
LineTo 			equ &bbf9  ;in: de=x, hl=y  ;/to specified target coordinate
SetOrigin	 	equ &bbc9  ;in: de=x, hl=y (also does MOVE 0,0)
GrPen			equ &bbde  ;in; a=ink color 

Black 			equ 0
Blue				equ 1
BrightBlue		equ 2
Red				equ 3
Magenta			equ 4
Mauve			equ 5
BrightRed		equ 6
Purple			equ 7
BrightMagenta		equ 8
Green			equ 9
Cyan				equ 10
SkyBlue			equ 11
Yellow			equ 12
White			equ 13
PastelBlue		equ 14
Orange			equ 15
Pink				equ 16
PastelMagenta		equ 17
BrightGreen		equ 18
SeaGreen			equ 19
BrightCyan		equ 20
Lime				equ 21
PastelGreen		equ 22
PastelCyan		equ 23
BrightYellow		equ 24
PastelYellow		equ 25
BrightWhite		equ 26

	org &1200			;Start of our program
	run &1200

;Setup
SetMode:
	ld a,0	; mode 0
	call Mode
	;ret
	
SetInks:
	;; setup inks 
	ld b,White
	ld c,White
	call Border
	ld a,0 		; background
	ld b,Black 	; black
	ld c,Black 
	call Ink
	ld a,1 		; text (ink 1)
	ld b,Orange
	ld c,Orange 
	ld a,2 		; flash text (ink 2)
	ld b,BrightRed
	ld c,BrightYellow 
	call Ink
	;; ship inks
	call Ink
	ld a,15 	; main body (ink 15)
	ld b,BrightWhite
	ld c,BrightWhite 
	call Ink
	ld a,14 	; stripe (ink 14)
	ld b,BrightRed
	ld c,BrightRed
	call Ink
	ld a,10 	; canopy (ink 10)
	ld b,PastelBlue
	ld c,PastelBlue
	call Ink
	ld a,4 		; outline (ink 4)
	ld b,White
	ld c,White
	call Ink
	ld a,8 		; tail flash (ink 8)
	ld b,White
	ld c,Orange 
	call Ink
	;ret

Text:
	ld h,3 
	ld l,4
	call TextCursor
	ld hl,Message
	call PrintString
	
drawline:
	push hl
	push de
		ld a,15
		call GrPen 
		ld hl,334
		ld de,0
		call SetOrigin
		call LineFrom
		ld hl,0
		ld de,640
		call LineTo
		ld a,1
		call GrPen
	pop de
	pop hl	

main:
	ld a,0				;Force Draw of character first run
	JR StartDraw
	
infloop:
	call check_keys
	call &bb24 			; KM Get Joystick... Returns ---FRLDU
	or a
	jr z,infloop		;See if no keys are pressed

StartDraw:
	push af
		ld de,(PlayerX)	;Back up X
		ld (PlayerX2),de

		ld hl,(PlayerY)	;Back up Y
		ld (PlayerY2),hl

		push hl
		push de
			call WaitFlyback
			call BlankPlayer ;Remove old player sprite
		pop de
		pop hl
	pop af
	

JoyNot:
	bit 0,A
	jr z,JoyNotUp		;Jump if UP not presesd
	inc hl				;Move Y Up the screen
	inc hl				;Move Y Up the screen
JoyNotUp:
	bit 1,A
	jr z,JoyNotDown		;Jump if DOWN not presesd
	dec hl				;Move Y Down the screen
	dec hl				;Move Y Down the screen
JoyNotDown:
	bit 2,A
	jr z,JoyNotLeft 	;Jump if LEFT not presesd
	dec de				;Move X Left 
	dec de				;Move X Left 
JoyNotLeft:
	bit 3,A
	jr z,JoyNotRight	;Jump if RIGHT not presesd
	inc de				;Move X Right
	inc de				;Move X Right
JoyNotRight: 
	bit 4,A
	jr z,JoyNotFire
	jr JoyNotFire
DrawLaser:
	push af
	push bc
	push de
	push hl
	ld a,4
	call pen
	ld de,(PlayerX)+64
	ld hl,(PlayerY)
	Call SetOrigin
	Call LineFrom
	ld de,(PlayerX)+64
	ld hl,(PlayerY)
	Call LineTo
	pop hl
	pop de
	pop bc
	pop af
JoyNotFire:	
	ld (PlayerX),de		;Update X
	ld (PlayerY),hl		;Update Y
CheckX:
	;X Boundary Check 
	ld a,d	
	cp 1				
	;jr c,PlayerPosXOk
	ld a,e
	cp 146	
	jr c,PlayerPosXOk
	jr PlayerReset		;Player out of bounds - Reset!
PlayerPosXOk:

	;Y Boundary Check - only need to check 1 byte
	ld a,l
	cp 8				;Player 8 lines tall
	jr c,PlayerReset
	cp 167
	jr c,PlayerPosYOk	;Not Out of bounds
	
PlayerReset:
	ld de,(PlayerX2) 	;Reset Xpos	
	ld (PlayerX),de	

	ld hl,(PlayerY2)	;Reset Ypos
	ld (PlayerY),hl
	
PlayerPosYOk:
	call DrawPlayer		;Draw Player Sprite
	ld bc,100
	call PauseBC		;Wait a bit!

	jp infloop



PauseBC:
	dec bc
	ld a,b
	or c
	jr nz,PauseBC
	ret


BlankPlayer:
	ld bc,blankSprite	;Blank Sprite source
	jr DrawPlayerSprite
DrawPlayer:
	ld bc,SpriteShip	;Player Sprite Source
DrawPlayerSprite:
	push bc
		call ScrDotPosition	;Scr Dot Position - Returns address in HL
	pop de
	ld b,8				;Lines
SpriteNextLine:
	push hl
		ld c,8				;Bytes per line (Width)
SpriteShipNextByte:
		ld a,(de)			;Source Byte
		ld (hl),a			;Screen Destination

		inc de				;INC Source (Sprite) Address
		inc hl				;INC Dest (Screen) Address

		dec c 				;Repeat for next byte
		jr nz,SpriteShipNextByte
	
		;ld a,(de)		;Source Byte
		
		;ld (hl),a		;Screen Destination
		;inc de			;INC Source (Sprite) Address
		;inc hl			;INC Dest (Screen) Address
		;ld a,(de)		;Source Byte
		;ld (hl),a		;Screen Destination
		;inc de			;INC Source (Sprite) Address
		;inc hl			;INC Dest (Screen) Address
	pop hl
	call ScrNextLine		;Scr Next Line (Alter HL to move down a line)
	djnz SpriteNextLine	;Repeat for next line
	ret					;Finished 


SpriteShip:
	   DB      &75,&FF,&AA,&00,&00,&00,&00,&00
        DB      &10,&FF,&FF,&00,&00,&00,&00,&00
        DB      &00,&75,&FF,&FF,&00,&0F,&0A,&00
        DB      &00,&75,&FF,&FF,&FF,&FF,&0F,&00
        DB      &17,&3F,&3F,&3F,&3F,&7F,&FF,&FF
        DB      &17,&3F,&3F,&3F,&3F,&FF,&FF,&AA
        DB      &00,&FF,&FF,&FF,&FF,&FF,&30,&00
        DB      &00,&00,&30,&30,&30,&30,&00,&00
        
SpriteAlienRed:
        DB      &00,&3F,&2A,&00
        DB      &15,&3F,&3F,&00
        DB      &7B,&B7,&F3,&2A
        DB      &3F,&B7,&B7,&2A
        DB      &15,&3F,&3F,&00
        DB      &15,&2B,&3F,&00
        DB      &3F,&15,&15,&2A
        DB      &2A,&15,&00,&2A

blankSprite:
	DB      &00,&00,&00,&00,&00,&00,&00,&00
	DB      &00,&00,&00,&00,&00,&00,&00,&00
	DB      &00,&00,&00,&00,&00,&00,&00,&00
	DB      &00,&00,&00,&00,&00,&00,&00,&00
	DB      &00,&00,&00,&00,&00,&00,&00,&00
	DB      &00,&00,&00,&00,&00,&00,&00,&00
	DB      &00,&00,&00,&00,&00,&00,&00,&00
	DB      &00,&00,&00,&00,&00,&00,&00,&00
	

;Current player pos
PlayerX: dw &4
PlayerY: dw &64

;Last player pos (For clearing sprite)
PlayerX2: dw &10
PlayerY2: dw &10

check_keys:
;; test if any key has been pressed
call ReadKey
ret nc
;; A = code of the key that has been pressed
;;
;; check the codes we are using and handle appropiatly.
cp '1'				; show message
jp z,keyTEXT
cp '1'				; show message
jp z,keyTEXT
ret

Locate:
		push hl
				inc h
				inc l
				call TextCursor 
		pop hl
		ret

NewLine:
		ld a,13 			; carrage return
		call PrintChar
		ld a,10				; line feed
		jp PrintChar
		ret

PrintString:
		ld a,(hl)			; print '255' terminated string
		cp 255
		ret z
		inc hl
		call PrintChar
		jr PrintString

Message: 
		db 'Joystick Sprites!',255
		
TheTEXT: 
		db 'This is a TEST!!',255

keyTEXT:
	ld h,3 
	ld l,10
	call TextCursor
	ld hl,TheTEXT
	call PrintString
	ret


