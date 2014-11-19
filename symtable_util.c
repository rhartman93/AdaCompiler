//symtable_util.c
//Specification for symbol table utility functions
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "symtable_util.h"
#include "binTree.h"
//Assigns inputed string to new string

int reg_num = 0;
int object_count = 4; //Start on 4 because it will be incremented immediately to account for main's activation record

char*  assString(char *copyMe){
   char *fillMe;
   fillMe =  malloc(sizeof(copyMe) + 1);
   strcpy(fillMe, copyMe);
   return fillMe;
}

//Creates outer context
void outerContext(){
   int offSet = 0; //How many trees deep
   struct node *thisGuy;
   //thisGuy = malloc(sizeof(struct node));
   //push("Outer Context"); //Push the outer context onto the stack
   binStack[stack_top].name = assString("Outer Context");
   //Note, this means there's a dummy tree at stack[0]

   insert("integer", &binStack[stack_top].tree); //Add Integer
   thisGuy = search_stack("integer", &offSet); //Search for Integer
   //This both validates that integer was inserted properly and allows
   //us to modify its members

   thisGuy->kind = assString("type"); //Set kind to type
   thisGuy->size = 1; //set size to 1

   insert("boolean", &binStack[stack_top].tree); //Add boolean
   thisGuy = search_stack("boolean", &offSet);

   thisGuy->kind = assString("type");
   thisGuy->size = 1;

   insert("true", &binStack[stack_top].tree); //Add true
   thisGuy = search_stack("true", &offSet);
   
   thisGuy->kind = assString("literal");
   thisGuy->value = 1;

   insert("false", &binStack[stack_top].tree); //Add false
   thisGuy = search_stack("false", &offSet);
   
   thisGuy->kind = assString("literal");
   thisGuy->value = 0;

   insert("maxint", &binStack[stack_top].tree); //Add maxint
   thisGuy = search_stack("maxint", &offSet);

   thisGuy->kind = assString("literal");
   thisGuy->value = 8;

   insert("exception", &binStack[stack_top].tree); //Add exception type
   thisGuy = search_stack("exception", &offSet);

   thisGuy->kind = assString("type");

   insert("write", &binStack[stack_top].tree); //Add write routine
   thisGuy = search_stack("write", &offSet);

   thisGuy->kind = assString("write_routine");

   insert("read", &binStack[stack_top].tree); //Add read routine
   thisGuy = search_stack("read", &offSet);

   thisGuy->kind = assString("read_routine");
}
   
void prologue(FILE *outFile){
   fprintf(outFile, "0 b := ?\n1 contents b, 0 := ?\n2 contents b, 1 := 4\n3 pc := ?\n4 halt\n");
}

int getRegNum(){
   reg_num++;
   return reg_num;
}

int getObjCount(){
   object_count++;
   return object_count;
}

void emit_assign(FILE *outFile, char * assMe,  struct to_pass *reg){
   int currOCount;
   /*currOCount = getObjCount();

   fprintf(outFile, "%d r%d := %d\n", currOCount, reg.base_reg_num , expr_value);

   */

    int walk_back = 0;
    struct node *result;
    fprintf(outFile, "Searching for variable %s on the left side\n", assMe);
    result = search_stack(assMe, &walk_back);

    if(result != NULL){
       if(walk_back > 0){
	  int current_reg = getRegNum();
	  emit_walkback(outFile, current_reg, walk_back, 0);
	  currOCount = getObjCount();
	  
	  if(reg->isLocal){
	     fprintf(outFile, "%d contents r%d, %d := contents b, %d\n", currOCount, current_reg, result->offSet, reg->offSet); 
	  } else {
	     fprintf(outFile, "%d contents r%d, %d := ", currOCount, current_reg, result->offSet);
	     if(reg->offSet == 0){
		fprintf(outFile, "r%d\n", reg->base_reg_num);
	     } else{
		fprintf(outFile, "contents r%d, %d\n", reg->base_reg_num, reg->offSet);
	     }
	  }
	  
       }

       else{
	  currOCount = getObjCount();
	  if(reg->isLocal){
	     fprintf(outFile, "%d contents b, %d := contents b, %d\n", currOCount, result->offSet, reg->offSet);
	  } else {
	     fprintf(outFile, "%d contents b, %d := ", currOCount, result->offSet);
	     if(reg->offSet == 0){
		fprintf(outFile, "r%d\n", reg->base_reg_num);
	     } else {
		fprintf(outFile, "contents r%d, %d\n", reg->base_reg_num, reg->offSet);
	     }
	  }
       }
    }
    else{
       fprintf(outFile, "Variable %s was not found\n", assMe);
    }
   return;
}

