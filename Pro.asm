;#############################################
;                 连线说明
;#############################################
; 8279
; 默认已接好
;
; 0809  ---
; SC/ALE---  输出 --- A或非门 --- 0FF20H+IOW
; OE    ---  输出 --- B或非门 --- 0FF20H+IOR
; IN0   ---  压力电压
;
; 8259  ---
; /CS   ---  320H
; INTA  ---  INTA
; INTR  ---  IRQR
; IRQ0  ---  OUT0
; IRQ1  ---  KEY1
; IRQ2  ---  KEY2
; IRQ3  ---  KEY3
;
; 8255  ---
; /CS   ---  300H
; A1    ---  LED1
; A2    ---  LED2
;
; 8253  ---
; /CS   ---  380H
; CLK0  ---  3M  (12M --- 1A --- 1QB)
; GATE0 ---  +5V
; OUT0  ---  IRQ0
; CLK1  ---  SPEED
; GATE1 ---  +5V



;#############################################
;                 系统说明
;#############################################
; 系统包括 1个6位数码管，2个LED，3个按键
; 一个电机，一个压力传感器
;
; 默认显示：转速_压力值
; 设置1：1___报警转速
; 设置2：2__报警压力
;
; 按键1切换显示内容
; 按键2减小
; 按键3增加
;
; 电机通过调节电压来控制转速，转速超过报警
; 转速时，LED1闪烁
;
; 压力传感器通过测量电压来判断压力，当压力
; 超过报警压力时，LED2闪烁




;#############################################
;                  地址说明
;#############################################
D8279   EQU     02F0H
C8279   EQU     02F1H

CS0809  EQU     0FF20H

M8259   EQU     0320H
C8259   EQU     0321H

CS8255  EQU     0303H
PARTA   EQU     0300H
PARTB   EQU     0301H
PARTC   EQU     0302H

CS8253  EQU     0383H
COUNT0  EQU     0380H
COUNT1  EQU     0381H
COUNT2  EQU     0382H



;#############################################
;                  数据段
;#############################################
DATA    SEGMENT
;---------------数码管显示缓冲区--------------
LEDBUF  DB     0, 0, 16, 0, 0, 0
;---------------0~F及空白对应段码-------------
LED     DB     0CH, 9FH, 4AH, 0BH
        DB     99H, 29H, 28H, 8FH
        DB     08H, 09H, 88H, 38H
        DB     6CH, 1AH, 68H, 0E8H
        DB     0FFH
;---------------计时初值，20msBASE------------
TIM2HMS DB     10
TIM1S   DB     50
TIM4S   DB     200
;---------------到计时标志位------------------
FLG2HMS DB     0FFH
FLG1S   DB     0FFH
FLG4S   DB     0FFH
;---------------当前速度及压力----------------
SPEED   DB     00H
VOLT    DB     00H
;---------------当前显示菜单------------------
MENU    DB     0
;---------------初始报警值--------------------
MAXSPD  DB     20
MAXVOL  DB     100
;---------------LED标志位---------------------
LEDSTA  DB     0FFH
LEDFLG1 DB     0FFH
LEDFLG2 DB     0FFH
DATA    ENDS



;#############################################
;                   堆栈段
;#############################################
SSTACK  SEGMENT
        DW     32   DUP(?)
SSTACK  ENDS



;#############################################
;                   代码段
;#############################################
CODE    SEGMENT
        ASSUME CS:CODE, DS:DATA, SS:SSTACK

;-------------------主函数--------------------
START   PROC NEAR
        MOV AX, 250EH
        INT 21H
        CALL SET8255
        CALL SET8259
        CALL SET8253
        CALL SET8279
        MOV AX, DATA
        MOV DS, AX
LOP:
        STI
        CALL LEDSER
        CALL SETSHOW
        CALL DISP
        MOV AX, 250EH
        INT 21H
        JMP LOP
START   ENDP

;---------------8255初始化--------------------
SET8255 PROC NEAR
        PUSH AX
        PUSH DX
        MOV DX, CS8255
        MOV AL, 80H      ;A口，方式0，输出
        OUT DX, AL
        POP DX
        POP AX
        RET
SET8255 ENDP

