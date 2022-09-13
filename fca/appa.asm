; 本作业演示了【高级手柄读取】
; 请参考之前作业中的 updateInput
; 试着把控制改为方向按钮来验证一下高级写法的优越性
; 
; 注意这个文件删除了很多与本例子不相干的代码
; updatePaddle 增加了新指令


    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1


    .rsset $0200
paddleX         .rs 1
buttonStatus    .rs 1


;;;;;;;;;;;;;;;
; bank0
;;;;;;;;;;;;;;;
    .bank 0
    .org $8000
__main:
        ; setup stack at 0x1FF
    LDX #$FF            ;162, 255,
    TXS                 ;154 
        ; 设置 ppu
    LDA #%10000000      ; 169, 128, 141, 0, 32, 169, 16, 141, 1, 32,
    STA $2000           ;
    LDA #%00010000      ;
    STA $2001           ;

    JSR setupPaddle     ; 32, 19, 128,

mainLoop:
    JMP mainLoop        ; 76, 16, 128,



setupPaddle:
        ; 设置 sprite0 的 4 个属性
    LDA #$10        ;169, 16, 141, 0, 0, 169, 0, 141, 1, 0, 169, 0, 141, 2, 0, 169, 16, 141, 3, 0, 
    STA $0000
    LDA #0          ; tile index
    STA $0001
    LDA #%00000000
    STA $0002
    LDA #$10
    STA $0003
    ; 
    RTS             ; 96



__nmi:
    JSR updateInput ;32, 72, 128, 32, 50, 128, 32, 61, 128, 64,
    JSR update
    JSR draw
    RTI


update:
    JSR updatePaddle ; 32, 54, 128, 96, 
    RTS


updatePaddle:
        ; 增加 2 个新指令吧
    LDY paddleX     ; 172, 0, 2,
    STY $0003       ; 140, 3, 0,
    ;
    RTS             ; 96


draw:
        ; oam dma
    LDA #$00       ; 169, 0, 141, 3, 32, 169, 0, 141, 20, 64,
    STA $2003
    LDA #$00
    STA $4014
    ;
    RTS             ; 96




updateInput:
        ; 设置读取模式
    LDA #1              ; 169, 1,   141, 22, 64,   169, 0,   141, 22, 64,
    STA $4016
    LDA #0
    STA $4016
        ; 用循环读 8 个按键状态
        ; 为了用 bne 来方便做循环
        ; 所以我们从 8 用 dex 减减到 0
        ; 这是一个新的循环方式
        ; 我们在例子中逐渐增加新指令，这样模拟器就不知不觉模拟完了
    ldx #8              ; 162, 8,
updateInputReadLoop:
        ; 循环 8 次依次读取 A B Select Start Up Down Left Right 信息
        ; 
    LDA $4016           ; 173, 22, 64, 
        ; LSR 指令见下面链接
        ; http://obelisk.me.uk/6502/reference.html#LSR
        ; 
        ; lda 4016 后寄存器 A 里面存储了一个数字 0 或 1
        ; 根据上方链接 lsr a 会设置 carry flag (Set to contents of old bit 0)
    LSR A               ; 74
        ; 
        ; ROL 指令参考下方链接
        ; http://obelisk.me.uk/6502/reference.html#ROL
        ; 
        ; Bit 0 is filled with the current value of the carry flag
        ; 左移 1 位, 并且把 bit0 设置为 carry flag 的值
        ; 注意这个指令操作的是内存
        ; 还有就是你不知道这是哪个寻址模式
        ; 请用 nesasm 生成的 nes 文件来验证
    ROL buttonStatus    ; 46, 1, 2
        ; x--
    DEX                 ; 202
        ; if x != 0: 
    BNE updateInputReadLoop
    ; --------
    ; loop end
    ; --------

        ; 循环结束后 buttonStatus 中的 8 个 bit 就会存储 A B Select Start Up Down Left Right 的按键信息
        ; 
        ; bit7 就是按键 A
    LDA buttonStatus        ; 173
    AND #%10000000          ; 41, 128
        ; BEQ 的判定条件是 zero flag
        ; AND 生成 zero flag 的条件是 A = 0
        ; 所以 buttonStatus 的 bit0 是 1 或者 0 决定了 zero flag
        ; 因为和 0b0000.0001 & 的话高 7 位必定是 0
    BEQ actionEnd1
        JSR moveRight
actionEnd1:
        ; 
        ; bit6 就是按键 B
    LDA buttonStatus
    AND #%01000000
    BEQ actionEnd2
        JSR moveLeft
actionEnd2:
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




;;;;;;;;;;;;;;;
; bank1 bank2
;;;;;;;;;;;;;;;
    .bank 1
    .org $FFFA
    .dw __nmi
    .dw __main
; 
    .bank 2
    .org $0000
    .incbin "balloon.tile"