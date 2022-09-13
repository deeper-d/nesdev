; 本作业演示了变量的使用
; 

; 你需要自行完成 app7.fc7 程序
; 新指令需要和其他人保持一致，所以得商量出来
    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1


        ; 这是 fc asm 定义变量的方式
        ; 我们用 0-ff 存储了 256 字节的 oam 数据
        ; 100 - 1ff 是系统保留栈
        ; 所以我们的变量是 200 开始
        ; 这是标准汇编定义变量的套路
        ; 用心去感受
        ; .rsset 标明了变量在内存中的地址
    .rsset $0200
; 变量名  .rs  变量长度
paddleX  .rs 1  ; 地址 200
paddleY  .rs 2  ; 地址 201  这个变量占用 2 字节，不过本例子中没有用到
paddleZ  .rs 1  ; 地址 203  这个变量占用 1 字节，不过本例子中没有用到


; fc7 的对应语法如下
; .vars 0x200
;     paddleX 1
;     paddleY 2
;     paddleZ 1
; .vars_end


;;;;;;;;;;;;;;;
; bank0
;;;;;;;;;;;;;;;
    .bank 0
    .org $8000 


__main:
        ; setup stack
    LDX #$FF                ; 162, 255
    TXS                     ; 154
        ; setup PPU
    LDA #%10000000          ; 169, 128
    STA $2000               ; 141, 0, 32,
    LDA #%00010000          ; 169, 16,
    STA $2001               ; 141, 1, 32,

        ; setup paddle
    JSR setupPaddle         ; 32, 19, 128,

mainLoop:
    JMP mainLoop            ; 76, 16, 128


    ; 这个函数复制粘贴的 4 个相似代码看起来很蠢
    ; 为什么不用循环来设置 4 个 sprite?
setupPaddle:
        ; 这里存入 4 个 sprite
        ; 设置 sprite0 的 4 个属性
    LDA #$10                ; 169, 16, 
    STA $0000               ; 141, 0, 0,
    LDA #$00                ;169, 0, 
    STA $0001               ;141, 1, 0,
    LDA #$00                ;169, 0,
    STA $0002               ;141, 2, 0,
    LDA #$10                ;169, 16, 
    STA $0003               ;141,3, 0,

        ; 设置 sprite1 的 4 个属性
    LDA #$10        ;169, 16,
    STA $0004       ; 141, 4, 0,
    LDA #$00        ;169, 0, 
    STA $0005       ;141, 5, 0,
    LDA #$00        ;169, 0,
    STA $0006       ;141, 6, 0, 
    LDA #$18        ;169, 24, 
    STA $0007       ;141, 7, 0, 

        ; 设置 sprite2 的 4 个属性
    LDA #$10        ; 169, 16,
    STA $0008       ;   141, 8, 0,
    LDA #$00        ;169, 0,
    STA $0009       ;141, 9, 0,
    LDA #$00        ;169, 0, 
    STA $000a       ;141, 10, 0,
    LDA #$20        ;169, 32,
    STA $000b       ;141, 11, 0,

        ; 设置 sprite3 的 4 个属性
    LDA #$10        ;169, 16,
    STA $000c       ;141, 12, 0, 
    LDA #$00        ;169, 0,
    STA $000d       ;141, 13, 0, 
    LDA #$00        ;169, 0, 
    STA $000e       ;141, 14, 0,
    LDA #$22        ;169, 34,
    STA $000f       ; 141, 15, 0,
    ;
    RTS             ; 96
; 对于示例程序来说，这样写更简单
; 一个例子只演示一个简单的变化，学习门槛大大降低
;
; 不过
; 你可以试试自己把它优化为一个循环读取 16 字节预定义的数据


__nmi:
        ; 在 udpateInput 中根据按键计算出 paddle.x 并存入变量 0x200 中
    JSR updateInput     ; 32, 170, 128,
        ; 在 update 中根据变量 0x200 去设置 4 个 sprite 的 x 坐标 
    JSR update          ; 32, 110, 128,
        ; 调用 oam dma 画图
    JSR draw            ; 32, 139, 128,
        ; 
    RTI                 ; 64,


update:
    JSR updatePaddle    ; 32, 114, 128,
    RTS                 ; 96,


updatePaddle:
    LDA paddleX         ; 173, 0, 2,
    ;
    STA $0003           ; 141, 3, 0, 
        ; CLC 一定需要吗？
        ; 不一定
        ; 但是无脑加上就不用想了
        ; 真正的天才不会浪费时间做无意义的事情
        ; 抓大放小才是极限优化
        ; 常人看来的低级错误只不过是专家的排水渠过弯
    CLC                 ; 24,
    ADC #$8             ; 105, 8,
    STA $0007           ; 141, 7, 0,
        ;
    CLC                 ; 24,
    ADC #$8             ; 105, 8, 
    STA $000b           ; 141, 11, 0,
        ;
    CLC                 ; 24, 
    ADC #$8             ; 105, 8,
    STA $000f           ; 141, 15, 0,
        ;
    RTS                 ; 96


draw:
        ; OAM DMA
    LDA #$00            ; 169, 0, 
    STA $2003           ; 141, 3, 32,
    LDA #$00            ;169, 0, 
    STA $4014           ;141, 20, 64,
        ;
    RTS                 ; 96




moveLeft:
    LDA paddleX         ;173, 0, 2,
    SEC                 ;56
    SBC #1              ;233, 1, 
    STA paddleX         ;141, 0, 2,
    ;
    RTS                 ;96

moveRight:
    LDA paddleX         ;173, 0, 2,
    CLC                 ;24, 
    ADC #1              ;105, 1, 
    STA paddleX         ;141, 0, 2,
    ;   
    RTS                 ;96,


updateInput:
        ; 设置读取模式
    LDA #1              ; 169, 1,  141, 22, 64,  169, 0,  141, 22, 64, 
    STA $4016
    LDA #0
    STA $4016
ButtonA: 
    LDA $4016           ; 
    AND #%00000001
    BEQ ButtonAEnd
        ; 按了
        JSR moveRight
ButtonAEnd:
;
ButtonB: 
    LDA $4016
    AND #%00000001
    BEQ ButtonBEnd
        JSR moveLeft
ButtonBEnd:
    ;
    RTS




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