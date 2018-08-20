;#############################################
;                 ����˵��
;#############################################
; 8279
; Ĭ���ѽӺ�
;
; 0809  ---
; SC/ALE---  ��� --- A����� --- 0FF20H+IOW
; OE    ---  ��� --- B����� --- 0FF20H+IOR
; IN0   ---  ѹ����ѹ
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
;                 ϵͳ˵��
;#############################################
; ϵͳ���� 1��6λ����ܣ�2��LED��3������
; һ�������һ��ѹ��������
;
; Ĭ����ʾ��ת��_ѹ��ֵ
; ����1��1___����ת��
; ����2��2__����ѹ��
;
; ����1�л���ʾ����
; ����2��С
; ����3����
;
; ���ͨ�����ڵ�ѹ������ת�٣�ת�ٳ�������
; ת��ʱ��LED1��˸
;
; ѹ��������ͨ��������ѹ���ж�ѹ������ѹ��
; ��������ѹ��ʱ��LED2��˸




;#############################################
;                  ��ַ˵��
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
;                  ���ݶ�
;#############################################
DATA    SEGMENT
;---------------�������ʾ������--------------
LEDBUF  DB     0, 0, 16, 0, 0, 0
;---------------0~F���հ׶�Ӧ����-------------
LED     DB     0CH, 9FH, 4AH, 0BH
        DB     99H, 29H, 28H, 8FH
        DB     08H, 09H, 88H, 38H
        DB     6CH, 1AH, 68H, 0E8H
        DB     0FFH
;---------------��ʱ��ֵ��20msBASE------------
TIM2HMS DB     10
TIM1S   DB     50
TIM4S   DB     200
;---------------����ʱ��־λ------------------
FLG2HMS DB     0FFH
FLG1S   DB     0FFH
FLG4S   DB     0FFH
;---------------��ǰ�ٶȼ�ѹ��----------------
SPEED   DB     00H
VOLT    DB     00H
;---------------��ǰ��ʾ�˵�------------------
MENU    DB     0
;---------------��ʼ����ֵ--------------------
MAXSPD  DB     20
MAXVOL  DB     100
;---------------LED��־λ---------------------
LEDSTA  DB     0FFH
LEDFLG1 DB     0FFH
LEDFLG2 DB     0FFH
DATA    ENDS



;#############################################
;                   ��ջ��
;#############################################
SSTACK  SEGMENT
        DW     32   DUP(?)
SSTACK  ENDS



;#############################################
;                   �����
;#############################################
CODE    SEGMENT
        ASSUME CS:CODE, DS:DATA, SS:SSTACK

;-------------------������--------------------
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

;---------------8255��ʼ��--------------------
SET8255 PROC NEAR
        PUSH AX
        PUSH DX
        MOV DX, CS8255
        MOV AL, 80H      ;A�ڣ���ʽ0�����
        OUT DX, AL
        POP DX
        POP AX
        RET
SET8255 ENDP

;----------------LED����----------------------
LEDSER  PROC NEAR
        PUSH AX
        PUSH DX
        MOV AL, [FLG2HMS]
        CMP AL, 0
        JNZ ENDLED
        NOT FLG2HMS            ;��200ms��ʱ
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

;---------------��ʼ����ʾ����----------------
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
        NOT FLG1S              ;��1s��ʱ
        CALL GETSPED
        MOV AL, [SPEED]
        MOV AH, 0
        MOV BL, 10
        DIV BL
        MOV LEDBUF+0, AL       ;1)ת�ٵ�λ
        MOV LEDBUF+1, AH       ;2)ת�ٸ�λ
        MOV LEDBUF+2, 16       ;3)�ر�
THEN:
        MOV AL, [FLG4S]
        CMP AL, 0
        JNZ ENDSHOW
        NOT FLG4S              ;��4s��ʱ
        CALL RUN0809
        MOV AL, [VOLT]
        MOV AH, 0
        MOV BL, 100
        DIV BL
        MOV LEDBUF+3, AL       ;4)ѹ����λ
        MOV AL, AH
        MOV AH, 0
        MOV BL, 10
        DIV BL
        MOV LEDBUF+4, AL       ;5)ѹ��ʮλ
        MOV LEDBUF+5, AH       ;6)ѹ����λ
        JMP ENDSHOW
