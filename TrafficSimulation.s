@ Latest edition: Fall 2012 v4
@ Sep Taheri
@===== STAGE 0
@  	Sets initial outputs and screen for INIT
@ Calls StartSim to start the simulation,
@	polls for left black button, returns to main to exit simulation

        .equ    SWI_EXIT, 		0x11		@terminate program
        @ swi codes for using the Embest board
        .equ    SWI_SETSEG8, 		0x200	@display on 8 Segment
        .equ    SWI_SETLED, 		0x201	@LEDs on/off
        .equ    SWI_CheckBlack, 	0x202	@check press Black button
        .equ    SWI_CheckBlue, 		0x203	@check press Blue button
        .equ    SWI_DRAW_STRING, 	0x204	@display a string on LCD
        .equ    SWI_DRAW_INT, 		0x205	@display an int on LCD  
        .equ    SWI_CLEAR_DISPLAY, 	0x206	@clear LCD
        .equ    SWI_DRAW_CHAR, 		0x207	@display a char on LCD
        .equ    SWI_CLEAR_LINE, 	0x208	@clear a line on LCD
        .equ 	SEG_A,	0x80		@ patterns for 8 segment display
				.equ 	SEG_B,	0x40
				.equ 	SEG_C,	0x20
				.equ 	SEG_D,	0x08
				.equ 	SEG_E,	0x04
				.equ 	SEG_F,	0x02
				.equ 	SEG_G,	0x01
				.equ 	SEG_P,	0x10                
        .equ    LEFT_LED, 	0x02	@patterns for LED lights
        .equ    RIGHT_LED, 	0x01
        .equ    BOTH_LED, 	0x03
        .equ    NO_LED, 	0x00       
        .equ    LEFT_BLACK_BUTTON, 	0x02	@ bit patterns for black buttons
        .equ    RIGHT_BLACK_BUTTON, 0x01
        @ bit patterns for blue keys 
        .equ    Ph1, 		0x0100	@ =8
        .equ    Ph2, 		0x0200	@ =9
        .equ    Ps1, 		0x0400	@ =10
        .equ    Ps2, 		0x0800	@ =11

		@ timing related
		.equ    SWI_GetTicks, 		0x6d	@get current time 
		.equ    EmbestTimerMask, 	0x7fff	@ 15 bit mask for Embest timer
											@(2^15) -1 = 32,767        										
        .equ	OneSecond,	1000	@ Time intervals
        .equ	TwoSecond,	2000
	@define the 2 streets
	@	.equ	MAIN_STREET		0
	@	.equ	SIDE_STREET		1
 
       .text           
       .global _start

@===== The entry point of the program
_start:		
	@ initialize all outputs
	BL Init				@ void Init ()
	@ Check for left black button press to start simulation
RepeatTillBlackLeft:
	swi     SWI_CheckBlack
	cmp     r0, #LEFT_BLACK_BUTTON	@ start of simulation
	beq		StrS
	cmp     r0, #RIGHT_BLACK_BUTTON	@ stop simulation
	beq     StpS

	bne     RepeatTillBlackLeft
StrS:	
	BL StartSim		@else start simulation: void StartSim()
	@ on return here, the right black button was pressed
StpS:
	BL EndSim		@clear board: void EndSim()
EndTrafficLight:
	swi	SWI_EXIT
	
@ === Init ( )-->void
@   Inputs:	none	
@   Results:  none 
@   Description:
@ 		both LED lights on
@		8-segment = point only
@		LCD = ID only
Init:
	stmfd	sp!,{r1-r10,lr}
	@ LCD = ID on line 1
	mov	r1, #0			@ r1 = row
	mov	r0, #0			@ r0 = column 
	ldr	r2, =lineID		@ identification
	swi	SWI_DRAW_STRING
	@ both LED on
	mov	r0, #BOTH_LED	@LEDs on
	swi	SWI_SETLED
	@ display point only on 8-segment
	mov	r0, #10			@8-segment pattern off
	mov	r1,#1			@point on
	BL	Display8Segment

DoneInit:
	LDMFD	sp!,{r1-r10,pc}

