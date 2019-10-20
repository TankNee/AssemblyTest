.386
;字符输出
print_char macro X
    mov ah,2
    mov dl,X
    int 21H
    endm    ;结束（end）宏定义（macro）
;字符串输出
print_string macro X
    lea dx,X
    mov ah,9
    int 21H
    endm
;字符输入 将字符的ASCII码送入AL中去
getinput_char macro 
    mov ah,1
    int 21H
    endm
;字符串输入 将字符串送入一个缓冲区中
getinput_string macro X
    lea dx,X
    mov ah,10
    int 21H
    endm
; ;检查输入的学号等信息是否合法
; inc_res macro 
    
;     endm

data segment use16
     
    ENGLI   db 80 dup(20H)  ; 3*N个空间，用于存放学号成绩和排名（此处N=10）
            db 20H
    ; ENGLI   db 20H,31H,20H,33H,39H,20H,38H,20H,31H,33H,20H,35H,37H,20H,36H 
    ;         db 80 dup(20H)  ; 3*N个空间，用于存放学号成绩和排名（此处N=10）
    ;         db 20H
    SEARCH_BUF db 30 dup(0)
    MENU db 13,10
    	db '*~*~*~*~*~MENU*~*~*~*~*~*~*~*~*~*~*~*~*',13,10
    	db '@         1.INPUT                     @',13,10
    	db '@         2.FIND                      @',13,10
    	db '@-------------------------------------@',13,10
    	db '@         Q.QUIT                      @',13,10
    	db '*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*',13,10
    	db 'PLEASE INPUT YOUR CHOICE:$'

    INPUTNOTICE db 13,10
                db 'PLEASE INPUT THE SCORE:',13,10,'$'
    IDSCORERANK db 'ID  SCORE   RANK',13,10,'$'
    FINDNOTICE db 13,10
               db 'PLEASE INPUTU THE ID YOU ARE SEARCHING FOR:$'
    NOTFINDNOTICE db 13,10
                  db 'THE DATA YOU ARE FINDING ARE NOT EXIST !$'
    OUTOFBUF db 13,10
             db 'THE MAX OF INPUT WAS 10 PEOPLE!!$'
data ends
stack segment use16
    db 50 dup(0)
stack ends
code segment use16
    assume cs:code,ds:data
start:
    mov ax,data
    mov ds,ax
    mov bx,1
    lea di,SEARCH_BUF   ; 输入字符的起始地址
    ; mov dh,0    ; 查询时输入字符的定位指针
    ; lea esi,ENGLI
menuloop:    
    call showmenu
    call menuchoice
    jmp menuloop
exit:    
    mov ax,4C00H
    int 21H

; 菜单显示子程序
showmenu proc near
    mov ax,3    ;清屏
    int 10H
    print_string MENU   ;打印菜单
    ret
showmenu endp

; 选项控制子程序
menuchoice proc near
    getinput_char

    cmp al,'1'  ; 跳转到成绩输入子程序
    je inputscore

    cmp al,'2'  ; 跳转到查询子程序
    je findpeople

    cmp al,'q'  ; 实现按下q/Q键退出的功能
    je exit     ; 跳转到退出程序段
    cmp al,'Q'
    je exit

    getinput_char ;接受一个字符，暂停在该界面
    ret
menuchoice endp
; 成绩输入子程序
inputscore proc near
    mov bx,1
    mov cx,0
    mov dl,0
    print_string INPUTNOTICE
    print_string IDSCORERANK


inputloop:
    getinput_char
    cmp al,'q' ; 按下Q退出
    je exit
    cmp al,'Q'
    je exit
    cmp al,13
    je menuloop
    cmp al,20H
    je inputloop_inc

    mov [bx],al
    inc bx

    jmp inputloop
inputloop_inc:
    inc cx
    mov [bx],al
    inc bx

    cmp cx,29
    jae inputloop_output
    jmp inputloop

inputloop_output:
    print_string OUTOFBUF
    getinput_char
    cmp al,0DH
    je menuloop
    ret
inputscore endp


; 按学号查找记录子程序
findpeople proc near
    mov bx,1    ; 存储字符的定位指针
    mov si,0    ; 输入字符的计数器
    
    print_string FINDNOTICE
    jmp findloop
    
notfind:
    print_string NOTFINDNOTICE
    getinput_char
    jmp menuloop

inc_part:
    inc bx
    inc cx
    cmp cx,4
    jae search_complete
    jb print_data

print_data:
    ; mov cx,0    ; 空格计数器，当到达第三个空格时停止输出
    print_char [bx]
    mov dl,20H
    cmp [bx],dl
    je inc_part
    inc bx
    jmp print_data

output:
    dec bx
    mov dl,20H          ; 让bx自减到上一个为空格的地方
    cmp [bx],dl    ; 若为空格则开始输出
    je print_data
    jmp output


findnext_inc:
    inc cx
    inc bx
    jmp findnext
findnext:
    lea di,SEARCH_BUF
    cmp cx,3
    je checkloop
    mov dl,20H
    cmp [bx],dl
    je findnext_inc
    inc bx
    jmp findnext

checkloop_pre:
    mov dl,20H
    mov [di],dl
    lea di,SEARCH_BUF   ; 输入字符的起始地址
    ; dec di
    jmp checkloop

checkloop: 
    mov cx,0
    mov dh,[di]
    cmp [bx],dh   ; 比较存储的输入字符和数据段的字符
    jne findnext    ; 若不相等则去寻找下一个学号

    mov dl,20H      ; 判断是否是空格
    cmp [bx],dl
    je output

    mov dl,0DH      ; 判断是否是回车
    cmp [bx],dl
    je output

    inc bx
    inc di
    cmp bx,50H
    jb checkloop   ; 继续循环的条件是这个单元格里的字符既不是回车也不是空格，并且两个字符相同
    jmp notfind

findloop:           ; 用两个指针记住查询时输入的查询数据，再进行不断比较
    mov cx,0
    getinput_char

    cmp al,'q' ; 按下Q退出
    je exit
    cmp al,'Q'
    je exit

    cmp al,20H
    je checkloop_pre

    cmp al,0DH
    je checkloop_pre

    mov [di],al
    inc di
    inc si
    ; inc bx
    ; cmp bx,82
    jmp findloop


    ret
findpeople endp

search_complete proc near
    lea di,SEARCH_BUF
    
clearloop:
    
    mov dl,00H
    mov [di],dl
    inc di
    cmp di,70H
    jae complete
    jmp clearloop
complete:
    lea di,SEARCH_BUF
    getinput_char

    cmp al,0DH
    je menuloop

    cmp al,'q' ; 按下Q退出
    je exit
    cmp al,'Q'
    je exit
    ret
search_complete endp

code ends   ;结束（end）段（segment）
end start