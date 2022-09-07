;;;;;;;;;;;;;;;
; 本作业用到的元素说明
; -----
;
; 算术寄存器 A
; 栈寄存器 S
; 状态寄存器 P
; 完整在下面链接但这里只用到 S P
; https://www.nesdev.org/wiki/CPU_registers
;
; 状态寄存器
; https://www.nesdev.org/wiki/Status_flags
;;;;;;;;;;;;;;;
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
        ; 0x2000 这个内存地址实际上是一个 PPU 寄存器叫做 PPUCTRL
        ; 这里设置 2000 的 bit7 为 1 表示【每帧要调用一个回调函数（称之为 vblank 中断，也叫做 nmi）】
        ; （所以你可以试试设置 2000 为 0 验证看看是否 nmi 不调用了）
        ; PPUCTRL 的具体设置见下面链接, 但我们现在可以不用管别的设置
        ; https://wiki.nesdev.com/w/index.php/PPU_registers#PPUCTRL
    LDA #%10000000          ; 169, 128           
    STA $2000               ; 141, 0, 32,

        ;---------------------------- 开启精灵图
    LDA #%00010000          ; 169, 16,
    STA $2001               ; 141, 1, 32

        ;---------------------------- 连续写入 oam 的前四位值
        ; 
        ; 写入 OAM 地址 0 
    LDA #0                  ; 169, 0,
    STA $2003               ; 141, 3, 32,
        ; 接下来写入 y    index    attribute    x
        ; y = 16
    LDA #$10                ; 169, 16,
    STA $2004               ; 141, 4, 32,
        ; tile index = 0
    LDA #0                  ; 169, 0,
    STA $2004               ; 141, 4, 32,
        ; attribute = 0
    LDA #0                  ; 169, 0,
    STA $2004               ; 141, 4, 32,
        ; x = 16
    LDA #$10                ; 169, 16,
    STA $2004               ; 141, 4, 32,

    ; 
mainLoop:                   
    JMP mainLoop            ; 76, 35, 128,




; 【NMI 回调】
; 由于 PPUCTRL 做了设置  所以这个【NMI 回调】每帧都会被调用一次
; 我们就可以在这里检查手柄
; 
; 这里展开说明一下 nmi 的实现机制，方便我们写 nes2.gua
; 首先这个中断向量（也就是回调地址，他们把这个回调叫做 【中断（interrupt）】）是写在 fffa fffb 里的 (#即 倒数 5、6 位)
; 参见本程序末尾

; fc 有 2k 内存（也就是 8 个 256 内存）是可以用于存储数据的
; 其他内存地址未必是内存，比如 0x2000 就不是内存
; 这 2k 内存（真正的内存）在地址 0-7ff（2047） 之间
; 0x000 - 0x0ff     第 1 个 256 字节内存    page 0
; 0x100 - 0x1ff     第 2 个 256 字节内存    page 1  栈 
; 0x200 - 0x2ff     第 3 个 256 字节内存    page 2
; 0x300 - 0x3ff     第 4 个 256 字节内存    page 3
; 0x400 - 0x4ff     第 5 个 256 字节内存    page 4
; 0x500 - 0x5ff     第 6 个 256 字节内存    page 5
; 0x600 - 0x6ff     第 7 个 256 字节内存    page 6
; 0x700 - 0x7ff     第 8 个 256 字节内存    page 7

; fc 里面把 256 字节叫做 page
; page 0 就是 0x00 - 0xff
; ...
; page 7 就是 0x700 - 0x7ff


; fc 有一个 S 寄存器，初始化的默认值是 0xff
; fc 用它来当【栈寄存器】
; cpu 把 page1 的 256 字节当做栈
; 也就是说 S 寄存器的值 加上 0x100 就是实际 cpu 会去操作的栈地址
; 压栈的时候，数据会存到地址 0x01ff 然后 S 变成 0x01fe


; fc 会在每一帧触发 nmi 中断（回调）
; 回调的具体步骤是
; 1，保存程序的状态
;     1) pc 压栈
;         由于 pc 是 16bit(s)
;         先压 high 8 bit(s)
;         再压 low 8 bit(s)
;             这个高低压参考资料
;             https://archive.org/details/6500-50a_mcs6500pgmmanjan76/page/n119/mode/2up
;     2) 状态寄存器压栈
; 2，跳转到 fffa fffb 存储的地址(nmi 中断向量)中去执行回调代码

