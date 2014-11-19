#ifndef __SYMUTIL__
#define __SYMUTIL__
//symtable_util.h
//Header file that contains a bunch of usefull functions for use with the symbol table
//and eventually list as well

struct to_pass{
   int offSet;
   int isVar; //1 for variable 0 for regular number
   int base_reg_num;
   int isLocal; //Did this guy have a walkback
   int value;
   struct to_pass *next;
};

extern int reg_num;
extern int object_count;

char *assString(char*);
void outerContext();
void prologue(FILE *outFile);
int getRegNum();
int getObjCount();
void emit_assign(FILE *outFile, char *assMe, struct to_pass *reg);
struct to_pass *emit_mult(FILE *outFile, struct to_pass *leftSide, char operator, struct to_pass *rightSide);
struct to_pass *emit_bool(FILE *outFile, struct to_pass *leftSide, char *operator, struct to_pass *rightSide);
struct to_pass *emit_relat(FILE *outFile, int left_reg, char *operator,  int right_reg);
struct to_pass *emit_expo(FILE *outFile, struct to_pass *base, struct to_pass *power);
void emit_walkback(FILE *outFile, int reg_num, int walkback, int isProc);

#endif
