ORG $8000

; MEMORY LAYOUT
;
;
; 0x0000-0x0100 Zero page
; 0x0100-0x0200 Stack page
; 0x0400-0x0800 Text page 1 (used for blanking screen)
; 0x0c00-0x2000 Code/data 
; 0x2000-0x4000 Hires page 1
; 0x4000-0x6000 Hires page 2
; 0x6000-0x8000 Rendered screen without animated sprites
; 0x8000-0xc000 Code/data
;

; Engine features
;
; + Keyboard control (repeating keypresses)
; + Draw level from tilemap
; + Double-buffer + page flipping
; + Dirty tiles for quick update (currently takes extra 8K)
; + Can climb up or down a ladder
; + Basic collision with a wall
; + Sprites can be of any height (14 pixels wide)
; + Tiles are 14x16 pixels
; + Free falling
; + Move to adjesting screens
; + Non-byte player x offset
;
; x Moving to a different screen makes freefall
; x No climbing animation
; x Can't pick up objects
; x Sprite hard alpha

incsrc "equ.s"

MAX_DIRTY	EQU 	#16
MAX_JUMP_FRAME	EQU	#7
MAX_INVENTORY	EQU	#8

SPRITE_INDX	EQU	$30
SPRITE_X	EQU	$31
SPRITE_Y	EQU	$32
SPRITE_HEIGHT	EQU	$33

PLAYER_ANIM	EQU	$34
PLAYER_DIR	EQU	$35

JUMP_FRAME	EQU	$38

PAGE		EQU	$39

DIR_RIGHT	EQU 	#$00
DIR_LEFT	EQU	#$01

KEY_UP		EQU	#'I'
KEY_LEFT	EQU	#'J'
KEY_DOWN	EQU	#'M'
KEY_RIGHT	EQU	#'L'
KEY_A		EQU	#'A'
KEY_JUMP	EQU	#'K'
KEY_1		EQU	#'1'

START
	jsr	CLEAR_SCREEN1
	jsr	CLEAR_SCREEN2

	; initialize graphics
	lda	HIRES
	lda	GR
	lda	CLRMIXED
	lda	CLRPAGE2

	ldx	#0			; INITIALIZE PLAYER POSITION
	stx	PlayerX

	ldy	#60
	sty	PlayerY

	lda	#$00
	sta	IsFreefalling
	sta	IsJumping
	sta	WasJumping
	sta	DirtySize+0
	sta	DirtySize+1

	jsr	InventoryClear

	lda	#$00			; INITIALIZE CURRENT SCREEN
	sta	CurrentScreen
	jsr	InitScreen

	lda	#$00			; INITIALIZE PLAYER ANIMATION
	sta	PLAYER_ANIM
	sta	PLAYER_DIR

	; draw onto page 2
	; set page 1 as visible
	lda	#$20
	sta	PAGE
	lda	SETPAGE1

	jsr	ZeroDirty
	                                                     	
	jsr	DRAW_SCREEN		; DRAW CURRENT SCREEN
	jsr	COPY_SCREEN
	jmp	FRAMELOOP

;***************************************
;
; Return the tile beneath the player.
;
; Probably good to compare with zero for
; telling if the player is in mid-air.
;
;***************************************
TileBeneathPlayer

	lda	PlayerX
	lsr
	lsr
	sta	$00

	lda	PlayerY
	clc
	adc	#20
	tay
	lda	DIV16,y
	tay
	lda	MUL20,y
	clc
	adc	$00
	tay
	lda	CurrentScreenData,y
	rts

;***************************************
;
; Return the tile behind the player.
;
; Good for telling if there's a ladder 
; behind her.
;
;***************************************
TileBehindPlayer
	jsr	CalcPlayerTilePosition
	tay
	lda	CurrentScreenData,y
	rts

;***************************************
;
; Calculate the offset of the player in
; the current map
;
;***************************************
CalcPlayerTilePosition
	lda	PlayerX
	lsr
	lsr
	sta	$00

	lda	PlayerY
	clc			; sprite is 20px, not 16px
	adc	#10		; hot spot for detection (fixme: was 19)
	tay
	lda	DIV16,y
	tay
	lda	MUL20,y
	clc
	adc	$00
	rts

