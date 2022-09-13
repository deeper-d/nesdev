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
        ; 0x2001 这个内存地址实际上是一个 PPU 寄存器叫做 PPUMASK
        ; 这里设置 2001 的 bit5 为 1 表示【要显示 OAM 里面的 sprite】
        ; （所以你可以试试设置 2001 为 0 验证看看是否 OAM 不显示了）
        ; 具体见下面链接, 但我们现在可以不用管别的设置
        ; https://wiki.nesdev.com/w/index.php/PPU_registers#PPUMASK
    LDA #%00010000              ; 169, 16,
    STA $2001                   ; 141, 1, 32


        ; 0x2003 这个内存地址实际上是一个 PPU 寄存器叫做 OAMADDR
        ; OAM 是一个长度 256 字节的特殊内存
        ; 我们在这里往 2003 写入 0 表示我们接下来要写入 OAM 内存的地址 0
    LDA #0                      ; 169, 0,
    STA $2003                   ; 141, 3, 32,

        ; 0x2004 也是一个 PPU 寄存器叫做 OAMDATA
        ; 我们往 2004 写入 1 字节后
        ; 2003 里的 OAM 地址会自动 +1
        ; 所以我们这里往 2004 连续写入了 4 个字节就等于设置了 OAM 内存的前 4 个字节
        ; 
        ; 接下来按顺序写入 y    index    attribute    x
        ; oam[0] = 0x10
        ; 也就是 sprite0.y = 16
    LDA #$10                    ;  169, 16, 
    STA $2004                   ; 141, 4, 32

        ; oam[1] = 0
        ; 也就是 sprite0.tileIndex = 0
    LDA #0                      ; 169, 0,
    STA $2004                   ; 141, 4, 32,

        ; oam[2] = 0
        ; 也就是 sprite0.attribute = 0
    LDA #0                      ; 169, 0,
    STA $2004                   ; 141, 4, 32,

        ; oam[3].x = 0x10
        ; 也就是 sprite0.x = 16
    LDA #$10                    ; 169, 16,
    STA $2004                   ;  141, 4, 32,


mainLoop:
    JMP mainLoop                ; 76, 30, 128,




;;;;;;;;;;;;;;;
; bank1
;;;;;;;;;;;;;;;
    .bank 1

    .org $fffc
    .dw __main




;;;;;;;;;;;;;;;
; bank2
;;;;;;;;;;;;;;;
    .bank 2
    .org $0000
    .incbin "balloon.tile"
