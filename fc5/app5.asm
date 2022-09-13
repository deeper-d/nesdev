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
    LDA #%00010010
    STA $2001

        ; 介绍一个全新概念 DMA(direct memory access)
        ; 
        ; 我们用内存 00-FF 这 256 字节来存放 OAM 数据
        ; 然后通过一次性拷贝这 256 字节到 OAM 的方式来显示
        ; 这是更好更方便的方法
        ; 
        ; 设置 sprite0 的 4 个属性
    LDA #$10
    STA $0000
    LDA #$00
    STA $0001
    LDA #$00
    STA $0002
    LDA #$10
    STA $0003

mainLoop:
    JMP mainLoop



__nmi:
        ;  写入 2003 来设置 OAM DMA 的 lb(low byte)
    LDA #$00
    STA $2003
        ; 写入 4014 设置 hb(high byte)
        ; 然后系统会自动从 (hb << 8) + lb 的地址开始读取 256 字节并写入 OAM
    LDA #$00
    STA $4014
        ; 
    RTI




;;;;;;;;;;;;;;;
; bank1
;;;;;;;;;;;;;;;
    .bank 1
    .org $fffa
    .dw __nmi
    .dw __main




;;;;;;;;;;;;;;;
; bank1
;;;;;;;;;;;;;;;
    .bank 2
    .org $0000
    .incbin "balloon.tile"