@===== EndSim()
@   Inputs:  none
@   Results: none
@   Description:
@      Clear the board and display the last message
EndSim:	
	stmfd	sp!, {r0-r2,lr}
	mov	r0, #10				@8-segment pattern off
	mov	r1,#0
	BL	Display8Segment		@Display8Segment(R0:number;R1:point)
	mov	r0, #NO_LED
	swi	SWI_SETLED
	swi	SWI_CLEAR_DISPLAY
	mov	r0, #5
	mov	r1, #7
	ldr	r2, =Goodbye
	swi	SWI_DRAW_STRING  	@ display goodbye message on line 7
	ldmfd	sp!, {r0-r2,pc}
	
@ === StartSim ( )-->void
@   Inputs:	none	
@   Results:  none 
@   Description:
@ 		XXX
StartSim:
   MOV R1,#1    @ Init first state position
SimStart: 
	 stmfd	sp!,{r2-r10,lr}
   BL CarCycle @ simulate car cycle
   CMP R11,#0    @ if no blue buttones pressed, repeate car cycle
   BEQ SimStart
   CMP R11,#-1    @ if left black pressed, end start sim
   BEQ EndStartSim
   MOV R1,R11       @ if reached, then blue button pressed
   BL PedCycle
   CMP R11,#1
   BEQ EndStartSim @ Black button pressed under I4/ Ped Cycle
   BAL SimStart
   
  
EndStartSim: 
	LDMFD	sp!,{r2-r10,pc}
	
	
	
	
@ ==== Int:R0 CarCycle ( State : r1 )
@   Input : R1 = State to which begin
@	  Results : Returns reason of terminating cycle
@   Description : Bulk of the program, simulates traffic cycle ( not ped)
@		I initially began with loops for S1 ans S2 but ran into various problems
@   Thus just rewrote the code to repeat them 4 and 2 times respectively.
CarCycle:
	Stmfd	sp!, {r0-r10,lr}	
  CMP R11,#4 @ Compare if to start at S5 due to pedcycle ending
  BEQ StartAtS5

	


S1:      
	 MOV R11,#0 @init return
	 MOV			r9,#1  @ Make intital I1 return 1
State11:
   MOV R10,#1     @ Draw pattern 1 on screen
   BL DrawScreen
   BL DrawState    @ Draw S1 on screeen
   MOV R1,#1
   MOV R0,#10
   BL Display8Segment  @ Display point only on 8segmentdisplay
   MOV R10, #TwoSecond  @ 2000 ms
   mov	r0, #LEFT_LED	@LEFT LED on
   swi	SWI_SETLED
   BL Wait					@ Wait 2 secs
	
State12:
	 MOV R10,#2  @ Draw pattern 2 on screen
   BL DrawScreen
   MOV R1,#1
   MOV R0,#10
   BL Display8Segment  @ Display point only on 8segmentdisplay
   mov	r0, #LEFT_LED		@LEFT LED on
   swi	SWI_SETLED
   MOV R10,#OneSecond     @ wait one second
   BL Wait
   
State111:
   MOV R10,#1     @ Draw pattern 1 on screen
   BL DrawScreen
   BL DrawState    @ Draw S1 on screeen
   MOV R1,#1
   MOV R0,#10
   BL Display8Segment  @ Display point only on 8segmentdisplay
   MOV R10, #TwoSecond  @ 2000 ms
   mov	r0, #LEFT_LED	@LEFT LED on
   swi	SWI_SETLED
   BL Wait					@ Wait 2 secs
   	
State121:
   MOV R10,#2  @ Draw pattern 2 on screen
   BL DrawScreen
   MOV R1,#1
   MOV R0,#10
   BL Display8Segment  @ Display point only on 8segmentdisplay
   mov	r0, #LEFT_LED		@LEFT LED on
   swi	SWI_SETLED
   MOV R10,#OneSecond     @ wait one second
   BL Wait
   
State112:
   MOV R10,#1     @ Draw pattern 1 on screen
   BL DrawScreen
   BL DrawState    @ Draw S1 on screeen
   MOV R1,#1
   MOV R0,#10
   BL Display8Segment  @ Display point only on 8segmentdisplay
   MOV R10, #TwoSecond  @ 2000 ms
   mov	r0, #LEFT_LED	@LEFT LED on
   swi	SWI_SETLED
   BL Wait					@ Wait 2 secs
   	