SHOW1:
        MOV LEDBUF+0, 1        ;1)�������ת��
        MOV LEDBUF+1, 16       ;2)�ر�
        MOV LEDBUF+2, 16       ;3)�ر�
        MOV LEDBUF+3, 16       ;4)�ر�
        MOV AL, [MAXSPD]
        MOV AH, 0
        MOV BL, 10
        DIV BL
        MOV LEDBUF+4, AL       ;5)���ת�ٵ�λ
        MOV LEDBUF+5, AH       ;6)���ת�ٸ�λ
        JMP ENDSHOW
SHOW2:
        MOV LEDBUF+0, 2        ;1)�������ѹ��
        MOV LEDBUF+1, 16       ;2)�ر�
        MOV LEDBUF+2, 16       ;3)�ر�
        MOV AL, [MAXVOL]
        MOV AH, 0
        MOV BL, 100
        DIV BL
        MOV LEDBUF+3, AL       ;4)���ѹ����λ
        MOV AL, AH
        MOV AH, 0
        MOV BL, 10
        DIV BL
        MOV LEDBUF+4, AL       ;5)���ѹ��ʮλ
        MOV LEDBUF+5, AH       ;6)���ѹ����λ
ENDSHOW:
        POP SI
        POP DI
        POP DX
        POP CX
        POP BX
        POP AX
        RET
SETSHOW ENDP

;------------------8259��ʼ��-----------------
SET8259 PROC NEAR
        CLI
        PUSH AX
        PUSH DX
        PUSH SI
        MOV DX, M8259
        MOV AL, 13H       ;��ƽ����
        OUT DX, AL
        MOV DX, C8259
        MOV AL, 08H
        OUT DX, AL
        MOV AL, 01H
        OUT DX, AL
        MOV AL, 11110000B ;���ж�
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

;-------------------�ж�0---------------------
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
        MOV [TIM2HMS], 10   ;��ʱ��200ms
_1s:
        MOV AL, [TIM1S]
        DEC AL
        MOV [TIM1S], AL
        CMP AL, 0
        JNZ _4s
        NOT FLG1S
        MOV [TIM1S], 50     ;��ʱ��1s
_4s:
        MOV AL, [TIM4S]
        DEC AL
        MOV [TIM4S], AL
        CMP AL, 0
        JNZ ENDT0
        NOT FLG4S
        MOV [TIM4S], 200    ;��ʱ��4s
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

;-------------------�ж�1---------------------
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

;-------------------�ж�2---------------------
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

;-------------------�ж�3---------------------
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

;-----------------8279��ʼ��------------------
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

;--------------0809ת������-------------------
RUN0809 PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI
        MOV DX, CS0809
        MOV AL, 0
        OUT DX, AL            ;����IN0 ת��
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

;------------------8253��ʼ��-----------------
SET8253 PROC NEAR
        PUSH AX
        PUSH DX
        MOV DX, CS8253
        MOV AL, 36H       ;������0��16λ��
        OUT DX, AL        ;��ʽ3����������
        MOV DX, COUNT0    ;��������
        MOV AX, 0EA60H    ;20ms(60000*1/3M)
        OUT DX, AL
        MOV AL, AH
        OUT DX, AL
        
        MOV DX, CS8253
        MOV AL, 76H       ;������1��16λ��
        OUT DX, AL        ;��ʽ3����������
        MOV DX, COUNT1    ;��������
        MOV AX, 0FFFFH    ;����ֵ
        OUT DX, AL
        MOV AL, AH
        OUT DX, AL
        POP DX
        POP AX
        RET
SET8253 ENDP

;---------------��ȡ��ǰ�ٶ�------------------
GETSPED PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI
        MOV DX, CS8253
        MOV AL, 40H        ;������1��
        OUT DX, AL         ;����ֵ����
        MOV DX, COUNT1
        IN AL, DX
        MOV BL, AL
        IN AL, DX
        MOV AH, AL
        MOV AL, BL
        MOV DX, 0FFFFH     ;65535 - ����ֵ
        SUB DX, AX         ; = ͨ���������
        MOV AX, DX
        MOV [SPEED], AL
CLRCNT1:                   ;������������
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

;--------------�������ʾ����-----------------
DISP    PROC NEAR
        PUSH AX
        PUSH BX
        PUSH CX
        PUSH DX
        PUSH DI
        PUSH SI
        MOV DI, OFFSET LEDBUF
        MOV AH, 85H          ;85H - 7FH
DPLOOP:                      ;= 6H ��ʾ��λ
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
        
