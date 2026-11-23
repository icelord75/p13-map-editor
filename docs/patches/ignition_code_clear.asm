; P13 (OKI M66911): clear trouble codes after N ignition cycles without engine start (N = 3..10)
; Assemble with asm662 (oki66k-tools); the code goes to 0x7F10-0x7F3F (FF in all known P13 ROMs).
;
; Hook sites (stock -> patched):
;   0x090A  32 EB 6E  CAL 0x6EEB   ->  32 10 7F  CAL ccl_boot   (warm start, interrupts still off)
;   0x1077  03 16 11  J   0x1116   ->  03 35 7F  J   ccl_run    (main loop, engine rotating)
;
; State byte 0x337: lies in 0x300-0x363, the area kept on a warm start (ignition cycle with
; backup power) and zeroed on a cold start; not used by the stock code and outside the
; backup checksums (0x330-0x333, 0x338-0x35D).
;   bits 0-3  consecutive ignition cycles without engine rotation
;   bit 7     engine rotated during this ignition cycle
; On the power-on after N cycles without rotation, the stock clear routine 0x4C9C runs
; (the same one the dealer tester triggers): it clears the stored codes and fault flags,
; learned values stay. Internal ECU restarts (r_reset_code 0xD4 != 0) are not counted.

                org 07F10h
ccl_boot:       LB      A, 0d4h          ; r_reset_code: 0 = real power-on
                JNE     ccl_done
                MOV     DP, #00337h
                LB      A, [DP]
                MB      C, ACC.7         ; engine rotated in the previous cycle?
                JLT     ccl_zero
                ANDB    A, #00fh
                ADDB    A, #001h
                CMPB    A, #003h         ; N: operand byte at 0x7F22, 3..10 (the editor sets it)
                JLT     ccl_store
                PUSHS   LRB
                MOV     LRB, #00076h     ; 0x4C9C addresses 0x336 via off(): needs page 0x300
                CAL     04c9ch           ; stock "clear trouble codes"
                POPS    LRB
ccl_zero:       CLRB    A
ccl_store:      MOV     DP, #00337h
                STB     A, [DP]
ccl_done:       J       06eebh           ; the stock call target

ccl_run:        PUSHS   LRB
                MOV     LRB, #00076h
                SB      off(00337h).7    ; engine rotated in this cycle
                POPS    LRB
                J       01116h           ; the stock jump target