State122:
   MOV R10,#2  @ Draw pattern 2 on screen
   BL DrawScreen
   MOV R1,#1
   MOV R0,#10
   BL Display8Segment  @ Display point only on 8segmentdisplay
   mov	r0, #LEFT_LED		@LEFT LED on
   swi	SWI_SETLED
   MOV R10,#OneSecond     @ wait one second
   BL Wait
   
State113:
   MOV R10,#1     @ Draw pattern 1 on screen
   BL DrawScreen
   BL DrawState    @ Draw S1 on screeen
   MOV R1,#1
   MOV R0,#10
   BL Display8Segment  @ Display point only on 8segmentdisplay
   MOV R10, #TwoSecond  @ 2000 ms
   mov	r0, #LEFT_LED	@LEFT LED on
   swi	SWI_SETLED
   BL Wait					@ Wait 2 secs
   	
State123:
   MOV R10,#2  @ Draw pattern 2 on screen
   BL DrawScreen
   MOV R1,#1
   MOV R0,#10
   BL Display8Segment  @ Display point only on 8segmentdisplay
   mov	r0, #LEFT_LED		@LEFT LED on
   swi	SWI_SETLED
   MOV R10,#OneSecond     @ wait one second
   BL Wait
   
S1Check:			@ Checking s1 has lasted 12 seconds
	CMP R9,#1
	MOV R10,#0 @ dont wait in waitandpoll
	BL WaitPoll @ Always wait and poll at this point
	CMP R9,#-1   @ compare return value with right black button being pressed
	BEQ InteruptCC
	CMP R9,#0 @ Compare return with no buttons pressed
	BEQ S2    @ IF no buttong pressed, continue next stage
	MOV R11,#2   @ If reached, then ped cycle was pressed , thus returning 2(IL2) to startsim
	BAL EndCarCycle
	
S2:
  MOV R10,#2
  BL DrawState    @ Draw S2 on screeen

S21:
  MOV			r9,#1  @ Make intital I2 return such that no buttons have been pressed
  MOV R10,#1  @ Draw pattern 1 on screen
  BL DrawScreen
  MOV R1,#1
  MOV R0,#10
  BL Display8Segment  @ Display point only on 8segmentdisplay
  mov	r0, #LEFT_LED		@LEFT LED on
  swi	SWI_SETLED
  
I2:
  MOV R10,#TwoSecond     @ wait two second
	CMP R9,#1
	BEQ WaitPoll @ Always wait and poll at this point		
	CMP R9,#-1   @ compare return value with right black button being pressed
	BEQ InteruptCC
	CMP R9,#0 @ Compare return with no buttons pressed
	BEQ S22    @ IF no buttong pressed, continue next stage
	MOV R11,#2   @ If reached, then ped cycle was pressed , thus returning 2(IL2) to startsim
	BAL EndCarCycle      

S22:
  MOV			r9,#1  @ Make intital I2 return such that no buttons have been pressed
  MOV R10,#2    @ Draw pattern 2 on screen
  BL DrawScreen
  MOV R1,#1
  MOV R0,#10
  BL Display8Segment  @ Display point only on 8segmentdisplay
  mov	r0, #LEFT_LED	@LEFT LED on
  swi	SWI_SETLED
  
I21:
	MOV R10,#OneSecond
	CMP R9,#1
	BEQ WaitPoll @ Always wait and poll at this point		
	CMP R9,#-1   @ compare return value with right black buttong
	BEQ InteruptCC
	CMP R9,#0 @ Compare return with no buttons pressed
	BEQ S211    @ IF no buttong pressed, continue next stage
	MOV R11,#2   @ If reached, then ped cycle was pressed , thus returning 2(IL2) to startsim
	BAL EndCarCycle
 
S211:
	MOV			r9,#1  @ Make intital I2 return such that no buttons have been pressed
	MOV R10,#1  @ Draw pattern 1 on screen
  BL DrawScreen
  MOV R1,#1
  MOV R0,#10
  BL Display8Segment  @ Display point only on 8segmentdisplay
  mov	r0, #LEFT_LED		@LEFT LED on
  swi	SWI_SETLED
  
