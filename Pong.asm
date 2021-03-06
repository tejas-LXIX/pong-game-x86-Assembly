STACK SEGMENT PARA STACK ;start by creating a stack segment
	DB 64 DUP (' ') ;fill the stack with 64 empty spaces. 
STACK ENDS
;18BEC0396 and 18BEC0863
DATA SEGMENT PARA 'DATA' ;segment where we will save our variables
	TIME_AUX DB 0
	WINDOW_WIDTH DW 140h   		;the width of the window (320 pixels)
	WINDOW_HEIGHT DW 0C8h  		;the height of the window (200 pixels)
	WINDOW_BOUNDS DW 6     		;variable used to check collisions early
	BALL_ORIGINAL_X DW 0A0h		;x position of the ball at the beginning of the game.
	BALL_ORIGINAL_Y DW 64h
	BALL_X DW 0A0h  			;declaring the ball variables here (x and y posn's of the ball)
	BALL_Y DW 64h  				;DW	stands for define word. can store 16 bits of info. we use it because down there,we are using 16 bits registers.
	; DB can only store 8 bits of data.
	BALL_SIZE DW 04h  			;size of the ball. 4 pixels on x(width) and on y(height). so,16 pixels in total.	
	BALL_VELOCITY_X DW 05h
	BALL_VELOCITY_Y DW 02h
	
	PADDLE_LEFT_X DW 0Ah
	PADDLE_LEFT_Y DW 0Ah
	
	PADDLE_RIGHT_X DW 130h
	PADDLE_RIGHT_Y DW 0Ah
	
	PADDLE_WIDTH DW 05h
	PADDLE_HEIGHT DW 1Fh
	PADDLE_VELOCITY DW 05h
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
	
		CALL CLEAR_SCREEN
		
		CHECK_TIME:
			MOV AH,2Ch ; set the configuration to get the system time. 2Ch is the function code on AH to get the system time.
			INT 21h  ;we will use the interruption 21h. CH = hour CL = minute DH = second DL = 1/100 seconds
			CMP DL,TIME_AUX ; check if the current time is equal to the previous one
			JE CHECK_TIME  ;JE stands for "Jump if condition is met". If DL and TIME_AUX are the same,check again. If not the same,then draw ball,move etc.
			
			MOV TIME_AUX,DL ;Update the value of time_aux with the new value of dl. basically,update the time.
			
			CALL CLEAR_SCREEN
			CALL MOVE_BALL
			CALL DRAW_BALL
			
			CALL MOVE_PADDLES
			CALL DRAW_PADDLES
			
			JMP CHECK_TIME
		
		RET
	MAIN ENDP

	MOVE_BALL PROC NEAR
		
		MOV AX,BALL_VELOCITY_X    
		ADD BALL_X,AX             ;move the ball horizontally
		
		MOV AX,WINDOW_BOUNDS
		CMP BALL_X,AX                         
		JL RESET_POSITION         ;BALL_X < 0 + WINDOW_BOUNDS (Y -> collided)
		
		MOV AX,WINDOW_WIDTH
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_X,AX	          ;BALL_X > WINDOW_WIDTH - BALL_SIZE  - WINDOW_BOUNDS (Y -> collided)
		JG RESET_POSITION
			
		MOV AX,BALL_VELOCITY_Y
		ADD BALL_Y,AX             ;move the ball vertically
		
		MOV AX,WINDOW_BOUNDS
		CMP BALL_Y,AX   ;BALL_Y < 0 + WINDOW_BOUNDS (Y -> collided)
		JL NEG_VELOCITY_Y                          
		
		MOV AX,WINDOW_HEIGHT	
		SUB AX,BALL_SIZE
		SUB AX,WINDOW_BOUNDS
		CMP BALL_Y,AX
		JG NEG_VELOCITY_Y		  ;BALL_Y > WINDOW_HEIGHT - BALL_SIZE - WINDOW_BOUNDS (Y -> collided)
		
		
		
		;here we check if the ball is colliding with the right paddle
		;maxx1>minx2 && minx1<maxx2 && maxy1>miny2 && miny1<maxy2. Condition for collision.
;therefore BALL_X+BALL_SIZE>PADDLE_RIGHT_X && BALL_X<PADDLE_RIGHT_X+PADDLE_WIDTH && BALL_Y+BALL_SIZE>PADDLE_RIGHT_Y  && BALL_Y<PADDLE_RIGHT_Y+PADDLE_HEIGHT
		
		MOV AX,BALL_X
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_X
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE ;jump if not greater,check if collision with left paddle

		MOV AX,PADDLE_RIGHT_X
		ADD AX,PADDLE_WIDTH
		CMP BALL_X,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE
		
		MOV AX,BALL_Y
		ADD AX,BALL_SIZE
		CMP AX,PADDLE_RIGHT_Y
		JNG CHECK_COLLISION_WITH_LEFT_PADDLE
		
		MOV AX,PADDLE_RIGHT_Y
		ADD AX,PADDLE_HEIGHT
		CMP BALL_Y,AX
		JNL CHECK_COLLISION_WITH_LEFT_PADDLE
		;if it reaches this point,means the ball collided with the right paddle.
		NEG BALL_VELOCITY_X
		RET
		
		RESET_POSITION:
			CALL RESET_BALL_POSITION
			RET
			
		NEG_VELOCITY_Y:
			NEG BALL_VELOCITY_Y   ;BALL_VELOCITY_Y = - BALL_VELOCITY_Y
			RET
		;here we check if the ball is colliding with the left paddle
		;maxx1>minx2 && minx1<maxx2 && maxy1>miny2 && miny1<maxy2. Condition for collision.
;therefore BALL_X+BALL_SIZE>PADDLE_LEFT_X && BALL_X<PADDLE_LEFT_X+PADDLE_WIDTH && BALL_Y+BALL_SIZE>PADDLE_LEFT_Y  && BALL_Y<PADDLE_LEFT_Y+PADDLE_HEIGHT
		CHECK_COLLISION_WITH_LEFT_PADDLE:
			MOV AX,BALL_X
			ADD AX,BALL_SIZE
			CMP AX,PADDLE_LEFT_X
			JNG EXIT_BALL_MOVEMENT ;jump if not greater,check if collision with left paddle

			MOV AX,PADDLE_LEFT_X
			ADD AX,PADDLE_WIDTH
			CMP BALL_X,AX
			JNL EXIT_BALL_MOVEMENT
			
			MOV AX,BALL_Y
			ADD AX,BALL_SIZE
			CMP AX,PADDLE_LEFT_Y
			JNG EXIT_BALL_MOVEMENT
			
			MOV AX,PADDLE_LEFT_Y
			ADD AX,PADDLE_HEIGHT
			CMP BALL_Y,AX
			JNL EXIT_BALL_MOVEMENT
			;if it reaches this point,means the ball collided with the left paddle.
			NEG BALL_VELOCITY_X
			RET
			
			EXIT_BALL_MOVEMENT:
				RET		
		RET
		
	MOVE_BALL ENDP
	
	MOVE_PADDLES PROC NEAR
		MOV AH,01h ;to check keystroke status
		INT 16h
		JZ CHECK_RIGHT_PADDLE_MOVEMENT ; JUMP if ZERO FLAG(of Ah=01) is set. Meaning,if ZF=1,this means a key is being pressed.
		;left paddle movement
		;check if any key is being pressed(if not then exit procedure)
		;if being pressed,then check which key is being pressed(AL will store the ASCII character of the key being pressed)
		MOV AH,00h ;to read which key has been pressed. Visit the site in video 12 of playlist.
		INT 16h
		; if it is 'w' or 'W', move up
		CMP AL,77h ; for 'w'. ASCII value of 'w' in hexadecimal
		JE MOVE_LEFT_PADDLE_UP
		CMP AL,57h ; for 'W'.
		JE MOVE_LEFT_PADDLE_UP
		
		; if it is 's' or 'S', move down
		CMP AL,73h ; for 's'. ASCII value of 's' in hexadecimal
		JE MOVE_LEFT_PADDLE_DOWN
		CMP AL,53h ; for 'S'.
		JE MOVE_LEFT_PADDLE_DOWN
		
		JMP CHECK_RIGHT_PADDLE_MOVEMENT ;if it reaches here,it means that they key pressed was neither w nor s
		
		MOVE_LEFT_PADDLE_UP:
			MOV AX,PADDLE_VELOCITY
			SUB PADDLE_LEFT_Y,AX
			MOV AX,WINDOW_BOUNDS
			CMP PADDLE_LEFT_Y,AX
			JL FIX_PADDLE_LEFT_TOP_POSITION ;jumps if paddle left y is lesser than ax. 'y' position is 0 on top,AND IT INCREASES as we go down.
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_TOP_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
				
		MOVE_LEFT_PADDLE_DOWN:
			MOV AX,PADDLE_VELOCITY
			ADD PADDLE_LEFT_Y,AX
			MOV AX,WINDOW_HEIGHT
			SUB AX,WINDOW_BOUNDS
			SUB AX,PADDLE_HEIGHT
			CMP PADDLE_LEFT_Y,AX
			JG FIX_PADDLE_LEFT_BOTTOM_POSITION ;jumps if paddle left y is greater than ax			
			JMP CHECK_RIGHT_PADDLE_MOVEMENT
			
			FIX_PADDLE_LEFT_BOTTOM_POSITION:
				MOV PADDLE_LEFT_Y,AX
				JMP CHECK_RIGHT_PADDLE_MOVEMENT
		CHECK_RIGHT_PADDLE_MOVEMENT:

		; if it is 'o' or 'O', move up
		CMP AL,6Fh ; for 'o'. ASCII value of 'o' in hexadecimal
		JE MOVE_RIGHT_PADDLE_UP
		CMP AL,4Fh ; for 'O'.
		JE MOVE_RIGHT_PADDLE_UP
		
		; if it is 'l' or 'L', move down
		CMP AL,6Ch ; for 'l'. ASCII value of 'l' in hexadecimal
		JE MOVE_RIGHT_PADDLE_DOWN
		CMP AL,4Ch ; for 'L'.
		JE MOVE_RIGHT_PADDLE_DOWN
		JMP EXIT_PADDLE_MOVEMENT
		
		MOVE_RIGHT_PADDLE_UP:
			MOV AX,PADDLE_VELOCITY
			SUB PADDLE_RIGHT_Y,AX
			MOV AX,WINDOW_BOUNDS
			CMP PADDLE_RIGHT_Y,AX
			JL FIX_PADDLE_RIGHT_TOP_POSITION ;jumps if paddle left y is lesser than ax. 'y' position is 0 on top,AND IT INCREASES as we go down.
			JMP EXIT_PADDLE_MOVEMENT
			
			FIX_PADDLE_RIGHT_TOP_POSITION:
				MOV PADDLE_RIGHT_Y,AX
				JMP EXIT_PADDLE_MOVEMENT
			
		MOVE_RIGHT_PADDLE_DOWN:
			MOV AX,PADDLE_VELOCITY
			ADD PADDLE_RIGHT_Y,AX
			MOV AX,WINDOW_HEIGHT
			SUB AX,WINDOW_BOUNDS
			SUB AX,PADDLE_HEIGHT
			CMP PADDLE_RIGHT_Y,AX
			JG FIX_PADDLE_RIGHT_BOTTOM_POSITION ;jumps if paddle left y is greater than ax			
			JMP EXIT_PADDLE_MOVEMENT
			
			FIX_PADDLE_RIGHT_BOTTOM_POSITION:
				MOV PADDLE_RIGHT_Y,AX
				JMP EXIT_PADDLE_MOVEMENT
		JMP EXIT_PADDLE_MOVEMENT

		EXIT_PADDLE_MOVEMENT:
			RET
	MOVE_PADDLES ENDP
	
	RESET_BALL_POSITION PROC NEAR
		MOV AX,BALL_ORIGINAL_X
		MOV BALL_X,AX
		
		MOV AX,BALL_ORIGINAL_Y
		MOV BALL_Y,AX
		RET
	RESET_BALL_POSITION ENDP
	
	DRAW_BALL PROC NEAR  ;to define a noew procedure that belongs to the same code segment. the main procedure can call this drawball procedure
		
		MOV CX,BALL_X ;set the initial column (X position) of the pixel to 10
		MOV DX,BALL_Y ;set initial y (row position) position to 10.
		;we draw one pixel in one line till we reach the width of 4. then do the same for each line till we reach 4 again. so,we print 16 pixels(4*4). this is done using the below loop
		DRAW_BALL_HORIZONTAL:
			MOV AH,0Ch ; set the configuration to writing a pixel
			MOV AL,0Fh ; chooose white colour for the pixel
			MOV BH,00h ; set the page number to zero
			INT 10h ;execute the configuration
			
			INC CX  ;CX=CX+1 incrementing the column by 1.			
					;CX - BALL_X > BALL_SIZE (We check this condition. If this occurs,means we have reached the width of the ball,so we reset and go to the next line. If not,then we go to next column)
			MOV AX,CX ;Using an auxiliary register AX so that we dont lose the current values.
			SUB AX,BALL_X ;This difference increases with each iteration. This Diff is stored in AX.
			CMP AX,BALL_SIZE ;comparing the two values
			JNG DRAW_BALL_HORIZONTAL ;JUMP,if NOT GREATER. if AX is not greater than ballsize,then loop this again.
			;this basically draws the columns.
			
			;if it reaches the below lines,means that AX became greater than ball_size. so,now we have to go to the next line and do this again.
			MOV CX,BALL_X ;resetting the column value to initial x position of the ball. CX register goes back to the initial column
			INC DX ;move to the next line
					;DX - BALL_Y > BALL_SIZE(to check if we have reached the final line).If true,then we exit this procedure. otherwise,we move to next line.
			MOV AX,DX
			SUB AX,BALL_Y
			CMP AX,BALL_SIZE
 			JNG DRAW_BALL_HORIZONTAL
					
		RET   ;to exit this procedure
	DRAW_BALL ENDP  ;denotes the end of this procedure
	
	DRAW_PADDLES PROC NEAR
		MOV CX,PADDLE_LEFT_X
		MOV DX,PADDLE_LEFT_Y
		
		DRAW_PADDLE_LEFT_HORIZONTAL:
			MOV AH,0Ch ; set the configuration to writing a pixel
			MOV AL,0Fh ; chooose white colour for the pixel
			MOV BH,00h ; set the page number to zero
			INT 10h ;execute the configuration
			
			INC CX
			MOV AX,CX
			SUB AX,PADDLE_LEFT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			MOV CX,PADDLE_LEFT_X
			INC DX
			MOV AX,DX
			SUB AX,PADDLE_LEFT_Y
			CMP AX,PADDLE_HEIGHT
 			JNG DRAW_PADDLE_LEFT_HORIZONTAL
			
		MOV CX,PADDLE_RIGHT_X ;set the initial column (X)
		MOV DX,PADDLE_RIGHT_Y ;set the initial line (Y)
		
		DRAW_PADDLE_RIGHT_HORIZONTAL:
			MOV AH,0Ch ;set the configuration to writing a pixel
			MOV AL,0Fh ;choose white as color
			MOV BH,00h ;set the page number 
			INT 10h    ;execute the configuration
			
			INC CX     ;CX = CX + 1
			MOV AX,CX          ;CX - PADDLE_RIGHT_X > PADDLE_WIDTH (Y -> We go to the next line,N -> We continue to the next column
			SUB AX,PADDLE_RIGHT_X
			CMP AX,PADDLE_WIDTH
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
			
			MOV CX,PADDLE_RIGHT_X ;the CX register goes back to the initial column
			INC DX        ;we advance one line
			
			MOV AX,DX              ;DX - PADDLE_RIGHT_Y > PADDLE_HEIGHT (Y -> we exit this procedure,N -> we continue to the next line
			SUB AX,PADDLE_RIGHT_Y
			CMP AX,PADDLE_HEIGHT
			JNG DRAW_PADDLE_RIGHT_HORIZONTAL
		RET
	DRAW_PADDLES ENDP
	
	CLEAR_SCREEN PROC NEAR  ;clear the screen by resetting the video mode
			MOV AH,00h ;set the configuration to video mode
			MOV AL,13h  ;choose the video mode. set it to 13h(is a part of provides 256 color graphics)
			INT 10h ; execute the configuration
			
			MOV AH,0Bh ;set the configuration
			MOV BH,00h ;to the background color
			MOV BL,00h ; choose black as background. 00h is the colour code for black
			INT 10h ; execute the configuration
			RET
	CLEAR_SCREEN ENDP
	
CODE ENDS
END