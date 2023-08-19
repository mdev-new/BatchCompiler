@echo off
setlocal enabledelayedexpansion

rem goal: compile self

rem todo:
rem blocks & single "sub-commands" (eg. if, for)


set input_fname=%1
set outpt_fname=%2

set LF=^


set template=!LF!^
include 'win64ax.inc' !LF!^
!LF!^
struc sized [args] { !LF!^
common . args !LF!^
sizeof.#. = $ - . !LF!^
} !LF!^
.code !LF!^
start: !LF!^
invoke GetStdHandle,STD_OUTPUT_HANDLE !LF!^
mov [outputhandle], rax

(

rem first pass
for /f "tokens=*" %%a in (%input_fname%) do (

	set line=%%a
	call :Trim line !line!

	if "!line:~0,1!"=="@" set line=!line:~1!

	if "!line:~0,4!"=="call" if "!line:~-3!"=="bat" (
		rem todo: remove exit /b from inlined scripts
		for /F "delims=" %%i in (!line:~6!) do set filename="%%~nxi"

		rem todo pass args
		if not defined script_!filename!_inlined (
			set script_!filename!_inlined=yes
			echo :script_!filename!
			type !line:~6!
		) else call script_!filename!
	) else echo %%a

	rem probably track and pre-expand non-delayed env vars here
	for /f %%x in ('echo !line! | findstr /R /C:"^%*^%"') do (
	)
)

) > pre.bat

(
	echo !template!

	rem second pass
	set /a lineidx=0
	set /a echoon=true
	for /f "tokens=*" %%a in (pre.bat) do (
		rem for /f "delims=^|^&" in ("%%a") do ()

		set line=%%a

		rem todo test the removing of leading whitespace
		call :Trim line !line!

		set /a ifidx=0

		rem skip all comments
		if not "!line:~0,2!"=="::" if not "!line:~0,3!"=="rem" (

			if "!line:~0,1!"=="@" (
				set line=!line:~1!
				if "!line:~1,5!"=="echo" (
					if "!line:~7,8!"=="on" (set echoon=true) else if "!line:~7,9!"=="off" (set echoon=false ) else call :echo
				)
			) else if "%echoon%"=="true" (
				set line_!lineidx!_echo=!line:~1!

				echo invoke WriteConsole,[outputhandle],line_!lineidx!_echo,(sizeof.line_!lineidx!_echo)-1,charswritten,0
			)

			rem call :getword command !line!

			rem set if for goto call -> most important commands
			rem todo check indexes
			if "!line:~0,1!"==":" echo !line:~1!:
			if "!line:~0,5!"=="call :" echo call !line:~6!
			if "!line:~0,5!"=="goto :" echo goto !line:~6!
			if "!line:~0,3!"=="set" call :setCmd !line:~5!
			if "!line:~0,2!"=="if" call :ifCmd !line:~4!
			if "!line:~0,3!"=="for" call :forCmd !line:~5!
			if "!line:~0,7!"=="setlocal" call :setLocal !line:~9!
			if "!line:~0,7!"=="endlocal" call :endLocal !line:~9!
			if "!line:~0,4!"=="echo" call :echo
			if "!line:~0,4!"=="exit" call :exit
			if "!line:~0,5!"=="title " (
				echo invoke SetConsoleTitle,"!line:~6!"
			)

		)

		set /a lineidx+=1
	)

	echo :eof
	echo mov rax, 0
	echo ret

	echo .data
	echo outputhandle: dq 0 ; quad for 64bit
	echo charswritten: dd 0
	echo tempptr dq 0
	echo envvarbuf1 sized rb 8192
	echo envvarbuf2 sized rb 8192
	echo envvarbuf3 sized rb 8192
	echo envvarbuf4 sized rb 8192
	echo envvarbuf5 sized rb 8192
	echo envvarbuf6 sized rb 8192
	echo envvarbuf7 sized rb 8192
	echo envvarbuf8 sized rb 8192

	for /f "tokens=1 delims==" %%a in ('set line_') do (
		echo %%a sized db "!%%a!",0
	)

	echo .end start

) > temp.asm

rem fasm temp.asm %outpt_fname%
rem del pre.bat temp.asm
exit /b

:forCmd
setlocal

if /i "%1"=="/l" (
	echo mov rcx, rem todo
	echo mov rdx, rem todo
	echo mov r8,  rem todo
	echo @@:
	echo push rcx
	echo push rdx
	echo push r8

	rem here will commands get outputted

	set "blockendhook=pop r8!LF!pop rdx!LF!pop rcx!LF!add rcx, rdx!LF!cmp rax, r8!LF!bne @@-"

	break || (
		echo pop r8
		echo pop rdx
		echo pop rcx
		echo add rcx, rdx
		echo cmp rax, r8
		echo bne @@-
		echo ret
	)
)

endlocal
exit /b



:ifCmd
set /a ifidx+=1
setlocal
if /i "%1"=="not" shift & set invert=y
if /i "%1"=="/i" shift & set insensitive=y
if /i "%1"=="not" shift & set invert=y

if "%2"=="==" (
	rem no arithmetic.

	set "line_!lineidx!_if!ifidx!_str1=%1"
	set "line_!lineidx!_if!ifidx!_str2=%3"
	rem todo case insensitivness (or every char with 0x20)
	echo mov rsi, line_!lineidx!_if!ifidx!_str1
	echo mov rdi, line_!lineidx!_if!ifidx!_str2
	echo mov rcx, sizeof.line_!lineidx!_if!ifidx!_str1 ; this should be len(shortest_str)
	echo cld ; some book on google books listed this
	echo rep cmpsb
	if not defined invert ( echo jnz @@+ ) else echo jz @@+
	rem they are same
	rem todo here will codeblock go
	rem echo @@:


) else (
	if /i "%2"=="geq" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo jge @@+
		rem commands here
		echo @@:
	)
	if /i "%2"=="leq" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo jle @@+
		rem commands here
		echo @@:
	)
	if /i "%2"=="gtr" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo jg @@+
		rem commands here
		echo @@:
	)
	if /i "%2"=="lss" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo jl @@+
		rem commands here
		echo @@:
	)
	if /i "%2"=="equ" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo jne @@+
		rem commands here
		echo @@:
	)
	if /i "%2"=="neq" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo je @@+
		rem commands here
		echo @@:
	)
)

endlocal
exit /b


:setCmd
setlocal

for /f "delims==" %%a in ("%1") do if "%%b"=="" set onlydisplay=y

rem if in set/a try statically evaluating the thing first (in case setting constants)
rem in that case output smth like invoke SetEnvironmentVariable,"test","12345"

if defined onlydisplay (
	echo invoke GetEnvironmentStrings
	echo mov [tempptr], rax
) else (

	if /i "%1"=="/a" (
		rem oops, we're gonna be doing math
	) else (
		for /f "delims==" %%x in ("%1") do (
			echo invoke SetEnvironmentVariable,"%%x","%%y"
		)
	)

)
endlocal
exit /b

:setLocal
setlocal
endlocal
exit /b


:endLocal
setlocal
endlocal
exit /b

:exit
setlocal
endlocal
exit /b

rem -- utility functions

:Trim
SetLocal EnableDelayedExpansion
set Params=%*
for /f "tokens=1*" %%a in ("!Params!") do EndLocal & set %1=%%b
exit /b

:getword
rem todo
rem rem is this really needed?
exit /b
