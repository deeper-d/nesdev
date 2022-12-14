; 我们要运行的程序 app0.nes 要自己编译生成（看完本程序你就会了）
; app0.nes 有 16 字节文件头
; 16k 程序
; 8k 图块数据

; fc 的地址线是 16 位
; 所以可寻址范围（可访问的内存）是 64k
; 其中
; 0-32k   暂时不管
; 32k-48k 我们的 16k 程序在这里
; 48k-64k 我们的 16k 程序会复制一份在这里

; 也就是说我们的 16k 程序会在运行时寻址内存的后 32k 中


; fc 编程里面，我们用 $10 表示十六进制数字 0x10
; -----
; 程序的入口写在内存地址倒数 3 4 的地方
; fc 的 cpu 是小端序，所以：
; $fffc (65532) 存地址的低位
; $fffd (65533) 存地址的高位
; 在我们这个程序中，地址是 $8000 或者 $c000
; （16k 程序复制一份后 c000 就是和 8000 一样的内容了）


; 这个程序是 fc 的标准汇编，Apple II 也是用的这款 cpu
; 在命令行用如下命令可以把这个文件编译为一个 app0.nes 程序
; win 下
; nesasm.exe app0.asm
;
; mac 下运行程序可能需要 chmod 和 xattr -c
; mac 下
; nesasm.mac app0.asm
;
; 可以使用 nestopia 运行生成的 app0.nes 程序


;;;;;;;;;;;;;;;
; 语法说明
; 0, 点开头的是伪指令
; 1, 只有 label 可以顶格
; 2, 其他任何代码都要缩进
; 3, 看不懂的地方 用心去感受 不要太究细节
;;;;;;;;;;;;;;;



; 这是文件头的定义，套路，和气球大战的文件头相似
; 总之，我们写的所有的程序都是这 4 行套路
; 而这 4 行具体代表什么，who cares?
    .inesprg 1
    .ineschr 1
    .inesmap 0
    .inesmir 1




;;;;;;;;;;;;;;;
; bank0
;;;;;;;;;;;;;;;
; .org 表示下面的 label 算地址的时候从 $8000 算起
; __main 和 mainLoop 都是 label
    .bank 0
    .org $8000 

__main:
mainLoop:
    ; 这里生成的机器码是 4c 00 80 
    JMP mainLoop




;;;;;;;;;;;;;;;
; bank1
;;;;;;;;;;;;;;;
    .bank 1
; 在 fffc 存程序入口地址
; 标准汇编一般把这个叫做【中断向量】
; 为啥是中断（因为程序会跳转到别的地方）向量（因为这是一个数字）
; .dw 表示要写入一个 word（2 字节）
; 千万别以为 word 就是标准术语永远是 2 字节
; 以后你会知道 arm 里的 halfword 表示 2 字节
; 这些都是各自混用的垃圾名词体系
    .org $fffc
    .dw __main




;;;;;;;;;;;;;;;
; bank2
;;;;;;;;;;;;;;;
; 下面 3 行是套路，意会，我也没想过为啥要是这样写
; 因为我知道想这个毫无意义
; balloon.tile 就是 balloon.nes 文件的最后 8k 的图块数据
    .bank 2
    .org $0000
    .incbin "balloon.tile"
