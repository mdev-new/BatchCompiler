include 'win64ax.inc'

struc sized [args] {
common . args
sizeof.#. = $ - .
}

.code
start:
invoke GetStdHandle,STD_OUTPUT_HANDLE
mov [outputhandle], rax
