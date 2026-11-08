; EL CIRCO DIMENSIONAL — Version 1.1 (ZX Spectrum 48K)
; © 2026 Tony C. Ware — codigo MIT, graficos derechos reservados
; Base version 1.0 con control por toques.
ORG $8041
    CALL over_gate
ORG $81C3
    CALL tick_and_advance
ORG $827F
    CALL start_over
; Descenso en puntos 5+: valores originales 46,38,32,27,23
ORG $81F8
    DB 22
ORG $81FF
    DB 26
ORG $8206
    DB 30
ORG $820D
    DB 36
ORG $8214
    DB 44
; Banda inicial: 55 fotogramas, SIN CAMBIO
; Se cambia la pantalla title_scr a "VS" conservando todo lo demas.
ORG $E068
frame_counter: DB 0
over_gate:
    CALL $8053
    LD B,A
    LD A,(frame_counter)
    CP 250
    JR NC,ready
    INC A
    LD (frame_counter),A
    XOR A
    RET
ready:
    LD A,B
    RET
start_over:
    XOR A
    LD (frame_counter),A
    JP $8283
tick_and_advance:
    PUSH HL
    PUSH BC
    LD HL,$8F0B
    LD B,5
scan:
    LD A,(HL)
    OR A
    JR NZ,play
    INC HL
    DJNZ scan
    JR continue
play:
    LD B,10
    LD C,32
    CALL $8A28
continue:
    POP BC
    POP HL
    JP $8237
