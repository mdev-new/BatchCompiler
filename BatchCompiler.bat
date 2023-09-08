@echo off
setlocal enableextensions enabledelayedexpansion

rem goal: compile self

rem todo:
rem blocks and single "sub-commands" (eg. if, for)


set input_fname=%1
set outpt_fname=%2

copy template.asm temp.asm > nul

rem steps: a) preparse (remove comments etc (maybe preexpand macros)), b) inline, c) generate code

rem todo special parsing of if for

rem todo handle quotes properly (escape them during parsing)

> pre.bat (

rem first pass
for /f "tokens=*" %%a in (%input_fname%) do (

	set line=%%a
	call :Trim line !line!

	if "!line:~0,1!"=="@" set line=!line:~1!
	if "!line:~0,3!"=="rem" set line=

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
	echo !line! > temp.txt
	for /f %%x in ('findstr /R /C:"^%*^%" temp.txt') do (
		break
	)
)

)


rem -----------------------------
rem code generation
rem -----------------------------

set /a blockdepth=0
set /a foridx=ifidx=0

>> temp.asm (
	echo batchstart:

	rem second pass
	set /a lineidx=0
	set /a echoon=true
	for /f "tokens=*" %%a in (pre.bat) do (
		set line=%%a

		rem todo test the removing of leading whitespace
		rem probably doesnt work
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
				set "line_!lineidx!_echo=!line:~1!"

				<nul set /p"=invoke WriteConsole,[outputhandle],line_!lineidx!_echo,(sizeof.line_!lineidx!_echo)-1,charswritten,0"
			)

			rem call :getword command !line!

			rem todo if we encounter opening paren, increment blockdepth
			rem todo if we encounter closing paren, decrement blockdepth
			rem todo if processing "embedded" commands (eg in if, else, etc) also increment blockdepth

			rem set if for goto call -> most important commands
			rem todo check indexes
			if /i "!line:~0,1!"==":" echo !line:~1!:
			if /i "!line:~0,5!"=="call :" echo call !line:~6!
			if /i "!line:~0,5!"=="goto :" echo goto !line:~6!
			if /i "!line:~0,3!"=="set" call :setCmd !line:~5!
			if /i "!line:~0,2!"=="if" call :ifCmd !line:~4!
			if /i "!line:~0,3!"=="for" call :forCmd !line:~5!
			if /i "!line:~0,7!"=="setlocal" call :setLocal !line:~9!
			if /i "!line:~0,7!"=="endlocal" call :endLocal !line:~9!
			if /i "!line:~0,4!"=="echo" call :echo
			if /i "!line:~0,4!"=="exit" call :exit
			if /i "!line:~0,5!"=="title " (
				echo invoke SetConsoleTitle,"!line:~6!"
			)

		)

		set /a lineidx+=1
	)

	echo eof:
	echo mov rax, 0
	echo ret

	echo .data
	echo outputhandle: dq 0 ; quad for 64bit
	echo charswritten: dd 0
	echo tempptr dq 0
	echo envvarbuf0 sized rb 8192
	echo envvarbuf1 sized rb 8192
	echo envvarbuf2 sized rb 8192
	echo envvarbuf3 sized rb 8192
	echo envvarbuf4 sized rb 8192
	echo envvarbuf5 sized rb 8192
	echo envvarbuf6 sized rb 8192
	echo envvarbuf7 sized rb 8192
	echo envvarbuf8 sized rb 8192
	echo envvarbuf9 sized rb 8192

	rem just about 320k i think, for 10 environments
	echo setlocalenvstack sized rb ^(32*1024*10^)

	for /f "tokens=1 delims==" %%a in ('set line_') do (
		echo %%a sized db "!%%a!",0
	)

	echo .end start

)

rem fasm temp.asm %outpt_fname%
rem del pre.bat temp.asm
exit /b

:forCmd
setlocal

set "firstparam=%1"

if /i "!firstparam:~0,2!"=="%%" (
)

if /i "%1"=="/l" (
	echo mov rcx, rem todo parse
	echo mov rdx, rem todo parse
	echo mov r8,  rem todo parse
	echo forlp!foridx!:
	echo push rcx
	echo push rdx
	echo push r8

	rem here will commands get outputted

	set "blockendhook=pop r8!LF!pop rdx!LF!pop rcx!LF!add rcx, rdx!LF!cmp rax, r8!LF!jne forlp!foridx!"

	break || (
		echo pop r8
		echo pop rdx
		echo pop rcx
		echo add rcx, rdx
		echo cmp rax, r8
		echo bne forlp!foridx!
		echo ret
	)
)

if /i "%1"=="/r" (
)

if /i "%1"=="/f" (
)

endlocal
exit /b



:ifCmd
set /a ifidx+=1
setlocal
if /i "%1"=="not" shift & set invert=y
if /i "%1"=="/i" shift & set insensitive=y
if /i "%1"=="not" shift & set invert=y

if not defined invert (
	set jge=jge
	set jle=jle
	set jg=jg
	set jl=jl
	set je=je
	set jne=jne
	set jz=jz
	set jnz=jnz
) else (
	set jge=jle
	set jle=jge
	set jg=jl
	set jl=jg
	set je=jne
	set jne=je
	set jz=jnz
	set jnz=jz
)

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
	echo !jnz! if_!ifidx!_end
	rem they are same
	rem todo here will codeblock go
	rem echo if_!ifidx!_end:


) else (
	if /i "%2"=="geq" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo !jge! if_!ifidx!_end
		rem commands here
		echo if_!ifidx!_end:
	)
	if /i "%2"=="leq" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo !jle! if_!ifidx!_end
		rem commands here
		echo if_!ifidx!_end:
	)
	if /i "%2"=="gtr" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo !jg! if_!ifidx!_end
		rem commands here
		echo if_!ifidx!_end:
	)
	if /i "%2"=="lss" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo !jl! if_!ifidx!_end
		rem commands here
		echo if_!ifidx!_end:
	)
	if /i "%2"=="equ" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo !jne! if_!ifidx!_end
		rem commands here
		echo if_!ifidx!_end:
	)
	if /i "%2"=="neq" (
		echo mov rcx, %1
		echo cmp rcx, %3
		echo !je! if_!ifidx!_end
		rem commands here
		echo if_!ifidx!_end:
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
