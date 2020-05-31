# Gebalang-Compiler

```
  ______             __                  __                               
 /      \           |  \                |  \                              
|  $$$$$$\  ______  | $$____    ______  | $$  ______   _______    ______  
| $$ __\$$ /      \ | $$    \  |      \ | $$ |      \ |       \  /      \ 
| $$|    \|  $$$$$$\| $$$$$$$\  \$$$$$$\| $$  \$$$$$$\| $$$$$$$\|  $$$$$$\
| $$ \$$$$| $$    $$| $$  | $$ /      $$| $$ /      $$| $$  | $$| $$  | $$
| $$__| $$| $$$$$$$$| $$__/ $$|  $$$$$$$| $$|  $$$$$$$| $$  | $$| $$__| $$
 \$$    $$ \$$     \| $$    $$ \$$    $$| $$ \$$    $$| $$  | $$ \$$    $$
  \$$$$$$   \$$$$$$$ \$$$$$$$   \$$$$$$$ \$$  \$$$$$$$ \$$   \$$ _\$$$$$$$
                                                                |  \__| $$
                                                                 \$$    $$
                                                                  \$$$$$$ 
```
This is a compiler of a simple imperative language for  GMV (Gembalang virtual machine).
Writen with C++, bison & yacc.* 

The virtual machine only contains a handfull of instructions, so the wheel had to be reinvented (ex. fast (O(log n)) multiplication).

The code was never ment to be seen or tuched by anyone but me and the vast majorty of things happen in a single file. I'm still proud of it. 

Consult docs.pdf for more informations about the virtual machine & language. To build the project, use the Makefiles provided

tic_tac_toe.imp contains an example of a program written in Gembalang.

This is how you'd implement the sieve of Eratosthenes in Gebalang:

```
[ sieve of Eratosthenes ]
DECLARE
    n, j, sito(2:100)
BEGIN
    n ASSIGN 100;
    FOR i FROM n DOWNTO 2 DO
        sieve(i) ASSIGN 1;
    ENDFOR
    FOR i FROM 2 TO n DO
        IF sito(i) NEQ 0 THEN
            j ASSIGN i PLUS i;
            WHILE j LEQ n DO
                sieve(j) ASSIGN 0;
                j ASSIGN j PLUS i;
            ENDWHILE
            WRITE i;
        ENDIF
    ENDFOR
END
```

* Well, more C than C++ actually.