;----------------LED函数----------------------
LEDSER  PROC NEAR
        PUSH AX
        PUSH DX
        MOV AL, [FLG2HMS]
        CMP AL, 0
        JNZ ENDLED
        NOT FLG2HMS            ;到200ms计时
SPDLED:
        MOV AL, [SPEED]
        MOV AH, [MAXSPD]
        CMP AL, AH
        JB OFFSLED
        NOT LEDFLG1
        MOV AL, [LEDFLG1]
        CMP AL, 0
        JNZ SLED1
        MOV AL, [LEDSTA]
        OR AL, 00000010B
        MOV [LEDSTA], AL
        JMP SLED2
SLED1:
        MOV AL, [LEDSTA]
        AND AL, 11111101B
        MOV [LEDSTA], AL
SLED2:
        MOV DX, PARTA
        OUT DX, AL
        JMP VOLLED
OFFSLED:
        MOV DX, PARTA
        MOV AL, [LEDSTA]
        OR AL, 00000010B
        MOV [LEDSTA], AL
        OUT DX, AL
VOLLED:
        MOV AL, [VOLT]
        MOV AH, [MAXVOL]
        CMP AL, AH
        JB OFFVLED
        NOT LEDFLG2
        MOV AL, [LEDFLG2]
        CMP AL, 0
        JNZ VLED1
        MOV AL, [LEDSTA]
        OR AL, 00000100B
        MOV [LEDSTA], AL
        JMP VLED2
VLED1:
        MOV AL, [LEDSTA]
        AND AL, 11111011B
        MOV [LEDSTA], AL
VLED2:
        MOV DX, PARTA
        OUT DX, AL
        JMP ENDLED
OFFVLED:
        MOV DX, PARTA
        MOV AL, [LEDSTA]
        OR AL, 00000100B
        MOV [LEDSTA], AL
        OUT DX, AL
ENDLED:
        POP DX
        POP AX
        RET
LEDSER  ENDP

;---------------初始化显示内容----------------
SETSHOW PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI
        
        MOV AL, [MENU]
        CMP AL, 0
        JZ SHOW0
        MOV AL, [MENU]
        CMP AL, 1
        JZ SHOW1
        MOV AL, [MENU]
        CMP AL, 2
        JZ SHOW2
        JMP ENDSHOW
SHOW0:
        MOV AL, [FLG1S]
        CMP AL, 0
        JNZ THEN
        NOT FLG1S              ;到1s计时
        CALL GETSPED
        MOV AL, [SPEED]
        MOV AH, 0
        MOV BL, 10
        DIV BL
        MOV LEDBUF+0, AL       ;1)转速低位
        MOV LEDBUF+1, AH       ;2)转速高位
        MOV LEDBUF+2, 16       ;3)关闭
THEN:
        MOV AL, [FLG4S]
        CMP AL, 0
        JNZ ENDSHOW
        NOT FLG4S              ;到4s计时
        CALL RUN0809
        MOV AL, [VOLT]
        MOV AH, 0
        MOV BL, 100
        DIV BL
        MOV LEDBUF+3, AL       ;4)压力百位
        MOV AL, AH
        MOV AH, 0
        MOV BL, 10
        DIV BL
        MOV LEDBUF+4, AL       ;5)压力十位
        MOV LEDBUF+5, AH       ;6)压力个位
        JMP ENDSHOW
SHOW1:
        MOV LEDBUF+0, 1        ;1)设置最大转速
        MOV LEDBUF+1, 16       ;2)关闭
        MOV LEDBUF+2, 16       ;3)关闭
        MOV LEDBUF+3, 16       ;4)关闭
        MOV AL, [MAXSPD]
        MOV AH, 0
        MOV BL, 10
        DIV BL
        MOV LEDBUF+4, AL       ;5)最大转速低位
        MOV LEDBUF+5, AH       ;6)最大转速高位
        JMP ENDSHOW
