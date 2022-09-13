; 本作业演示了【调色板】和【oam 属性】
;
; oam 属性就是 sprite 的 byte 2
; 这次作业只用了 3 个属性 
; 分别是  bit7    bit6    bit1 bit0
; 
; https://wiki.nesdev.com/w/index.php/PPU_OAM
; Byte 2
; Attributes
; 
; 76543210
; ||||||||
; ||||||++- Palette (4 to 7) of sprite
; |||||      这 2 bit 表示 sprite 的调色板，括号里的 4-7 是啥意思你就猜吧，反正链接里他也没写
; |||+++--- Unimplemented
; ||+------ Priority (0: in front of background; 1: behind background)
; |+------- Flip sprite horizontally
; +-------- Flip sprite vertically


    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1


    .rsset $0200
paddleX  .rs 1  ; 地址 200


;;;;;;;;;;;;;;;
; bank0
;;;;;;;;;;;;;;;
    .bank 0
    .org $8000 

__main:
        ; setup stack at 0x1FF
    LDX #$FF
    TXS
        ; 设置 ppu
    LDA #%10000000
    STA $2000
    LDA #%00010000
    STA $2001

    JSR setupPaddle
        ; 这个函数设置了调色板
    JSR setupPalette

mainLoop:
    JMP mainLoop


    ; 我们之前的作业给出了调色板下标表示的颜色值
    ; 下面的链接中有颜色图，可以有直观的感受（不过本作业不看也一样）
    ; https://wiki.nesdev.com/w/index.php/PPU_palettes
_data_palette:
        ; 背景和 sprite 各有 4 个调色板
        ; 所以上面说的 4-7 说的是【调色板一共有 8 个，背景用前四个（0-3），oam 用后四个（4-7）】
        ; 一共 16 * 2 = 32 字节数据
        ; nt palette
    .db $0,$1,$2,$3,  $0,$4,$5,$6,  $0,$7,$8,$9,  $0,$a,$b,$c
        ; oam palette
    .db $0,$11,$12,$13,  $0,$14,$15,$16,  $0,$17,$18,$19,  $0,$1a,$1b,$1c


    ; https://wiki.nesdev.com/w/index.php/PPU_memory_map
    ; $3F00-$3F1F    $0020    Palette RAM indexes
setupPalette:
        ; read 2002 to reset 2006 high/low 
    LDA $2002
        ; set ppu.addr
    LDA #$3F
    STA $2006
    LDA #$00
    STA $2006
        ; 循环写入 32 字节的调色板
    LDX #0
setupPaletteLoop:
    LDA _data_palette, x
    STA $2007
    INX
    CPX #$20
    BNE setupPaletteLoop
    ;
    RTS


setupPaddle:
        ; 我们用内存 00-FF 这 256 字节来存放 OAM 数据
        ; 然后通过一次性拷贝 256 字节到 OAM 的方式来显示

        ; 设置 sprite0 的 4 个属性
    LDA #$10
    STA $0000
    LDA #0          ; tile index
    STA $0001
    LDA #%00000000  ; 这次作业要实现的属性
    STA $0002
    LDA #$10
    STA $0003

        ; 设置 sprite1 的 4 个属性
    LDA #$10
    STA $0004
    LDA #0          ; tile index
    STA $0005
    LDA #%01000001  ; 这次作业要实现的属性
    STA $0006
    LDA #$18
    STA $0007

        ; 设置 sprite2 的 4 个属性
    LDA #$10
    STA $0008
    LDA #0          ; tile index
    STA $0009
    LDA #%10000010  ; 这次作业要实现的属性
    STA $000a
    LDA #$20
    STA $000b

        ; 设置 sprite3 的 4 个属性
    LDA #$10
    STA $000c
    LDA #0          ; tile index
    STA $000d
    LDA #%11000011  ; 这次作业要实现的属性
    STA $000e
    LDA #$28
    STA $000f

    RTS



__nmi:
    JSR updateInput
    JSR update
    JSR draw
    RTI


update:
    JSR updatePaddle
    RTS


updatePaddle:
    LDA paddleX
    ;
    STA $0003
    ;
    CLC
    ADC #$8
    STA $0007
    ;
    CLC
    ADC #$8
    STA $000b
    ;
    CLC
    ADC #$8
    STA $000f
    ;
    RTS


draw:
        ;  写入 2003 设置 lb(low byte)
    LDA #$00
    STA $2003
        ; 写入 4014 设置 hb(high byte)
        ; 然后系统会自动从 hb << 8 + lb 的地址开始读取 256 字节并写入 OAM
    LDA #$00
    STA $4014
    ;
    RTS




moveLeft:
    LDA paddleX
    SEC
    SBC #1
    STA paddleX
    ;
    RTS

moveRight:
    LDA paddleX
    CLC
    ADC #1
    STA paddleX
    ;
    RTS

updateInput:
    ; 设置读取模式  这 4 行是套路
    LDA #1
    STA $4016
    LDA #0
    STA $4016
ButtonA: 
    LDA $4016
    AND #%00000001
    ; 没按就跳到 ButtonAEnd（跳过按键逻辑）
    BEQ ButtonAEnd
        ; 按了
        JSR moveRight
ButtonAEnd:
ButtonB: 
    LDA $4016
    AND #%00000001
    ; 没按就跳到 ButtonAEnd（跳过按键逻辑）
    BEQ ButtonBEnd
        JSR moveLeft
ButtonBEnd:
    ;
    RTS




;;;;;;;;;;;;;;;
; bank1
;;;;;;;;;;;;;;;

    .bank 1

; 3 个中断向量
    .org $FFFA
    .dw __nmi
    .dw __main




;;;;;;;;;;;;;;;
; bank2
;;;;;;;;;;;;;;;
    
    .bank 2
    .org $0000
    .incbin "balloon.tile"
