#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <cstdio>
#include <malloc.h>

int removeChar(char* str, char chrToRemove) {
	signed int i = -1;
	while (str[++i] != chrToRemove);
	str[i] = '\0';
	return i;
}

int main(int argc, char** argv) {

	FILE* f = fopen((const char*)argv[1], "r");
	char line[1024] = { 0 };

	FILE* foutpt = fopen((const char*)argv[2], "wb");

	while (fgets(line, sizeof(line), f)) {
		int linelen = removeChar(line, '\n');

		for (int i = 0; i < linelen; i++) {
			// todo parse the line here
		}
	}

	fclose(f);
	fclose(foutpt);

	return 0;

}
