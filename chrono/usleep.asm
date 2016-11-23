section .text
align 8

extern usleep
global Lightning_MicrosecondsSleep
global _Lightning_MicrosecondsSleep

Lightning_MicrosecondsSleep:
_Lightning_MicrosecondsSleep:
    jmp usleep
