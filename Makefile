a: clean all

all: main.o x86_function.o
	gcc -Wall -fPIC -m64 -o QuadraticFunction main.o x86_function.o -lSDL2 

x86_function.o: x86_function.s
	nasm -f elf64 -o x86_function.o x86_function.s

main.o: main.c
	gcc -Wall -fPIC -m64 -c -o main.o main.c -lSDL2

clean:
	rm -f *.o