I22:
  MOV R10,#TwoSecond     @ wait two second
	cMP R9,#1
  BEQ WaitPoll @ Always wait and poll at this point		
	CMP R9,#-1   @ compare return value with right black buttong
	BEQ InteruptCC
	CMP R9,#0 @ Compare return with no buttons pressed
	BEQ S221   @ IF no buttong pressed, continue next stage
	MOV R11,#2   @ If reached, then ped cycle was pressed , thus returning 2(IL2) to startsim
	BAL EndCarCycle
	
S221:
  MOV			r9,#1  @ Make intital I2 return such that no buttons have been pressed
  MOV R10,#2     @ Draw pattern 2 on screen
  BL DrawScreen
  MOV R1,#1
  MOV R0,#10
  BL Display8Segment  @ Display point only on 8segmentdisplay
  mov	r0, #LEFT_LED	@LEFT LED on
  swi	SWI_SETLED
  
I23:
  MOV R10, #OneSecond  @ 1000 ms
  CMP R9,#1
	BEQ WaitPoll @ Always wait and poll at this point		
  CMP R9,#-1   @ compare return value with right black buttong
  BEQ InteruptCC
	CMP R9,#0 @ Compare return with no buttons pressed
	BEQ State3    @ IF no buttong pressed, continue next stage
	MOV R11,#2   @ If reached, then ped cycle was pressed , thus returning 2(IL2) to startsim
	BAL EndCarCycle

State3:
   MOV R10,#3     @ Draw pattern  on screen
   BL DrawScreen
   BL DrawState    @ Draw S3 on screeen
   MOV R1,#0
   MOV R0,#10
   BL Display8Segment  @ Display nothing on 8segmentdisplay
   MOV R10,#TwoSecond  @ 2000 ms
	 BL WaitBlink          @ wait
	 
S4:
   MOV R10,#4     @ Draw pattern  on screen
   BL DrawScreen
   BL DrawState    @ Draw S4 on screeen
   MOV R1,#0
   MOV R0,#10
   BL Display8Segment  @ Display NOTHING on 8segmentdisplay
   MOV R10,#OneSecond  @ 2000 ms
   mov	r0, #BOTH_LED	@LEFT LED on
	 swi	SWI_SETLED
   BL Wait          @ wait
   
StartAtS5:
	MOV R11,#0 @ MAKE init return 0
	
S5:
   MOV R10,#5     @ Draw pattern  on screen
   BL DrawScreen
   BL DrawState    @ Draw S5 on screeen
   MOV R1,#1
   MOV R0,#10
   BL Display8Segment  @ Display point only on 8segmentdisplay
   mov	r0, #BOTH_LED	@BOTH LED on
	 swi	SWI_SETLED
	 MOV R10,#TwoSecond
	 BL Wait          @ wait
   BL Wait          @ wait
   BL Wait          @ wait
   
S6:
   MOV R10,#6     @ Draw pattern  on screen
   BL DrawScreen
   BL DrawState    @ Draw S6 on screeen
   MOV R1,#1
   MOV R0,#10
   BL Display8Segment  @ Display NOTHING on 8segmentdisplay
   mov	r0, #RIGHT_LED	@RIGHT LED on
	 swi	SWI_SETLED
	 MOV R10,#TwoSecond
	 BL Wait          @ wait
	 
S7:
   MOV R10,#4    @ Draw pattern  on screen
   BL DrawScreen
   MOV R10,#7   
   BL DrawState    @ Draw S7 on screeen
   MOV R1,#1
   MOV R0,#10
   BL Display8Segment  @ Display point only on 8segmentdisplay
   mov	r0, #BOTH_LED	@BOTH LED on
	 swi	SWI_SETLED
	 MOV R10,#OneSecond
	 BL Wait          @ wait
	 
I3:
		MOV R10,#0
	MOV R0,#0
	BL WaitPoll @ Always wait and poll at this point
	CMP R9,#-1   @ compare return value with right black buttong
	BEQ InteruptCC
	CMP R9,#0 @ Compare return with no buttons pressed
	BEQ S1    @ IF no buttong pressed, continue to state 3
	MOV R11,#3   @ If reached, then ped cycle was pressed , thus returning 3(IL3) to startsim
	BL EndCarCycle
	