SHOW2:
        MOV LEDBUF+0, 2        ;1)设置最大压力
        MOV LEDBUF+1, 16       ;2)关闭
        MOV LEDBUF+2, 16       ;3)关闭
        MOV AL, [MAXVOL]
        MOV AH, 0
        MOV BL, 100
        DIV BL
        MOV LEDBUF+3, AL       ;4)最大压力百位
        MOV AL, AH
        MOV AH, 0
        MOV BL, 10
        DIV BL
        MOV LEDBUF+4, AL       ;5)最大压力十位
        MOV LEDBUF+5, AH       ;6)最大压力个位
ENDSHOW:
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
SETSHOW ENDP

;------------------8259初始化-----------------
SET8259 PROC NEAR
        CLI
        PUSH AX
        PUSH DX
        PUSH SI
        MOV DX, M8259
        MOV AL, 13H       ;电平触发
        OUT DX, AL
        MOV DX, C8259
        MOV AL, 08H
        OUT DX, AL
        MOV AL, 01H
        OUT DX, AL
        MOV AL, 11110000B ;开中断
        OUT DX, AL
SETTI:
        PUSH DS
        XOR AX, AX
        MOV DS, AX
SETTI0:
        MOV AX, OFFSET TIMMER
        MOV SI, 0020H
        MOV [SI], AX
        MOV AX, CS
        MOV SI, 0022H
        MOV [SI], AX
SETTI1:
        MOV AX, OFFSET KEY1SER
        MOV SI, 0024H
        MOV [SI], AX
        MOV AX, CS
        MOV SI, 0026H
        MOV [SI], AX
SETTI2:
        MOV AX, OFFSET KEY2SER
        MOV SI, 0028H
        MOV [SI], AX
        MOV AX, CS
        MOV SI, 002AH
        MOV [SI], AX
SETTI3:
        MOV AX, OFFSET KEY3SER
        MOV SI, 002CH
        MOV [SI], AX
        MOV AX, CS
        MOV SI, 002EH
        MOV [SI], AX
        
        POP DS
        POP SI
        POP DX
        POP AX
        STI
        RET
SET8259 ENDP

;-------------------中断0---------------------
TIMMER  PROC NEAR
        CLI
        PUSH AX
        PUSH DX
_200ms:
        MOV AL, [TIM2HMS]
        DEC AL
        MOV [TIM2HMS], AL
        CMP AL, 0
        JNZ _1s
        NOT FLG2HMS
        MOV [TIM2HMS], 10   ;计时到200ms
_1s:
        MOV AL, [TIM1S]
        DEC AL
        MOV [TIM1S], AL
        CMP AL, 0
        JNZ _4s
        NOT FLG1S
        MOV [TIM1S], 50     ;计时到1s
_4s:
        MOV AL, [TIM4S]
        DEC AL
        MOV [TIM4S], AL
        CMP AL, 0
        JNZ ENDT0
        NOT FLG4S
        MOV [TIM4S], 200    ;计时到4s
ENDT0:
        MOV DX, M8259
        MOV AL, 20H
        OUT DX, AL
        OUT 20H, AL
        POP DX
        POP AX
        STI
        IRET
TIMMER  ENDP

;-------------------中断1---------------------
KEY1SER PROC NEAR
        CLI
        PUSH AX
        PUSH DX
        MOV AL, [MENU]
        INC AL
        MOV [MENU], AL
        CMP AL, 3
        JNZ ENDK1
        MOV [MENU], 0
ENDK1:
        MOV DX, M8259
        MOV AL, 20H
        OUT DX, AL
        OUT 20H, AL
        POP DX
        POP AX
        STI
        IRET
KEY1SER ENDP

;-------------------中断2---------------------
KEY2SER PROC NEAR
        CLI
        PUSH AX
        PUSH DX
        MOV AL, [MENU]
        CMP AL, 1
        JZ SPDDEC
        MOV AL, [MENU]
        CMP AL, 2
        JZ VOLDEC
        JMP ENDK2
SPDDEC:
        MOV AL, [MAXSPD]
        DEC AL
        MOV [MAXSPD], AL
        CMP AL, 10
        JNZ ENDK2
        MOV [MAXSPD], 11
        JMP ENDK2
VOLDEC:
        MOV AL, [MAXVOL]
        DEC AL
        MOV [MAXVOL], AL
        CMP AL, 100
        JNZ ENDK2
        MOV [MAXVOL], 101
        JMP ENDK2
