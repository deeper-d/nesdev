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
; ppu 拥有 16k 的内存，也就是显存
; 卡带上的 8k 图块叫做 pattern table
; 存在在显存中的 0-1fff 的地方
; 前面 256 个 tile 的显存地址是 0000-0fff, 这叫 pattern table 0
; 后面 256 个 tile 的显存地址是 1000-1fff, 这叫 pattern table 1
; 
; bit4 为 0 表示背景使用 pattern table 0
; bit4 为 1 表示背景使用 pattern table 1
; bit3 为 0 表示 oam 使用 pattern table 0
; bit3 为 1 表示 oam 使用 pattern table 1
; 
; bit1 bit0 合起来表示要使用的 nametable 是哪个
; 我们这里设置为 00 表示我们要使用的 nametable 开始地址是显存地址 2000
; 注意这个 2000 说的是显存的地址 2000，而不是 CPU 可以访问到的 2000（PPUCTRL）
; 
; 
; 对 2000（PPUCTRL） 的设置文档如下
; 7  bit  0
; ---- ----
; VPHB SINN
; |||| ||||
; |||| ||++- Base nametable address
; |||| ||        (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
; |||| |+--- VRAM address increment per CPU read/write of PPUDATA
; |||| |         (0: add 1, going across; 1: add 32, going down)
; |||| |        这里是说写入 ppudata 后 ppuaddr 会增加几
; |||| |        0 表示 +1   going across 表示横着走
; |||| |        1 表示 +32  going down 表示竖着走（+32 等于 y+1）
; |||| +---- Sprite pattern table address for 8x8 sprites
; ||||             (0: $0000; 1: $1000; ignored in 8x16 mode)
; |||+------ Background pattern table address (0: $0000; 1: $1000)
; ||+------- Sprite size (0: 8x8 pixels; 1: 8x16 pixels)
; |+-------- PPU master/slave select
; |                    (0: read backdrop from EXT pins; 1: output color on EXT pins)
; +--------- Generate an NMI at the start of the
;                        vertical blanking interval (0: off; 1: on)



    LDA #%00011010
    STA $2001
; 2001 的这些设置看下面的文档
; https://wiki.nesdev.com/w/index.php/PPU_registers#PPUMASK
; 7  bit  0
; ---- ----
; BGRs bMmG
; |||| ||||
; |||| |||+- Greyscale (0: normal color, 1: produce a greyscale display)
; |||| ||+-- 1: Show background in leftmost 8 pixels of screen, 0: Hide
; |||| ||      这里是说 nametable 在屏幕上最左边的 8 个像素是否要显示
; |||| |+--- 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
; |||| +---- 1: Show background
; |||+------ 1: Show sprites
; ||+------- Emphasize red (green on PAL/Dendy)
; |+-------- Emphasize green (red on PAL/Dendy)
; +--------- Emphasize blue

        ; ppu 有 16k 显存
        ; nametable 我们设置了从【显存地址 2000】开始
        ; 所以写入 nametable 的时候要设置写入地址为 2000
        ; 所以要 2 字节才能设置好 2000 这个地址
        ; 先写入高 8 位到 2006 再写入低 8 位到 2006(PPUADDR)
        ; 所以先写入 20 再写入 00
        ; 
        ; 写入 2006 之前先读取一次 2002(PPUSTATUS) 来重置 PPUADDR 的写入状态
        ; 这是标准做法，所以要这样写
    LDA $2002
        ; 设置写入地址为 0x2000
    LDA #$20
    STA $2006
    LDA #$00
    STA $2006

        ; 开始写入 2007（PPUDATA）
        ; 和 oam 的写入一样, 这里写入后 PPUADDR 会自动增加
        ;     可以自动增加 1 或者 32, 这里我们设置的是 +1, 见上面的描述
        ; 由于气球大战的 pattern table 1 的前面几个 tile 分别是图案 “0 1 2 3”
        ; 所以这里写入的 0 1 2 3 显示的 tile 就是 0 1 2 3
        ; 气球大战这个游戏故意这样编排的, 可能是为了方便他们写程序吧
    LDA #0
    STA $2007
    LDA #1
    STA $2007
    LDA #2
    STA $2007
    LDA #3
    STA $2007
    LDA #4
    STA $2007
    LDA #5
    STA $2007
    LDA #6
    STA $2007
    LDA #7
    STA $2007
    LDA #8
    STA $2007
    LDA #9
    STA $2007
    ; 很多人看到这样的代码第一反应: 太蠢了竟然不用循环
    ; 但是教书要这样才最好, 尽可能屏蔽新的东西, 抓大放小
    ; 几行重复代码是没有成本的，但一个循环就要命了


        ; 对 2005（PPUSCROLL） 连续写入 2 次 0
        ; 这样才能让 nametable 在屏幕上正确显示
        ; 这是给标准模拟器用的设置
        ; 并且必须在写入 nametable 后做这个操作
        ; 你可以试试改变这个操作的顺序看效果会有什么变化
        ; 
        ; 文档地址如下，不过你现在也不应该看这个
        ; https://wiki.nesdev.com/w/index.php/PPU_registers
    LDA #0
    STA $2005
    STA $2005

mainLoop:
    JMP mainLoop



    ; nmi 直接 RTI 了
    ; 虽然这个程序没用上 nmi 但就这么放着吧
__nmi:
    RTI




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
