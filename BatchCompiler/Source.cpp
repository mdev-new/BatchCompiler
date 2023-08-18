#include <vector>
#include <string>
#include <map>
#include <fstream>
#include <iostream>
#include <algorithm>
#include <sstream>

std::map<int, std::string> echos;

inline std::string& ltrim(std::string& s, const char* t = " \t") {
	s.erase(0, s.find_first_not_of(t));
	return s;
}

char asm_template[] = R"""(
format PE64 console
use64
entry main

include 'C:\Users\Zdenda\Downloads\Compressed\fasmw17331\INCLUDE\WIN64A.INC'

section '.bss' readable writeable

stack_ptr dq ?

section '.idata' import data readable writeable

    library kernel,'KERNEL32.DLL'

    import kernel,\
      VirtualAlloc, 'VirtualAlloc',\
	  SetConsoleTitle, 'SetConsoleTitleA'

section '.text' code readable executable

main:
	invoke VirtualAlloc, 0, 8*1024*1024, (0x00001000 or 0x00002000), 0x04
	test rax, rax
	jnz @f
	mov rax, 1
	ret ; VirtualAlloc failed
@@: mov [stack_ptr], rax

compiled_program_start:

)""";

int main(int argc, char* argv[]) {
	if (argc < 2) {
		printf("Not enough arguments\n");
		return 1;
	}

	std::ifstream input_stream(argv[1]);
	std::ofstream output_stream("temp.asm", std::ofstream::out | std::ofstream::trunc);

	output_stream << asm_template;

	std::string str;
	std::string preprocessed;

	std::stringstream data;
	data << "section '.data' data readable writeable" << '\n';

	std::stringstream strstream;

	int lineno = 0;

	// 1st pass - preprocessing/inlining
	while (getline(input_stream, str)) {

		ltrim(str);
		if (str.starts_with("call") && str[5] != ':' && str.ends_with(".bat")) {
			strstream << std::ifstream(&str[6]).rdbuf();
			preprocessed += strstream.str() + '\n';
		} else {
			preprocessed += str + '\n';
		}

	}

	std::istringstream iss(preprocessed);
	std::cout << preprocessed << std::endl;

	while (getline(iss, str)) {

		ltrim(str);

		if (str.starts_with("call")) {
			if (str[5] == ':') {
				output_stream << "call " << &str.data()[6] << '\n';
			}
		}

		if (str.starts_with("title")) {
			data << "console_title_" << lineno << ": db '" << &str.data()[6] << "',0" << '\n';
			output_stream << "invoke SetConsoleTitle, " << "console_title_" << lineno << '\n';
		}

		if (str.starts_with("::")) continue;
		if (str[0] == ':') {
			output_stream << &str.data()[1] << ':' << '\n';
		}

		lineno++;
	}

	output_stream << "mov rax, 0\nret\n";
	output_stream << data.str();
}