struct to_pass *emit_mult(FILE *outFile, struct to_pass *leftSide, char operator, struct to_pass *rightSide){
   struct to_pass *multRes = NULL;
   int reg_num = getRegNum();
   int currObj;
   multRes = malloc(sizeof(struct to_pass));
   multRes->base_reg_num = reg_num;
   multRes->offSet = 0;
   multRes->isLocal = 0;
   multRes->isVar = 1;//Results won't have an actual value, therefore should be referred to with a register
   fprintf(outFile, "Emit Multi\n");
   currObj = getObjCount();
    if(leftSide->isLocal){
      fprintf(outFile, "%d r%d := contents b, %d %c ", currObj, reg_num, leftSide->offSet, operator);
   } else if(leftSide->offSet == 0){
      fprintf(outFile, "%d r%d := r%d %c ", currObj, reg_num, leftSide->base_reg_num, operator);  
   } else {
      fprintf(outFile, "%d r%d := contents r%d, %d %c ", currObj, reg_num, leftSide->base_reg_num, leftSide->offSet, operator);
   }
   


   if(rightSide->isLocal){
      fprintf(outFile, "contents b, %d\n", rightSide->offSet);
   } else if(rightSide->offSet == 0){
      fprintf(outFile, "r%d\n", rightSide->base_reg_num);
   } else {
      fprintf(outFile, "contents r%d, %d\n", rightSide->base_reg_num, rightSide->offSet);
   }

   return multRes;
}

struct to_pass *emit_bool(FILE *outFile, struct to_pass *leftSide, char *operator, struct to_pass *rightSide){
      struct to_pass *multRes = NULL;
   int reg_num = getRegNum();
   int currObj;
   multRes = malloc(sizeof(struct to_pass));
   multRes->base_reg_num = reg_num;
   multRes->offSet = 0;
   multRes->isLocal = 0;
   multRes->isVar = 1; //Results won't have an actual value, therefore should be referred to with a register
   fprintf(outFile, "Emit Bool\n");
   currObj = getObjCount();
   if(leftSide->isLocal){
      fprintf(outFile, "%d r%d := contents b, %d %s ", currObj, reg_num, leftSide->offSet, operator);
   } else if(leftSide->offSet == 0){
      fprintf(outFile, "%d r%d := r%d %s ", currObj, reg_num, leftSide->base_reg_num, operator);  
   } else {
      fprintf(outFile, "%d r%d := contents r%d, %d %s ", currObj, reg_num, leftSide->base_reg_num, leftSide->offSet, operator);
   }
   
   /*if(strcmp(operator, ">") == 0){
       fprintf(outFile, "< ");
    } else if(strcmp(operator, ">=") == 0){
       fprintf(outFile, "<= "); 
    } else {
       fprintf(outFile, "%s ", operator);
       }*/
     

   if(rightSide->isLocal){
      fprintf(outFile, "contents b, %d\n", rightSide->offSet);
   } else if(rightSide->offSet == 0){
      fprintf(outFile, "r%d\n", rightSide->base_reg_num);
   } else {
      fprintf(outFile, "contents r%d, %d\n", rightSide->base_reg_num, rightSide->offSet);
   }

   return multRes;
}

