; EL CIRCO DIMENSIONAL — ZX Spectrum 48K, Z80
; UNICA CORRECCION: O/P POR PULSACIONES (sin autorrepeticion)
; Aplica este parche al binario original definitivo cargado en $8000.
; Direcciones contrastadas con el ASM definitivo V12.

MOVE_CD           EQU $8EDB ; reutilizado: mascara de teclas pulsadas
PLAYER            EQU $8ED8
PLAYER_MOVED      EQU $8F07
KEY_FIRE_ORIGINAL EQU $8133

ORG $80EC
    JP teclado_por_toques

ORG $E024
teclado_por_toques:
    PUSH BC
    LD A,$DF
    IN A,($FE)
    AND $03
    XOR $03           ; O = bit 1, P = bit 0 (1 significa pulsada)
    LD B,A
    LD A,(MOVE_CD)   ; mascara del fotograma anterior
    XOR $03
    AND B            ; solo teclas que acaban de pasar de 0 a 1
    LD C,A
    LD A,B
    LD (MOVE_CD),A   ; guardar pulsaciones actuales, incluso en los bordes

    LD A,C
    AND $02           ; O pulsada por primera vez
    JR Z,ver_p
    LD A,(PLAYER)
    OR A
    JR Z,terminar
    DEC A
    LD (PLAYER),A
    LD A,1
    LD (PLAYER_MOVED),A
    JR terminar

ver_p:
    LD A,C
    AND $01           ; P pulsada por primera vez
    JR Z,terminar
    LD A,(PLAYER)
    CP 4
    JR Z,terminar
    INC A
    LD (PLAYER),A
    LD A,1
    LD (PLAYER_MOVED),A

terminar:
    POP BC
    JP KEY_FIRE_ORIGINAL ; deja el codigo original de ESPACIO intacto
