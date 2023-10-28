all:
	gcc  transformationtable.c -o transformationtable -lm
	vasmm68k_mot -kick1hunks -devpac -Fhunkexe -quiet -esc  -m68000 -D USE_DBLBUF -DMATRIX_STACK_SIZE=0  ./tunnel.s  -o ./tunnel -I/usr/local/amiga/os-include && chmod 777 ./tunnel
	vasmm68k_mot -kick1hunks -devpac -Fhunkexe -quiet -esc  -m68000 -D USE_DBLBUF -DMATRIX_STACK_SIZE=0 -D COLORDEBUG  ./tunnel.s  -o ./tunneldebug -I/usr/local/amiga/os-include && chmod 777 ./tunneldebug

	./comprimi.sh