;***************************************
;
; Update fall if player is in mid-air (and
; not jumping.)
;
;***************************************
UpdateFall

	lda	IsJumping
	beq	NOT_JUMPING
	rts

NOT_JUMPING	
	lda	#$00
	sta	IsFreefalling

	; find which tile we're standing on
	jsr	TileBeneathPlayer
	beq	f0

	; standing on something
f4:	lda	#00
	sta	WasJumping
	rts

	; there is nothing beneath the player (freefalling!)
f0:	ldy	PlayerY
	cpy	#191-20
	bcs	f3

	; still not out of the screen (paranoia, there should
	; always be a block to prevent this.)
	lda	PlayerY
	clc
	adc	#4
	sta	PlayerY

	; find if hit a tile
	jsr	TileBeneathPlayer
	beq	f2

	; we hit a brick, make sure we stand on it
	; that is, make sure PlayerY is a multiple of 16
	lda	PlayerY
	clc
	adc	#15
	and	#%11110000
	sec
	sbc	#4
	sta	PlayerY
	jmp	f4

	; mark player as freefalling (disable keys)
f2:	lda	#$01
	sta	IsFreefalling

	; maybe she's falling left or right
	lda	WasJumping
	beq	f3

	lda	left_down
	beq	f1

	dec	PlayerX
	jmp	f3

f1:	lda	right_down
	beq	f3
	
	inc	PlayerX
	jmp	f3

f3:	rts

;***************************************
;
; Page flip
;
; Inverts the visible page, and inverts
; drawing page
;
;***************************************
Flip
	lda	PAGE
	bne	@page1
	
	; page=0
	lda	#$20
	sta	PAGE
	lda	SETPAGE1
	rts

@page1:	; page=1
	lda	#$00
	sta	PAGE
	lda	SETPAGE2
	rts

;***************************************
;
; Empty the entry dirty list
;
;***************************************
ZeroDirty

	lda	#$00
	sta	DirtySize+0
	sta	DirtySize+1
	rts

;***************************************
;
; Update jumping state machine
;
; If the player is not jumping, then 
; nothing happens. Otherwise it updates
; the animation state, PlayerX and 
; PlayerY
;
;***************************************
UpdateJumping

	lda	IsJumping
	bne	j2
	rts

	; is_jumping == true
j2	ldx	JUMP_FRAME
	cpx	MAX_JUMP_FRAME
	bne	j3

	; reached the last frame of jump
	lda	#$00
	sta	IsJumping

	lda	#$01
	sta	WasJumping
	rts

	; still jumping
j3	lda	jump_offset,x
	sta	$00
	lda	PlayerY
	sec
	sbc	$00
	sta	PlayerY
	inc	JUMP_FRAME

	; always same sprite when jumping
	lda	#$00
	sta	PLAYER_ANIM

	; was jumping left ?
	lda	left_down
	beq	j4

	; jumping left
	dec	PlayerX
	rts

	; was jumping right
j4	lda	right_down
	beq	j5

	inc	PlayerX
j5	rts

;***************************************
;
; 6502, You're drunk. Go home.
;
;***************************************
Delay
	ldx	#$50
d1	ldy	#$40
d2	dey
	bpl	d2
	dex
	bne	d1
	rts

;***************************************
;
; Check if there's an item behind the player
;
;***************************************
CheckItemPickUp
	jsr	TileBehindPlayer
	bne	+
	rts

+	cmp	#$4
	beq	pickup_item
	cmp	#$6
	beq	pickup_item

	; something else, a ladder maybe?
	rts

pickup_item:
	jsr	InventoryAdd		; add this item to inventory
	bcs	inventory_was_full

	jsr	CalcPlayerTilePosition	; remove item from screen
	tay
	lda	#$0
	sta	CurrentScreenData,y

	jsr	DRAW_SCREEN
	jsr	DrawInventory
	jsr	COPY_SCREEN

