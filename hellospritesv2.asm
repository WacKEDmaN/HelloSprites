Mode			equ &bc0e
CLS			equ &bc14
PrintChar	equ &bb5a
WaitChar		equ &bb06
Ink			equ &bc32 ;(a,b,c)
Border		equ &bc38 ;(b,c)
Pen			equ &bb90 ;(in: A=foreground color 0..15)
TextCursor	equ &bb75 ;(h=x,l=y,a=rollcount)
MoveCursor	equ &bb8a ;(h=x,l=y)
ScrNextLine 	equ &BC26	;out: HL=HL+800h, or HL=HL+50h-3800h (or so)
ScrDotPosition equ &BC1D ;in: DE=x, HL=y, out: HL=vram addr, C=mask, DE, B

Black 		equ 0
Blue			equ 1
BrightBlue	equ 2
Red			equ 3
Magenta		equ 4
Mauve		equ 5
BrightRed	equ 6
Purple		equ 7
BrightMagenta	equ 8
Green		equ 9
Cyan			equ 10
SkyBlue		equ 11
Yellow		equ 12
White		equ 13
PastelBlue	equ 14
Orange		equ 15
Pink			equ 16
PastelMagenta	equ 17
BrightGreen	equ 18
SeaGreen		equ 19
BrightCyan	equ 20
Lime			equ 21
PastelGreen	equ 22
PastelCyan	equ 23
BrightYellow	equ 24
PastelYellow	equ 25
BrightWhite	equ 26

	org &1000		;Start of our program

	ld a,0 ; mode 0 
	call Mode

	;; setup inks 
	ld b,Black
	ld c,Black
	call Border
	ld a,0 ; background
	ld b,Black ; black
	ld c,Black 
	call Ink
	ld a,1 ; text (ink 1)
	ld b,Orange
	ld c,Orange 
	ld a,2 ; flash text (ink 2)
	ld b,BrightRed
	ld c,BrightYellow 
	call Ink
	
	;; ship inks
	call Ink
	ld a,15 ; main body (ink 15)
	ld b,BrightWhite
	ld c,BrightWhite 
	call Ink
	ld a,14 ; stripe (ink 14)
	ld b,BrightRed
	ld c,BrightRed
	call Ink
	ld a,10 ; canopy (ink 10)
	ld b,PastelBlue
	ld c,PastelBlue
	call Ink
	ld a,4 ; outline (ink 4)
	ld b,White
	ld c,White
	call Ink
	ld a,8 ; tail flash (ink 8)
	ld b,White
	ld c,Orange 
	call Ink

	;; SHIP SPRITE
	ld de,10		;Xpos (in pixels)
	ld hl,160		;Ypos (in pixels)

	call ScrDotPosition		;Scr Dot Position - Returns address in HL

	ld de,SpriteShip	;Ship Sprite Source (8x)

	ld b,8			;Lines (Height)
SpriteShipNextLine:
	push hl
		ld c,8		;Bytes per line (Width)
SpriteShipNextByte:
		ld a,(de)		;Source Byte
		ld (hl),a		;Screen Destination

		inc de		;INC Source (Sprite) Address
		inc hl		;INC Dest (Screen) Address

		dec c 		;Repeat for next byte
		jr nz,SpriteShipNextByte
	pop hl
	call ScrNextLine 	;Scr Next Line (Alter HL to move down a line)
	djnz SpriteShipNextLine	;Repeat for next line

	;; SPRITE ALIEN
	ld de,100		;Xpos (in pixels)
	ld hl,160		;Ypos (in pixels)
SpriteAlienR:
	call ScrDotPosition		;Scr Dot Position - Returns address in HL

	ld de,SpriteAlienRed	;Ship Sprite Source (8x4)

	ld b,8			;Lines (Height)
SpriteAlienRedNextLine:
	push hl
		ld c,4		;Bytes per line (Width)
SpriteAlienRedNextByte:
		ld a,(de)	;Source Byte
		ld (hl),a	;Screen Destination

		inc de		;INC Source (Sprite) Address
		inc hl		;INC Dest (Screen) Address

		dec c 		;Repeat for next byte
		jr nz,SpriteAlienRedNextByte
	pop hl
	call ScrNextLine 	;Scr Next Line (Alter HL to move down a line)
	djnz SpriteAlienRedNextLine	;Repeat for next line

	;; TEXT
	ld h,4 
	ld l,4
	call TextCursor
	ld hl,Message
	Call PrintString

	;; MOVE Alien Sprite
	ld a,100 		;; i = 100
Loop_Cond
	ld b,161		;; i < 160
	cp a
	jp z, Loop_Exit

	add a,l
	ld l,a
	jr nc,hl_ok
	inc h
	hl_ok:	
	ld de,100 ;Xpos (in pixels)
	;;ld hl,160		;Ypos (in pixels)
	Call SpriteAlienR
	inc b
	jp Loop_Cond
Loop_Exit	
	;; WAIT for keypress
	call WaitChar
	;; Print exit message
	ld a,2 ; set pen to 2
	call Pen
	ld h,3 
	ld l,1
	call TextCursor
	ld h,0 
	ld l,0
	call MoveCursor
	ld hl,Exit
	call PrintString
	ld h,0
	ld l,10
	call TextCursor
	ld a,1 ; set pen back to 1
	call Pen
	ret			;Finished

Locate:
		push hl
				inc h
				inc l
				call TextCursor 
		pop hl
		ret

NewLine:
		ld a,13 		; carrage return
		call PrintChar
		ld a,10		; line feed
		jp PrintChar
		ret

PrintString:
		ld a,(hl)		; print '255' terminated string
		cp 255
		ret z
		inc hl
		call PrintChar
		jr PrintString

Message: db 'Hello Sprites!',255
Exit: db 'This is a TEST!!',255

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