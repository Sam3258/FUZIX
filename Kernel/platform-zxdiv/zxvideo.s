;
;        zx128 vt primitives
;

        .module zxvideo

        ; exported symbols
        .globl _plot_char
        .globl _scroll_down
        .globl _scroll_up
        .globl _cursor_on
        .globl _cursor_off
	.globl _cursor_disable
        .globl _clear_lines
        .globl _clear_across
        .globl _do_beep
	.globl _fontdata_8x8
	.globl _curattr

        .area _VIDEO

        ; colors are ignored everywhere for now

videopos:
        ld a,e
        and #7
        rrca
        rrca
        rrca 
        add a,d
        ld d,e
        ld e,a
        ld a,d
        and #0x18
        or #0x40	    ; Standard screen
        ld d,a
        ret

videoattr:
	;			32 x E + D into HL
	ld a,e
	rrca
	rrca
	rrca			; A is now 32xE with the top bits overflowed
				; into the low 2 bits
	ld l,a
	and #3			; Extract the low 2 bits for the high
	add #0x58		; Attributes start 0x5800
	ld h,a
	ld a,l
	and #0xE0		; mask the bits that are valid
	add d			; add the low 5 bits from D
	ld l,a			; and done (the add can't overflow)
	ret

_plot_char:
	pop iy
        pop hl
        pop de              ; D = x E = y
        pop bc
        push bc
        push de
        push hl
	push iy

	push de
        call videopos

        ld b, #0            ; calculating offset in font table
        ld a, c
	or a		    ; clear carry
        rla
        rl b
        rla
        rl b
        rla
        rl b
        ld c, a

        ld hl, #_fontdata_8x8-32*8    ; font
        add hl, bc          ; hl points to first byte of char data


        ; printing
        ld c, #8
plot_char_loop:
        ld a, (hl)
        ld (de), a
        inc hl              ; next byte of char data
        inc d               ; next screen line
        dec c
        jr nz, plot_char_loop
	pop de
	call videoattr
	ld a,(_curattr)
	ld (hl),a
        ret


_clear_lines:
	pop bc
        pop hl
        pop de              ; E = line, D = count
        push de
        push hl
	push bc
	; This way we handle 0 correctly
	inc d
	jr nextline

clear_next_line:
        push de
        ld d, #0            ; from the column #0
        ld b, d             ; b = 0
        ld c, #32           ; clear 32 cols
        push bc
        push de
	push af
        call _clear_across
	pop af
        pop hl              ; clear stack
        pop hl

        pop de
        inc e
nextline:
        dec d
        jr nz, clear_next_line

        ret


_clear_across:
	pop iy
        pop hl
        pop de              ; DE = coords 
        pop bc              ; C = count
        push bc
        push de
        push hl
	push iy
	ld a,c
	or a
	ret z		    ; No work to do - bail out
	push de
	push bc
        call videopos       ; first pixel line of first character in DE
        push de
        pop hl              ; copy to hl
        xor a

        ; no boundary checks. Assuming that D + C < SCREEN_WIDTH

clear_line:
        ld b, #8            ; 8 pixel lines to clear for this char
clear_char:
        ld (de), a
        inc d
        djnz clear_char

        ex de, hl
        inc de
        push de
        pop hl

        dec c
        jr nz, clear_line
	pop bc
	pop de
	call videoattr
	ld a,(_curattr)
	ld b,c
setattr:
	ld (hl),a
	inc hl
	djnz setattr
        ret

copy_line:
        ; HL - source, DE - destination

        ; convert line coordinates to screen coordinates both for DE and HL
        push de
        ex de, hl
        call videopos
        ex de, hl
        pop de
        call videopos

        ld c, #8

copy_line_nextchar:
        push hl
        push de

        ld b, #32

copy_pixel_line:
        ld a, (hl)
        ld (de), a
        inc e
        inc l
        djnz copy_pixel_line

        pop de
        pop hl
        inc d
        inc h
        dec c
        jr nz, copy_line_nextchar
        ret

        ; TODO: the LDIR way should be much faster

_scroll_down:
        ; set HL = (0,22), DE = (0, 23)
        xor a
        ld d, a
        ld h, a
        ld l, #22
        ld e, #23
        ld c, #23           ; 23 lines to move

loop_scroll_down:
        push hl
        push de
        push bc

        call copy_line

        pop bc
        pop de
        pop hl

        dec l
        dec e
        dec c
        jr nz, loop_scroll_down

	; Attributes
	ld hl,#0x5ADF
	ld de,#0x5AFF
	ld bc,#0x02E0
	lddr

        ret


_scroll_up:
        ; set HL = (0,1), DE = (0, 0)
        xor a
        ld d, a
        ld e, a
        ld h, a
        ld l, #1
        ld c, #23           ; 23 lines to move

loop_scroll_up:
        push hl
        push de
        push bc

        call copy_line

        pop bc
        pop de
        pop hl

        inc l
        inc e
        dec c
        jr nz, loop_scroll_up

	ld hl,#0x5820
	ld de,#0x5800
	ld bc,#0x02E0
	ldir
        ret

_cursor_on:
	pop bc
        pop hl
        pop de
        push de
        push hl
	push bc
        ld (cursorpos), de

        call videopos
        ld a, #7
        add a, d
        ld d, a
        ld a, #0xFF
        ld (de), a
        ret
_cursor_disable:
_cursor_off:
        ld de, (cursorpos)
        call videopos
        ld a, #7
        add a, d
        ld d, a
        xor a
        ld (de), a

_do_beep:
        ret

        .area _DATA

cursorpos:
        .dw 0