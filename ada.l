%{
#include "y.tab.h"
char linebuf[500];
int lineno = 1;
%}

digits [0-9]
alpha [a-zA-Z]
%%

"end if" {return ENDIF;}
"end record" {return ENDREC;}
"end loop" {return ENDLOOP;}
"exit when" {return EXITWHEN;}
"is" {return IS;}
"of" {return OF;}
"begin" {return BEG;}
"end" {return END;}
".." {return DOTDOT;}
"'" {return TICK;}
"procedure" {return PROCEDURE;}
"type" {return TYPE;}
"array" {return ARRAY;}
"record" {return RECORD;}
"in" {return IN;}
"out" {return OUT;}
"range" {return RANGE;}
"constant" {return CONSTANT;}
":=" {return ASSIGN;}
"exception" {return EXCEPTION;}
"null" {return NULLWORD;}
"loop" {return LOOP;}
"if" {return IF;}
"then" {return THEN;}
"elsif" {return ELSEIF;}
"else" {return ELSE;}
"exit" {return EXIT;}
"when" {return WHEN;}
"and" {return AND;}
"or" {return OR;}
"not" {return NOT;}
"=" {return EQ;}
"/=" {return NEQ;}
">" {return GT;}
"<" {return LT;}
">=" {return GTE;}
"<=" {return LTE;}
"**" {return EXP;}
"raise" {return RAISE;}
"others" {return OTHERS;}
"=>" {return ARROW;}
{alpha}+({alpha}|{digits}|"_")* {yylval.var = malloc(strlen(yytext)+1);
                               strcpy(yylval.var, yytext);
                               printf("In lexer: ID= %s\n", yytext);
                               return ID;}
{digits}+ {yylval.integer = atoi(yytext);
           return NUMBER;}
[ \t] ;
"\n".* {strcpy(linebuf, yytext + 1); lineno++; yyless(1);} 
"--".*"\n" { break;}
. {return yytext[0];}

%%

yyerror(char *s){
	printf("%s at line %d: %s\n", s, lineno, linebuf);
}

