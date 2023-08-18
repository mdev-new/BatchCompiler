#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <cstdio>
#include <malloc.h>

#include "Data.h"

int removeChar(char* str, char chrToRemove) {
	signed int i = -1;
	while (str[++i] != chrToRemove);
	str[i] = '\0';
	return i;
}

void skipws(char** str) {
	while (**str && ((**str == ' ') || (**str == '\t'))) str[0]++;
	return;
}

void skiptext(char* str) {
	while (*str && ((*str != ' ') && (*str != '\t'))) str++;
	return;
}

char* strndup(const char* str, size_t n) {
	size_t len;
	char* copy;

	for (len = 0; len < n && str[len]; len++)
		continue;

	if ((copy = (char*)malloc(len + 1)) == NULL)
		return (NULL);

	memcpy(copy, str, len);
	copy[len] = '\0';
	return (copy);
}

char* getFirstWord(char* str) {
	char* orig_str = str;
	skiptext(str);
	return strndup(orig_str, str - orig_str);
}

int main(int argc, char** argv) {

	FILE* f = fopen((const char*)argv[1], "r");
	char line[1024] = { 0 };

	FILE* foutpt = fopen("temp.asm", "w");

	char command[512] = { 0 }, *pcommand = command, *pline = line;

	bool silentcmd = false;

#define emit(x) fwrite(x, 1, strlen(x), foutpt)


	while (fgets(line, sizeof(line), f)) {
		int linelen = removeChar(line, '\n');

		// todo support ^'s at end of line

		pcommand = command;
		pline = line;
		size_t firstWordLen = 0;
		silentcmd = false;

		for (int i = 0; i < linelen; i++) {
			// todo parse the line here
			skipws(&pline);
			strcpy(command, getFirstWord(line));
			firstWordLen = strlen(command);

			if (command[0] != '@') {
				emit(print_command);
			}

			if (command[0] == ':') {
				emit(&command[1]);
				emit(":");
			}

			// todo push args to the stack

			// skip straight over comments
			if (strncmp(pcommand, "::", 2) == 0) break;
			if (strncmp(pcommand, "rem", 3) == 0) break;

			if (strncmp(pcommand, "echo", 4) == 0) break;
			if (strncmp(pcommand, "set", 3) == 0) break;
			if (strncmp(pcommand, "call", 4) == 0) break;
			if (strncmp(pcommand, "if", 2) == 0) break;
			if (strncmp(pcommand, "for", 3) == 0) break;

		}
	}

	fclose(f);
	fclose(foutpt);

	CreateProcess("FASM.exe", "-m 524288 temp.asm output.exe");

	return 0;

}
