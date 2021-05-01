STACK SEGMENT PARA STACK ;start by creating a stack segment
	DB 64 DUP (' ') ;fill the stack with 64 empty spaces. 
STACK ENDS
;18BEC0396 and 18BEC0863
DATA SEGMENT PARA 'DATA' ;segment where we will save our variables
	
DATA ENDS

CODE SEGMENT PARA 'CODE'
	
	MAIN PROC FAR  ;creating our main procedure(main function jaise)
	
	ASSUME CS:CODE,DS:DATA,SS:STACK ; to clearly define the segments of our program.
	;code segment,data segment,stack segment. Assembler assumes that these are called code,data and stack.
	; useful for telling the assembler where to get the variables from(where they have been defined),rather than using random garbage values.
	
	PUSH DS ;push to the stack the DS segment.
	SUB AX,AX  ;clean the AX Register by subtracting it with itself
	PUSH AX ;push ax to the stack
	MOV AX,DATA ;save on the AX Register the contents of the DATA segment
	MOV DS,AX   ;save on the data segment,the contents of AX.
	POP AX   ;release the top item from the stack to the register
	POP AX   
	
	CLEAR_SCREEN PROC NEAR
		MOV AH,00h
		MOV AL,13h
		INT 10h
				
		MOV AH,0Bh
		MOV BH,00h
		MOV BL,00h
		INT 10h
		RET
	CLEAR_SCREEN ENDP

		RET
	MAIN ENDP
	
CODE ENDS
END