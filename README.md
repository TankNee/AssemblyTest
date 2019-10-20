
## 完成汇编程序设计课设要求
- 程序开始有个选项栏，里面有2个选项：
- 1、输入成绩，以图5.20的形式输入最多N个同学的学号、分数、名次信息，N可以在程序中预定义，输入过程中如果超过这个N，出现超标提示停止输入（上交作业时可预先定义N为10,即最多只能输入10个人的成绩），按回车健停止输入成绩，回到选项栏。
- 2、查询成绩：按学号查询成绩，显示格式按书中定义；按回车健停止查询成绩，回到选项栏。无论输入成绩或查询成绩过程中，键入‘Q’退出整个程序。

### 程序设计结构
1. 宏汇编：

   ```assembly
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
   ```

2. 数据段设计：

      ```assembly
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
      ```

3. 程序段设计（code segment）：

      - 程序初始化

        ```assembly
        start:
            mov ax,data
            mov ds,ax
            mov bx,1
            lea di,SEARCH_BUF   ; 输入字符的起始地址
        ```

      - 菜单显示：

        ```assembly
        menuloop:    
            call showmenu
            call menuchoice
            jmp menuloop
        ```

      - 退出程序：

        ```assembly
        exit:    
            mov ax,4C00H
            int 21H
        ```

      - 输入成绩子程序部分：

        ```assembly
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
        ```

      - 成绩查询子程序：

        ```assembly
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
        ```

      - 输入缓冲区清零子程序：

        ```assembly
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
        ```

4. 程序运行截图：

      - 初始化界面：

        <img src="https://img.tanknee.cn/img/20191020200003.png">

      - 输入程序界面：

        <img src="https://img.tanknee.cn/img/20191020200220.png"/>

        每个部分用空格隔开，可以连续输入十个人的学号，成绩，排名

        <img src="https://img.tanknee.cn/img/20191020200300.png"/>

      - 查询成绩界面：

        输入学号，查询该同学的成绩排名！

        <img src="https://img.tanknee.cn/img/20191020200436.png"/>
        

### 本文首发于-[我的博客]([https://tanknee.cn/2019/10/20/%E6%B1%87%E7%BC%96%E7%A8%8B%E5%BA%8F%E8%AE%BE%E8%AE%A1](https://tanknee.cn/2019/10/20/汇编程序设计))

声明：归舟棹远|版权所有，违者必究|如未注明，均为原创|本网站采用[BY-NC-SA](https://creativecommons.org/licenses/by-nc-sa/3.0/)协议进行授权

转载：转载请注明原文链接 - [汇编程序设计](https://tanknee.cn/2019/10/20/汇编程序设计)