EndCarCycle:
	ldmfd	sp!, {r0-r10,pc}	
InteruptCC:
  MOV R11,#-1
	ldmfd	sp!, {r0-r10,pc}	
	
@ ==== int PedCycle(CallPosition:r1) 
@   Inputs:  R1 = position to begin in
@   Results: 1 if right black button pressed. 0 if ends normally
@   Description:
@      Stop vehicular traffic and begin simulating pedestrian cycle
PedCycle:
	CMP R1,#3 @ IF called from I3, Start at P3
	BEQ StartAtP3
	stmfd	sp!,{r0-r10,lr}
	MOV R11,#4 @ If Called from I1,I2 , set Flag indicated resume CarCycle at S5
	
P1:
   mov	r0, #NO_LED	@BOTH LED on
	 swi	SWI_SETLED
   MOV R10,#3    @ Draw pattern  on screen
   BL DrawScreen
   MOV R10,#8   
   BL DrawState    @ Draw P1 on screeen
   MOV R1,#0
   MOV R0,#10
   BL Display8Segment  @ Display NOTHING on 8segmentdisplay
	 MOV R10,#TwoSecond
	 BL WaitBlink          @ wait 2s
	 
P2:
   MOV R10,#4    @ Draw pattern  on screen
   BL DrawScreen
   MOV R10,#9   
   BL DrawState    @ Draw P2 on screeen
   MOV R1,#0
   MOV R0,#10
   BL Display8Segment  @ Display point only on 8segmentdisplay
   mov	r0, #BOTH_LED	@BOTH LED on
	 swi	SWI_SETLED
	 MOV R10,#OneSecond
	 BL Wait          @ wait 1s
	 BAL P3
	 
StartAtP3:
	stmfd	sp!,{r0-r10,lr}
	
P3:
   MOV R10,#7   @ Draw pattern  on screen
   BL DrawScreen
   MOV R10,#10  
   BL DrawState    @ Draw P3 on screeen
   mov	r0, #BOTH_LED	@BOTH LED on
	 swi	SWI_SETLED
	     
	 @ beggining pedestrian walk count down w/o using a loop
	 
	 MOV R1,#1
   MOV R0,#6
   BL Display8Segment  @ Display 6 on 8segmentdisplay
	 MOV R10,#OneSecond
	 BL Wait          @ wait
	 
	 MOV R1,#1
   MOV R0,#5
   BL Display8Segment  @ Display 5 on 8segmentdisplay
	 MOV R10,#OneSecond
	 BL Wait          @ wait
	 
	 MOV R1,#1
   MOV R0,#4
   BL Display8Segment  @ Display 4 on 8segmentdisplay
	 MOV R10,#OneSecond
	 BL Wait          @ wait
	 
	 MOV R1,#1
   MOV R0,#3
   BL Display8Segment  @ Display 3 8segmentdisplay
	 MOV R10,#OneSecond
	 BL Wait          @ wait
	 
P4:
   MOV R10,#8    @ Draw pattern  on screen
   BL DrawScreen
   MOV R10,#11   
   BL DrawState    @ Draw P4 on screeen
   mov	r0, #BOTH_LED	@BOTH LED on
	 swi	SWI_SETLED
	 
  @ continuing countown timer , again w/o loop
  
	 MOV R1,#1
   MOV R0,#2
   BL Display8Segment  @ Display 2 on 8segmentdisplay
	 MOV R10,#OneSecond
	 BL Wait          @ wait 1s
	 
	 MOV R1,#1
   MOV R0,#1
   BL Display8Segment  @ Display 1 on 8segmentdisplay
	 MOV R10,#OneSecond
	 BL Wait          @ wait 1s
	 
P5:
   MOV R10,#4   @ Draw pattern  on screen
   BL DrawScreen
   MOV R10,#12    @ Draw pattern  on screen
   BL DrawState    @ Draw P5 on screeen
   mov	r0, #BOTH_LED	@BOTH LED on
	 swi	SWI_SETLED
	 
	 @ Finishing countdown timer for pedestrians.
	 
	 MOV R1,#0
   MOV R0,#0
   BL Display8Segment  @ Display 0 on 8segmentdisplay
	 MOV R10,#OneSecond
	 BL Wait          @ wait 1s
	 