; 假设现在 S 寄存器是 0xff
; 假设下一条应该执行的地址（也就是 pc 的值）是 0x0203
; 假设状态寄存器的值为 0x01
; 那么 nmi 后
; 0x1ff 里面存的值是 0x02
; 0x1fe 里面存的值是 0x03
; 0x1fd 里面存的值是 0x01
; S 寄存器的值为 0xfc（0xff-3）



__nmi:
        ; 下面这 4 行是套路
        ; 先往 4016 写入 1 再写入 0 
        ; 然后就可以顺序读取 8 次，来获取到 8 个按键的状态
        ; 8 个按键分别如下
        ; 0 - A
        ; 1 - B
        ; 2 - Select
        ; 3 - Start
        ; 4 - Up
        ; 5 - Down
        ; 6 - Left
        ; 7 - Right
        ; 
        ; 我们这里只读取了 1 次，也就是按钮 A
    LDA #1              ; 169, 1,
    STA $4016           ; 141, 22, 64,
    LDA #0              ; 169, 0,
    STA $4016           ; 141, 22, 64,

ButtonA:
        ; 读取按钮 A 的状态到 A 寄存器（这句话中两个 A 表示的含义是不同的）
    LDA $4016           ; 173, 22, 64,
        ; 去看一下 AND 指令是怎么做【逻辑与】以及影响了什么 flag
        ; https://www.nesdev.org/obelisk-6502-guide/reference.html#AND
    AND #%00000001      ; 41, 1,
        ; 没按就跳到 ButtonAEnd（跳过按键逻辑）
        ; BEQ 看的是 zero flag 所以如果 A 中存的数字的 bit0 不是 1 那么 BEQ 就会执行跳转了
        ; 写汇编的时候就是这样，想怎么写就怎么写
        ; 当然这样不够好，只是汇编都这么写，你不这样写别人反而觉得你 low
        ; 
        ; https://www.nesdev.org/obelisk-6502-guide/reference.html#BEQ
        ; 需要注意的是，BEQ 是一个相对跳转，指令长度 2 字节，注意看上一行链接中的文档
        ; 也可以到 chat 讨论
    BEQ ButtonAEnd      ; 240, 14,
            ; 这里的缩进是逻辑上的缩进，方便看代码用
            ; 如果 BEQ 没跳转，表示按钮 A 被按了
            ; 我们让 sprite0.x++
            ; 
            ; 这里设置要操作 OAM 的内存地址 3
            ; 也就是第一个 sprite 的 x
        LDA #3          ; 169, 3,
        STA $2003       ;  141, 3, 32,
            ; 把 x 读出来并且 +1 再写回去
            ; A = sprite0.x
        LDA $2004       ;  173, 4, 32,
            ; A += 1
            ; ADC 前的 CLC 是必要的
        CLC             ; 24,
        ADC #1          ; 105, 1,
            ; sprite0.x = A
        STA $2004       ; 141, 4, 32, 
ButtonAEnd:
        ; 注意这个 RTI 指令
        ; 它的作用是从栈里复原 状态寄存器 和 PC 寄存器并且从中断返回
    RTI                 ; 64,



;;;;;;;;;;;;;;;
; bank1
;;;;;;;;;;;;;;;
    .bank 1
; 注意这里地址为 fffa 
; 并且多了一个 __nmi 的地址
    .org $fffa
    .dw __nmi
    .dw __main




;;;;;;;;;;;;;;;
; bank2
;;;;;;;;;;;;;;;
    .bank 2
    .org $0000
    .incbin "balloon.tile"
