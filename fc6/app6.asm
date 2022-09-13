; 你需要自行完成 app6.fc6 程序
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
        ; setup stack at 0x1FF
        ; 对我们的程序来说这不必要
        ; 但是别人的程序都这样写的
        ; 我们的模拟器也要实现这个指令才行
        ; 
        ; 此外 fc 有一个【重启】的功能
        ; 【重启】的时候会执行 __main 但 S 寄存器并不会被重置为 0xff
        ; 所以要手动重置
        ; 资料如下
        ; https://wiki.nesdev.com/w/index.php/CPU_power_up_state
        ; 但我们的程序其实用不着这个
    LDX #$FF                    ; 162, 255
    TXS                         ; 154,
        ; 
    LDA #%10010000              ; 169, 144
    STA $2000                   ; 141, 0, 32
    LDA #%00010010              ; 169, 18,
    STA $2001                   ; 141, 1, 32


        ; oam 数据
        ; 设置 sprite0 的 4 个属性
    LDA #$10                    ; 169, 16
    STA $0000                   ; 141, 0, 0,
    LDA #$00                    ; 169, 0
    STA $0001                   ; 141, 1, 0,
    LDA #$00                    ; 169, 0
    STA $0002                   ; 141, 2, 0,
    LDA #$10                    ; 169, 16,
    STA $0003                   ; 141, 3, 0,


mainLoop:
    JMP mainLoop                ; 76, 33, 128



__nmi:
        ; Jump to SubRoutine
        ; 根据文档 jsr 会把下一条指令的地址减 1 然后存入栈内存
        ; 然后开始跳转到新地址执行
    JSR udpate                  ; 32, 43, 128
        ; 我们的 .fc6 程序中 jsr 翻译作 call
    JSR draw                    ; 32, 80, 128
        ; 
    RTI                         ; 64


    ; update 在我们这里被当做一个函数来使用
    ; 由于是 jsr 跳转过来的
    ; 我们必须用 rts 返回到调用点
    ; rts 会从栈内存中 pop 出一个地址加 1 然后给 pc 跳转回去
udpate:
ButtonA: 
    LDA $4016                   ; 173, 22, 64
    AND #%00000001              ; 41, 1
    ; 没按就跳到 ButtonAEnd（跳过按键逻辑）
    BEQ ButtonAEnd              ; 240, 3  相对跳转
        ; 按了  去执行右移代码
        JSR moveRight           ; 32, 70, 128
ButtonAEnd:

ButtonB: 
    LDA $4016                   ; 173, 22, 64
    AND #%00000001              ; 41, 1
    ; 没按就跳到 ButtonAEnd（跳过按键逻辑）
    BEQ ButtonBEnd              ; 240, 9, 相对跳转
        ; 按了, 让 sprite0.x--
        ; A = sprite0.x
        LDA $3                  ; 173, 3, 0, 
        ; A -= 1
        ; sec 是必要的
        SEC                     ; 56
        SBC #1                  ; 233, 1
        ; sprite0.x = A
        STA $3                  ; 141, 3, 0,
ButtonBEnd:
    ; 我们的 .fc6 程序中 rts 要翻译为 return_from_call
    RTS                         ; 96


moveRight:
        ; 让 sprite0.x++
        ; A = sprite0.x
    LDA $3                      ;  173, 3, 0
        ; A += 1
        ; clc 是必要的
    CLC                         ; 24
    ADC #1                      ; 105, 1
        ; sprite0.x = A 
    STA $3                      ; 141, 3, 0
        ;
    RTS                         ; 96



draw:
        ;  写入 2003 来设置 OAM DMA 的 lb(low byte)
    LDA #$00                    ; 169, 0
    STA $2003                   ; 141, 3, 32,
        ; 写入 4014 设置 hb(high byte)
        ; 然后系统会自动从 hb << 8 + lb 的地址开始读取 256 字节并写入 OAM
    LDA #$00                    ; 169, 0
    STA $4014                   ; 141, 20, 64,
        ; 
    RTS                         ; 96






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
