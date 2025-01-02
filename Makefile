all:
	gcc -o wiki2md main.c \
		-O3 -Wall -Wextra

run:
	./wiki2md