struct to_pass *emit_relat(FILE *outFile, int left_reg, char *operator, int right_reg){
   struct to_pass *multRes = NULL;
   int reg_num = getRegNum();
   int currObj;
   multRes = malloc(sizeof(struct to_pass));
   multRes->base_reg_num = reg_num;
   multRes->offSet = 0;
   multRes->isLocal = 0;
   multRes->isVar = 1; //Results won't have an actual value, therefore should be referred to with a register
   fprintf(outFile, "Emit Bool\n");
   currObj = getObjCount();

   if((strcmp(operator, ">") == 0)){
      fprintf(outFile, "%d r%d :=  r%d <  r%d\n", currObj, multRes->base_reg_num, right_reg, left_reg);
   } else if((strcmp(operator, ">=") == 0)){
      fprintf(outFile, "%d r%d := r%d <=  r%d\n", currObj, multRes->base_reg_num, right_reg, left_reg);
   } else {
      fprintf(outFile, "%d r%d := r%d %s r%d\n", currObj, multRes->base_reg_num, left_reg, operator, right_reg);
   }
   /*if(leftSide->isLocal){
      fprintf(outFile, "%d r%d := contents b, %d ", currObj, reg_num, leftSide->offSet);
   } else if(leftSide->offSet == 0){
      fprintf(outFile, "%d r%d := r%d ", currObj, reg_num, leftSide->base_reg_num);  
   } else {
      fprintf(outFile, "%d r%d := contents r%d, %d ", currObj, reg_num, leftSide->base_reg_num, leftSide->offSet);
      }*/
   
   /*if(strcmp(operator, ">") == 0){
       fprintf(outFile, "< ");
    } else if(strcmp(operator, ">=") == 0){
       fprintf(outFile, "<= "); 
    } else {
       fprintf(outFile, "%s ", operator);
       }*/
     

   /*if(rightSide->isLocal){
      fprintf(outFile, "contents b, %d\n", rightSide->offSet);
   } else if(rightSide->offSet == 0){
      fprintf(outFile, "r%d\n", rightSide->base_reg_num);
   } else {
      fprintf(outFile, "contents r%d, %d\n", rightSide->base_reg_num, rightSide->offSet);
      }*/

   return multRes;
}

struct to_pass *emit_expo(FILE *outFile, struct to_pass *base, struct to_pass *power){
   int currObj;
   char *baseRef;
   int powerReg;
   int compReg;

   struct to_pass *multRes = NULL;
   
   multRes = malloc(sizeof(struct to_pass));
   multRes->offSet = 0;
   multRes->isLocal = 0;
   multRes->isVar = 1; //Results won't have an actual value, therefore should be referred to with a register

   //Set up reference for the base and the power
   if(base->isVar){
      if(base->isLocal){
	 baseRef = malloc(sizeof("contents b, 0 ") + 1);
	 sprintf(baseRef, "contents b, %d ", base->offSet);
      } 
      else {
	 baseRef = malloc(sizeof("contents r0, 0 ") + 1);
	 sprintf(baseRef, "contents r%d, %d ", base->base_reg_num, base->offSet);
      }
   } 
   else {
      baseRef = malloc(sizeof("r0 ") + 1);
      sprintf(baseRef, "r%d ", base->base_reg_num);
   }

   //Store power in register
   if(power->isVar){
      currObj = getObjCount();
      
      if(power->isLocal){
	 currObj = getObjCount();
	 powerReg = getRegNum();
	 fprintf(outFile, "%d r%d := contents b, %d\n", currObj, powerReg, power->offSet);
      } 
      else {
	 powerReg = getRegNum();
	 fprintf(outFile, "%d r%d := contents r%d, %d\n", currObj, powerReg, power->base_reg_num, power->offSet);
      }
   } 
   else {
      powerReg = power->base_reg_num;
   }
	 
   //Set registers for zero, one and the result
   int regZero = getRegNum();
   int regOne = getRegNum();
   int result_reg = getRegNum();
   multRes->base_reg_num = result_reg; //Pass up result's register

   fprintf(outFile, "Emit Exponent\n");

   currObj = getObjCount();
   fprintf(outFile, "%d r%d := 0\n", currObj, regZero);
 
