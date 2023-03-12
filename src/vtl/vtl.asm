;;;---------------------------------------------------------------------------
;;; Tiny Monitor with Very Tiny Language Interpreter (VTL-4004)
;;; for Intel 4004 evaluation board
;;;
;;; by Ryo Mukai
;;; 2023/03/12
;;;---------------------------------------------------------------------------

;;;---------------------------------------------------------------------------
;;; This source can be assembled with the Macroassembler AS
;;; (http://john.ccac.rwth-aachen.de:8000/as/)
;;;---------------------------------------------------------------------------

	cpu 4004        ; AS's command to specify CPU

	include "macros.inc" 	; aliases and macros

;;;---------------------------------------------------------------------------
;;; Hardware Configuration
;;;---------------------------------------------------------------------------

;;; RAM0 and RAM1 must be 4002-1 and located in the BANK#0 (CM-RAM0).
;;; For RAM2 and RAM3, 4002-2 is preferred, because it can be located
;;; in the BANK#0 same as RAM0 and RAM1.
;;; However -2 is more expensive and difficult to get than -1,
;;; so the chip type of RAM2 and RAM3 is configurable.
;;; If you use -1 for RAM2 and RAM3, they are located in
;;; the BANK#1 (CM-RAM1), and DCL must be executed before SRC.

;;; Chip type of RAM2 and RAM3
RAM23TYPE	equ "4002-2"	; or "4002-1"

;;; BANK# for DCL, and CHIP#=(D7.D6.000000) for SRC
BANK_RAM0	equ 0
CHIP_RAM0      	equ 00H
BANK_RAM1      	equ 0
CHIP_RAM1      	equ 40H
	if (RAM23TYPE == "4002-2")
BANK_RAM2      	equ 0
CHIP_RAM2      	equ 80H
BANK_RAM3      	equ 0
CHIP_RAM3      	equ 0C0H
	elseif (RAM23TYPE == "4002-1")
BANK_RAM2      	equ 1
CHIP_RAM2      	equ 00H
BANK_RAM3      	equ 1
CHIP_RAM3      	equ 40H
	endif

;;; Default Bank
;;; The CM-RAM line should be always set to BANK_DEFAULT
;;; to omit DCL as much as possible.
;;; (This is for when RAM23TYPE=="4002-1".)
BANK_DEFAULT	equ BANK_RAM0
		
;;; Output port for serial interface
BANK_SERIAL     equ BANK_RAM3
CHIP_SERIAL     equ CHIP_RAM3

;;; Output port for program memory bank selection
BANK_PMSELECT	equ BANK_RAM0
CHIP_PMSELECT   equ CHIP_RAM0

;;; Program Memory RAM area
PM_RAM_START	equ 0F00H	; Start address of program memory RAM
PM_READ_P0_P1   equ 0FFEH	; Entry of the subroutine to read RAM
				; "FIN P1 and BBL 0"

;;; Address labels in the logical program memory PM12
;;; PM12_LINEBUF	equ 080H
PM12_LINEBUF	equ 000H
PM12_PROGRAM	equ 100H
PM12_DATA	equ 0B00H
PM12_MEMEND	equ 0DFFH

;;;---------------------------------------------------------------------------
;;; Data RAM Register Configuration
;;;---------------------------------------------------------------------------
;;; RAM0
REG16_INDEX 		equ 00H	; or @, `
REG16_A 		equ 04H	;
REG16_B 		equ 08H	;
REG16_C 		equ 0CH	;
REG16_D 		equ 10H	;
REG16_E 		equ 14H	;
REG16_F 		equ 18H	;
REG16_G 		equ 1CH	;
REG16_H 		equ 20H	;
REG16_I 		equ 24H	;
REG16_J 		equ 28H	;
REG16_K 		equ 2CH	;
REG16_L 		equ 30H	;
REG16_M 		equ 34H	;
REG16_N 		equ 38H	;
REG16_O 		equ 3CH	;
;;; RAM1
REG16_P 		equ 40H	;
REG16_Q 		equ 44H	;
REG16_R 		equ 48H	;
REG16_S 		equ 4CH	;
REG16_T 		equ 50H	;
REG16_U 		equ 54H	;
REG16_V 		equ 58H	;
REG16_W 		equ 5CH	;
REG16_X 		equ 60H	;
REG16_Y 		equ 64H	;
REG16_Z  		equ 68H	;
REG16_LINENUM  		equ 6CH	; current line number
REG16_NEXTLINEPTR	equ 70H	; pointer to the next program line
REG16_PEND		equ 74H	; pointer to the end of program

REG8_ERROR		equ 78H	; 8bit register
REG8_ERROR2		equ 7AH	; 8bit register

REG4_ZEROSUP		equ 7CH	; 4bit register
REG4_SIGN		equ 7DH	; 4bit register
REG4_PRINTFORMAT	equ 7EH	; 4bit register
REG4_RESERVE_7FH	equ 7FH	; 4bit register (reserved)

	;; This program assumes RAM2 and RAM3 are 4002-2.
	;; If you use 4002-1, you may need to modify program
	;; related to data RAM registers.
	if (RAM23TYPE == "4002-2")
;;; RAM2
REG16_LVALUE		equ 80H
REG16_RVALUE		equ 84H
REG16_FACTOR		equ 88H
REG16_EVAL		equ 8CH
REG16_RMND		equ 90H	; Remainder (result of last DIV)
REG16_RETURN		equ 94H
REG16_RANDOM		equ 98H	; (not implemented)
REG16_ARRAYINDEX	equ 9CH	; (not implemented)
REG16_TMP		equ 0A0H
REG16_TMP2		equ 0A4H
REG16_TMP3		equ 0A8H
REG16_TMP_PRN		equ 0ACH ; temporary for PRINT routine
REG16_RESERVED_0B0	equ 0B0H
REG16_RESERVED_0B4	equ 0B4H
REG16_RESERVED_0B8	equ 0B8H
REG16_RESERVED_0BC	equ 0BCH
;;; RAM3
REG16_STACKAREA_0C0	equ 0C0H
REG16_STACKAREA_0C4	equ 0C4H
REG16_STACKAREA_0C8	equ 0C8H
REG16_STACKAREA_0CC	equ 0CCH
REG16_STACKAREA_0D0	equ 0D0H
REG16_STACKAREA_0D4	equ 0D4H
REG16_STACKAREA_0D8	equ 0D8H
REG16_STACKAREA_0DC	equ 0DCH
REG16_STACKAREA_0E0	equ 0E0H
REG16_STACKAREA_0E4	equ 0E4H
REG16_STACKAREA_0E8	equ 0E8H
REG16_STACKAREA_0EC	equ 0ECH
REG16_STACKAREA_0F0	equ 0F0H
REG16_STACKAREA_0F4	equ 0F4H
REG16_STACKAREA_0F8	equ 0F8H
REG16_STACKAREA_0FC	equ 0FCH
REG16_STACKPOINTER	equ 0FCH ; SP is Status char 0 and 1 of This register
INITVAL_STACKPOINTER	equ 00H	 ; Initial value of the SP
				 ; (The SP should be even value
				 ;  in the current implementation)
	endif
	
;;;---------------------------------------------------------------------------
;;; Data RAM Register Operation
;;;---------------------------------------------------------------------------

;;;---------------------------------------------------------------------------
;;; Program Start
;;;---------------------------------------------------------------------------
	org 0000H		; beginning of Program Memory

;;;---------------------------------------------------------------------------
;;; Mail Loop for Monitor Program
;;;---------------------------------------------------------------------------
MAIN:
        CLB
	;; DL is assumed to be set back to BANK_DEFAULT (normally 0)
	;; except when in use for another banks.
	LDM BANK_DEFAULT
	DCL

	JMS INIT_STACKPOINTER	; initialize stack pointer
	JMS INIT_SERIAL 	; Initialize Serial Port

	FIM P1, loop(16)	; R3 = 0..15
PM_INIT_LOOP:
	LD R3
	JMS PM_SELECTPMB
	JMS PM_INIT_BANK ; write PM_READ code on program memory
	ISZ R3, PM_INIT_LOOP

	CLB
	JMS PM_SELECTPMB	 ; set PMB to 0
	
;       JCN TN, $		;wait for TEST="0" (button pressed)
	FIM P0, lo(STR_VFD_INIT) ; init VFD
        JMS PRINTSTR_P0
	FIM P0, lo(STR_OMSG) ; opening message in the Page 7
        JMS PRINTSTR_P0

CMD_LOOP:
        FIM P1, ']'		; prompt
        JMS PUTCHAR_P1

L_CR:
	JMS GETCHAR_P1
        JMS DISPLED_P1
	JMS ISCRLF_P1
	JCN Z, L0
	JMS PRINT_CRLF
	JUN CMD_LOOP

L0:
	JMS PUTCHAR_P1
	
	FIM P0, 'r'		; read data memory
	JMS CMP_P0P1
	JCN ZN, L1
	JMS SETBANKCHIP_P5
	JUN COMMAND_R
L1:
	FIM P0, 'w'		; write to data memory
	JMS CMP_P0P1
	JCN ZN, L2
	JMS SETBANKCHIP_P5
	JUN COMMAND_W
L2:
	FIM P0, 'R'		; READ program memory
	JMS CMP_P0P1
	JCN ZN, L3
	JUN COMMAND_PMR
L3:
	FIM P0, 'W'		; Write Program memory
	JMS CMP_P0P1
	JCN ZN, L4
	JUN COMMAND_PMW
L4:
	FIM P0, 'C'		; Clear program memory
	JMS CMP_P0P1
	JCN ZN, L5
	JUN COMMAND_PMC
L5:
 	FIM P0, 'B'		; Set PMB (Program Memory Bank)
 	JMS CMP_P0P1
	JCN ZN, L6
 	JUN COMMAND_PMB
L6:
	FIM P0, 'g'		; Go to PM_RAM_START (0F00H)
	JMS CMP_P0P1
	JCN ZN, L7
	JUN COMMAND_G
L7:
	FIM P0, 'v'		; VTL-4004 Interpreter
	JMS CMP_P0P1
	JCN ZN, L8
	JUN COMMAND_V
L8:
	FIM P0, 'l'		; Read Logical Memory
	JMS CMP_P0P1
	JCN ZN, L9
	JUN COMMAND_LMR
L9:
	FIM P0, 'L'		; Write Logical Memory
	JMS CMP_P0P1
	JCN ZN, L10
	JUN COMMAND_LMW
L10:
	FIM P0, lo(STR_CMDERR)
	JMS PRINTSTR_P0
	JUN CMD_LOOP
	
;;;---------------------------------------------------------------------------
;;; SETBANKCHIP_P5
;;; Set #bank and #chip to R10 and R11
;;;---------------------------------------------------------------------------
SETBANKCHIP_P5:
	FIM P0, lo(STR_BANK)	; print " BANK="
	JMS PRINTSTR_P0
	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3
	XCH R10			; save BANK to R10

	FIM P0, lo(STR_CHIP)	; print " CHIP="
	JMS PRINTSTR_P0
	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3		; R3 is #chip(x.x.D3.D2)
	CLC
	RAL
	CLC
	RAL
	XCH R11 	;set D3D2.00@X2 to R11 (0000 or 0100 or 1000 or 1100)
	JMS PRINT_CRLF
	BBL 0
	

;;;----------------------------------------------------------------------------
;;; ISHEX_P1
;;; check P1 is a hex digit letter ('0' to '9') or ('a' to 'f') or ('A' to 'F')
;;; return: ACC=0 if P1 is not a hex digit letter
;;;         ACC=1 if P1 is a hex digit letter
;;; destroy: P7
;;;----------------------------------------------------------------------------
ISHEX_P1:
	FIM P7, '0'
	JMS CMP_P1P7
	JCN C, ISHEX_L00
	BBL 0			; P1<'0'
ISHEX_L00:	
	FIM P7, '9'+1
	JMS CMP_P1P7
	JCN C,  ISHEX_L1	; P1>='9'+1 then jump to next chance
	BBL 1			; '0'<=P1<='9'
ISHEX_L1:
	FIM P7, 'A'
	JMS CMP_P1P7
	JCN C, ISHEX_L10
	BBL 0			; P1<'A'
ISHEX_L10:
	FIM P7, 'F'+1
	JMS CMP_P1P7
	JCN C,  ISHEX_L2	; P1>='F'+1 then jump to next chance
	BBL 1			; 'A'<=P1<='F'
ISHEX_L2:
	FIM P7, 'a'
	JMS CMP_P1P7
	JCN C, ISHEX_L20
	BBL 0			; P1<'a'
ISHEX_L20:	
	FIM P7, 'f'+1
	JMS CMP_P1P7
	JCN C, ISHEX_FALSE	; P1>='f'+1
	BBL 1			; 'a'<=P1<= 'f'
ISHEX_FALSE:
	BBL 0

;;;---------------------------------------------------------------------------
;;; Program for Very Very Tiny Language Interpreter
;;;---------------------------------------------------------------------------
	org 0100H

;;;---------------------------------------------------------------------------
;;; Error codes
;;;---------------------------------------------------------------------------
ERROR_NOERROR			equ 00H
ERROR_PRINT_CANNOTPRINT		equ 0A0H
ERROR_RETURN_P2_IS_00		equ 0B0H
ERROR_EXEC_SYNTAX_ERROR		equ 0E0H
ERROR_EVAL_UNEXPECTED_EOL	equ 0E1H
ERROR_EVAL_UNKNOWNOPERATOR	equ 0E2H
ERROR_FACTOR_NOTAFACTOR		equ 0F0H
	
;;;---------------------------------------------------------------------------
COMMAND_V:
;;; commented out for debug
	FIM P0, lo(STR_VTL_MESSAGE)
	JMS PRINTSTR_P0

	FIM P1, ERROR_NOERROR
	FIM P0, REG8_ERROR
	JMS LD_REG8P0_P1		; clear ERROR
	FIM P0, REG8_ERROR2
	JMS LD_REG8P0_P1		; clear ERROR

	FIM P0, REG16_PEND
	FIM P2, up(PM12_PROGRAM)
	FIM P3, lo(PM12_PROGRAM)
	JMS LD_REG16P0_P2P3	; REG(PEND) = PM12_PROGRAM (&=256)
	
;;;---------------------------------------------------------------------------
;;; Main Loop
;;;---------------------------------------------------------------------------
VTL_START:
	;; print REG(ERROR) if not zero
	FIM P0, REG8_ERROR
	JMS LD_P1_REG8P0
	JMS ISZEROORNOT_P1
	JCN Z, VTL_NOERROR

	;; print error code
	FIM P0, lo(STR_VTL_ERROR)
	JMS PRINTSTR_P0		; print error message
	JMS PRINTHEX_P1		; print error code
	FIM P0, REG8_ERROR2
	JMS LD_P1_REG8P0
	JMS PRINTHEX_P1		; print error code 2
	JMS PRINT_SPC
	
	;; print remainig buffer 
	FIM P0, lo(STR_VTL_BUF)
	JMS PRINTSTR_P0
	FIM P0, REG16_INDEX
	FIM P1, REG16_INDEX
	JMS PUSH_REG16P1
	JMS DEC_REG16P0
	JMS PRINTSTR_PM12REG16P0 ; print PM(REG(INDEX)-1) (for debug)
	JMS POP_REG16P1		 ; print PM(REG(INDEX)) is enough?
	JMS PRINT_CRLF

	;; print error line number
	FIM P1, REG16_LINENUM
	JMS ISZEROORNOT_REG16P1
	JCN Z, VTL_ERROR_NOLINENUM
	FIM P0, lo(STR_VTL_ERRORLINENUM)
	JMS PRINTSTR_P0
	FIM P1, REG16_LINENUM
	JMS PRINT_REG16P1
	JMS PRINT_CRLF
	
VTL_ERROR_NOLINENUM:
	;; clear error registers
	FIM P1, ERROR_NOERROR
	FIM P0, REG8_ERROR
	JMS LD_REG8P0_P1		; clear ERROR
	FIM P0, REG8_ERROR2
	JMS LD_REG8P0_P1		; clear ERROR
	
VTL_NOERROR:
	;; if SP !=0 print it and reset (for debug)
	FIM P7, REG16_STACKPOINTER
	SRC P7
	RD0
	XCH R2
	RD1
	XCH R3
	JMS ISZEROORNOT_P1
	JCN Z, VTL_OK
	FIM P0, lo(STR_VTL_SP)
	JMS PRINTSTR_P0         ; print SP
	LD R2
	JMS PRINT_ACC
	LD R3
	JMS PRINT_ACC

	;; RESET SP
 	JMS INIT_STACKPOINTER	; reset stack pointer
VTL_OK:	
	FIM P0, lo(STR_VTL_OK)
	JMS PRINTSTR_P0

;;; LOOP entry for program input
VTL_LOOP:
	;; 	FIM P1, '%'
	;; 	JMS PUTCHAR_P1		; put a prompt (for debug)

	FIM P0, REG16_LINENUM	; clear linenumber counter
	JMS CLEAR_REG16P0

	FIM P0, REG16_INDEX
	FIM P2, up(PM12_LINEBUF)
	FIM P3, lo(PM12_LINEBUF)
	JMS LD_REG16P0_P2P3	; REG(INDEX) = PM12_LNEBUF

	JMS GETLINE_PM12REG16P0
	;; 	JMS SKIPSPACE_PM12REG16P0

	JMS LD_P1_PM12REG16P0	; P1=PM12(REG(INDEX)

	FIM P7, '.'		; quit to the monitor program (for debug)
	JMS CMP_P1P7
	JCN ZN, VTL_L0
	JUN CMD_LOOP
VTL_L0:
	JMS ISNUM_P1
	JCN Z, VTL_L1
	JUN VTL_INSERT_PROGRAMLINE ; Top character is a number
VTL_L1:	
	FIM P0, REG16_LINENUM
	FIM P2, 00H
	FIM P3, 00H
	JMS LD_REG16P0_P2P3	; REG(LINENUM)=0

	FIM P0, REG16_NEXTLINEPTR
	FIM P2, up(PM12_MEMEND)
	FIM P3, lo(PM12_MEMEND)
	JMS LD_REG16P0_P2P3	; REG(NEXTLINEPTR)=MEMEND to exit after exec

	FIM P0, REG16_INDEX
	JUN VTL_RUN_SINGLE_LINE

;;;----------------------------------------------------------------------------
;;; VTL_INSERT_PROGRAMLINE
;;; Input program line to program area
;;;----------------------------------------------------------------------------
VTL_INSERT_PROGRAMLINE:
	;; 	include "stacktest.inc"
	;; 	include "numbertest.inc"
	;; FIM P0, REG16_INDEX  ; this can be omitted?
	FIM P1, REG16_TMP
	JMS GETNUMBER_PM12REG16P0_REG16P1
	JMS ISZEROORNOT_REG16P1
	JCN ZN, INSERT_PROGRAM_L1
	JUN PRINT_LIST
INSERT_PROGRAM_L1:
	JMS INC_REG16P0		; skip ' ' without check for symplification

	JMS LD_P2P3_REG16P1 
	FIM P0, REG16_PEND
	LD_P1_P3
	JMS LD_PM12REG16P0_P1	; PM12(REG(PEND)++) = P3 (lower byte)
	JMS INC_REG16P0
	LD_P1_P2
	JMS LD_PM12REG16P0_P1	; PM12(REG(PEND)++) = P2 (upper byte)
	JMS INC_REG16P0
	LD_P1_P0
	JMS PUSH_REG16P1	; PUSH(REG(PEND)) to write a pointer
				; to the next line afterward
	JMS INC_REG16P0
	JMS INC_REG16P0		; PEND=PEND+2
	
INSERT_PROGRAM_LOOP:
	FIM P0, REG16_INDEX
	JMS LD_P1_PM12REG16P0
	JMS ISZEROORNOT_P1	; EOL
	JCN Z, INSERT_PROGRAM_EXIT
	JMS INC_REG16P0		; REG(INDEX)++
	FIM P0, REG16_PEND
	JMS LD_PM12REG16P0_P1	; copy PM12(REG(INDEX)) to PM12(REG(PEND))
	JMS INC_REG16P0		; REG(PEND)++
	;; the end of memory check is omitted for simplicity
	JUN INSERT_PROGRAM_LOOP	;
	
INSERT_PROGRAM_EXIT:
	FIM P0, REG16_PEND
	FIM P1, 00H
	JMS LD_PM12REG16P0_P1	; write EOL and increment REG(PEND)
	JMS INC_REG16P0

	JMS LD_P2P3_REG16P0	; P2P3=REG(PEND)
	FIM P1, REG16_TMP
	JMS POP_REG16P1		; pop the place to write the next line pointer
	LD_P0_P1
	LD_P1_P3
	JMS LD_PM12REG16P0_P1
	JMS INC_REG16P0
	LD_P1_P2
	JMS LD_PM12REG16P0_P1
	
	JUN VTL_LOOP
;;; 	JUN CMD_LOOP		;; return to command loop (for debug)

;;;----------------------------------------------------------------------------
;;; LD_P2P3_PM12REG16P0_AND_INCREMENT
;;; Get 16bit from PM
;;; P3=PM(REG(P0)++)
;;; P2=PM(REG(P0)++)
;;; destroy: P1
;;;----------------------------------------------------------------------------
LD_P2P3_PM12REG16P0_AND_INCREMENT:
	JMS LD_P1_PM12REG16P0
	JMS INC_REG16P0
	LD_P3_P1
	JMS LD_P1_PM12REG16P0
	JMS INC_REG16P0
	LD_P2_P1
	BBL 0
	
;;;----------------------------------------------------------------------------
;;; PRINT_LIST:
;;; Print program list
;;;----------------------------------------------------------------------------
PRINT_LIST:
	FIM P0, REG16_INDEX
	FIM P2, up(PM12_PROGRAM)
	FIM P3, lo(PM12_PROGRAM)
	JMS LD_REG16P0_P2P3	; REG(INDEX) = PM12_PROGRAM

PRINT_LIST_LOOP:
	FIM P1, REG16_PEND
	JMS CMP_REG16P0_REG16P1
	JCN CN, PRINT_LIST_PRINTLINE
	JUN VTL_START		; exit to VTL_START
PRINT_LIST_PRINTLINE
	;; Get line number
	JMS LD_P2P3_PM12REG16P0_AND_INCREMENT
	FIM P1, REG16_LINENUM
	JMS LD_REG16P1_P2P3

	JMS PRINT_REG16P1
	JMS PRINT_SPC
	
	JMS INC_REG16P0 	; skip pointer to next line
	JMS INC_REG16P0

	JMS PRINTSTR_PM12REG16P0
	JMS PRINT_CRLF
	JMS INC_REG16P0		; increment pointer to the next char of EOL
	JUN PRINT_LIST_LOOP

;;;----------------------------------------------------------------------------
;;; FIND_LINE_AND_EXEC
;;; Search for the linenumber REG(LINENUM) and find the pointer of the line
;;; to be executed (minimum linenumber >= REG(LINENUM))
;;; in the PM(PROGRAM) and set REG(LINENUM) to the found linenumber
;;; and execute it
;;;----------------------------------------------------------------------------
FIND_LINE_AND_EXEC:
	FIM P0, REG16_INDEX
	FIM P2, up(PM12_PROGRAM)
	FIM P3, lo(PM12_PROGRAM)
	JMS LD_REG16P0_P2P3	; REG(INDEX) = PM12_PROGRAM

FIND_LINE_LOOP:
	JMS LD_P2P3_PM12REG16P0_AND_INCREMENT ; P2P3= line number
	FIM P0, REG16_TMP
	JMS LD_REG16P0_P2P3		; REG(TMP) = current line number

	FIM P1, REG16_LINENUM
	JMS CMP_REG16P0_REG16P1
 	JCN C, FIND_LINE_AND_EXEC_GO	; REG(TMP) >= REG(LINENUM) then exec
	
	FIM P0, REG16_INDEX
	JMS LD_P2P3_PM12REG16P0_AND_INCREMENT ; P2P3= next line pointer
	FIM P1, REG16_PEND
	JMS LD_REG16P0_P2P3	; REG(INDEX) = next line pointer
	JMS CMP_REG16P0_REG16P1
	JCN C, FIND_LINE_AND_EXEC_EXIT	; REG(INDEX)>=REG(PEND)
	JUN FIND_LINE_LOOP
	
FIND_LINE_AND_EXEC_GO:
	JMS LD_REG16P1_REG16P0	; REG(LINENUM) = real linenum
	JUN VTL_RUN_PROGRAM_PMINDEX_FROM_GOTO ; 
	
FIND_LINE_AND_EXEC_EXIT:
	JUN VTL_START		; reach the end of the program
	
;;;----------------------------------------------------------------------------
;;; VTL_RUN_PROGRAM_PMINDEX:
;;; Run the program buffer
;;; one line is:
;;; 	2 byte: linenumber
;;; 	2 byte: PTR to next line
;;; 	   x  : program code
;;; 	1 byte: 00H (EOL)
;;; if REG(NEXTLINEPTR)==0 or REG(NEXTLINEPTR)>=REG(PEND) then back to prompt
;;;----------------------------------------------------------------------------
VTL_RUN_PROGRAM_PMINDEX:
	FIM P0, REG16_INDEX
	JMS LD_P2P3_PM12REG16P0_AND_INCREMENT ; P2P3= line number
	FIM P0, REG16_LINENUM
	JMS LD_REG16P0_P2P3		; REG(LINENUM) = current line number
VTL_RUN_PROGRAM_PMINDEX_FROM_GOTO:
	FIM P0, REG16_INDEX
	JMS LD_P2P3_PM12REG16P0_AND_INCREMENT 
	FIM P0, REG16_NEXTLINEPTR
	JMS LD_REG16P0_P2P3             ; P2P3= next line pointer

VTL_RUN_SINGLE_LINE:
	JUN VTL_EXECUTE_PMINDEX

VTL_RUN_SINGLE_LINE_RETURN:
	FIM P0, REG16_PEND
	FIM P1, REG16_NEXTLINEPTR
	JMS CMP_REG16P0_REG16P1
	JCN CN, VTL_RUN_PROGRAM_EXIT	; REG(PEND) < REG(NEXTLINEPTR)
	JCN  Z, VTL_RUN_PROGRAM_EXIT	; REG(PEND) == REG(NEXTLINEPTR)
	FIM P0, REG16_INDEX
	JMS LD_REG16P0_REG16P1		; REG(INDEX) = REG(NEXTLINEPTR)
	JUN VTL_RUN_PROGRAM_PMINDEX
VTL_RUN_PROGRAM_EXIT:
	JUN VTL_START		; exit to VTL_START
	
;;;----------------------------------------------------------------------------
;;; VTL_EXECUTE_PMINDEX
;;; Execute a string PM12(REG(INDEX))
;;; destroy: P0, P1
;;;----------------------------------------------------------------------------
VTL_EXECUTE_PMINDEX:
	;; if some initialization is needed, write here
VTL_EXECUTE_PMINDEX_CONTINUE:
	FIM P0, REG16_INDEX

	JMS SKIPSPACE_PM12REG16P0 ; skip spaces ' '
	JMS LD_P1_PM12REG16P0	  ; get the left term
	JMS ISZEROORNOT_P1
	JCN ZN, VTL_EXEC_L0
	JUN VTL_RUN_SINGLE_LINE_RETURN ; return to the run loop

VTL_EXEC_L0:	
	JMS INC_REG16P0		; REG16P0++

	;;  Print
	FIM P7, '?'
	JMS CMP_P1P7
	JCN Z, VTL_SET_PRINTFMT	; go to check print format
	JUN VTL_EXEC_L1
VTL_SET_PRINTFMT:
	;; check the next char to '?' and set print format
	JMS LD_P1_PM12REG16P0  ; check printformat "?=" or "?$=" or "??="

	FIM P7, '$'
	JMS CMP_P1P7
	JCN NZ, VTL_EXEC_L0_CHECKHEX4;
	JMS INC_REG16P0		; REG16P0++ for '$'

	LDM PRINTFMT_HEX2B
	JMS SET_PRINTFORMAT
	
	JUN VTL_EXEC_PRINT

VTL_EXEC_L0_CHECKHEX4:
	FIM P7, '?'
	JMS CMP_P1P7
	JCN NZ, VTL_EXEC_L0_NORMAL
	JMS INC_REG16P0		; REG16P0++ for '?'

	LDM PRINTFMT_HEX4B
	JMS SET_PRINTFORMAT

	JUN VTL_EXEC_PRINT

VTL_EXEC_L0_NORMAL
	;; normally it's "?=" but not check "=" for simplification
	LDM PRINTFMT_NORMAL
	JMS SET_PRINTFORMAT

	JUN VTL_EXEC_PRINT

	;; "left term = right expression" type procedures
VTL_EXEC_L1:
	JMS INC_REG16P0		; SKIP '=' without check for symplification
	JMS PUSH_P1		; push the left term

	;; Evaluate the right expression
	FIM P1, REG16_EVAL
	FIM P2, lo(RETURN_EXEC_R1)
	JUN EVAL_EXPRESSION_PMINDEX_REG16P1

EXEC_R1:
	FIM P2, REG16_EVAL	; set P2 to the evaluated result value
	JMS POP_P1		; pop the left term

	;; Assignment to the normal variable
	JMS ISALPHA_P1
	JCN Z, VTL_EXEC_L2
	JMS CTOREG16NUM_P1	; convert the name to the register address
	JMS LD_REG16P1_REG16P2
	JUN VTL_EXECUTE_PMINDEX_CONTINUE ; execute remaining string

VTL_EXEC_L2:
	;; IF
	FIM P7, ';'
	JMS CMP_P1P7
	JCN ZN, VTL_EXEC_L3
	FIM P1, REG16_EVAL
	JMS ISZEROORNOT_REG16P1
	JCN ZN, VTL_EXEC_L2_TRUE
	JUN VTL_RUN_SINGLE_LINE_RETURN ; return to the run loop
VTL_EXEC_L2_TRUE:
	JUN VTL_EXECUTE_PMINDEX_CONTINUE ; execute remaining string

VTL_EXEC_L3:
	;; GOTO
	FIM P7, '#'
	JMS CMP_P1P7
	JCN ZN, VTL_EXEC_L4
VTL_EXEC_GOTO_FROM_GOSUB:
	FIM P1, REG16_EVAL
	JMS ISZEROORNOT_REG16P1
	JCN Z, VTL_EXEC_SKIPGOTO
	FIM P1, REG16_LINENUM	         ; execute GOTO
	JMS LD_REG16P1_REG16P2
	JUN FIND_LINE_AND_EXEC
VTL_EXEC_SKIPGOTO:			 ; #=0 then do nothing
	JUN VTL_EXECUTE_PMINDEX_CONTINUE ; execute remaining string

VTL_EXEC_L4:
	;; GOSUB
	FIM P7, '!'
	JMS CMP_P1P7
	NOP
	NOP
	NOP
	NOP
	JCN Z, VTL_EXEC_GOSUB
	JUN VTL_EXEC_L5
VTL_EXEC_GOSUB:
	FIM P0, REG16_RETURN
	FIM P1, REG16_LINENUM
	JMS LD_REG16P0_REG16P1
	JMS INC_REG16P0		        ; REG(!)=REG(#)+1
	FIM P0, REG16_INDEX
	
	JUN VTL_EXEC_GOTO_FROM_GOSUB     ; jump to GOTO
	
VTL_EXEC_L5:
	;; &
	FIM P7, '&'
	JMS CMP_P1P7
	JCN ZN, VTL_EXEC_L6
	FIM P1, REG16_PEND
	JMS LD_REG16P1_REG16P2
	JUN VTL_EXECUTE_PMINDEX_CONTINUE ; execute remaining string
VTL_EXEC_L6:
	;; Putchar
	FIM P7, '$'
	JMS CMP_P1P7
	JCN ZN, VTL_EXEC_L7
	LD_P0_P2
	JMS LD_P1_REG16P0_8BIT
	JMS PUTCHAR_P1
	JUN VTL_EXECUTE_PMINDEX_CONTINUE ; execute remaining string
VTL_EXEC_L7:
VTL_EXEC_L8:
VTL_EXEC_L9:
VTL_EXEC_L10:
VTL_EXEC_SYNTAX_ERROR:
	FIM P0, REG8_ERROR2
	JMS LD_REG8P0_P1
	FIM P0, REG8_ERROR
	FIM P1, ERROR_EXEC_SYNTAX_ERROR
	JMS LD_REG8P0_P1

	JUN VTL_START

;;;----------------------------------------------------------------------------
;;; SET_PRINTFORMAT
;;; REG4(PRINTFORMAT) = ACC
;;;----------------------------------------------------------------------------
PRINTFMT_NORMAL		equ 00H
PRINTFMT_HEX2B		equ 01H
PRINTFMT_HEX4B		equ 02H

SET_PRINTFORMAT:	
	FIM P7, REG4_PRINTFORMAT
	SRC P7
	WRM
	BBL 0

GET_PRINTFORMAT_R5:
	FIM P7, REG4_PRINTFORMAT
	SRC P7
	RDM
	XCH R5
	BBL 0
;;;----------------------------------------------------------------------------
;;; VTL_EXEC_PRINT
;;;----------------------------------------------------------------------------
VTL_EXEC_PRINT:
	JMS INC_REG16P0		; SKIP '=' without check for symplification

	JMS LD_P1_PM12REG16P0
	JMS ISZEROORNOT_P1
	JCN ZN, VTL_EXEC_PRINT_L1	; not EOL
	JUN VTL_PRINT_ERREXIT   	; EOL
VTL_EXEC_PRINT_L1:
	FIM P7, '"'		; "
	JMS CMP_P1P7
	JCN ZN, VTL_PRINT_L2
	JUN VTL_PRINT_QUOTEDSTRING
VTL_PRINT_L2:	
	FIM P1, REG16_EVAL
	FIM P2, lo(RETURN_PRINT_R1)
	JUN EVAL_EXPRESSION_PMINDEX_REG16P1
PRINT_R1:
	JMS GET_PRINTFORMAT_R5
	CLB
	LDM PRINTFMT_HEX2B
	SUB R5
	JCN NZ, VTL_PRINT_FMT2
	FIM P0, REG16_EVAL		; restore P0 afterwards if needed
	JMS LD_P1_REG16P0_8BIT
	JMS PRINTHEX_P1
	JUN VTL_PRINT_EXIT
VTL_PRINT_FMT2:
	CLB
	LDM PRINTFMT_HEX4B
	SUB R5
	JCN NZ, VTL_PRINT_DEFAULT
	JMS PRINTHEX_REG16P1
	JUN VTL_PRINT_EXIT

VTL_PRINT_DEFAULT:
	JMS PRINT_REG16P1
	JUN VTL_PRINT_EXIT

VTL_PRINT_QUOTEDSTRING:
	JMS INC_REG16P0		; INDEX++
	JMS PRINTSTR_PM12REG16P0_DELIM_P1
	JMS LD_P1_PM12REG16P0
	FIM P7, ';'
	JMS CMP_P1P7
	JCN Z, VTL_PRINT_SKIPCRLF	; skip CRLF and increment INDEX
	JMS PRINT_CRLF
	JUN VTL_PRINT_EXIT
VTL_PRINT_SKIPCRLF:	
	JMS INC_REG16P0
	JUN VTL_PRINT_EXIT

VTL_PRINT_ERREXIT:
	FIM P0, REG8_ERROR
	FIM P1, ERROR_PRINT_CANNOTPRINT
	JUN VTL_START			 ; error and jump to start
	
VTL_PRINT_EXIT:
	JUN VTL_EXECUTE_PMINDEX_CONTINUE ; execute remaining string

;;;----------------------------------------------------------------------------
;;; EVAL_EXPRESSION_PMINDEX_REG16P1
;;; Evaluate expression PM(REG(INDEX)) and set result to REG(P1)
;;; destory: P0, P6, P7
;;; return: P0=REG16_INDEX, REG(P1)=result
;;; REG16(INDEX) is incremented to the end of expression +1, (EOL if EOL)
;;;----------------------------------------------------------------------------
EVAL_EXPRESSION_PMINDEX_REG16P1:
	JMS PUSH_P2		; PUSH a return label
	JMS PUSH_P1

	FIM P0, REG16_INDEX
	JMS LD_P1_PM12REG16P0
	JMS ISZEROORNOT_P1	; check EOL
	JCN ZN, EVAL_START
	;; EOL and EXIT
	;; Do nothing, and REG(EVAL) does not change.
	FIM P0, REG8_ERROR
	FIM P1, ERROR_EVAL_UNEXPECTED_EOL
	JMS LD_REG8P0_P1
	JUN VTL_START		; error and jump to VTL_START
	;; 	FIM P0, REG16_INDEX	; restore P0 to INDEX
	;; 	JMS POP_P1
	;; 	JMS POP_P2
	;; 	JUN RETURN_P2

EVAL_START:	
	;; get a factor and push it
	FIM P1, REG16_LVALUE
	FIM P2, lo(RETURN_EVAL_R1)
	JUN GETFACTOR_PMINDEX_REG16P1
EVAL_R1:	
EVAL_CONTINUE:
	FIM P0, REG16_INDEX
	FIM P1, REG16_LVALUE
	JMS PUSH_REG16P1		; push the LVALUE
	JMS LD_P1_PM12REG16P0		; get an operator

	JMS ISZEROORNOT_P1		; no operator and EOL, then exit
	JCN ZN, EVAL_NEXT1
	JUN EVAL_EXIT
EVAL_NEXT1:
	JMS INC_REG16P0			; increment INDEX if not EOL

	FIM P7, ')'
	JMS CMP_P1P7
	JCN ZN, EVAL_NEXT2		; if ')', then exit
	JUN EVAL_EXIT
EVAL_NEXT2:
	FIM P7, ' '
	JMS CMP_P1P7
	JCN ZN, EVAL_NEXT3		; if ' ', then exit
	JUN EVAL_EXIT
EVAL_NEXT3:

	JMS PUSH_P1			; push the operator

	FIM P1, REG16_RVALUE
	FIM P2, lo(RETURN_EVAL_R2)
	JUN GETFACTOR_PMINDEX_REG16P1   ; get RVALUE
EVAL_R2:	
	JMS POP_P2			; pop the operator to P2

	FIM P1, REG16_LVALUE
	JMS POP_REG16P1		        ; pop the LVALUE

;;; 
	FIM P0, REG16_LVALUE		; set P0 = REG_LVALUE
	FIM P1, REG16_RVALUE		; set P1 = REG_RVALUE
;;; 
;;;  execute operator calculation
;;; 
	FIM P7, '+'
	JMS CMPEQ_P2P7
	JCN ZN, EVAL_O1
	JMS ADD_REG16P0_REG16P1
	JUN EVAL_CONTINUE
EVAL_O1:
	FIM P7, '-'
	JMS CMPEQ_P2P7
	JCN ZN, EVAL_O2
	JMS SUB_REG16P0_REG16P1
	JUN EVAL_CONTINUE
EVAL_O2:
	FIM P7, '*'
	JMS CMPEQ_P2P7
	JCN ZN, EVAL_O3
	JMS MUL_REG16P0_REG16P1
	JUN EVAL_CONTINUE
EVAL_O3:
	FIM P7, '/'
	JMS CMPEQ_P2P7
	NOP
	NOP
	JCN ZN, EVAL_O4
	JMS DIV_REG16P0_REG16P1
	JUN EVAL_CONTINUE
EVAL_O4:
	FIM P7, '='
	JMS CMPEQ_P2P7
	JCN ZN, EVAL_O5
	JMS CMP_REG16P0_REG16P1
	JCN Z, EVAL_LVALUE_TRUE ; jump if REG(P0)==REG(P1)
EVAL_LVALUE_FALSE:	
	JMS CLEAR_REG16P0	; set LVALUE=0
	JUN EVAL_CONTINUE
EVAL_LVALUE_TRUE:	
	FIM P1, 1
	JMS LD_REG16P0_8BIT_P1	; set LVALUE=1
	JUN EVAL_CONTINUE
EVAL_O5:
	FIM P7, '<'
	JMS CMPEQ_P2P7
	JCN ZN, EVAL_06
	JMS CMP_REG16P0_REG16P1
	JCN CN, EVAL_LVALUE_TRUE  ; jump if REG(P0) < REG(P1)
	JUN EVAL_LVALUE_FALSE
EVAL_06:
	FIM P7, '>'
	JMS CMPEQ_P2P7
	JCN ZN, EVAL_O7
	JMS CMP_REG16P0_REG16P1
	JCN CN, EVAL_LVALUE_FALSE ; jump if REG(P0) < REG(P1)
;;; 
;;; '>' is TEST FOR GREATER THAN OR EQUAL TO
;;; 
;;; 	JCN Z, EVAL_LVALUE_FALSE  ;         REG(P0) == REG(P1)
	JUN EVAL_LVALUE_TRUE	  ;         REG(P0) > REG(P1)
EVAL_O7:
EVAL_O8:
EVAL_O9:
	;; ERROR (unknown operator)
	FIM P0, REG8_ERROR
	FIM P1, ERROR_EVAL_UNKNOWNOPERATOR

	FIM P1, REG16_LVALUE	; set current LVALUE as a result
	JMS PUSH_REG16P1
	JUN VTL_START		; error and jump to VTL_START
EVAL_EXIT:
	FIM P1, REG16_TMP
	JMS POP_REG16P1		; return with stacked value

	JMS POP_P1
	FIM P0, REG16_TMP
	JMS LD_REG16P1_REG16P0	; load result to REG(P1)
	
	FIM P0, REG16_INDEX	; restore P0 to INDEX
	JMS POP_P2
	JUN RETURN_P2	
	
;;;----------------------------------------------------------------------------
;;; GETFACTOR_PMINDEX_REG16P1
;;; Get a value of the first factor from PMINDEX and set it to REG(P1)
;;;----------------------------------------------------------------------------
GETFACTOR_PMINDEX_REG16P1:
	JMS PUSH_P2		; PUSH a return label
	JMS PUSH_P1

	FIM P0, REG16_INDEX
	JMS LD_P1_PM12REG16P0

	FIM P7, '('
	JMS CMP_P1P7
	JCN NZ,GETFACTOR_L0
	JMS INC_REG16P0
	FIM P2, lo(RETURN_GETFACTOR_R1)
	FIM P1, REG16_FACTOR
	JUN EVAL_EXPRESSION_PMINDEX_REG16P1
GETFACTOR_R1:
	JUN GETFACTOR_EXIT_NOINCREMENT

GETFACTOR_L0:
	FIM P2, REG16_FACTOR	; P2 = REG16_FACTOR

	;; unary operator minus '-' 
	FIM P7, '-'
	JMS CMP_P1P7
	JCN NZ,GETFACTOR_L1
	JMS INC_REG16P0
	FIM P2, lo(RETURN_GETFACTOR_R2)
	FIM P1, REG16_FACTOR
	JUN GETFACTOR_PMINDEX_REG16P1
GETFACTOR_R2:
	;; REG(FACTOR)=-REG(FACTOR) (2's complement)
	FIM P0, REG16_FACTOR
	JMS COMPLEMENT_REG16P0
	JMS INC_REG16P0
	;; FIM P0, REG16_INDEX ; can be omitted because NOINCREMENT P0
	
	JUN GETFACTOR_EXIT_NOINCREMENT
GETFACTOR_L1:
	;; decimal number
	JMS ISNUM_P1
	JCN Z, GETFACTOR_L2
	FIM P1, REG16_FACTOR
	JMS GETNUMBER_PM12REG16P0_REG16P1
	JUN GETFACTOR_EXIT_NOINCREMENT
GETFACTOR_L2:
	;; variable
	JMS ISALPHA_P1
	JCN Z, GETFACTOR_L3
	JMS CTOREG16NUM_P1
	JMS LD_REG16P2_REG16P1
	JUN GETFACTOR_EXIT
GETFACTOR_L3:
	;; remainder of the last DIV
	FIM P7, '%'
	JMS CMP_P1P7
	JCN ZN, GETFACTOR_L4

	FIM P1, REG16_RMND
	JMS LD_REG16P2_REG16P1

	JUN GETFACTOR_EXIT
GETFACTOR_L4:
	;; line number
	FIM P7, '#'
	JMS CMP_P1P7
	JCN ZN, GETFACTOR_L5

	FIM P1, REG16_LINENUM
	JMS LD_REG16P2_REG16P1
	
	JUN GETFACTOR_EXIT
GETFACTOR_L5:
	;; return address
	FIM P7, '!'
	JMS CMP_P1P7
	JCN ZN, GETFACTOR_L6

	FIM P1, REG16_RETURN
	JMS LD_REG16P2_REG16P1

	JUN GETFACTOR_EXIT
GETFACTOR_L6:
	;; random number
	FIM P7, '\''
	JMS CMP_P1P7
	JCN ZN, GETFACTOR_L7

	FIM P1, REG16_RANDOM
	JMS LD_REG16P2_REG16P1

	JUN GETFACTOR_EXIT
GETFACTOR_L7:
	;; the last byte of program
	FIM P7, '&'
	JMS CMP_P1P7
	JCN ZN, GETFACTOR_L8

	FIM P1, REG16_PEND
	JMS LD_REG16P2_REG16P1

	JUN GETFACTOR_EXIT
GETFACTOR_L8:
	;; input one charactoer from serial
	FIM P7, '$'
	JMS CMP_P1P7
	JCN ZN, GETFACTOR_L9

	JMS GETCHAR_P1
	FIM P0, REG16_FACTOR
	JMS LD_REG16P0_8BIT_P1

	FIM P0, REG16_INDEX

	JUN GETFACTOR_EXIT
GETFACTOR_L9:
	;; input one line from serial and evaluate it
	FIM P7, '?'
	JMS CMP_P1P7
	JCN Z, GETFACTOR_L91
	JUN GETFACTOR_L10
GETFACTOR_L91:
	FIM P0, REG16_INDEX
	FIM P1, REG16_INDEX
	JMS PUSH_REG16P1	; push REG(INDEX)
	FIM P2, up(PM12_LINEBUF)
	FIM P3, lo(PM12_LINEBUF)
	JMS LD_REG16P0_P2P3	; REG(INDEX) = PM12_LNEBUF
	JMS GETLINE_PM12REG16P0	; get line input

	FIM P1, REG16_FACTOR
	FIM P2, lo(RETURN_GETFACTOR_L9_R1)
	JUN EVAL_EXPRESSION_PMINDEX_REG16P1 ; eval it
GETFACTOR_L9_R1:
	FIM P1, REG16_INDEX
	JMS POP_REG16P1		; pop REG(INDEX)

	JUN GETFACTOR_EXIT
GETFACTOR_L10:


GETFACTOR_ERROR:
	FIM P0, REG8_ERROR2
	JMS LD_REG8P0_P1

	FIM P1, ERROR_FACTOR_NOTAFACTOR
	FIM P0, REG8_ERROR
	JMS LD_REG8P0_P1
	JUN VTL_START		; error and jump to VTL_START
GETFACTOR_EXIT:
	JMS INC_REG16P0		; increment REG(INDEX)
GETFACTOR_EXIT_NOINCREMENT:
	JMS POP_P1
	FIM P0, REG16_FACTOR
	JMS LD_REG16P1_REG16P0	; load result to REG(P1)
	FIM P0, REG16_INDEX	; set P0 to INDEX

	JMS POP_P2
	JUN RETURN_P2
	
;;;----------------------------------------------------------------------------
;;; SKIPSPACE_PM12REG16P0
;;; Skip ' ' in the string buffer PM(REG16(P0))
;;; increment REG16(P0) to not a ' ' char.
;;; destroy: P7
;;;----------------------------------------------------------------------------
SKIPSPACE_PM12REG16P0:
	JMS PUSH_P1
SKIPSPACE_LOOP:	
	JMS LD_P1_PM12REG16P0
	;; 	JMS ISZEROORNOT_P1
	;;	JCN Z, SKIPSPACE_EXIT	; EOL
	FIM P7, ' '
	JMS CMP_P1P7
	JCN ZN, SKIPSPACE_EXIT
	JMS INC_REG16P0
	JUN SKIPSPACE_LOOP
SKIPSPACE_EXIT:
	JMS POP_P1
	BBL 0

;;;----------------------------------------------------------------------------
;;; CTOREG16NUM_P1
;;; return address of REG16_x, (x=A to Z)
;;; assuming that REG16_A=04H, ..., REG16_Z=68H
;;; P1 must be an alphabet caracter and no error check
;;; 
;;; (Aa) 41H, 61H: 01x0 0001 -> 0000 0100 (04H)
;;; (Bb) 42H, 62H: 01x0 0010 -> 0000 1000 (08H)
;;; ...
;;; (Zz) 5AH, 7AH: 01x1 1010 -> 0110 1000 (68H)
;;;           bit: 7654 3210 -> .432 10.. (.=0)
;;;----------------------------------------------------------------------------
CTOREG16NUM_P1:
	CLB
	LD R2
	RAR
	TCC			; ACC=R2.bit0 (=P1.bit4)
	RAL
	RAL
	XCH R2			; R2 = .4..
	LD R3
	RAR
	CLC
	RAR
	CLC
	ADD R2
	XCH R2			; R2 = .432
	CLB
	LD R3
	RAL
	CLC
	RAL
	XCH R3			; R3 = 10..
	BBL 0
	

;;;----------------------------------------------------------------------------
;;; Subroutines for REG16 (16bit registars)
;;;----------------------------------------------------------------------------
;;;----------------------------------------------------------------------------
;;; CLEAR_REG16P0
;;; REG16(P0) = 0
;;; destroy: P7
;;;----------------------------------------------------------------------------
CLEAR_REG16P0:
	LD R1
	XCH R15			; save R1
	LDM loop(4)
	XCH R14
	CLB
CLEARREG16_LOOP:
	SRC P0
	WRM
	INC R1
	ISZ R14, CLEARREG16_LOOP	
	LD R15
	XCH R1			; restore R1
	BBL 0

;;;----------------------------------------------------------------------------
;;; LD_REG16P0_REG16P1
;;; REG16(P0) = REG16(P1)
;;; destroy: P7
;;;----------------------------------------------------------------------------
LD_REG16P0_REG16P1:
	LD R1
	XCH R15			; save R1 to R15
	LD R3
	XCH R13			; save R3 to R13

	LDM loop(4)
	XCH R14
LDREG16P0P1_LOOP:
	SRC P1
	RDM
	SRC P0
	WRM
	INC R1
	INC R3
	ISZ R14, LDREG16P0P1_LOOP

	LD R15
	XCH R1			; restore R1
	LD R13
	XCH R3			; restore R3
	BBL 0

;;;----------------------------------------------------------------------------
;;; LD_REG16P1_REG16P0
;;; REG16(P1) = REG16(P0)
;;; destroy: P7
;;;----------------------------------------------------------------------------
LD_REG16P1_REG16P0:
	LD R1
	XCH R15			; save R1 to R15
	LD R3
	XCH R13			; save R3 to R13

	LDM loop(4)
	XCH R14
LDREG16P1P0_LOOP:
	SRC P0
	RDM
	SRC P1
	WRM
	INC R1
	INC R3
	ISZ R14, LDREG16P1P0_LOOP

	LD R15
	XCH R1			; restore R1
	LD R13
	XCH R3			; restore R3
	BBL 0

;;;----------------------------------------------------------------------------
;;; LD_REG16P1_REG16P2
;;; REG16(P1) = REG16(P2)
;;; destroy: P7
;;;----------------------------------------------------------------------------
LD_REG16P1_REG16P2:
	LD R5
	XCH R15			; save R5 to R15
	LD R3
	XCH R13			; save R3 to R13

	LDM loop(4)
	XCH R14
LDREG16P1P2_LOOP:
	SRC P2
	RDM
	SRC P1
	WRM
	INC R5
	INC R3
	ISZ R14, LDREG16P1P2_LOOP

	LD R15
	XCH R5			; restore R5
	LD R13
	XCH R3			; restore R3
	BBL 0

;;;----------------------------------------------------------------------------
;;; LD_REG16P2_REG16P0
;;; REG16(P2) = REG16(P0)
;;; destroy: P7
;;;----------------------------------------------------------------------------
LD_REG16P2_REG16P0:
	LD R1
	XCH R15			; save R1 to R15
	LD R5
	XCH R13			; save R5 to R13

	LDM loop(4)
	XCH R14
LDREG16P2P0_LOOP:
	SRC P0
	RDM
	SRC P2
	WRM
	INC R1
	INC R5
	ISZ R14, LDREG16P2P0_LOOP

	LD R15
	XCH R1			; restore R1
	LD R13
	XCH R5			; restore R3
	BBL 0
	
;;;----------------------------------------------------------------------------
;;; LD_REG16P2_REG16P1
;;; REG16(P2) = REG16(P1)
;;; destroy: P7
;;;----------------------------------------------------------------------------
LD_REG16P2_REG16P1:
	LD R3
	XCH R15			; save R3 to R15
	LD R5
	XCH R13			; save R5 to R13

	LDM loop(4)
	XCH R14
LDREG16P2P1_LOOP:
	SRC P1
	RDM
	SRC P2
	WRM
	INC R3
	INC R5
	ISZ R14, LDREG16P2P1_LOOP

	LD R15
	XCH R3			; restore R1
	LD R13
	XCH R5			; restore R3
	BBL 0
	

;;;----------------------------------------------------------------------------
;;; GETSIGN_REG16P0_TOCARRY
;;; Get a sign of REG(P0) and set it to Carry
;;; CY = SIGN(REG16(P0)), ACC=0
;;;----------------------------------------------------------------------------
GETSIGN_REG16P0_TOCARRY:
	LD R1
	XCH R15			; save R1 to R15
	INC R1
	INC R1
	INC R1
	SRC P0
	RDM			; bitFEDC
	RAL			; rotate left (CY<-MSB)
	LD R15
	XCH R1			; restore R1
	BBL 0

;;;----------------------------------------------------------------------------
;;; ISZEROORNOT_REG16P1
;;; return:
;;; 	ACC = 0, CY = 0 if REG16(P1) == 0
;;; 	ACC = 1, CY = 0 if 1<=REG16(P1)<=0x7fff
;;; 	ACC = 1, CY = 1 if 0x80<=REG16(P1)<=0xffff
;;; destroy: R15, R14
;;;----------------------------------------------------------------------------
ISZEROORNOT_REG16P1:
	LD R3
	XCH R15			; save R3 to R15

	LDM loop(4)
	XCH R14
ISZEROORNOT_LOOP:
	SRC P1
	RDM			; bit4321
	JCN ZN, ISZEROREGP0_EXIT1
	INC R3
	ISZ R14, ISZEROORNOT_LOOP

	LD R15
	XCH R3			; restore R3
	BBL 0

ISZEROREGP0_EXIT1:
	LD R15
	XCH R3			; restore R3
	BBL 1


;;;----------------------------------------------------------------------------
;;; INC_REG16P0
;;; REG16(P0) = REG16(P0)+1
;;; destroy: P7(R14, R15)
;;;----------------------------------------------------------------------------
INC_REG16P0:
	LD R1
	XCH R15			; save R1 to R15

	LDM loop(4)
	XCH R14			; R14 = 12, 13, 14, 15
REG16_INC_LOOP:
	SRC P0
	RDM
	IAC 
	WRM
	JCN NZ, REG16_INC_EXIT
	INC R1
	ISZ R14, REG16_INC_LOOP

REG16_INC_EXIT:
	LD R15
	XCH R1			; restore R1
	BBL 0

;;;----------------------------------------------------------------------------
;;; DEC_REG16P0
;;; REG16(P0) = REG16(P0) - 1
;;; destroy: P7(R14, R15)
;;;----------------------------------------------------------------------------
DEC_REG16P0:
	LD R1
	XCH R15			; save R1 to R15

	LDM loop(4)
	XCH R14			; R14 = 12, 13, 14, 15
	CLC
REG16_DEC_LOOP:
	SRC P0
	RDM
	DAC
	WRM
	JCN C, REG16_DEC_EXIT	; CY=1 if no borrow
	INC R1
	ISZ R14, REG16_DEC_LOOP
REG16_DEC_EXIT:
	LD R15
	XCH R1			; restore R1
	BBL 0

;;;----------------------------------------------------------------------------
;;; COMPLEMENT_REG16P0
;;; REG16(P0) = not REG16(P0)
;;; destroy: P7(R14, R15)
;;;----------------------------------------------------------------------------
COMPLEMENT_REG16P0:
	LD R1
	XCH R15			; save R1 to R15

	LDM loop(4)
	XCH R14			; R14 = 12, 13, 14, 15
REG16_COMPLEMENT_LOOP:
	SRC P0
	RDM
	CMA
	WRM
	INC R1
	ISZ R14, REG16_COMPLEMENT_LOOP

REG16_COMPLEMENT_EXIT:
	LD R15
	XCH R1			; restore R1
	BBL 0

;;;----------------------------------------------------------------------------
;;; LD_REG16P0_P2P3
;;; REG16(P0) = P2P3(R4R5R6R7)
;;; destroy: P7
;;;----------------------------------------------------------------------------
LD_REG16P0_P2P3:
	SRC P0
	LD R7
	WRM

	INC R1
	SRC P0
	LD R6
	WRM

	INC R1
	SRC P0
	LD R5
	WRM

	INC R1
	SRC P0
	LD R4
	WRM

	LD R1
	DAC
	DAC
	DAC
	XCH R1			; restore R1
	BBL 0

;;;----------------------------------------------------------------------------
;;; LD_REG16P1_P2P3
;;; REG16(P1) = P2P3(R4R5R6R7)
;;; destroy: P7
;;;----------------------------------------------------------------------------
LD_REG16P1_P2P3:
	SRC P1
	LD R7
	WRM

	INC R3
	SRC P1
	LD R6
	WRM

	INC R3
	SRC P1
	LD R5
	WRM

	INC R3
	SRC P1
	LD R4
	WRM

	LD R3
	DAC
	DAC
	DAC
	XCH R3			; restore R3
	BBL 0

;;;----------------------------------------------------------------------------
;;; LD_P2P3_REG16P1
;;; P2(R4R5) = REG16(P1).bitFEDCBA98
;;; P3(R6R7) = REG16(P1).bit76543210
;;;----------------------------------------------------------------------------
LD_P2P3_REG16P1:
	SRC P1
	RDM
	XCH R7			; R7 = REG16(P1).bit3210

	INC R3
	SRC P1
	RDM
	XCH R6			; R6 = REG16(P1).bit7654
	
	INC R3
	SRC P1
	RDM
	XCH R5			; R5 = REG16(P1).bitBA98

	INC R3
	SRC P1
	RDM
	XCH R4			; R4 = REG16(P1).bitFEDC

	LD R3
	DAC
	DAC
	DAC
	XCH R3			; restore R3

	BBL 0

;;;----------------------------------------------------------------------------
;;; LD_REG16P0_8BIT_P1
;;; REG16(P0) = P1
;;; load lower 8bit, upper 8bit becomes 0
;;;----------------------------------------------------------------------------
LD_REG16P0_8BIT_P1:
	SRC P0
	LD R3
	WRM

	INC R1
	SRC P0
	LD R2
	WRM

	CLB
	INC R1
	SRC P0
	WRM

	INC R1
	SRC P0
	WRM

	LD R1
	DAC
	DAC
	DAC
	XCH R1			; restore R1
	BBL 0

;;;----------------------------------------------------------------------------
;;; CLEAR_SIGNFLAG
;;; TOGGLE_SIGNFLAG
;;; GET_SIGNFLAG_TOCARRY
;;;----------------------------------------------------------------------------
CLEAR_SIGNFLAG:
	FIM P7, REG4_SIGN
	SRC P7
	CLB
	WRM
	BBL 0

TOGGLE_SIGNFLAG:
	FIM P7, REG4_SIGN
	SRC P7
	RDM
	CMA
	WRM
	BBL 0

GET_SIGNFLAG_TOCARRY:	
	FIM P7, REG4_SIGN
	SRC P7
	RDM
	RAR
	BBL 0

;;;----------------------------------------------------------------------------
;;; LD_REG8P0_P1
;;; REG8(P0) = P1
;;;----------------------------------------------------------------------------
LD_REG8P0_P1:
	SRC P0
	LD R3
	WRM

	INC R1
	SRC P0
	LD R2
	WRM

	LD R1
	DAC
	XCH R1			; restore R1
	BBL 0

;;;----------------------------------------------------------------------------
;;; LD_P1_REG16P0_8BIT (= LD_P1_REG8P0)
;;; P1 = REG16(P0).bit76543210
;;; or 	P1 = REG8(P0)
;;;----------------------------------------------------------------------------
LD_P1_REG8P0
LD_P1_REG16P0_8BIT:
	SRC P0
	RDM
	XCH R3			; R5 = REG16(R14R15).bit3210

	INC R1			; R1++
	SRC P0
	RDM			; R4 = REG16(R14R15).bit7654
	XCH R2

	LD R1
	DAC
	XCH R1			; restore R1
	BBL 0

;;;----------------------------------------------------------------------------
;;; LD_P2P3_REG16P0
;;; P2(R4R5) = REG16(P0).bitFEDCBA98
;;; P3(R6R7) = REG16(P0).bit76543210
;;;----------------------------------------------------------------------------
LD_P2P3_REG16P0:
	SRC P0
	RDM
	XCH R7			; R7 = REG16(P0).bit3210

	INC R1
	SRC P0
	RDM
	XCH R6			; R6 = REG16(P0).bit7654
	
	INC R1
	SRC P0
	RDM
	XCH R5			; R5 = REG16(P0).bitBA98

	INC R1
	SRC P0
	RDM
	XCH R4			; R4 = REG16(P0).bitFEDC

	LD R1
	DAC
	DAC
	DAC
	XCH R1			; restore R1

	BBL 0

;;;----------------------------------------------------------------------------
;;; MUL2_REG16P0
;;; REG16(P0) = REG16(P0)*2
;;; CY=1 if overflow
;;; destroy: P7(R14, R15)
;;;----------------------------------------------------------------------------
MUL2_REG16P0:
	LD R1
	XCH R15			; save R1 to R15

	LDM loop(4)
	XCH R14
	CLC
MUL2REG16P0_LOOP:
	SRC P0
	RDM
	RAL
	WRM
	INC R1
	ISZ R14, MUL2REG16P0_LOOP

	LD R15
	XCH R1			; restore R1
	BBL 0

;;;----------------------------------------------------------------------------
;;; MUL2_REG16P1
;;; REG16(P1) = REG16(P1)*2
;;; CY=1 if overflow
;;; destroy: P7(R14, R15)
;;;----------------------------------------------------------------------------
MUL2_REG16P1:
	LD R3
	XCH R15			; save R3 to R15

	LDM loop(4)
	XCH R14
	CLC
MUL2REG16P1_LOOP:
	SRC P1
	RDM
	RAL
	WRM
	INC R3
	ISZ R14, MUL2REG16P1_LOOP

	LD R15
	XCH R3			; restore R3
	BBL 0

;;;----------------------------------------------------------------------------
;;; DIV2_REG16P2
;;; REG16(P2) = REG16(P2)/2
;;; CY=1 if LSB was 1
;;; destroy: P7(R14, R15)
;;;----------------------------------------------------------------------------
DIV2_REG16P2:
	INC R5
	INC R5
	INC R5			; R5=R5+3
	LDM loop(4)
	XCH R14
	CLB
	XCH R15
DIV2REG16_LOOP:
	LD R15
	RAR			; restore last CY
	SRC P2
	RDM
	RAR
	WRM
	TCC			;
	XCH R15			; R15=CY
	LD R5
	DAC
	XCH R5			; R5--
	ISZ R14, DIV2REG16_LOOP
	INC R5			; restore R5
	LD R15
	RAR			; set last CY
	BBL 0
	
;;;----------------------------------------------------------------------------
;;; ADD_REG16P0_REG16P1
;;; REG16(P0) = REG16(P0) + REG16(P1)
;;; destroy: P6, P7
;;;----------------------------------------------------------------------------
ADD_REG16P0_REG16P1:
	LD R1
	XCH R15			; save R1 to R15
	LD R3
	XCH R13			; save R3 to R13

	LDM loop(4)
	XCH R14
	CLC
REG16_ADD_LOOP:
	SRC P1
	RDM
	SRC P0
	ADM
	WRM
	INC R1
	INC R3
	ISZ R14, REG16_ADD_LOOP

	LD R15
	XCH R1			; restore R1
	LD R13
	XCH R3			; restore R3
	BBL 0

;;;----------------------------------------------------------------------------
;;; SUB_REG16P0_REG16P1
;;; REG16(P0) = REG16(P0) - REG16(P1)
;;; destroy: P6, P7
;;;----------------------------------------------------------------------------
SUB_REG16P0_REG16P1:
	LD R1
	XCH R15			; save R1 to R15
	LD R3
	XCH R13			; save R3 to R13

	LDM loop(4)
	XCH R14
	STC
REG16_SUB_LOOP:
	CMC
	SRC P0
	RDM
	SRC P1
	SBM
	SRC P0
	WRM
	INC R1
	INC R3
	ISZ R14, REG16_SUB_LOOP

	LD R15
	XCH R1			; restore R1
	LD R13
	XCH R3			; restore R3
	BBL 0

;;;----------------------------------------------------------------------------
;;; P2P3 = P2P3/16
;;;----------------------------------------------------------------------------
DIV16_P2P3:	
	LD R6
	XCH R7			; 10'->1'
	LD R5
	XCH R6			; 100'->10'
	LD R4
	XCH R5			; 1000'->100'
	CLB
	XCH R4			;  0 ->1000'
	BBL 0

;;;----------------------------------------------------------------------------
;;; P2P3 = P2P3*16
;;;----------------------------------------------------------------------------
MUL16_P2P3:	
	LD R5
	XCH R4			; 100'->1000'
	LD R6
	XCH R5			; 10'->100'
	LD R7
	XCH R6			; 1'->10'
	CLB
	XCH R7			; 0->1'
	BBL 0
	
;;;----------------------------------------------------------------------------
;;; MUL_REG16P0_REG16P1
;;; REG16(P0) =  REG16(P0) * REG16(P1)
;;; destroy P7, P6, R5
;;;----------------------------------------------------------------------------
MUL_REG16P0_REG16P1:
	JMS PUSH_P1
	JMS PUSH_P2

	FIM P2, REG16_TMP
	JMS LD_REG16P2_REG16P0	; REG(TMP)= REG(P0)
	
	FIM P2, REG16_TMP2
	JMS LD_REG16P2_REG16P1	; REG(TMP2)= REG(P1)

	JMS CLEAR_REG16P0	; REG(P0) = 0
	FIM P1, REG16_TMP
	FIM P2, REG16_TMP2

	LDM loop(16)
	XCH R10
MUL_REG16_LOOP:
	JMS DIV2_REG16P2
	JCN CN, MUL_REG16_NEXT
	JMS ADD_REG16P0_REG16P1
MUL_REG16_NEXT:	
	JMS MUL2_REG16P1
	ISZ R10, MUL_REG16_LOOP

	JMS POP_P2
	JMS POP_P1
	BBL 0

;;;----------------------------------------------------------------------------
;;; DIV_REG16P0_REG16P1
;;; REG16(P0) =  REG16(P0) / REG16(P1)
;;; REG(RMND) = remainder
;;; return: ACC=0 OK, ACC=1 divide by zero
;;; destroy: P2, P3, P4, P5, P6, P7
;;;----------------------------------------------------------------------------
DIV_REG16P0_REG16P1:
	JMS PUSH_REG16P1
	JMS PUSH_P1
	JMS PUSH_P0

	JMS CLEAR_SIGNFLAG
	
	FIM P2, 00H
	JMS GETSIGN_REG16P0_TOCARRY
	JCN NC, DIV_POSITIVE_DIVIDEND
	JMS COMPLEMENT_REG16P0
	JMS INC_REG16P0		; REG(P0)=-REG(P0)
	JMS TOGGLE_SIGNFLAG	; set SIGNFLAG
	FIM P2, 01H
DIV_POSITIVE_DIVIDEND:
	JMS PUSH_P2		; save sign of REG(P0) for sign of the remainder
	JMS LD_P2P3_REG16P0
	FIM P0, REG16_RMND
	JMS LD_REG16P0_P2P3	; REG(RMND) = abd(REG(P0))
	
	LD_P0_P1
	JMS GETSIGN_REG16P0_TOCARRY
	JCN NC, DIV_POSITIVE_DIVISOR
	JMS COMPLEMENT_REG16P0
	JMS INC_REG16P0		; REG(P1)=-REG(P1)
	JMS TOGGLE_SIGNFLAG	; toggle SIGN
DIV_POSITIVE_DIVISOR:
	JMS LD_P2P3_REG16P1 	; P2P3=abs(REG(P1)) P2P3 = divisor

	FIM P0, REG16_RMND
	
	;; registers for the result
	FIM P4, 00H		; R8R9 = 00H
	FIM P5, 00H		; R10R11 = 00H
	
	LD R4
	JCN NZ, REG16_DIV_L1
	JMS MUL16_P2P3		; P2P3 *= 16

	LD R4
	JCN NZ, REG16_DIV_L2
	JMS MUL16_P2P3		; P2P3 *= 16

	LD R4
	JCN NZ, REG16_DIV_L3
	JMS MUL16_P2P3		; P2P3 *= 16

	LD R4
	JCN NZ, REG16_DIV_L4

;;; 	 Error: divide by zero 
	FIM P0, REG16_RMND
	JMS CLEAR_REG16P0	; RMND=0

	JMS POP_P0
	FIM P2, 07FH
	FIM P3, 0FFH
	JMS LD_REG16P0_P2P3	; result = MAXINT
	BBL 1
	
REG16_DIV_L4:
	JMS LD_REG16P1_P2P3	; REG(P1)=P2P3
REG16_DIV_LOOP4:
	JMS SUB_REG16P0_REG16P1	; REG(RMND) = REG(RMND) - REG(P1)
	JCN CN, REG16_DIV_NEXT4
	INC R8			; result +=1000H
	JUN REG16_DIV_LOOP4
REG16_DIV_NEXT4:
	JMS ADD_REG16P0_REG16P1	; REG(RMND) = REG(RMND) + REG(P1)
	JMS DIV16_P2P3		; P2P3 /=16
REG16_DIV_L3:
	JMS LD_REG16P1_P2P3	; REG(P1)=P2P3
REG16_DIV_LOOP3:
	JMS SUB_REG16P0_REG16P1	; REG(RMND) = REG(RMND) - REG(P1)
	JCN CN, REG16_DIV_NEXT3
	INC R9			; result +=100H
	JUN REG16_DIV_LOOP3
REG16_DIV_NEXT3:
	JMS ADD_REG16P0_REG16P1	; REG(RMND) = REG(RMND) + REG(P1)
	JMS DIV16_P2P3		; P2P3 /=16
REG16_DIV_L2:
	JMS LD_REG16P1_P2P3	; REG(P1)=P2P3
REG16_DIV_LOOP2:
	JMS SUB_REG16P0_REG16P1	; REG(RMND) = REG(RMND) - REG(P1)
	JCN CN, REG16_DIV_NEXT2
	INC R10			; result +=10H
	JUN REG16_DIV_LOOP2
REG16_DIV_NEXT2:
	JMS ADD_REG16P0_REG16P1	; REG(RMND) = REG(RMND) + REG(P1)
	JMS DIV16_P2P3		; P2P3 /=16
REG16_DIV_L1:	
	JMS LD_REG16P1_P2P3	; REG(P1)=P2P3
REG16_DIV_LOOP1:
	JMS SUB_REG16P0_REG16P1	; REG(RMND) = REG(RMND) - REG(P1)
	JCN CN, REG16_DIV_NEXT1
	INC R11	 		; result +=1H
	JUN REG16_DIV_LOOP1
REG16_DIV_NEXT1:
	JMS ADD_REG16P0_REG16P1	; REG(RMND) = REG(RMND) + REG(P1)

	JMS POP_P2		; set sign of remainder
	LD R5
	JCN Z, REG16_DIV_POSITIVE_RMND
	JMS COMPLEMENT_REG16P0
	JMS INC_REG16P0
REG16_DIV_POSITIVE_RMND:
	LD_P2_P4
	LD_P3_P5

	JMS POP_P0
	JMS LD_REG16P0_P2P3		; REG(P0)=P2P3 (ABS(REG(P0))/ABS(REG(P1)))
	JMS GET_SIGNFLAG_TOCARRY	; check the sign of the result
	JCN NC, REG16_DIV_EXIT
	;; REG(P0)=-REG(P0)
	JMS COMPLEMENT_REG16P0
	JMS INC_REG16P0
REG16_DIV_EXIT:
	JMS POP_P1
	JMS POP_REG16P1
	
	BBL 0

;;;----------------------------------------------------------------------------
;;; CMP_REG16P0_REG16P1
;;; execute REG16(P0) - REG16(P1) and generate flag
;;; output: ACC=1, CY=0 if REG16(P0) <  REG16(P1)
;;; 	    ACC=0, CY=1 if REG16(P0) == REG16(P1)
;;; 	    ACC=1, CY=1 if REG16(P0) >  REG16(P1)
;;; destroy: P6, P7, R5
;;;----------------------------------------------------------------------------
CMP_REG16P0_REG16P1:
	LD R1
	XCH R15			; save R1 to R15
	LD R3
	XCH R13			; save R3 to R13
	CLB
	XCH R12			; R12 = 0
	LDM loop(4)
	XCH R14			; R14=12, 13, 14, 15
	STC
REG16_CMP_LOOP:
	CMC
	SRC P0
	RDM
	SRC P1
	SBM
	INC R1
	INC R3
	XCH R11			; save ACC to R11 (exit with MSB)
	LD R11
	JCN Z, REG16_CMP_NEXT
	LDM 1
	XCH R12			; set flag for REG(P0) != REG(P1)
REG16_CMP_NEXT:
	ISZ R14, REG16_CMP_LOOP
	LD R11
	RAL
	CMC			; CY=~MSB

	LD R15
	XCH R1			; restore R1
	LD R13
	XCH R3			; restore R3

	LD R12
	JCN Z, REG16_CMP_EXIT0
	BBL 1
REG16_CMP_EXIT0:
	BBL 0

;;;----------------------------------------------------------------------------
;;; PRINTSTR_PM12REG16P0_DELIM_P1(Delimiter is P1 and 00H)
;;; PRINTSTR_PM12REG16P0 (Delimiter is 0x00)
;;; Print a string 
;;; put a string on PM12(REG16(P0)) to serial output until the P1 or 00H
;;; REG(INDEX) is incremented to
;;; 	the end of the string    (if the last char == 00H)
;;; 	the end of the string +1 (if the last char != 00H)
;;; 
;;; destroy: P6, P7
;;;----------------------------------------------------------------------------
PRINTSTR_PM12REG16P0:
	JMS PUSH_P2
	JMS PUSH_P1
	FIM P1, 00H
	JUN PRINTSTR_PM12REG16P0_XX
PRINTSTR_PM12REG16P0_DELIM_P1:
	JMS PUSH_P2
	JMS PUSH_P1
PRINTSTR_PM12REG16P0_XX:
	JMS PUSH_P0
	LD_P2_P1		; save the delimiter P1 to P2
PRINTSTR_LOOP:
	JMS LD_P1_PM12REG16P0
	JMS ISZEROORNOT_P1
	JCN Z, PRINTSTR_EXIT
	JMS CMPEQ_P1P2
	JCN Z, PRINTSTR_EXIT
	JMS PUTCHAR_P1
	
	JMS INC_REG16P0
	JUN PRINTSTR_LOOP
PRINTSTR_EXIT:
	FIM P2, 00H
	JMS CMPEQ_P1P2
	JCN Z, PRINTSTR_EXIT_NOINCREMENT
	JMS INC_REG16P0		; pointer++ if the last char is not 00H
PRINTSTR_EXIT_NOINCREMENT:
	JMS POP_P0
	JMS POP_P1
	JMS POP_P2
	BBL 0


;;;----------------------------------------------------------------------------
;;; PRINT_REG16P1
;;; PRINT REG16(P1) in decimal format
;;; destroy: P3, P4, P5, P6, P7
;;;----------------------------------------------------------------------------
PRINT_REG16P1:
	; PUSH P0, REG(P1), P1, P2, and REG(RMND)
	JMS PUSH_P0
	JMS PUSH_REG16P1
	JMS PUSH_P1
	JMS PUSH_P2
	LD_P0_P1		; P0 = P1, below here
	FIM P1, REG16_RMND	; save last RMND before this PRINT
	JMS PUSH_REG16P1

	FIM P7, REG4_ZEROSUP	; set zero supress flag
	LDM 1
	SRC P7
	WRM
	
	JMS GETSIGN_REG16P0_TOCARRY ; Print '-' if REG(P0) < 0
	JCN NC, PRINT_REG16P1_POSITIVE
	JMS COMPLEMENT_REG16P0
	JMS INC_REG16P0
	FIM P1, '-'
	JMS PUTCHAR_P1

PRINT_REG16P1_POSITIVE:	
	;; 10000'
	FIM P1, REG16_TMP_PRN	; REG16(TMP_PRN) = 10000
	FIM P2, up(10000)
	FIM P3, lo(10000)
	JMS LD_REG16P1_P2P3
	JMS DIV_REG16P0_REG16P1	; REG(P0)=REG(P0)/REG(TMP_PRN)
	JMS PRINT_REG4P0_ZEROSUP

	FIM P1, REG16_RMND
	JMS LD_REG16P0_REG16P1	; REG(P0) = REG(RMND)

	;; 1000'
	FIM P1, REG16_TMP_PRN	; REG16(TMP_PRN) = 1000
	FIM P2, up(1000)
	FIM P3, lo(1000)
	JMS LD_REG16P1_P2P3

	JMS DIV_REG16P0_REG16P1	; REG(P0)=REG(P0)/REG(TMP_PRN)
	JMS PRINT_REG4P0_ZEROSUP

	FIM P1, REG16_RMND
	JMS LD_REG16P0_REG16P1	; REG(P0) = REG(RMND)

	;; 100'
	FIM P1, REG16_TMP_PRN	; REG16(TMP_PRN) = 100
	FIM P2, up(100)
	FIM P3, lo(100)
	JMS LD_REG16P1_P2P3

	JMS DIV_REG16P0_REG16P1	; REG(P0)=REG(P0)/REG(TMP_PRN)
	JMS PRINT_REG4P0_ZEROSUP

	FIM P1, REG16_RMND
	JMS LD_REG16P0_REG16P1	; REG(P0) = REG(RMND)

	;; 10'
	FIM P1, REG16_TMP_PRN	; REG16(TMP_PRN) = 10
	FIM P2, up(10)
	FIM P3, lo(10)
	JMS LD_REG16P1_P2P3

	JMS DIV_REG16P0_REG16P1	; REG(P0)=REG(P0)/REG(TMP_PRN)
	JMS PRINT_REG4P0_ZEROSUP

	;; 1'
	FIM P0, REG16_RMND
	SRC P0
	RDM
	JMS PRINT_ACC
	
	; POP P0, REG(P1), P1, P2, and REG(RMND)
	FIM P1, REG16_RMND	; restore last RMND
	JMS POP_REG16P1
	JMS POP_P2
	JMS POP_P1
	JMS POP_REG16P1		; restore REG(P1)
	JMS POP_P0
	BBL 0
	
;;;----------------------------------------------------------------------------
;;; PRINTHEX_REG16P1
;;; PRINT REG16(P0)
;;; destroy: P6, P7
;;;----------------------------------------------------------------------------
PRINTHEX_REG16P1:
	JMS PUSH_P1
	JMS PUSH_P2
	LD_P2_P3
	JMS PUSH_P2
	
	JMS LD_P2P3_REG16P1
	LD R4
	JMS PRINT_ACC		; print bit.FEDC
	LD R5
	JMS PRINT_ACC		; print bit.BA98
	LD R6
	JMS PRINT_ACC		; print bit.7654
	LD R7
	JMS PRINT_ACC		; print bit.3210

	JMS POP_P2
	LD_P3_P2
	JMS POP_P2
	JMS POP_P1
	BBL 0
;;;----------------------------------------------------------------------------
;;; PRINTHEX_P1
;;; Print 8bit register pair in HEX format
;;; PRINT HEX
;;; destroy: P6, P7
;;;----------------------------------------------------------------------------
PRINTHEX_P1:
	JMS PUSH_P0
	JMS PUSH_P1
	LD_P0_P1
	LD R0
	JMS PRINT_ACC		; print upper 4bit
	LD R1
	JMS PRINT_ACC		; print lower 4bit
	JMS POP_P1
	JMS POP_P0
	BBL 0

;;;----------------------------------------------------------------------------
;;; PRINT_REG4P0_ZEROSUP:
;;; PRINT REG4(P0)
;;; if REG4(P0) !=0 then print it and clear REG(ZEROSUP) flag
;;; else if REG4(ZEROSUP) == false then print (P0)
;;; skip otherwise
;;; destroy: P6, P7
;;;----------------------------------------------------------------------------
PRINT_REG4P0_ZEROSUP:
	SRC P0
	RDM
	JCN ZN, PRINT_AND_CLEARFLAG 	; print if REG4(P0) != 0
	FIM P7, REG4_ZEROSUP
	SRC P7
	RDM
	JCN Z, PRINT_AND_CLEARFLAG 	; if flag == 0 then print
	BBL 1				; skip print and return (flag=still 1)
PRINT_AND_CLEARFLAG:
	JMS PRINT_ACC
	FIM P7, REG4_ZEROSUP
	CLB
	SRC P7
	WRM				; clear the flag
	BBL 0

;;;----------------------------------------------------------------------------
;;; Subroutines for program memory operation
;;;----------------------------------------------------------------------------
;;;---------------------------------------------------------------------------
;;; PM_WRITE_P0_P1
;;; Write to program memory located at Page 15 (0F00H-0FFFH)
;;; (0F00H+P0) = P1
;;; input: P0, P1
;;; output: none
;;;---------------------------------------------------------------------------
PM_WRITE_P0_P1:
	SRC P0
	LD R3
	WPM			; write lower 4bit
	LD R2
	WPM			; write higher 4bit
	BBL 0

;;;---------------------------------------------------------------------------
;;; PM_WRITE_P6_P7
;;; Write to program memory located at Page 15 (0F00H-0FFFH)
;;; (0F00H+P6) = P7
;;; input: P6, P7
;;; output: none
;;;---------------------------------------------------------------------------
PM_WRITE_P6_P7:
	SRC P6
	LD R15
	WPM			; write lower 4bit
	LD R14
	WPM			; write higher 4bit
	BBL 0

;;;---------------------------------------------------------------------------
;;; PM_INIT_BANK
;;; initialization for program memory (RAM)
;;; Write a subroutne code for reading memory
;;; destroy: P6, P7
;;;---------------------------------------------------------------------------
PM_INIT_BANK:	
	FIM P6, lo(PM_READ_P0_P1)
	FIM P7, 32H		; FIN P1
	JMS PM_WRITE_P6_P7
	INC R13
	FIM P7, 0C0H		; BBL 0
	JMS PM_WRITE_P6_P7
	BBL 0

;;;---------------------------------------------------------------------------
;;; PM_SELECTPMB
;;; Write ACC to RAM port (BANK_PMSELECT, CHIP_PMSELECT)
;;; The bank selection port should be BANK_DEFAULT to omit the DCL instruction
;;; destroy: P7
;;;---------------------------------------------------------------------------
PM_SELECTPMB:
        FIM P7, CHIP_PMSELECT
        SRC P7
        WMP
	BBL 0

;;;---------------------------------------------------------------------------
;;; COMMAND_PMB
;;; Set program memory bank
;;;---------------------------------------------------------------------------
COMMAND_PMB:
	FIM P0, lo(STR_BANK)	; print " BANK="
	JMS PRINTSTR_P0
	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3
	JMS PM_SELECTPMB
	JMS PM_INIT_BANK
	JMS PRINT_CRLF

	JUN CMD_LOOP		; return to command loop

;;;---------------------------------------------------------------------------
;;; PM12
;;; Logical program memory with 12 bit address space
;;; Phisical PM is 254byte(00H to 0FD)x16 bank memory
;;; PM12 is a logical memory space (000H to FFFH) mapped to Phisical PM
;;; FFEH-FFFH  in each bank is used for PM_READ_P0_P1(2 byte subroutine
;;; to read the PM of the bank)
;;; PM12 is a 000H-FDF flat space.
;;; 
;;;    PM12(BA98.7654.3210)
;;;   -> PM(3210.7654.BA98) BANK=3210, ADD=7654BA98
;;; 
;;;    PM16(FEDC.BA98.7654.3210) (not yet implemented)
;;;   -> PM(7654.3210.FEDC.BA98) BANK=BA98.7654 ADD=3210FEDC
;;;---------------------------------------------------------------------------
;;;---------------------------------------------------------------------------
;;; LD_P1_PM12REG16P0
;;; P1 = PM12(REG(P0))
;;; destroy: P6, P7
;;;---------------------------------------------------------------------------
LD_P1_PM12REG16P0:
	LD_P6_P0		; P6 = P0
	SRC P6
	RDM			; ACC=REG(P0).bit3210

        FIM P7, CHIP_PMSELECT
        SRC P7
        WMP			; set bank to REG(P0).bit3210

	INC R13
	SRC P6
	RDM
	XCH R1			; R1=REG(P0).bit7654
	
	INC R13	
	SRC P6
	RDM
	XCH R0			; R0 = REG(P0).bitBA98

	JMS PM_READ_P0_P1	; P1 = PM(REG(P0))

	LD R12                  ; restore P0
        XCH R0
        LD R13
	;; 	CLC             ; can be omitted?
        DAC
        DAC
        XCH R1
        BBL 0

;;;---------------------------------------------------------------------------
;;; LD_PM12REG16P0_P1
;;; PM12(REG(P0)) = P1
;;; destroy: P7
;;;---------------------------------------------------------------------------
LD_PM12REG16P0_P1:
	SRC P0
	RDM			; bit3210 of REG(P0)
        FIM P7, CHIP_PMSELECT
        SRC P7
        WMP			; set bank to REG(P0).bit3210


	INC R1
	SRC P0
	RDM			; bit7654 of REG(P0)
	XCH R13			; R13 = REG(P0).bit7654

	INC R1
	SRC P0
	RDM
	XCH R12			; R12 = REG(P0).bitBA98
	
	SRC P6
	LD R3
	WPM
	LD R2
	WPM
	
	LD R1			; restore P0
	;; 	CLC             ; can be omitted?
	DAC
	DAC
	XCH R1
	BBL 0

;;;----------------------------------------------------------------------------
;;; PUSH_P0, P1, P2, P3
;;; POP_P0, P1, P2, P3
;;; Push and Pop an 8bit register pair
;;; Stack area is a 16x4bit ring buffer using one register in data RAM.
;;; Stack pointer is status character 0 of the register.
;;; destroy P7, P6
;;;----------------------------------------------------------------------------

;;;----------------------------------------------------------------------------
PUSHP	macro ThisR0, ThisR1
	LDM 2
	XCH R12
	FIM P7, REG16_STACKPOINTER
	SRC P7
	RD1
	CLC
	SUB R12
	WR1			; sp.3210=sp.3210-2
	XCH R15			; R15=new sp.3210(CHAR#)
	RD0
	JCN C, PUSH_NOBORROW_ThisR0_ThisR1	; check borrow of the last SUB R12
	DAC			; decriment upper 4bit
PUSH_NOBORROW_ThisR0_ThisR1:
	WR0			; sp.7654--
	XCH R14			; R14=new sp.7654(REG#)

	SRC P7			;
	LD ThisR1		; lower 4bit
	WRM			; (sp)=ThisR1
	INC R15			; carry check is omitted
				; because the SP shoudld be even address
	SRC P7			;
	LD ThisR0		; upper 4bit
	WRM			; (sp+1)=ThisR0
	BBL 0
	endm
;;;----------------------------------------------------------------------------
POPP	macro ThisR0, ThisR1
	FIM P7, REG16_STACKPOINTER
	SRC P7
	RD0			;
	XCH R14			; R14=sp.7654 (REG#)
	RD1			;
	XCH R15			; R15=sp.3210 (CHAR#)
	SRC P7			;
	RDM
	XCH ThisR1		; ThisR1=(sp)
	INC R15			; R15++
				; Carry check is omitted here because SP was even
	SRC P7			;
	RDM
	XCH ThisR0		; ThisR0=(sp+1)

	FIM P6, REG16_STACKPOINTER
	SRC P6			;
	INC R15			; R15++
	LD R15
	WR1			; sp.lower=sp.lower+2
	JCN ZN, POP_NOCARRY_ThisR0_ThisR1
	INC R14
	LD R14
	WR0			; sp.upper=sp.upper+1
POP_NOCARRY_ThisR0_ThisR1:
	BBL 0
	endm
;;;----------------------------------------------------------------------------
;;; INIT_STACKPOINTER
;;; Initialize Stack Pointer
;;;----------------------------------------------------------------------------
INIT_STACKPOINTER:
	FIM P0, REG16_STACKPOINTER
	FIM P1, INITVAL_STACKPOINTER
	SRC P0
	LD R2
	WR0
	LD R3
	WR1
	BBL 0

;;;----------------------------------------------------------------------------
;;; Generate real codes from macros
;;;----------------------------------------------------------------------------
PUSH_P0: PUSHP  R0, R1
PUSH_P1: PUSHP  R2, R3
PUSH_P2: PUSHP  R4, R5
POP_P0: POPP R0, R1
POP_P1: POPP R2, R3
POP_P2: POPP R4, R5

;;;----------------------------------------------------------------------------
;;; PUSH_REG16P1
;;; POP_REG16P1
;;; Push and Pop an REG16 register REG16(P1)
;;; Stack area is registers in data RAM.
;;; Stack pointer is status character 0 (REG#) and 1 (CHAR#) of
;;; the REG16_STACKPOINTER
;;; destroy: P7, P6
;;;----------------------------------------------------------------------------
PUSH_REG16P1:
	LD R3
	XCH R13			; save R3

	LDM 4
	XCH R12
	FIM P7, REG16_STACKPOINTER
	SRC P7
	RD1
	CLC
	SUB R12
	WR1			; sp.3210=sp.3210-4
	XCH R15			; R15=new sp.3210(CHAR#)
	RD0			; 
	JCN C, PUSH_REG16P1_NOBORROW ; check borrow of the last SUB R12
	DAC			; decriment upper 4bit
PUSH_REG16P1_NOBORROW:
	WR0			; sp.7654--
	XCH R14			; R14=new sp.7654(REG#)
	
	LDM loop(4)
	XCH R12
PUSH_REG16P1_LOOP:
	SRC P1
	RDM
	SRC P7
	WRM			; (R15)=REG(P1)
	INC R15
	LD R15
	JCN ZN, PUSH_REG16P1_NOINCUPPER
	INC R14			; increment REG#
PUSH_REG16P1_NOINCUPPER:
	INC R3
	ISZ R12, PUSH_REG16P1_LOOP

	LD R13
	XCH R3			; restore R3
	BBL 0
;;;----------------------------------------------------------------------------
POP_REG16P1:
	LD R3
	XCH R13			; save R3

	FIM P7, REG16_STACKPOINTER
	SRC P7
	RD0			;
	XCH R14			; R14=sp.7654 (REG#)
	RD1			;
	XCH R15			; R15=sp.3210 (CHAR#)
	LDM loop(4)
	XCH R12
POP_REG16P1_LOOP:
	SRC P7
	RDM
	SRC P1
	WRM			; REG(P1)=(R15)
	INC R15
	LD R15
	JCN ZN, POP_REG16P1_NOCARRY
	INC R14			; increment REG#
POP_REG16P1_NOCARRY:
	INC R3
	ISZ R12, POP_REG16P1_LOOP

	LD R13
	XCH R3			; restore R3

	FIM P6, REG16_STACKPOINTER
	SRC P6 			; write new sp (old sp+4)
	LD R14
	WR0
	LD R15
	WR1

	BBL 0

;;;----------------------------------------------------------------------------
;;; GETLINE_PM12REG16P0
;;; Get line from serial input and store to PM12(REG(P0))
;;; The value of REG(P0) does not change
;;;----------------------------------------------------------------------------
GETLINE_PM12REG16P0:
	JMS PUSH_P0
	JMS PUSH_P1

	FIM P1, REG16_TMP
	JMS LD_REG16P1_REG16P0	; REG(TMP)=REG(INDEX)

GETLINE_LOOP:
	JMS GETCHAR_P1		; P1 = getchar()

	JMS ISCRLF_P1
	JCN Z, GETLINE_L1
	JMS PRINT_CR
	JMS PRINT_LF
	JUN GETLINE_EXIT
GETLINE_L1:
	FIM P7, 08H		; backspace
	JMS CMP_P1P7
	JCN ZN, GETLINE_INSERTCHAR

	FIM P1, REG16_TMP
	JMS CMP_REG16P0_REG16P1
	JCN ZN, GETLINE_BS	; do BS if REG(P0)!=REG(TMP)
	JUN GETLINE_LOOP	; ignore BS
GETLINE_BS:		; delete a character on the cursor
	JMS DEC_REG16P0		; REG(P0)--
GETLINE_L1_NEXT:		; delete a character on the cursor
	FIM P1, 08H
	JMS PUTCHAR_P1		; put backspace
	JMS PRINT_SPC		; put ' '
	JMS PUTCHAR_P1		; put backspace

	JUN GETLINE_LOOP
GETLINE_INSERTCHAR:
	JMS PUTCHAR_P1
	JMS LD_PM12REG16P0_P1
	JMS INC_REG16P0		; *REG(P0)++ = P1

	JUN GETLINE_LOOP
GETLINE_EXIT:
	FIM P1, 00H
	JMS LD_PM12REG16P0_P1 	; write NULL on the end of line buffer
	JMS INC_REG16P0
	JMS LD_PM12REG16P0_P1 	; write extra NULL to prevent buffer overrun

	FIM P1, REG16_TMP
	JMS LD_REG16P0_REG16P1	; restore REG(INDEX)
	JMS POP_P1		; restore P1
	JMS POP_P0		; restore P0
	BBL 0

;;;----------------------------------------------------------------------------
;;; GETNUMBER_PM12REG16P0_REG16P1
;;; Read a decimal or hexadecimal number in the string and store to register
;;; Read string from PM12(REG16(P0)) and set a number to REG16(P1)
;;; REG16(P0) is incremented to the character which is not a number.
;;; Hexadecimal number begins with 0 (ex. 0A123).
;;; destroy: P7, P6, P2, P3
;;; TMP: result
;;; TMP2: input char buffer
;;; TMP3: working for multiply by 10
;;;----------------------------------------------------------------------------
GETNUMBER_PM12REG16P0_REG16P1:
	JMS PUSH_P0
	JMS PUSH_P1
	LD_P2_P0		; P0 is saved to P2

	LD_P0_P1
	JMS CLEAR_REG16P0	; REG(P1) = 0

	FIM P0, REG16_TMP
	JMS CLEAR_REG16P0	; REG(TMP) = 0 register for the result

	LD_P0_P2		; restore P0
	JMS LD_P1_PM12REG16P0	; P1 = PM12(REG16(P0))
	FIM P7, '0'
	JMS CMP_P1P7
	JCN ZN, GETNUMBER_LOOP
	JUN GETHEXNUMBER	; start with '0' then get hex number
GETNUMBER_LOOP:
	JMS CTOI_P1

	FIM P0, REG16_TMP2
	JMS LD_REG16P0_8BIT_P1       ; REG(TEMP2) = P1

	FIM P0, REG16_TMP
	FIM P1, REG16_TMP
	JMS ISZEROORNOT_REG16P1
	JCN Z, GETNUMBER_SKIP_MUL10
	;; REG(TMP) *= 10
	FIM P1, REG16_TMP3
	JMS LD_REG16P1_REG16P0	; REG(TMP3) = REG(TMP)
	JMS MUL2_REG16P0	; REG(TMP) *= 2
	JMS MUL2_REG16P0	; REG(TMP) *= 2
	JMS ADD_REG16P0_REG16P1	; REG(TMP) += REG(TMP3)
	JMS MUL2_REG16P0	; REG(TMP) *= 2
GETNUMBER_SKIP_MUL10:	
	FIM P1, REG16_TMP2
	JMS ADD_REG16P0_REG16P1	; REG(TMP) = REG(TMP)*10 + REG(TMP2)

	LD_P0_P2		; restore P0
	JMS INC_REG16P0		; REG(P0)++
	JMS LD_P1_PM12REG16P0	; P1 = PM12(REG16(P0))
	JMS ISNUM_P1
	JCN Z, GETNUMBER_EXIT
	JUN GETNUMBER_LOOP
GETNUMBER_EXIT:
	JMS POP_P1
	FIM P0, REG16_TMP
	JMS LD_REG16P1_REG16P0	; REG(P1) = REG(TMP)
	JMS POP_P0
 	BBL 0
GETHEX_EXIT:
	FIM P0, REG16_TMP
	JMS LD_REG16P0_P2P3
	JUN GETNUMBER_EXIT
GETHEXNUMBER:
	FIM P2, 00H
	FIM P3, 00H
GETHEX_LOOP:
	JMS INC_REG16P0		; REG(P0)++
	JMS LD_P1_PM12REG16P0	; P1 = PM12(REG16(P0))
	JMS ISHEX_P1
	JCN Z, GETHEX_EXIT	; not a hex number then exit
	JMS CTOI_P1
	JMS MUL16_P2P3		; R4R5R6R7 *= 16
	LD R3
	XCH R7			; R7=R3
	JUN GETHEX_LOOP
	
;;; 	JUN RETURN_P2 ; for another implementation

;;;----------------------------------------------------------------------------
;;; Routines for monitor program command to read/write logical memory
;;;----------------------------------------------------------------------------
COMMAND_LMR:
	FIM P0, lo(STR_ADR)
	JMS PRINTSTR_P0

	;; input 2 hexdigits to REG16(TMP)
	CLB
	XCH R4
	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3
	XCH R5
	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3
	XCH R6
	CLB
	XCH R7
	FIM P1, REG16_TMP
	JMS LD_REG16P1_P2P3

	;; input 1 hexdigits to R11
	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3
	CMA			;R11=15-R3 for ISZ loop(R3+1)
	XCH R11
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
	NOP
COMMAND_LMR_VLOOP:
	JMS PRINT_CRLF
	FIM P1, REG16_TMP
	JMS PRINTHEX_REG16P1
	FIM P1, ':'
	JMS PUTCHAR_P1

	LDM 0
	XCH R10
COMMAND_LMR_HLOOP:
	FIM P0, REG16_TMP
	JMS LD_P1_PM12REG16P0
	JMS PRINTHEX_P1
	JMS INC_REG16P0
	ISZ R10, COMMAND_LMR_HLOOP
	ISZ R11, COMMAND_LMR_VLOOP

	JMS PRINT_CRLF
	JUN CMD_LOOP
	
COMMAND_LMW:
	FIM P0, lo(STR_ADR)
	JMS PRINTSTR_P0

	;; input 3 hexdigits to REG16(TMP)
	CLB
	XCH R4
	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3
	XCH R5
	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3
	XCH R6
	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3
	XCH R7
	FIM P1, REG16_TMP
	JMS LD_REG16P1_P2P3

COMMAND_LMW_LOOP:
	JMS PRINT_CRLF
	FIM P1, REG16_TMP
	JMS PRINTHEX_REG16P1
	FIM P1, ':'
	JMS PUTCHAR_P1

	JMS GETCHAR_P1
	JMS ISCRLF_P1
	JCN ZN, COMMAND_LMW_EXIT
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3
	XCH R4
	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R4
	XCH R2
	FIM P0, REG16_TMP
	JMS LD_PM12REG16P0_P1
	JMS INC_REG16P0

	JUN COMMAND_LMW_LOOP
COMMAND_LMW_EXIT:
	JMS PRINT_CRLF
	JUN CMD_LOOP

	org 0BD0H
;;;----------------------------------------------------------------------------
;;; RETURN_P2
;;; Return to the address refering jump table
;;;----------------------------------------------------------------------------
RETURN_P2:
	LD R5
	JCN ZN, RETURN_P2_OK
	LD R4
	JCN ZN, RETURN_P2_OK
	FIM P0, REG8_ERROR
	FIM P1, ERROR_RETURN_P2_IS_00
	JUN VTL_START		; exit (for debug)
RETURN_P2_OK:
	JIN P2			; Jump to Return Table

RETURN_EXEC_R1:
	JUN EXEC_R1
RETURN_EVAL_R1:	
	JUN EVAL_R1
RETURN_EVAL_R2:	
	JUN EVAL_R2
RETURN_GETFACTOR_R1:
	JUN GETFACTOR_R1
RETURN_GETFACTOR_R2:
	JUN GETFACTOR_R2
RETURN_PRINT_R1:
	JUN PRINT_R1
RETURN_GETFACTOR_L9_R1:	
	JUN GETFACTOR_L9_R1
	
;;;---------------------------------------------------------------------------
;;; Monitor commands located in page 0C00H
;;;---------------------------------------------------------------------------
	org 0C00H
	
;;;---------------------------------------------------------------------------
;;; COMMAND_G
;;; Go to Top of Program memory PM_RAM_START(0x0F00)
;;;---------------------------------------------------------------------------
COMMAND_G:
	JMS PRINT_CRLF
	JMS PM_RAM_START
	JUN CMD_LOOP		; return to command loop

;;;---------------------------------------------------------------------------
;;; COMMAND_R
;;; Read Data RAM
;;; input:
;;; 	R10: #bank
;;; 	R11: #chip (D3.D2.0.0)
;;; working memory:
;;;     P0(R0R1): working for PRINTSTR_P0
;;;     P1(R2R3): working for PUTCHAR_P1, PRINT_ACC
;;;     R4: loop counter for #REG (0.0.D1.D0)
;;;     R5: working for input
;;;     R6: working for SCR (R6=R11+R4)
;;;     R7: working for SCR #CHARACTER (D3.D2.D1.D0)@X3 (loop counter)
;;;         SCR R6R7
;;; 	R11: #CHIP (D3.D2.0.0)@X2
;;;     P6(R12R13): working for uart
;;;     P7(R14R15): working for uart
;;;---------------------------------------------------------------------------
COMMAND_R:
	;; PRINT 4 registers
	LDM loop(4)		; 4 regs
	XCH R4			; R4=loop(4)

	;; PRINT 16 characters
CMDR_L1:
	LDM loop(16)		; 16 characters
	XCH R7			; R7=D3D2D1D0@X3 (#character)
CMDR_L2:
	CLB
	LDM 4
	ADD R4		;ACC<-#reg (D1D0@X2)(00, 01, 10, 11 for each loop)
	CLC
	ADD R11
	XCH R6		;R6=D3D2D1D0@X2 (#chip.#reg)
	
	SRC R6R7	; set address
	RDM		; read data memory
	JMS PRINT_ACC
	ISZ R7,CMDR_L2

	;; PRINT STATUS 
	FIM P1, ':'
	JMS PUTCHAR_P1
	SRC R6R7	; set address
	RD0
	JMS PRINT_ACC
	SRC R6R7	; set address
	RD1
	JMS PRINT_ACC
	SRC R6R7	; set address
	RD2
	JMS PRINT_ACC
	SRC R6R7	; set address
	RD3
	JMS PRINT_ACC
	JMS PRINT_CRLF

	ISZ R4,CMDR_L1
	JUN CMD_LOOP		; return to command loop
	
;;;---------------------------------------------------------------------------
;;; COMMAND_W:
;;; Write Data RAM
;;; input:
;;; 	R10: #bank
;;; 	R11: #chip (D3.D2.0.0)
;;;---------------------------------------------------------------------------
COMMAND_W:
	;; PRINT 4 registers
	LDM loop(4)		; 4 regs
	XCH R4			; R4=loop(4)

	;; PRINT 16 characters
CMDW_L1:
	LDM loop(16)		; 16 characters
	XCH R7			; R7=D3D2D1D0@X3 (#character)
CMDW_L2:
	CLB
	LDM 4
	ADD R4		;ACC<-#reg (D1D0@X2)(00, 01, 10, 11 for each loop)
	CLC
	ADD R11
	XCH R6		;R6=D3D2D1D0@X2 (#chip.#reg)

	JMS GETCHAR_P1
	JMS CTOI_P1

	SRC R6R7	; set address
	LD R3
	WRM			; write to memory
	JMS PRINT_ACC
	ISZ R7,CMDW_L2

	;; PRINT STATUS 
	FIM P1, ':'
	JMS PUTCHAR_P1

	JMS GETCHAR_P1
	JMS CTOI_P1

	SRC R6R7	; set address
	LD R3
	WR0
	JMS PRINT_ACC

	JMS GETCHAR_P1
	JMS CTOI_P1

	SRC R6R7	; set address
	LD R3
	WR1
	JMS PRINT_ACC

	JMS GETCHAR_P1
	JMS CTOI_P1

	SRC R6R7	; set address
	LD R3
	WR2
	JMS PRINT_ACC

	JMS GETCHAR_P1
	JMS CTOI_P1

	SRC R6R7	; set address
	LD R3
	WR3
	JMS PRINT_ACC
	JMS PRINT_CRLF

	ISZ R4,CMDW_L1
	
	JUN CMD_LOOP		; return to command loop

;;;---------------------------------------------------------------------------
;;; COMMAND_PMW
;;; Write Program Memory
;;;---------------------------------------------------------------------------
COMMAND_PMW:
	FIM P0, lo(STR_ADR)	; print " ADR="
	JMS PRINTSTR_P0
	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3
	XCH R5
	JMS PRINT_CRLF

	FIM P1,'F'
	JMS PUTCHAR_P1
	LD R5
	JMS PRINT_ACC
	FIM P1,'0'
	JMS PUTCHAR_P1
	FIM P1,':'
	JMS PUTCHAR_P1
	
	LD R5
	XCH R0

	LDM 0
	XCH R1
CMDPMW_L1:
	JMS PRINT_SPC

	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1
	LD R3
	XCH R4

	JMS GETCHAR_P1
	JMS PUTCHAR_P1
	JMS CTOI_P1

	LD R4
	XCH R2

	JMS PM_WRITE_P0_P1
	ISZ R1, CMDPMW_L1

	JMS PRINT_CRLF

	JUN CMD_LOOP		; return to command loop

;;;---------------------------------------------------------------------------
;;; COMMAND_PMR
;;; Dump Program Memory
;;;---------------------------------------------------------------------------
COMMAND_PMR:
	JMS PRINT_CRLF

	JMS PM_INIT_BANK

	FIM P0, 00H
CMDPMR_L0:
	FIM P1,'F'
	JMS PUTCHAR_P1
	LD R0
	JMS PRINT_ACC
	FIM P1,'0'
	JMS PUTCHAR_P1
	FIM P1,':'
	JMS PUTCHAR_P1
CMDPMR_L1:	
	;; 	FIM P1, ' '
	;; 	JMS PUTCHAR_P1

	JMS PM_READ_P0_P1	; Read program memory
	LD R3
	XCH R5
	LD R2
	JMS PRINT_ACC
	LD R5
	JMS PRINT_ACC

	ISZ R1, CMDPMR_L1
	JMS PRINT_CRLF
        ISZ R0, CMDPMR_L0
	
	JUN CMD_LOOP		; return to command loop

;;;---------------------------------------------------------------------------
;;; COMMAND_PMC
;;; Clear Program Memory
;;;---------------------------------------------------------------------------
COMMAND_PMC:
	JMS PRINT_CRLF

	FIM P2, loop(16)	; R5 = 0..15
CMDPMC_BANKLOOP:
	LD R5
	JMS PM_SELECTPMB
	FIM P0, 00H		; loop counter
	FIM P1, 00H		; data to fill
CMDPMC_L1:
	JMS PM_WRITE_P0_P1
	ISZ R1, CMDPMC_L1
	ISZ R0, CMDPMC_L1

	JMS PM_INIT_BANK 	; write PM_READ code on program memory
	ISZ R5, CMDPMC_BANKLOOP

	CLB
	JMS PM_SELECTPMB	; set PMB to 0
	
	JUN CMD_LOOP		; return to command loop


;;;---------------------------------------------------------------------------
;;; ISCRLF_P1
;;; check if P1=='\r' | P1=='\n'
;;; input: P0
;;; output: ACC=1 if P1=='\r' || P1=='\n'
;;;         ACC=0 P1!='\r' && P1!='\n'
;;;---------------------------------------------------------------------------
ISCRLF_P1:
	LD R2
	JCN NZ, ISCRLF_EXIT0	; check upper 4bit
	CLC
	LDM '\r'
	SUB R3
	JCN Z, ISCRLF_EXIT1	; check lower 4bit
	CLC
	LDM '\n'
	SUB R3
	JCN Z, ISCRLF_EXIT1	; check lower 4bit
ISCRLF_EXIT0:
	BBL 0
ISCRLF_EXIT1:
	BBL 1
;;;----------------------------------------------------------------------------
;;; I/O and some basic routines located in Page 0D00H
;;;----------------------------------------------------------------------------
	org 0D00H
;;;---------------------------------------------------------------------------
;;; Software UART Routine
;;; GETCHAR_P1 and PUTCHAR_P1
;;; defined in separated file
;;;---------------------------------------------------------------------------
;;; supported baudrates are 4800bps or 9600bps
;; BAUDRATE equ 4800	; 4800 bps, 8 data bits, no parity, 1 stop bit
BAUDRATE equ 9600   ; 9600 bps, 8 data bits, no parity, 1 stop bit

	switch BAUDRATE
	case 4800
	include "4800bps.inc"
	case 9600
	include "9600bps.inc"
	endcase

;;;---------------------------------------------------------------------------
;;; PRINT_ACC
;;; print contents of ACC('0'...'F') as a character
;;; destroy: P1, P6, P7, ACC
;;;---------------------------------------------------------------------------
PRINT_ACC:
	FIM R2R3, 30H		;'0'
	CLC			; clear carry
	DAA			; ACC=ACC+6 if ACC>9 and set carry
	JCN CN, PRINTACC_L1
	INC R2
	IAC
PRINTACC_L1:	
	XCH R3			; R3<-ACC
	JUN PUTCHAR_P1		; not JMS but JUN (Jump to PUTCHAR and return)

;;;---------------------------------------------------------------------------
;;; PRINT_SPC
;;; print " "
;;; destroy: ACC
;;; this routine consumes 2 PC stack
;;;---------------------------------------------------------------------------
PRINT_SPC:
	JMS PUSH_P1
	FIM P1, ' '
	JMS PUTCHAR_P1
	JMS POP_P1
	BBL 0

;;;---------------------------------------------------------------------------
;;; PRINT_CRLF
;;; print "\r\n"
;;; destroy: ACC
;;; this routine consumes 2 PC stack
;;;---------------------------------------------------------------------------
PRINT_CRLF:
	JMS PUSH_P1
	FIM P1, '\r'
	JMS PUTCHAR_P1
	FIM P1, '\n'
	JMS PUTCHAR_P1
	JMS POP_P1
	BBL 0

;;;---------------------------------------------------------------------------
;;; PRINT_CR
;;; print "\r"
;;; destroy: P1, ACC
;;; this routine consumes 1 PC stack
;;;---------------------------------------------------------------------------
PRINT_CR:
	FIM P1, '\r'
	JUN PUTCHAR_P1

;;;---------------------------------------------------------------------------
;;; PRINT_LF
;;; print "\n"
;;; destroy: P1, ACC
;;; this routine consumes 1 PC stack
;;;---------------------------------------------------------------------------
PRINT_LF:
	FIM P1, '\n'
	JUN PUTCHAR_P1

;;;----------------------------------------------------------------------------
;;; DISPLED_P1
;;;   DISPLAY the contents of P1 on Port 1 and 2
;;; Input: P1(R2R3)
;;; Output:  ACC=0
;;; Working: P7
;;; Destroy: P7
;;;----------------------------------------------------------------------------
DISPLED_P1:
	LDM BANK_RAM1
        DCL
        FIM P7, CHIP_RAM1
        SRC P7
        LD R2
        WMP
	
        LDM BANK_RAM2
        DCL
        FIM P7, CHIP_RAM2
        SRC P7
        LD R3
        WMP

        LDM BANK_DEFAULT	; restore BANK to default
	DCL
	
        BBL 0

;;;---------------------------------------------------------------------------
;;; INIT_SERIAL
;;; Initialize serial port
;;;---------------------------------------------------------------------------
INIT_SERIAL:
	LDM BANK_SERIAL     ; bank of output port
        DCL                 ; set port bank
	
        FIM P7, CHIP_SERIAL ; chip# of output port
	SRC P7              ; set port address
	LDM 1
        WMP                 ; set serial port to 1 (TTL->H)

	LDM BANK_DEFAULT    
        DCL                 ; restore bank to default

        BBL 0

;;;---------------------------------------------------------------------------
;;; ISNUM_P1
;;; check P1 '0' to '9' as a ascii character
;;; return: ACC=0 if P1 is not a number
;;;         ACC=1 if P1 is a number
;;; destroy: P7
;;;---------------------------------------------------------------------------
ISNUM_P1:
	FIM P7, '0'
	JMS CMP_P1P7
	JCN CN, ISNUM_FALSE	; P1 < '0'
	FIM P7, '9'+1
	JMS CMP_P1P7
	JCN C,  ISNUM_FALSE	; P1 >= '9'+1
	BBL 1			; P1 is a number
ISNUM_FALSE:
	BBL 0			; P1 is not a number

;;;----------------------------------------------------------------------------
;;; ISALPHA_P1
;;; check P1 is an alphabet as a ascii character
;;; return: ACC=0 if P1 is not an alphabet
;;;         ACC=1 if P1 is an alphabet
;;; destroy: P7
;;;----------------------------------------------------------------------------
ISALPHA_P1:
ISALPHA_L1:
	FIM P7, 'A'
	JMS CMP_P1P7
	JCN C, ISALPHA_L10
	BBL 0			; P1<'A'
ISALPHA_L10:
	FIM P7, 'Z'+1
	JMS CMP_P1P7
	JCN C,  ISALPHA_L2	; P1>='Z'+1 then jump to next chance
	BBL 1			; 'A'<=P1<='Z'
ISALPHA_L2:
	FIM P7, 'a'
	JMS CMP_P1P7
	JCN C, ISALPHA_L20
	BBL 0			; P1<'a'
ISALPHA_L20:	
	FIM P7, 'z'+1
	JMS CMP_P1P7
	JCN C, ISALPHA_FALSE	; P1>='z'+1
	BBL 1			; 'a'<=P1<= 'z'
ISALPHA_FALSE:
	BBL 0

;;;---------------------------------------------------------------------------
;;; CTOI_P1
;;; convert character ('0'...'f') to value 0000 ... 1111
;;; input: P1(R2R3)
;;; output: R3, (R2=0)
;;;---------------------------------------------------------------------------
CTOI_P1:
	CLB
	LDM 3
	SUB R2
	JCN Z, CTOI_09		; check upper 4bit
	CLB
	LDM 9
	ADD R3
	XCH R3			; R3 = R3 + 9 for 'a-fA-F'
CTOI_09:
	CLB
	XCH R2			; R2 = 0
	BBL 0
	
;;;---------------------------------------------------------------------------
;;; CMP_P0P1
;;; compare P0(R0R1) and P1(R2R3)
;;; input: P0, P1
;;; output: ACC=1,CY=0 if P0<P1
;;;         ACC=0,CY=1 if P0==P1 
;;;         ACC=1,CY=1 if P0>P1
;;; P0 - P1 (the carry bit is a complement of the borrow)
;;;---------------------------------------------------------------------------
CMP_P0P1:
	CLB
	LD R0			
	SUB R2			;R0-R2
	JCN Z, CMP01L1
	BBL 1			;P0>P1,  ACC=1, CY=1
				;P0<P1,  ACC=1, CY=0
CMP01L1:	
	CLB
	LD R1
	SUB R3			;R1-R3
	JCN Z, CMP01EXIT01
	BBL 1			;P0<P1,  ACC=1, CY=0
				;P0<P1,  ACC=1, CY=0
CMP01EXIT01:
	BBL 0			;P0==P1, ACC=0, CY=1

;;;---------------------------------------------------------------------------
;;; CMP_P1P7
;;; compare P1(R2R3) and P7(R14R15)
;;; input: P1, P7
;;; output: ACC=1,CY=0 if P1<P7
;;;         ACC=0,CY=1 if P1==P7
;;;         ACC=1,CY=1 if P1>P7
;;; P1 - P7 (the carry bit is a complement of the borrow)
;;;---------------------------------------------------------------------------
CMP_P1P7:
	CLB
	LD R2			
	SUB R14			;R2-R14
	JCN Z, CMP17_L1		; jump if R2==R14
	BBL 1			; if P1<P7 then ACC=1, CY=0
CMP17_L1:	
	CLB
	LD R3
	SUB R15			;R3-R15
	JCN Z, CMP17_EXIT01	; jump if R3==R15
	BBL 1			; if P1<P7 then ACC=1, CY=0
				; if P1>P7 then ACC=1, CY=1
CMP17_EXIT01:
	BBL 0			; P1==P7, ACC=0, CY=1
	
;;;---------------------------------------------------------------------------
;;; CMPEQ_P1P2
;;; compare P1 and P2 equal or not
;;; return: Take care the return value. It is comptatible with CMP
;;; 	ACC=0 if P1==P2
;;;     ACC=1 if P1!=P2
;;;---------------------------------------------------------------------------
CMPEQ_P1P2:
	LD R2
	CLC
	SUB R4
	JCN NZ, CMPEQ12_EXIT1
	LD R3
	CLC
	SUB R5
	JCN NZ, CMPEQ12_EXIT1
	BBL 0
CMPEQ12_EXIT1:
	BBL 1

;;;---------------------------------------------------------------------------
;;; CMPEQ_P2P7
;;; compare P2 and P7 equal or not
;;; return: Take care the return value. It is comptatible with CMP
;;; 	ACC=0 if P2==P7
;;;     ACC=1 if P2 != P7
;;;---------------------------------------------------------------------------
CMPEQ_P2P7:
	LD R4
	CLC
	SUB R14
	JCN NZ, CMPEQ27_EXIT1
	LD R5
	CLC
	SUB R15
	JCN NZ, CMPEQ27_EXIT1
	BBL 0
CMPEQ27_EXIT1:
	BBL 1
	
;;;---------------------------------------------------------------------------
;;; ISZEROORNOT_P1
;;; check P1 is zero or not
;;; Return 0 if P1 is 0
;;; return: ACC=0 if P1 == 0
;;; 	    ACC=1 if P1 != 0
;;;---------------------------------------------------------------------------
ISZEROORNOT_P1:
	LD R3
	JCN ZN, ISZEROORNOT_EXIT1
	LD R2
	JCN ZN, ISZEROORNOT_EXIT1
	BBL 0
ISZEROORNOT_EXIT1:
	BBL 1
;;;----------------------------------------------------------------------------
;;; Print subroutine and string data located in Page E (0E00H-0EFFH)
;;; The string data sould be located in the same page as the print routine.
;;;----------------------------------------------------------------------------
        org 0E00H
;;;----------------------------------------------------------------------------
;;; PRINTSTR_P0
;;; Input: P0 (top of the string is 0E00H+P0)
;;; Destroy: P6, P7 (by PUTCHAR)
;;;----------------------------------------------------------------------------
PRINTSTR_P0:
	JMS PUSH_P0
	JMS PUSH_P1
PRINTSTRP0_LOOP:
        FIN P1			; P1=(P0)
        LD R2
        JCN ZN, PRINTSTRP0_PUT	; R2!=0 then putchar
	LD R3
        JCN Z, PRINTSTRP0_EXIT     	; R2==0 and R3==0 then exit
PRINTSTRP0_PUT:
        JMS PUTCHAR_P1          ; putchar(P1)
        ISZ R1, PRINTSTRP0_LOOP   ; P0=P0+1
        INC R0
        JUN PRINTSTRP0_LOOP	; print remaining string
PRINTSTRP0_EXIT:
	JMS POP_P1
	JMS POP_P0
        BBL 0                   ; exit if P1(R2,R3) == 0
                
;;;----------------------------------------------------------------------------
;;; String data
;;;----------------------------------------------------------------------------

STR_OMSG:
	data "\rIntel MCS-4 (4004)\r\nTiny Monitor\r\n", 0
STR_VFD_INIT:		;reset VFD and set scroll mode
	data 1bH, 40H, 1fH, 02H, 0
STR_BANK:
	data " BANK=", 0
STR_CHIP:
	data " CHIP=", 0
STR_ADR:
	data " ADR=", 0
STR_VTL_MESSAGE:
	data "\r\nVTL-4004 Interpreter Ver 1.0\r\n", 0
STR_VTL_OK:
	data "\r\nOK\r\n", 0
STR_VTL_ERROR:
	data "ERROR=", 0
STR_VTL_BUF:
	data "BUF=", 0
STR_VTL_SP:
	data "SP=", 0
STR_VTL_ERRORLINENUM:
	data "IN #", 0
STR_CMDERR:
	data "\r\nv=VTL, r/w=RD/WR RAM, R/W/C/B=RD/WR/CLR/BNK PM, l/L=rd/wr LM, g=go PM(F00)\r\n", 0 ;

;;;---------------------------------------------------------------------------
;;; Subroutine for reading program memory located on page 15 (0F00H-0FFFH)
;;;---------------------------------------------------------------------------
;;; READPM_P0
;;; P1 = (P0)
;;; input: P0
;;; output: P1
;;;---------------------------------------------------------------------------
;;; 	org 0FFEH
;;; PM_READ_P0_P1:
	FIN P1
	BBL 0

	end