inventory_was_full:
	rts

;***************************************
;
; Main frame loop, looped as fast as 
; possible
;
;***************************************
FRAMELOOP	


	jsr	UpdateJumping
	jsr	UpdateFall
	jsr	UpdatePosition
	jsr	CheckItemPickUp

	jsr	ClearDirty
	jsr	DrawPlayer
	jsr	Flip
	jsr	Delay

	lda	IsFreefalling
	ora	IsJumping
	bne	@skip
	jsr	ReadKey
@skip
	jmp	FRAMELOOP

keypress db 0
keydown db 0

right_down db 0
left_down db 0

ReadKey

;	lda	KBD
;	eor	#$80
;	bpl	HASKEY
;	rts
;HASKEY	sta	KBDSTRB
	lda	KBD
	sta	keypress
	lda	KBDSTRB
	sta	keydown

	lda	keypress
	bmi	new_keypress

	ldx	keydown
	bmi	stale_keypress

	lda	#0
	sta	left_down
	sta	right_down

	; nothing
	rts

stale_keypress
	ora	#$80

new_keypress
	eor	#$80

	cmp	KEY_RIGHT		; WAS RIGHT?
	beq	IS_L

	cmp	KEY_LEFT		; WAS LEFT?
	beq	IS_J

	cmp	KEY_UP			; WAS UP?
	beq	IS_I

	cmp	KEY_DOWN		; WAS DOWN?
	beq	IS_M

	cmp	KEY_JUMP		; WAS JUMP?
	bne	chk_a
	jmp	IS_SPACE

chk_a:	cmp	KEY_A
	bne	ignore
	jmp	IS_A

	; ignore this key
ignore:	rts

IS_L	lda	IsClimbing
	bne	ignore

	inc	PlayerX

	lda	DIR_RIGHT		; Turn Right
	sta	PLAYER_DIR

	inc	PLAYER_ANIM		; Increase animation
	lda	PLAYER_ANIM
	cmp	#2
	bne	IS_L1
	lda	#0
	sta	PLAYER_ANIM	

IS_L1	lda	#1			; Right is still pressed
	sta	right_down

	jsr	IsCollidingWithLevel	; Is blocked by level?
	beq	IS_L2			
	dec	PlayerX	
IS_L2	rts

IS_J	lda	IsClimbing
	bne	ignore

	lda	DIR_LEFT		; TURN LEFT
	sta	PLAYER_DIR
        dec	PlayerX

	dec	PLAYER_ANIM
	bpl	IS_J1
	lda	#1
	sta	PLAYER_ANIM

IS_J1   lda	#1
	sta	left_down

	jsr	IsCollidingWithLevel
	beq	IS_J2			; empty
	
	; not empty
	inc	PlayerX
IS_J2	rts

IS_M	jsr	CanClimbDown	
	beq	cant2

	lda	PlayerY
	clc
	adc	#4
	sta	PlayerY

	lda	#1
	sta	IsClimbing
	rts

cant2	lda	#0
	sta	IsClimbing
	rts

IS_I	jsr	CanClimbUp
	beq	cant

	lda	PlayerY
	sec
	sbc	#4
	sta	PlayerY

	lda	#1
	sta	IsClimbing
	rts

cant	lda	#0
	sta	IsClimbing
	rts

IS_SPACE
	lda	keydown
	ldx	keypress
	lda	#$01
	sta	IsJumping

	lda	#$00
	sta	JUMP_FRAME
	rts

IS_A	lda	#6
	jsr	InventoryRemove
	jsr	DrawInventory
	jsr	COPY_SCREEN
	rts

;***************************************
;
; Check if there is a collision in player
; position with the level (like a block
; or stone.)
;
; A is non-zero if colliding.
;***************************************
IsCollidingWithLevel
	lda	PlayerX
	cmp	#160
	bcs	ok

	jsr	TileBehindPlayer
	beq	ok

	cmp	#$b
	beq	ok
	cmp	#$e
	beq	ok

	lda	#$01
	rts