   currObj = getObjCount();
   fprintf(outFile, "%d r%d :=  1\n", currObj, regOne);
   
   //Store base in result register
   currObj = getObjCount();
   fprintf(outFile, "%d r%d := %s\n", currObj, result_reg, baseRef);

   //Output if power <= 0 jump?
   currObj = getObjCount();
   compReg = getRegNum();
   //First store comparison
   fprintf(outFile, "%d r%d := r%d <= r%d\n", currObj, compReg, powerReg, regZero);
   currObj = getObjCount();
   fprintf(outFile, "%d pc := %d if r%d\n", currObj, currObj + 6, compReg);

   //Output multiplication
   currObj = getObjCount();
   fprintf(outFile, "%d r%d := r%d * %s\n", currObj, result_reg, result_reg, baseRef);

   //Output decrement of power
   currObj = getObjCount();
   fprintf(outFile, "%d r%d := r%d - r%d\n", currObj, powerReg, powerReg, regOne);

   //Output if power > 0 multiply again
   currObj = getObjCount();
   compReg = getRegNum();
   //First store comparison
   fprintf(outFile, "%d r%d := r%d < r%d\n", currObj, compReg, regZero, powerReg);
   currObj = getObjCount();
   fprintf(outFile, "%d pc := %d if r%d\n", currObj, currObj - 3, compReg); //Mult is 3 lines back

   //Output jump out of expression
   currObj = getObjCount();
   fprintf(outFile, "%d pc := %d\n", currObj, currObj + 10);

   //Output jump to setting result to 1 because power started at 0
   currObj = getObjCount();
   compReg = getRegNum();
   //First store comparison
   fprintf(outFile, "%d r%d := r%d = r%d\n", currObj, compReg, powerReg, regZero);
   currObj = getObjCount();
   fprintf(outFile, "%d  pc := %d if r%d\n", currObj, currObj + 7, compReg);

   //Output mult for negative exponents
   currObj = getObjCount();
   fprintf(outFile, "%d r%d := r%d * %s\n", currObj, result_reg, result_reg, baseRef);

   //Output exponent increment
   currObj = getObjCount();
   fprintf(outFile, "%d r%d := r%d + r%d\n", currObj, powerReg, powerReg, regOne);

   //Output jump if power is less than zero
   currObj = getObjCount();
   compReg = getRegNum();
   //First Store Comparison
   fprintf(outFile, "%d r%d := r%d < r%d\n", currObj, compReg, powerReg, regZero);
   currObj = getObjCount();
   fprintf(outFile, "%d pc := %d if r%d\n", currObj, currObj - 3, compReg);

   //Output division of result for negative exponents
   currObj = getObjCount();
   fprintf(outFile, "%d r%d := r%d / r%d\n", currObj, result_reg, regOne, result_reg);

   //Output leave expression
   currObj = getObjCount();
   fprintf(outFile, "%d pc := %d\n", currObj, currObj + 2);

   //Output setting result to 1 when exponent is 0
   currObj = getObjCount();
   fprintf(outFile, "%d r%d := r%d\n", currObj, result_reg, regOne);

   return multRes;

}

void emit_walkback(FILE *outFile, int reg_num, int walkback, int isProc){
   int i;
   int currOC;
   if(!isProc){ //Line already outputted for dynamic walkbacks

      currOC = getObjCount();
      fprintf(outFile, "%d r%d := b\n", currOC, reg_num);
   }

   for(i = walkback; i > 0; i--){
      currOC = getObjCount();
      fprintf(outFile, "Emitting Walkback\n");
      if(isProc && i == 1){
	 fprintf(outFile, "%d contents b, 2 := contents r%d, 2\n", currOC,  reg_num);
      } else{
	 fprintf(outFile, "%d r%d := contents r%d, 2\n", currOC, reg_num, reg_num);
      }
   }

   /*if(isProc){
      currOC = getObjCount();
      fprintf(outFile, "%d contents b, 2 := r%d\n", currOC,  reg_num);
      }*/
}
