%option noyywrap
%option yylineno

%{
	#include "parser.tab.h"
	#include <string>
	#include <iostream>
	
	
%}
%x COMMENT

%%
"["				BEGIN(COMMENT);
<COMMENT>"]"	BEGIN(INITIAL);
<COMMENT>"["	{std::cout<<"Illegal comment within another comment. Calling quit: \n";return(1);}
<COMMENT>.		;
<COMMENT>\n		;
[ \t]+ 			;
\n				;

"PLUS"				return PLUS; 
"MINUS"				return MINUS; 
"TIMES"				return TIMES; 
"DIV"				return DIV; 
"MOD"	 			return MOD; 
"EQ" 			return EQ;
"NEQ"			return NEQ;
"LE"				return LE;
"GE"				return GE;
"LEQ"			return LEQ;
"GEQ"			return GEQ;
"ASSIGN"    		return ASSIGN;
"("				return LB;
")"				return RB;
":"				return COLON;
";"				return SEMICOLON;
","				return COMMA;
"DECLARE"		return DECLARE;
"BEGIN"			return _BEGIN;
"END"			return END;
"WRITE"			return WRITE;
"READ"			return READ;
"IF"			return IF;
"THEN"			return THEN;
"ELSE"			return ELSE;
"ENDIF"			return ENDIF;
"WHILE"			return WHILE;
"DO"			return DO;
"ENDDO"			return ENDDO;
"ENDWHILE"		return ENDWHILE;
"FOR"			return FOR;
"FROM"			return FROM;
"TO"			return TO;
"DOWNTO"		return DOWNTO;
"ENDFOR"		return ENDFOR;

[_a-z]+				{ 	
						yylval.str = (char *)strdup(yytext);
						return pidentifier;
					}
-?[0-9]+				{ 	
						yylval.str = (char *)strdup(yytext);
						return num;	
					}

.					{
						std::string lexerError("Unexcepted token: '");
						std::string yyLexerError(yytext);
						lexerError += yyLexerError;
						lexerError += "'";
						std::cout<<(lexerError.c_str());
						 return(1);
					}
%%