ok	lda	#$00
	rts


;***************************************
; 
; Check if the player can climb up (in 
; front of a ladder or on a rope.
;
;***************************************
CanClimbUp

	jsr	TileBehindPlayer
	cmp	#$b
	beq	ReturnTrue

	cmp	#$e
	beq	ReturnTrue

ReturnFalse
	lda	#0
	rts

ReturnTrue
	lda	#1
	rts

;***************************************
; 
; Check if the player can climb down (on
; a ladder or a rope. Or above a ladder. 
;
;***************************************
CanClimbDown

	jsr	TileBeneathPlayer
	cmp	#$b
	beq	ReturnTrue

	cmp	#$e
	beq	ReturnTrue

	jmp	ReturnFalse

;***************************************
;
; Update player position: make sure player
; hasn't left the screen boundaries. If 
; has, move to the next screen.
;
;***************************************
UpdatePosition

	; out of screen to the left?
	lda	PlayerX
	bmi	scroll_left
	
	; out of screen to the right?
	cmp	#77
	bcs	scroll_right

	; out of screen above?
	lda	PlayerY
	cmp	#256-8
	bcs	scroll_up

	; out of screen below?
	cmp	#172
	bcs	scroll_down

	; nope, still in the same screen
	rts

scroll_left

	lda	#76
	sta	PlayerX

	ldy	CurrentScreen
	dey
	bpl	ok1
	ldy	#2
ok1	
	sty	CurrentScreen
	jsr	InitScreen

	jsr	DRAW_SCREEN		; DRAW CURRENT SCREEN
	jsr	COPY_SCREEN

	rts

scroll_right

	lda	#0
	sta	PlayerX

	ldy	CurrentScreen
	iny
	cpy	#3
	bne	ok2
	ldy	#0
ok2	sty	CurrentScreen
	jsr	InitScreen

	jsr	DRAW_SCREEN		; DRAW CURRENT SCREEN
	jsr	COPY_SCREEN
	rts

scroll_up

	lda	#$00
	sta	PlayerY
	rts

scroll_down

	lda	#172
	sta	PlayerY
	rts


;***************************************
;
; Run through all levels, reset items (all visible)
;
;***************************************
ResetGameItems
	lda	#$00
	sta	$00
	rts

;***************************************
;
; Initialize current screen and memory 
; pointers
;
;***************************************
InitScreen
	ldy	CurrentScreen
	lda	SCRLO,y
	sta	$00
	lda	SCRHI,y
	sta	$01

	; FIXME: simplify, remove use of x
	ldx	#240
	ldy	#$00
cp:	lda	($00),y
	sta	CurrentScreenData,y
	iny
	dex
	bne	cp

	; load number of items on this page
	lda	($00),y
	beq	no_items

	; FIXME
	; there's a bug here if there are more than 16 bytes AFTER the map (0xF0 + 0x10)

	; are there some items on this page
more_items:

	iny
	pha
	lda	($00),y			; is item visible?
	beq	item_invisible

	iny
	lda	($00),y			; load item position
	tax
	iny
	lda	($00),y			; load item id
	sta	CurrentScreenData,x	; save it on CurrentScreenData

next_item:
	pla
	sec
	sbc	#$01
	bne	more_items
	rts

item_invisible:
	iny				; skip next two bytes
	iny	
	jmp	next_item

no_items:

	rts

;***************************************
; 
; Draws the player at PlayerX, PlayerY 
; using PLAYER_DIR and PLAYER_ANIM as 
; modifiers.
;
;***************************************
DrawPlayer

	ldx	PlayerY
	stx	SPRITE_Y		; sprite_y = (PlayerY * 16) - 4

	lda	PlayerX
	sta	SPRITE_X		; sprite_x = (PlayerX * 2)

	lda	#20
	sta	SPRITE_HEIGHT		; sprite_height = 20

	lda	IsClimbing
	bne	draw_climbing

	; not climbing
	lda	PLAYER_DIR
	asl
	clc
	adc	PLAYER_ANIM
	sta	SPRITE_INDX		; sprite_index = player_anim + (player_dir * 2)
	jmp	DrawSprite

draw_climbing:

	lda	PlayerY
	lsr
	lsr
	lsr
	and	#1
	clc
	adc	#4
	sta	SPRITE_INDX
	jmp	DrawSprite

COPY_SCREEN
	jsr	CP3TO2
	jsr	CP3TO1
	rts

;***************************************
;
; Copy background screen onto hires page 1
;
;***************************************
CP3TO1	
	lda	#$60
	sta	loop31+2
	lda	#$20
	sta	loop31+5

	ldy	#$00
	ldx	#$20
loop31:	lda	$6000,y
	sta	$2000,y
	dey
	bne	loop31
	inc	loop31+2
	inc	loop31+5
	dex
	bne	loop31
	rts

;***************************************
;
; Copy background screen onto hires page 2
;
;***************************************
CP3TO2
	lda	#$60
	sta	loop32+2
	lda	#$40
	sta	loop32+5

	ldy	#$00
	ldx	#$20
loop32:	lda	$6000,y
	sta	$4000,y
	dey
	bne	loop32
	inc	loop32+2
	inc	loop32+5
	dex
	bne	loop32
	rts



;***************************************
;
; Clear all dirty tiles and copy each from
; background page on to hires page 1.
;
;***************************************

ClearDirty

	lda	PAGE
	bne	+

	ldx	DirtySize+0
	bne	full1
	rts			; empty

+	ldx	DirtySize+1
	bne	full2		; empty
	rts

	; load the last one
full1
	DEX
	STX	DirtySize+0

	LDA	DirtyX,X	; load dirty tile x
	ASL
	STA	$00
	LDA	DirtyY,X	; load dirty tile y
	ASL
	ASL	
	ASL
	ASL
	STA	$01
	jmp	full3

full2
	DEX
	STX	DirtySize+1

	LDA	DirtyX+MAX_DIRTY,X	; load dirty tile x
	ASL
	STA	$00
	LDA	DirtyY+MAX_DIRTY,X	; load dirty tile y
	ASL
	ASL	
	ASL
	ASL
	STA	$01


full3

	LDA	#16
	STA	$06

-row	LDX	$01
	LDA	YLO,X
	STA	$02
	STA	$04
	LDA	YHI,X
	TAY
	CLC
	ADC	PAGE
	STA	$03
	TYA
	CLC
	ADC	#$40
	STA	$05

	LDY	$00
	LDA	($04),Y
	STA	($02),Y
	INY
	LDA	($04),Y
	STA	($02),Y
	INC	$01
	DEC	$06
	BNE	-row
	
	JMP	ClearDirty

;***************************************
;
; Draw iventory on screen
;
;***************************************
DrawInventory
	ldy	MAX_INVENTORY-1
itemd:
	tya				; push y onto stack
	pha

	asl				; x position
	tax				

	lda	Inventory,y		; tile to draw
	ldy	#0			; y position
	jsr	DrawTile

	pla				; pop a
	tay
	dey
	bpl	itemd
	rts

;***************************************
;
; Is inventory full?
;
;***************************************
InventoryFull
	ldy	MAX_INVENTORY-1
	ldx	#0
itemf:
	lda	Inventory,y
	beq	not_full
	dey
	bpl	itemf

	; full
	inx

not_full:
	txa
	rts

;***************************************
;
; Clear inventory
;
;***************************************
InventoryClear
	ldy	MAX_INVENTORY-1
	lda	#$0
itemc:
	sta	Inventory,y
	dey
	bpl	itemc
	rts

;***************************************
;
; Remove an item from inventory. Makes
; sure list does not contain empty slots.
; Item to remove in A. Does nothing if not
; found in inventory.
;
;***************************************
InventoryRemove
	sta	$0
	ldy	#0
itemr:
	lda	Inventory,y
	cmp	$0
	beq	foundr
	iny
	cpy	MAX_INVENTORY
	bne	itemr

	; not found
	rts

foundr:	
	cpy	MAX_INVENTORY-1
	beq	clear_last
	iny
	lda	Inventory,y
	dey
	sta	Inventory,y
	iny
	jmp	foundr

clear_last:
	lda	#0
	sta	Inventory+MAX_INVENTORY-1
	rts

;***************************************
;
; Adds an item to inventory.
; Item to add in A. Does nothing if full.
;
;***************************************
InventoryAdd
	sta	$00
	ldy	#0
itema:
	lda	Inventory,y
	beq	empty
	iny
	cpy	MAX_INVENTORY
	bne	itema

	; inventory is full
	sec
	rts

empty:	lda	$00
	sta	Inventory,y
	clc
	rts

;***************************************
;
; Checks if an item is in inventory.
; Item to check in A. Returns position of
; item or negative if not found.
;
;***************************************
InventoryContains
	sta	$00
	ldy	MAX_INVENTORY-1
itemcs:
	lda	Inventory,y
	cmp	$00
	beq	found
	dey
	bpl	itemcs

	lda	#$ff
	rts

found:	tya
	rts


;***************************************
;
; Draw screen in CurrentScreen onto 
; background page.
;
;***************************************
DRAW_SCREEN     

	lda	#0
	sta	$12 	                ; X-POS=0
	sta	$13			; Y-POS=0
	sta	$14			; OFFSET IN BYTES=0

LOOPY	lda	$12
	asl
	tax
	ldy	$14
	lda	CurrentScreenData,y	; GET TILE NUMBER
	inc	$14
	ldy	$13

	cmp	#$00
	beq	empty_tile
	jsr	DrawTile
	jmp	next_x
empty_tile
	jsr	ClearTile
next_x

	; NEXT X
	inc	$12
	lda	$12
	cmp	#20
	bcc	LOOPY

	; NEXT Y
	lda	#0
	sta	$12

	lda	$13
	clc
	adc	#16
	cmp	#191
	bcs	DONE
	sta	($13)
	jmp	LOOPY

DONE	
	jsr	ZeroDirty
	jsr	DrawInventory
	rts
		


CLEAR_SCREEN1
	lda	#$20
	sta	cs1+2
	lda	#$30
	sta	cs1+5

	lda	#$00
	ldx	#$10
	ldy	#$00
cs1:	sta	$2000,y
	sta	$3000,y
	dey
	bne	cs1
	inc	cs1+2
	inc	cs1+5
	dex
	bne	cs1
	rts

CLEAR_SCREEN2
	lda	#$40
	sta	cs2+2
	lda	#$50
	sta	cs2+5

	lda	#$00
	ldx	#$10
	ldy	#$00
cs2:	sta	$4000,y
	sta	$5000,y
	dey
	bne	cs2
	inc	cs2+2
	inc	cs2+5
	dex
	bne	cs2
	rts

;----------------------------------------------------------
; 
; Draw a sprite on screen
; 
; SPRITE_INDX - SPRITE TO DRAW
; SPRITE_X - X POSITION ON SCREEN [0..159]
; SPRITE_Y - Y POSITION ON SCREEN [0..191]
; SPRITE_HEIGHT - SPRITE ROWS
; 
;----------------------------------------------------------
DrawSprite:

	lda	SPRITE_HEIGHT   ; Rows left to render
	sta	$07	

	lda	#$00		; Byte offset within sprite
	sta	$06		

	ldx	SPRITE_INDX	; Load 16-bit pointer to 
	lda	SPRLO,x		; sprite data into zp($02)
	sta	$02
	lda	SPRHI,x	
	sta	$03		 

	lda	SPRITE_Y	; Current row
	sta	$05

	lda	SPRITE_X	; Shift position (0..3)
	and	#$03
	sta	$04

	lda	SPRITE_X
	lsr
	lsr
	asl
	sta	SPRITE_X

	; uses $0a and $0b for storing sprite data

DSROW	
	ldy	$05		; load row offset (consider PAGE)
	lda	YLO,y
	sta	$00
	lda	YHI,y
	clc
	adc	PAGE
	sta	$01

	ldy	$06		; load 2 bytes from sprite
	lda	($02),y
	sta	$0a
	iny
	lda	($02),y
	sta	$0b
	iny
	sty	$06

	ldy	SPRITE_X

	ldx	$04		; check sprite shift
	beq	shift0
	dex
	beq	shift1
	dex
	beq	shift2
	jmp	shift3

shift0:
	;lda	($00),y
	;ora	$0a
	lda	$0a
	beq	+
	sta	($00),y

+	iny
	;lda	($00),y
	;ora	$0b
	lda	$0b
	beq	++
	sta	($00),y
++
	jmp	nextrow

shift1:
	; ldy	SPRITE_X        ; load 7 pixels
	lda	($00),y		
	        
	and	#%10000111	; remove 4 rightmost pixels	
	sta	$0c

	lda	$0a
	beq	+
	and	#%1111		; remove top bits
	asl
	asl
	asl			; keep next 4 bits

	ora	$0c		; mix these two together
	sta	($00),y

	; ---

+	iny             	; now mix both $a and $b
	lda	$0a
	and	#%01110000
	lsr
	lsr
	lsr
	lsr
	sta	$0c

	lda	$0b
	and	#%1111
	asl			
	asl			
	asl
	ora	$0c
	beq	+
	sta	($00),y

	; ---

+	iny
	lda	($00),y
	and	#%1111
	asl
	asl
	asl
	sta	$0c

	lda	$0b
	lsr
	lsr
	lsr
	lsr
	and	#%111
	ora	$0c
	sta	($00),y
	
	jmp	nextrow

shift2:
	iny
	jmp	shift0

shift3:
	iny
	jmp	shift1

nextrow:
	inc	$05

	dec	$07
	beq	DSDONE
	jmp	DSROW

DSDONE:

	; add to dirty list
	lda	SPRITE_X
	lsr	
	sta	$0				; $1 = x/4

	ldy	SPRITE_Y
	lda	DIV16,y
	sta	$1				; $0 = y/16

	; store x,y
	jsr	AddDirtyTile

	; store x+1,y
	inc	$0
	jsr	AddDirtyTile

	; store x+1,y+1
	inc	$1
	jsr	AddDirtyTile

	; store x,y+1
	dec	$0
	jsr	AddDirtyTile

	rts


;***************************************
;
; Adds a dirty tile to the dirty-list. 
; The tile will be added to the current
; dirty_list (2 are availble, one for
; each page.)
;
; X,Y are stored at $00, $01
;
;***************************************
AddDirtyTile

	lda	PAGE
	bne	+

	; saving onto page 1
	ldx	DirtySize+0
	cpx	MAX_DIRTY
	beq	out	; overflow

	lda	$00
	sta	DirtyX,x

	lda	$01
	sta	DirtyY,x

	inc	DirtySize+0
	rts

+	ldx	DirtySize+1
	cpx	MAX_DIRTY
	beq	out

	lda	$00
	sta	DirtyX+MAX_DIRTY,x

	lda	$01
	sta	DirtyY+MAX_DIRTY,x

	inc	DirtySize+1

out	rts


;***************************************
; 
; Draw a tile at the given position on
; screen.
; 
; A = Tile to draw.
; X,Y = Position on screen. X [0..39], Y [0..191]
; 
;***************************************
DrawTile
	STX	$04		; X-POS
	STY	$05		; Y-POS

	TAX			; X=SPRITE NO
	LDA	TILESLO,X	; A=LOW POINTER TO SPRITE
	STA	BEEF1+1
	STA	BEEF2+1
	LDA	TILESHI,X	
	STA	BEEF1+2		; ZP ($02) HOLDS 16BIT POINTER TO SPRITE
	STA	BEEF2+2

	LDX	#$00		; OFFSET IN SPRITE

	LDA	#16		; 16-ROWS
	STA	$06


CPROW	LDY	$05		; LOAD Y POSITION
	LDA	YLO,Y		; LOAD LO BYTE OF SCREEN OFFSET
	STA	$00		; KEEP
	LDA	YHI,Y		; LOAD HI BYTE OF SCREEN OFFSET
	CLC
	ADC	#$40
	STA	$01

	LDY	$04

BEEF1	LDA	#$BEEF,X
	INX
	STA	($00),Y
	INY

BEEF2	LDA	#$BEEF,X
	INX
	STA	($00),Y

	INC	$05
	DEC	$06
	BNE	CPROW
	RTS

;***************************************
;
; Clear a tile (with zeros), faster than DrawTile(0)
;
; X,Y = POSITION ON SCREEN, X [0..39], Y[0..191]
;
;***************************************
ClearTile
	lda	#16
	sta	$00

CLEAR_ROW
	lda	YLO,y
	sta	BEEF3+1
	sta	BEEF4+1
	lda	YHI,y
	clc
	adc	#$40
	sta	BEEF3+2
	sta	BEEF4+2

	lda	#$00
BEEF3	sta	#$BEEF,x
	inx
BEEF4	sta	#$BEEF,x
	dex

	iny
	dec	$00
	bne	CLEAR_ROW
	rts

;***************************************
;
; Crash!
;
;***************************************
HALT	JMP	HALT

;***************************************
;
; Wait for VSYNC
;
;***************************************
VSYNC	
	lda	$c019
	bmi	VSYNC
	rts

;***************************************
;
; Wait for VBLANK
;
;***************************************
VBLANK	
	lda	$c019
	bpl	VBLANK
	rts

incsrc "levels.s"
incsrc "sprites.s"
incsrc "tiles.s"
incsrc "hires.s"

MUL16	hex 00 10 20 30 40 50 60 70 80 90 a0 b0 c0 d0 e0 f0

MUL20	hex 00 14 28 3c 50 64 78 8c a0 b4 c8 dc f0 

DIV16	hex 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 
	hex 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 01 
	hex 02 02 02 02 02 02 02 02 02 02 02 02 02 02 02 02 
	hex 03 03 03 03 03 03 03 03 03 03 03 03 03 03 03 03 
	hex 04 04 04 04 04 04 04 04 04 04 04 04 04 04 04 04 
	hex 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 05 
	hex 06 06 06 06 06 06 06 06 06 06 06 06 06 06 06 06 
	hex 07 07 07 07 07 07 07 07 07 07 07 07 07 07 07 07 
	hex 08 08 08 08 08 08 08 08 08 08 08 08 08 08 08 08 
	hex 09 09 09 09 09 09 09 09 09 09 09 09 09 09 09 09 
	hex 0a 0a 0a 0a 0a 0a 0a 0a 0a 0a 0a 0a 0a 0a 0a 0a 
	hex 0b 0b 0b 0b 0b 0b 0b 0b 0b 0b 0b 0b 0b 0b 0b 0b 
	hex 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 0c 
	hex 0d 0d 0d 0d 0d 0d 0d 0d 0d 0d 0d 0d 0d 0d 0d 0d 
	hex 0e 0e 0e 0e 0e 0e 0e 0e 0e 0e 0e 0e 0e 0e 0e 0e 
	hex 0f 0f 0f 0f 0f 0f 0f 0f 0f 0f 0f 0f 0f 0f 0f 0f 


; Player position
PlayerX	db 0		; Player X position (0 .. 159)
PlayerY	db 0 		; Player Y position (0 .. 191)

; Dirty page manager
DirtySize dsb 2
DirtyX dsb MAX_DIRTY*2
DirtyY dsb MAX_DIRTY*2

jump_offset hex 4 3 2 1 0 0 0

kbdx db 0
kbdy db 0

IsJumping db 0
IsFreefalling db 0
IsClimbing db 0
WasJumping db 0
CurrentScreen 	db	0
CurrentScreenData dsb 20*12

; Items in inventory
Inventory hex 04 06 00 00 00 00 00 00
