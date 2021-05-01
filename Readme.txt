Steps to execute the code.

1. Download DOSBox from "https://www.dosbox.com/download.php?main=1". Choose the version thats right for your Hardware.
2. Launch DOSBox.
3. Navigate to the directory that contains your 8086 Assembler files and your game file Pong.asm
4. Run the following commands,pressing the semicolon ';' whenever prompted:
	masm /a pong.asm
	link pong
	pong