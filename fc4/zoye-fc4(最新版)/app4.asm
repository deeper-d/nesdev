    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1



;;;;;;;;;;;;;;;
; bank0
;;;;;;;;;;;;;;;
    .bank 0
    .org $8000 


__main:
    LDA #%10010000
    STA $2000
    LDA #%00011010
    STA $2001

    LDA $2002
    LDA #$20
    STA $2006
    LDA #$00
    STA $2006

        ; 用循环来写入
    LDX #0
SetupBGLoop:
        ; load (_data_background + X)
        ; 也就是 _data_background + 0
        ;       _data_background + 1
        ;       _data_background + ...
        ;       _data_background + 15
    LDA _data_background, x
    STA $2007
    INX
        ; compare x with 0x10
        ; branch if not equal
    CPX #$10
    BNE SetupBGLoop

        ; 
        ; 下面这个【clear scroll】注释很精妙
        ; 没有注释你倒释然了
        ; 这种语焉不详的一句话注释会让你怀疑自己，怎么别人这么简单的东西我就是看不懂呢

        ; clear scroll
    LDA #0
    STA $2005
    STA $2005

mainLoop:
    JMP mainLoop


    ; nmi 直接 RTI 了
    ; 虽然这个程序没用上 nmi 但就这么放着吧
__nmi:
    RTI


    ; 这里存放了 15 个数据
    ; 方便我们用循环来写入
_data_background:
    .db $10,$11,$12,$3,$4,$5,$6,$7,$8,$9,$a,$b,$c,$d,$e,$f


;;;;;;;;;;;;;;;
; bank1
;;;;;;;;;;;;;;;
    .bank 1
    .org $fffa
    .dw __nmi
    .dw __main




;;;;;;;;;;;;;;;
; bank2
;;;;;;;;;;;;;;;
    .bank 2
    .org $0000
    .incbin "balloon.tile"
