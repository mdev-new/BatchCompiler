format PE64 CONSOLE
entry start

section '.bss' readable writeable
section '.data' data readable writeable
section '.text' code readable executable

start:
	sub	rsp,8*5