# RegView-32Bit-Arm
View instruction register through GameGuardian !

How its work:
  - Regview will hook instruction address you've provided, and redirect it to our shellcode.
Our shellcode just has one task, which is read and write register. Firstly our shellcode will
store all register in stack, then save the stack address to our allocated memory.
At this time, Regview script will try to probe if stack is ready to read. Then *poof* it works !

Features:
  - Dump, Write, Jump, Copy Register !