I4:
	MOV R10,#0
	MOV R0,#0   @ do not wait, just poll
	BL WaitPoll @ poll at this point
	CMP R9,#-1   @ compare return value with right black buttong
	BEQ InteruptPC

EndPedCycle:   
	LDMFD	sp!,{r0-r10,pc}
InteruptPC:
  MOV R11,#1
	ldmfd	sp!, {r0-r10,pc}	


@ ==== int WaitAndPoll(Delay:r10) 
@   Inputs:  R10 = delay in milliseconds
@   Results: 0 if max time passed. -1 if right black button pressed. 8/9/10/11 depending on blue button.
@   Description:
@      Wait for r10 milliseconds using a 15-bit timer and poll to see if any buttons have been pressed.
WaitPoll:
	stmfd	sp!, {r0-r8,lr}	
	ldr     r7, =EmbestTimerMask
	swi     SWI_GetTicks		@get time T1
	and		r1,r0,r7			@T1 in 15 bits
WaitLoop2:
	swi SWI_GetTicks			@get time T2
	and		r2,r0,r7			@T2 in 15 bits
	cmp		r2,r1				@ is T2>T1?
	bge		simpletimeW2
	sub		r9,r7,r1			@ elapsed TIME= 32,676 - T1
	add		r9,r9,r2			@    + T2
	bal		CheckIntervalW2
simpletimeW2:
		sub		r9,r2,r1		@ elapsed TIME = T2-T1
CheckIntervalW2:
	cmp		r9,r10				@is TIME < desired interval?
	blt		WaitLoop2

Poll:
	swi     SWI_CheckBlack			@ Check if right black buton pressed
	cmp r0,#RIGHT_BLACK_BUTTON
	beq DoneBlack 
	SWI	SWI_CheckBlue

	cmp r0,#Ph1
	beq Done8
	cmp r0,#Ph2
	beq Done9
	cmp r0,#Ps1
	beq Done10
	cmp r0,#Ps2
	beq Done11
	bal DonePoll

DoneBlack:
	MOV	r9,#-1
	ldmfd	sp!, {r0-r8,pc}	
Done8: 
	MOV			r9,#8  @ Make intital return 0
	ldmfd 	sp!, {r0-r8,pc}
Done9: 
	MOV			r9,#9  @ Make intital return 0
	ldmfd 	sp!, {r0-r8,pc}
Done10: 
	MOV			r9,#10  @ Make intital return 0
	ldmfd 	sp!, {r0-r8,pc}
Done11: 
	MOV			r9,#11  @ Make intital return 0
	ldmfd 	sp!, {r0-r8,pc}
DonePoll: 
	MOV			r9,#0  @ Make intital return 0
	ldmfd 	sp!, {r0-r8,pc}
	
@ ==== void WaitBlink 
@   Inputs:  R10 = delay in milliseconds
@   Results: none
@   Description:
@      Wait for r10 milliseconds using a 15-bit timer 
WaitBlink:
	stmfd	sp!, {r0-r2,r7-r10,lr}
	ldr     r7, =EmbestTimerMask
	swi     SWI_GetTicks		@get time T1
	and		r1,r0,r7			@T1 in 15 bits
WaitLoop3:
  mov	r0, #BOTH_LED	@BOTH LED on
	swi	SWI_SETLED
	
	swi SWI_GetTicks			@get time T2
	and		r2,r0,r7			@T2 in 15 bits
	
	mov	r0, #NO_LED	@BOTH LED on
	swi	SWI_SETLED
	
	cmp		r2,r1				@ is T2>T1?
	bge		simpletimeW3
	sub		r9,r7,r1			@ elapsed TIME= 32,676 - T1
	add		r9,r9,r2			@    + T2
	bal		CheckIntervalW3
simpletimeW3:
		sub		r9,r2,r1		@ elapsed TIME = T2-T1
CheckIntervalW3:
	cmp		r9,r10				@is TIME < desired interval?
	blt		WaitLoop3