ENDK2:
        MOV DX, M8259
        MOV AL, 20H
        OUT DX, AL
        OUT 20H, AL
        POP DX
        POP AX
        STI
        IRET
KEY2SER ENDP

;-------------------中断3---------------------
KEY3SER PROC NEAR
        CLI
        PUSH AX
        PUSH DX
        MOV AL, [MENU]
        CMP AL, 1
        JZ SPDINC
        MOV AL, [MENU]
        CMP AL, 2
        JZ VOLINC
        JMP ENDK3
SPDINC:
        MOV AL, [MAXSPD]
        INC AL
        MOV [MAXSPD], AL
        CMP AL, 30
        JNZ ENDK3
        MOV [MAXSPD], 29
        JMP ENDK3
VOLINC:
        MOV AL, [MAXVOL]
        INC AL
        MOV [MAXVOL], AL
        CMP AL, 200
        JNZ ENDK3
        MOV [MAXVOL], 199
        JMP ENDK3
ENDK3:
        MOV DX, M8259
        MOV AL, 20H
        OUT DX, AL
        OUT 20H, AL
        POP DX
        POP AX
        STI
        IRET
KEY3SER ENDP

;-----------------8279初始化------------------
SET8279 PROC NEAR
        PUSH AX
        PUSH DX
        MOV DX, C8279
        MOV AX, 00H
        OUT DX, AL
        MOV AL, 32H
        OUT DX, AL
        MOV AL, 0DFH
        OUT DX, AL
CLRBUF:
        IN AL, DX
        TEST AL, 00H
        JNZ CLRBUF
        POP DX
        POP AX
        RET
SET8279 ENDP

;--------------0809转换函数-------------------
RUN0809 PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI
        MOV DX, CS0809
        MOV AL, 0
        OUT DX, AL            ;启动IN0 转换
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        IN AL, DX
        MOV [VOLT], AL
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
RUN0809 ENDP

;------------------8253初始化-----------------
SET8253 PROC NEAR
        PUSH AX
        PUSH DX
        MOV DX, CS8253
        MOV AL, 36H       ;计数器0，16位，
        OUT DX, AL        ;方式3（方波），
        MOV DX, COUNT0    ;二进制数
        MOV AX, 0EA60H    ;20ms(60000*1/3M)
        OUT DX, AL
        MOV AL, AH
        OUT DX, AL
        
        MOV DX, CS8253
        MOV AL, 76H       ;计数器1，16位，
        OUT DX, AL        ;方式3（方波），
        MOV DX, COUNT1    ;二进制数
        MOV AX, 0FFFFH    ;最大初值
        OUT DX, AL
        MOV AL, AH
        OUT DX, AL
        POP DX
        POP AX
        RET
SET8253 ENDP

;---------------获取当前速度------------------
GETSPED PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI
        MOV DX, CS8253
        MOV AL, 40H        ;计数器1，
        OUT DX, AL         ;计数值锁存
        MOV DX, COUNT1
        IN AL, DX
        MOV BL, AL
        IN AL, DX
        MOV AH, AL
        MOV AL, BL
        MOV DX, 0FFFFH     ;65535 - 计数值
        SUB DX, AX         ; = 通过脉冲个数
        MOV AX, DX
        MOV [SPEED], AL
CLRCNT1:                   ;重新启动计数
        MOV DX, CS8253
        MOV AL, 76H
        OUT DX, AL
        MOV DX, COUNT1
        MOV AX, 0FFFFH
        OUT DX, AL
        MOV AL, AH
        OUT DX, AL
        
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
GETSPED ENDP

;--------------数码管显示函数-----------------
DISP    PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI
        MOV DI, OFFSET LEDBUF
        MOV AH, 85H          ;85H - 7FH
DPLOOP:                      ;= 6H 显示六位
        MOV DX, C8279
        MOV AL, AH
        OUT DX, AL
        MOV BX, DI
        MOV AL, [BX]
        MOV BX, OFFSET LED
        XLAT
        MOV DX, D8279
        OUT DX, AL
        INC DI
        DEC AH
        CMP AH, 7FH
        JNZ DPLOOP
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
DISP    ENDP

CODE    ENDS
        END START
        