WaitDone3:
	ldmfd	sp!, {r0-r2,r7-r10,pc}	
	
	

@ ==== void Wait(Delay:r10) 
@   Inputs:  R10 = delay in milliseconds
@   Results: none
@   Description:
@      Wait for r10 milliseconds using a 15-bit timer 
Wait:
	stmfd	sp!, {r0-r2,r7-r10,lr}
	ldr     r7, =EmbestTimerMask
	swi     SWI_GetTicks		@get time T1
	and		r1,r0,r7			@T1 in 15 bits
WaitLoop:
	swi SWI_GetTicks			@get time T2
	and		r2,r0,r7			@T2 in 15 bits
	cmp		r2,r1				@ is T2>T1?
	bge		simpletimeW
	sub		r9,r7,r1			@ elapsed TIME= 32,676 - T1
	add		r9,r9,r2			@    + T2
	bal		CheckIntervalW
simpletimeW:
		sub		r9,r2,r1		@ elapsed TIME = T2-T1
CheckIntervalW:
	cmp		r9,r10				@is TIME < desired interval?
	blt		WaitLoop
WaitDone:
	ldmfd	sp!, {r0-r2,r7-r10,pc}	

@ *** void Display8Segment (Number:R0; Point:R1) ***
@   Inputs:  R0=NUMber to display; R1=point or no point
@   Results:  none
@   Description:
@ 		Displays the number 0-9 in R0 on the 8-segment
@ 		If R1 = 1, the point is also shown
Display8Segment:
	STMFD 	sp!,{r0-r2,lr}
	ldr 	r2,=Digits
	ldr 	r0,[r2,r0,lsl#2]
	tst 	r1,#0x01 @if r1=1,
	orrne 	r0,r0,#SEG_P 			@then show P
	swi 	SWI_SETSEG8
	LDMFD 	sp!,{r0-r2,pc}
	
@ *** void DrawScreen (PatternType:R10) ***
@   Inputs:  R10: pattern to display according to state
@   Results:  none
@   Description:
@ 		Displays on LCD screen the 5 lines denoting
@		the state of the traffic light
@	Possible displays:
@	1 => S1.1 or S2.1- Green High Street
@	2 => S1.2 or S2.2	- Green blink High Street
@	3 => S3 or P1 - Yellow High Street   
@	4 => S4 or S7 or P2 or P5 - all red
@	5 => S5	- Green Side Road
@	6 => S6 - Yellow Side Road
@	7 => P3 - all pedestrian crossing
@	8 => P4 - all pedestrian hurry
DrawScreen:
	STMFD 	sp!,{r0-r2,lr}
	cmp	r10,#1
	beq	DS11
	cmp	r10,#2
	beq	DS12
	cmp	r10,#3
	beq	DS3
	cmp	r10,#4
	beq	DS4
	cmp	r10,#5
	beq	DS5
	cmp	r10,#6
	beq	DS6
	cmp	r10,#7
	beq	DP3
	cmp	r10,#8
	beq	DP4

	
	bal	EndDrawScreen
DS11:
	ldr	r2,=line1S11
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S11
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S11
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
DS12:
	ldr	r2,=line1S12
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S12
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S12
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
DS3:
	ldr	r2,=line1S3
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S3
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S3
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
DS4:
	ldr	r2,=line1S4
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S4
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S4
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
DS5:
	ldr	r2,=line1S5
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S5
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S5
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
DS6:
	ldr	r2,=line1S6
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3S6
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5S6
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
DP3:
	ldr	r2,=line1P3
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3P3
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5P3
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
DP4:
	ldr	r2,=line1P4
	mov	r1, #6			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line3P4
	mov	r1, #8			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	ldr	r2,=line5P4
	mov	r1, #10			@ r1 = row
	mov	r0, #11			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawScreen
	
EndDrawScreen:
	LDMFD 	sp!,{r0-r2,pc}
	
@ *** void DrawState (PatternType:R10) ***
@   Inputs:  R10: number to display according to state
@   Results:  none
@   Description:
@ 		Displays on LCD screen the state number
@		on top right corner
DrawState:
	STMFD 	sp!,{r0-r2,lr}
	cmp	r10,#1
	beq	S1draw
	cmp	r10,#2
	beq	S2draw
	cmp	r10,#3
	beq	S3draw
	cmp	r10,#4
	beq	S4draw
	cmp	r10,#5
	beq	S5draw
	cmp	r10,#6
	beq	S6draw
	cmp	r10,#7
	beq	S7draw
	cmp	r10,#8
	beq	P1draw
	cmp	r10,#9
	beq	P2draw
	cmp	r10,#10
	beq	P3draw
	cmp	r10,#11
	beq	P4draw
	cmp	r10,#12
	beq	P5draw


	bal	EndDrawScreen
S1draw:
	ldr	r2,=S1label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S2draw:
	ldr	r2,=S2label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S3draw:
	ldr	r2,=S3label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S4draw:
	ldr	r2,=S4label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S5draw:
	ldr	r2,=S5label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S6draw:
	ldr	r2,=S6label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
S7draw:
	ldr	r2,=S7label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
P1draw:
	ldr	r2,=P1label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
P2draw:
	ldr	r2,=P2label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
P3draw:
	ldr	r2,=P3label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
P4draw:
	ldr	r2,=P4label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
P5draw:
	ldr	r2,=P5label
	mov	r1, #2			@ r1 = row
	mov	r0, #30			@ r0 = column
	swi	SWI_DRAW_STRING
	bal	EndDrawState
EndDrawState:
	LDMFD 	sp!,{r0-r2,pc}
	
@@@@@@@@@@@@=========================
	.data
	.align
Digits:							@ for 8-segment display
	.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_G 	@0
	.word SEG_B|SEG_C 							@1
	.word SEG_A|SEG_B|SEG_F|SEG_E|SEG_D 		@2
	.word SEG_A|SEG_B|SEG_F|SEG_C|SEG_D 		@3
	.word SEG_G|SEG_F|SEG_B|SEG_C 				@4
	.word SEG_A|SEG_G|SEG_F|SEG_C|SEG_D 		@5
	.word SEG_A|SEG_G|SEG_F|SEG_E|SEG_D|SEG_C 	@6
	.word SEG_A|SEG_B|SEG_C 					@7
	.word SEG_A|SEG_B|SEG_C|SEG_D|SEG_E|SEG_F|SEG_G @8
	.word SEG_A|SEG_B|SEG_F|SEG_G|SEG_C 		@9
	.word 0 									@Blank 
	.align
lineID:		.asciz	"Traffic Light -- Sep Taheri- v00704838"
@ patterns for all states on LCD
line1S11:		.asciz	"        R W        "
line3S11:		.asciz	"GGG W         GGG W"
line5S11:		.asciz	"        R W        "

line1S12:		.asciz	"        R W        "
line3S12:		.asciz	"  W             W  "
line5S12:		.asciz	"        R W        "

line1S3:		.asciz	"        R W        "
line3S3:		.asciz	"YYY W         YYY W"
line5S3:		.asciz	"        R W        "

line1S4:		.asciz	"        R W        "
line3S4:		.asciz	" R W           R W "
line5S4:		.asciz	"        R W        "

line1S5:		.asciz	"       GGG W       "
line3S5:		.asciz	" R W           R W "
line5S5:		.asciz	"       GGG W       "

line1S6:		.asciz	"       YYY W       "
line3S6:		.asciz	" R W           R W "
line5S6:		.asciz	"       YYY W       "

line1P3:		.asciz	"       R XXX       "
line3P3:		.asciz	"R XXX         R XXX"
line5P3:		.asciz	"       R XXX       "

line1P4:		.asciz	"       R !!!       "
line3P4:		.asciz	"R !!!         R !!!"
line5P4:		.asciz	"       R !!!       "

S1label:		.asciz	"S1"
S2label:		.asciz	"S2"
S3label:		.asciz	"S3"
S4label:		.asciz	"S4"
S5label:		.asciz	"S5"
S6label:		.asciz	"S6"
S7label:		.asciz	"S7"
P1label:		.asciz	"P1"
P2label:		.asciz	"P2"
P3label:		.asciz	"P3"
P4label:		.asciz	"P4"
P5label:		.asciz	"P5"

Goodbye:
	.asciz	"*** Traffic Light Simulation Ended***"

	.end

