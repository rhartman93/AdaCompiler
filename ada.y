%{#include <stdio.h>
extern int yydebug;
int yydebug = 1;
//To do, exception part, see if we need WHILE/FOR loops, Do we need REVERSE loops?
%}


%token IS BEG END PROCEDURE ID NUMBER TYPE ARRAY RAISE OTHERS
%token RECORD IN OUT RANGE CONSTANT ASSIGN EXCEPTION NULLWORD LOOP IF
%token THEN ELSEIF ELSE EXIT WHEN AND OR EQ NEQ LT GT GTE LTE TICK
%token NOT EXP ARROW OF DOTDOT ENDIF ENDREC ENDLOOP EXITWHEN
%type <integer> NUMBER
%type <integer> beg_loop 
%type <integer> just_else else_part
%type <var> ID
%type <var> type_name
%type <var> mode
%type <var> bool_op relat_op
%type <idList> id_list
%type <treeNode> form_param
%type <treeNode> fp_list
%type <treeNode> formal_param_part
%type <treeNode> range_def
%type <treeNode> array_def
%type <treeNode> type_definition
%type <integer> index
%type <op> adding_op multi_op
%type <expr_info>  call_params b_expr condition expr relat easyExpr simpleExpr term factor primary
%union {
   int integer;
   char *var;
   char op;
   struct idnode *idList;
   struct node *treeNode;
   struct to_pass *expr_info;
}
%%

adaProg : prog {printf("Compilation finished..\n");} ';'
;

prog : proc formal_param_part IS decl_opt  beg_state state_seq except_part END { printf("Popped scope for %s\n", binStack[stack_top].name);
                                                            printInOrder(binStack[stack_top].tree); 
                                                            //insert(binStack[stack_top].tree,

                                                            //Generating machine code for procedure return
                                                            int reg_num = getRegNum();
                                                            int currObj = getObjCount();
                                                            fprintf(outFile, "Return from %s\n", binStack[stack_top].name);
                                                            fprintf(outFile, "%d r%d := contents b, 1\n", currObj, reg_num);
                                                            currObj = getObjCount();
                                                            fprintf(outFile, "%d b := contents b, 3\n", currObj);
                                                            currObj = getObjCount();
                                                            fprintf(outFile, "%d pc := r%d\n", currObj, reg_num);

                                                            //Will need to calculate main's ARsize while creating patchList
                                                            
                                                            if(stack_top == 1){
                                                               //Patch Main's Base
                                                               tpAppend(&patchList, 0, object_count + 1);
                                                               //Patch the start of Main's code
                                                               tpAppend(&patchList, 3, treeOffset);
                                                               //Patch beginning of activation stack (main's base) + the size of the AR (treeOffset)
                                                               tpAppend(&patchList, 1, object_count + 1 + treeOffset);
                                                            }
                                                            pop(); }
;

beg_state : BEG {    
                     //Store Max offset of procedure to get total AR size
                     if(stack_top > 1){
                        int walkback = 0;
                        struct node *result = search_stack(binStack[stack_top].name, &walkback);
                        result->ARsize = treeOffset;
                        result->prg_start = object_count + 1; //Get object_count but don't increment
                        printf("%s 's AR size is: %d and Prg_Start is: %d\n", binStack[stack_top].name, result->ARsize, result->prg_start);
                     }


		     /*if(stack_top > 1){
                     int currReg = getRegNum();
                     int currOCount = getObjCount();
                     printf("Reached begin of program\n");
                     fprintf(outFile, "%d r%d := b\n", currOCount, currReg);
                     printf("Printed %d r%d := b\n", currOCount, currReg);*/
                     fprintf(outFile, "Start of %s's body\n", binStack[stack_top].name);
                  //}
                }
;

proc : PROCEDURE ID                     { struct node *temp = NULL;
                                        int didInsert = 0;
                                        int offSet = 0;
                         		if(stack_top > 0){
                         		didInsert = insert($2, &binStack[stack_top].tree);
				 	if(didInsert){
                         		   temp = search_stack($2, &offSet);
                         		   temp->kind = assString("procedure");
                                           temp->ARsize = 0;
                                        }
                                        else{
					   printf("Error ID: %s already delcared\n", $2);
                                        }
                                        //temp->next = $3;
                         		}
                         		push($2); 
                                        printf("Pushing new scope for %s\n", $2);
					treeOffset = 4;}
;


formal_param_part : '(' fp_list ')' {$$ = $2;}
                  |
;

fp_list : form_param ';' fp_list   { struct node *temp = $1;
                                   while(temp->next != NULL){ 
                                      temp = temp->next;
                                   }
				   temp->next = $3;
                                   printf("Symbol: %s's next symbol is %s\n", temp->symbol, temp->next->symbol); 
                                   $$ = $1;}
        | form_param {$$ = $1;}
;

form_param : id_list ':' mode type_name { struct idnode *temp = $1;
			                  int offSet;
                                          struct node *prev = NULL;
			                  struct node *result = NULL;

			                  while(temp != NULL){
					    int didInsert = 0;
				            didInsert = insert(temp->name, &binStack[stack_top].tree);
					    if(didInsert){
				               result = search_stack(temp->name, &offSet);
				               result->kind = assString("parameter");
                                               printf("Kind: %s\n", binStack[stack_top].tree->kind);
				               result->mode = assString($3);
					       printf("Mode: %s\n", binStack[stack_top].tree->mode);
                                               result->pType = search_stack($4, &offSet);
					       result->offSet = treeOffset;
			                       treeOffset += result->pType->size;
                                               printf("ID: %s with parent type: %s Added to the symbol table: %s\n", result->symbol, result->pType->symbol, binStack[stack_top].name);
                                            
					    //printInOrder(binStack[stack_top].tree->left);
                                            //printInOrder(binStack[stack_top].tree->right);
                                            if(prev != NULL){
                                              prev->next = result;
					      printf("Symbol: %s's next symbol is: %s\n", prev->symbol, prev->next->symbol);
                                            } else {
                                              $$ = result;
                                            }
                                         
					    prev = result;
                                           }
						
				            temp = temp->next;
				         }

                                            theList = NULL;
			      //printInOrder(binStack[stack_top].tree);
                              }
                             

;

id_list : id_list ',' ID  {
			  addList(&$1, $3, NULL);
			  $$ = $1;
                           }
        | ID         {
                      /*struct idnode *aList;
                      aList = malloc((idnodeptr)(sizeof(struct idnode)));
		      aList->next = NULL;
		      aList->name = malloc(strlen($1));
		      strcpy(aList->name, $1);
		      $$ = aList;*/
                      addList(&theList, $1, NULL);
		      $$ = theList;
                      }
;

mode : IN {printf("input parameter\n");
           $$ = assString("in");
	}
         
     | OUT {printf("output parameter\n");
            $$ = assString("out");}
     | IN OUT {printf("in out parameter\n");
               $$ = assString("in out");}
     | {printf("Empty aka Input parameter\n");
        $$ = assString("in");
       }
;

type_name : ID {
                strcpy($$, $1);}
;

decl_opt : decl_part subprg_list
         | subprg_list
;

decl_part : decl ';' decl_part {}
          | decl ';' {}
;

decl : id_list ':' type_name {
                              printList($1);
			      idnodeptr temp = $1;
			      int offSet;
			      struct node *result = NULL;
                              printf("line#: %d  ", lineno);
			      while(temp != NULL){
				 int didInsert = 0;
				 didInsert = insert(temp->name, &binStack[stack_top].tree);
				 if(didInsert){
				    result = search_stack(temp->name, &offSet);
				    result->kind = assString("object");
                                    result->pType = search_stack($3, &offSet);
                                    result->size = result->pType->size;
                                    result->offSet = treeOffset;
				    //printf("ID: %s Added to the symbol table with kind %s with offset %d\n", result->symbol, result->kind, result->offSet);
                                    printf("%s ", result->symbol);
			            treeOffset += result->pType->size; 
                                 }
                                 else {
                                    printf("\nERROR: %s has already been declared\n", temp->name);
                                 }
				 temp = temp->next;
				}
			      //printInOrder(binStack[stack_top].tree);
                              printf(" : %s\n", $3);//result->pType->symbol);
                              theList = NULL;
                              }
     | id_list ':' CONSTANT ASSIGN const_expr {}
     | TYPE ID IS type_definition {
                                   int didInsert = 0;
                                   int offSet = 0;
				   struct node *result = NULL;
                                   didInsert = insert($2, &binStack[stack_top].tree);
				   if(didInsert){
				         result = search_stack($2, &offSet);
				         result->kind = assString($4->kind);
					 result->lower = $4->lower;
                                         result->upper = $4->upper;
                                         result->size = $4->size;
                                         result->pType = $4->pType;
                                   }
              
                                   }
     | id_list ':' EXCEPTION { printList($1);
                               idnodeptr temp = $1;
			      int offSet;
			      struct node *result = NULL;
                              printf("line#: %d  ", lineno);
			      while(temp != NULL){
				 int didInsert = 0;
				 didInsert = insert(temp->name, &binStack[stack_top].tree);
				 if(didInsert){
				    result = search_stack(temp->name, &offSet);
				    result->kind = assString("exception");
                                    result->pType = search_stack("exception", &offSet);
                                    //result->size = result->pType->size;
                                    //result->offSet = treeOffset;
				    //printf("ID: %s Added to the symbol table with kind %s with offset %d\n", result->symbol, result->kind, result->offSet);
                                    printf("%s ", result->symbol);
			            //treeOffset += result->size; 
                                 }
                                 else {
                                    printf("\nERROR: %s has already been declared\n", temp->name);
                                 }
				 temp = temp->next;
				}
			      //printInOrder(binStack[stack_top].tree);
                              printf(" : Exception\n");//result->pType->symbol);
                              theList = NULL;}
;

subprg_list : subprg ';' subprg_list
            | 

;

type_definition : array_def {$$ = $1;}
                | record_def {}
                | range_def {
                             $$ = $1;
                            }
;

array_def : ARRAY '(' index DOTDOT index ')' OF type_name {int didInsert = 0;
                                                           int offSet = 0;
                                                           struct node *result = NULL;
                                                           result = (struct node *)malloc(sizeof(struct node));
                                                           result->kind = assString("array");
							   result->lower = $3;
                                                           result->upper = $5;
							   result->pType = search_stack($8, &offSet);
                                                           result->size = ($5 - $3 + 1) * result->pType->size;
                                                           result->offSet = treeOffset - result->lower; //- result->lower deals with non 0 lower's
                                                           $$ = result;
                                                           }
                                                           
;


index : ID {}
      | NUMBER {$$ = $1;}
;

record_def : RECORD comp_list ENDREC 
;

range_def : RANGE index DOTDOT index {struct node *result = NULL;
                                      
                                      result = (struct node *)malloc(sizeof(struct node));
				      result->kind = assString("type");
			              result->lower = $2;
                                      result->upper = $4;
                                      result->pType = NULL;
				      result->size = 1;
                                     $$ = result;
                                     }

;

subprg : prog {}

;
comp_list : comp_decl ';' comp_list {}
          | comp_decl ';' {}
;

comp_decl : id_list ':' type_name init_opt {}

;

init_opt : ASSIGN expr {}
         | 
;
state_seq : statement ';' state_seq {}
          | statement ';' {}
;


except_part : EXCEPTION  except_list {}
            | 
;

except_list : except_head except_list
            | except_head
;

except_head : WHEN choice_seq ARROW state_seq 
            | WHEN OTHERS ARROW state_seq

;

choice_seq : ID '|' choice_seq
           | ID
;

statement : NULLWORD {}
          | ass_state
          | if_state {}
          | loop_state {}
          | call_state {printf("Finished procedure\n");}
          | raise_state {}
;

ass_state : ID ASSIGN expr {printf("Variable: %s set to %d\n", $1, $3->value);
                                //int reg_num = getRegNum();
                                fprintf(outFile, "Assignment Statement\n");
                                /*if(walk_back != 0){
                                   emit_walkback(outFile, $3->base_reg_num, walk_back, 0);
                                   
                                }
                                reg_info.offSet = result->offSet;
                                reg_info.base_reg_num = reg_num;
                                //reg_info.memory = 1; //true
                                */

                            emit_assign(outFile, $1, $3);
                            }

;

if_state : if_bexp then_part if_state_seq ENDIF {struct patch *temp = toPatchStack[patch_top];
                                                 printPatch(toPatchStack[patch_top], 0);
                                                 printf("Patching jumps for the above ifs to line %d\n", object_count + 1);
                                                 while(temp != NULL){
					            printf("About to add line %d jump to %d\n", temp->line, object_count + 1);
                                                    tpAppend(&patchList, temp->line, object_count + 1);
                      			            temp = temp->next;
                                                 }
                                                 printf("Patch List at this point is:\n");
					         printPatch(patchList, 1);
                                                 printf("----------\n");
					         pPop(); 
                                                 ifCount--;}
         | if_bexp then_part if_state_seq else_part ENDIF { struct patch *temp = toPatchStack[patch_top];
                                                            printPatch(toPatchStack[patch_top], 0);
                                                            printf("Patching jumps for the above ifs to line %d\n", object_count + 1);
                                                            while(temp != NULL){
					                       printf("About to add line %d jump to %d\n", temp->line, object_count + 1);
                                                               tpAppend(&patchList, temp->line, object_count + 1);
                      			                       temp = temp->next;
                                                            }
                                                            printf("Patch List at this point is:\n");
					                    printPatch(patchList, 1);
                                                            printf("----------\n");
					                    pPop(); 
                                                            ifCount--;
                                                           }
         | if_bexp then_part if_state_seq elsif_list ENDIF {struct patch *temp = toPatchStack[patch_top];
                                                            printPatch(toPatchStack[patch_top], 0);
                                                            printf("Patching jumps for the above ifs to line %d\n", object_count + 1);
                                                            while(temp != NULL){
					                       printf("About to add line %d jump to %d\n", temp->line, object_count + 1);
                                                               tpAppend(&patchList, temp->line, object_count + 1);
                      			                       temp = temp->next;
                                                            }
                                                            printf("Patch List at this point is:\n");
					                    printPatch(patchList, 1);
                                                            printf("----------\n");
					                    pPop(); 
                                                            ifCount--;
                                                            }
         | if_bexp then_part if_state_seq elsif_list else_part ENDIF { struct patch *temp = toPatchStack[patch_top];
                                                                       printPatch(toPatchStack[patch_top], 0);
                                                                       printf("Patching jumps for the above ifs to line %d\n", object_count + 1);
                                                                       while(temp != NULL){
					                                  printf("About to add line %d jump to %d\n", temp->line, object_count + 1);
                                                                          tpAppend(&patchList, temp->line, object_count + 1);
                      			                                  temp = temp->next;
                                                                       } 
                                                                       printf("Patch List at this point is:\n");
					                               printPatch(patchList, 1);
                                                                       printf("----------\n");
					                               pPop(); 
                                                                       ifCount--;
                                                                     }

;

if_bexp : IF b_expr { int currObj = getObjCount();
                      fprintf(outFile, "%d pc := ? if not r%d\n", currObj, $2->base_reg_num);
                      pPush(); //This level used for base
		      ifCount++;
                      ifBase[ifCount] = patch_top;
                    }
;

if_state_seq : state_seq {int currObj = getObjCount();
                          fprintf(outFile, "%d pc := ?\n", currObj);//Jump to the end of the if statement
                          printf("%d needs to be patched to the end\n", currObj);
                          pAppend(&toPatchStack[ifBase[ifCount]], currObj);

                          struct patch *temp = toPatchStack[patch_top];
                          printPatch(toPatchStack[patch_top], 0);
                          printf("Patching jumps for the above ifs to line %d\n", object_count + 1);
                          while(temp != NULL){
				printf("In If Statement List: About to add line %d jump to %d\n", temp->line, object_count + 1);
                                tpAppend(&patchList, temp->line, object_count + 1);
                      		temp = temp->next;
                          }
                          printf("Patch List at this point is:\n");
			  printPatch(patchList, 1);
                          printf("----------\n");
                          pPop();//Popping last thing added aka jump that doesn't go to the end
                         }

;

then_part : THEN {    pPush();//This level is for the next jump
                      pAppend(&toPatchStack[patch_top], object_count);
                 }

;

else_part : just_else state_seq { }
;

just_else : ELSE {/*struct patch *temp = toPatchStack[patch_top];
                          printPatch(toPatchStack[patch_top], 0);
                          printf("Patching jumps for the above ifs to line %d\n", object_count + 1);
                          while(temp != NULL){
				printf(" Beginning of Else: About to add line %d jump to %d\n", temp->line, object_count + 1);
                                tpAppend(&patchList, temp->line, object_count + 1);
                      		temp = temp->next;
                          }
                          printf("Patch List at this point is:\n");
			  printPatch(patchList, 1);
                          printf("----------\n");
                          pPop();//Popping last thing added aka jump that goes to the else
                    */
                  }

;
elsif_list : elsif_bexp then_part if_state_seq elsif_list
           | elsif_bexp then_part if_state_seq
;

elsif_bexp : ELSEIF b_expr { int currObj = getObjCount();
                             fprintf(outFile, "%d pc := ? if not r%d\n", currObj, $2->base_reg_num);
                           }

;

b_expr : condition {$$ = $1;}
;

condition : expr {$$ = $1;}

;

loop_state : opt_loop_stuff b_loop
;

opt_loop_stuff : ID ':'
               | it_clause
               | ID ':' it_clause
               |
;

it_clause : "WHILE" b_expr
          | "FOR" ID IN index DOTDOT index

;

b_loop : beg_loop loop_state_seq ENDLOOP {int currObj = getObjCount();
                                          fprintf(outFile, "%d pc := %d\n", currObj, $1);
                                          struct patch *temp = toPatchStack[patch_top];
                                          printPatch(toPatchStack[patch_top], 0);
                                          printf("Patching jumps for the above lines to line %d\n", currObj + 1);
                                          while(temp != NULL){
					     printf("About to add line %d jump to %d\n", temp->line, currObj + 1);
                                             tpAppend(&patchList, temp->line, currObj + 1);
                      			     temp = temp->next;
                                          }
                                          printf("Patch List at this point is:\n");
					  printPatch(patchList, 1);
                                          printf("----------\n");
					  pPop(); 
                                         }

;

beg_loop : LOOP {$$ = object_count + 1;
                 pPush();
                }

;

loop_state_seq : statement ';' loop_state_seq
               | exit_state ';' loop_state_seq
               | statement ';'
               | exit_state ';'
;

exit_state : EXIT {int currObj = getObjCount();
                   fprintf(outFile, "%d pc := ?\n", currObj);
                   pAppend(&toPatchStack[patch_top], currObj);
                  }
           | EXITWHEN b_expr {int currObj = getObjCount();
                              fprintf(outFile, "%d pc := ? if r%d\n", currObj, $2->base_reg_num);
                              pAppend(&toPatchStack[patch_top], currObj);
                             }

;

call_state : ID {int reg_num = getRegNum();
                 int currObj = getObjCount();
                 int walkback = 0;
                 printf("Entering call state\n");
                 struct node *result;
                 result = search_stack($1, &walkback);
                 //printf("Found procedure: %s\n", result->symbol);
		 fprintf(outFile, "Procedure Call\n");
                 fprintf(outFile, "%d r%d := b\n", currObj, reg_num);
                 //Adjust new base of AR
                 currObj = getObjCount();
                 fprintf(outFile, "%d b := contents r%d, 0\n", currObj, reg_num);
                 //printf("Adjusted base of AR\n");
                 //Fix dynamic link
                 currObj = getObjCount();
                 fprintf(outFile, "%d contents b, 3 := r%d\n", currObj, reg_num);
                 //printf("Fixed dynamic link\n");

                 //Fix static Link
                 if(walkback == 0){
		   currObj = getObjCount();
                   fprintf(outFile, "%d contents b, 2 := r%d\n", currObj, reg_num);
                 } else {
                   emit_walkback(outFile, reg_num, walkback, 1);
                 }
                 //printf("Fixed static link\n");
                 //Fix next base
                 currObj = getObjCount();
                 reg_num = getRegNum();
                 fprintf(outFile, "%d r%d := %d\n", currObj, reg_num, result->ARsize);
                 currObj = getObjCount();
                 fprintf(outFile, "%d contents b, 0 := b + r%d\n", currObj, reg_num);

                 //printf("Fixed next base\n");
                 //Fix Return Address
                 currObj = getObjCount();
                 reg_num = getRegNum();
                 fprintf(outFile, "%d r%d := %d\n", currObj, reg_num, currObj + 3); //Plus Three because it takes 3 lines to finish return address stuff
                 
                 currObj = getObjCount();
                 fprintf(outFile, "%d contents b, 1 := r%d\n", currObj, reg_num);
                 //printf("Fixed return address\n");
                 //Jump to code of procedure
                 currObj = getObjCount();
	         fprintf(outFile, "%d pc := %d\n", currObj, result->prg_start);
                 
                 }
           | ID '(' call_params ')' opt_assign {  struct node *result;
                                       		  struct to_pass *temp;
                                       		  temp = $3;
                                       		  int walkback = 0;
                                       		  result = search_stack($1, &walkback);
                                       		  if(strcmp(result->kind, "write_routine") == 0){
                                          	     int currObj = getObjCount();
                                          	     while(temp !=NULL){
                                             		if(temp->isLocal){
                                                	fprintf(outFile, "%d write contents b, %d\n", currObj, temp->offSet);
                                             		} else if(temp->offSet == 0){
      					       		   fprintf(outFile, "%d write r%d\n", currObj, temp->base_reg_num);  
                                             		} else {
                                               		fprintf(outFile, "%d write contents r%d, %d\n", currObj,temp->base_reg_num, temp->offSet);
                                             		}
                                             		temp = temp->next;
                                          	     }//End while
                                                   } //End if
                                                   else if (strcmp(result->kind, "read_routine") == 0){
                                                    int currObj = getObjCount();
					            if(temp->next != NULL){
					               yyerror("Invalid number of arguments to procedure 'read'\n");
                                                    } else if ((!($3->isLocal)) && $3->offSet == 0){
                                                       yyerror("Invalid argument to procedure 'read', expected type object got type constant\n");
                                                    } else if ($3->isLocal){
                                                      fprintf(outFile, "%d read contents b, %d\n", currObj, $3->offSet);
                                                    } else{//non local variable
                                                      fprintf(outFile, "%d read contents r%d, %d\n", currObj, $3->base_reg_num, $3->offSet);
                                          	    }
                                                 }
                                                    //else if (strcmp(result->
                                               }
;

opt_assign : ASSIGN expr {}

;

call_params : expr ',' call_params {$$->next = $3;}
            | expr {$$->next = NULL;}
;

raise_state : RAISE ID

;

expr : relat {$$ = $1;
             }
     | expr bool_op relat { if($1->isVar == 0 && $3->isVar == 0){
			    	if(strcmp($2, "AND") == 0){
				   $$->value = $1->value && $3->value;
                                   $$->base_reg_num = getRegNum();
                                   int currObj = getObjCount();
                                   fprintf(outFile, "%d r%d := %d\n", currObj, $$->base_reg_num, $$->value);
                                   $$->isVar = 0;
                                   $$->isLocal = 0;
                                   $$->offSet = 0;
                                } else if(strcmp($2, "OR") == 0){
                                   $$->value = $1->value || $3->value;
                                   $$->base_reg_num = getRegNum();
                                   int currObj = getObjCount();
                                   fprintf(outFile, "%d r%d := %d\n", currObj, $$->base_reg_num, $$->value);
                                   $$->isVar = 0;
                                   $$->isLocal = 0;
                                   $$->offSet = 0;
                                }
                            }
                            else {
                                printf("Before Emit Bool\n");
                                $$ = emit_bool(outFile, $1, $2, $3);
                                printf("After Emit Bool\n");
                            }
                          }
;


relat : easyExpr {$$ = $1;
                  //printf("Full relat detected\n");
                 }
      | relat relat_op easyExpr { 
                                        fprintf(outFile, "Left register = %d, Right register = %d\n", $1->base_reg_num, $3->base_reg_num);
                                        int newLReg = 0;
                                        int newRReg = 0;
                                        int currObj;
                                        if($1->isVar){
                                           newLReg = getRegNum();
					   if($1->isLocal){
                                              currObj = getObjCount();
                                              fprintf(outFile, "%d r%d := contents b, %d\n", currObj, newLReg, $1->offSet); //If $1 is a local var, store its location in a register
                                              }
                                           else{
                                              currObj = getObjCount();
                                              fprintf(outFile, "%d r%d := contents r%d, %d\n", currObj, newLReg, $1->base_reg_num, $1->offSet);
                                           }
                                        }
                                        else{
                                           newLReg = $1->base_reg_num; //If $1 is just a number, just pass its register
                                        }

                                        if($3->isVar){
                                           newRReg = getRegNum();
                                           if($3->isLocal){
                                              currObj = getObjCount();
                                              fprintf(outFile, "%d r%d := contents b, %d\n", currObj, newRReg, $3->offSet); //If $2 is a local var, store its location in a register
                                              }
                                           else{
                                              currObj = getObjCount();
                                              fprintf(outFile, "%d r%d := contents r%d, %d\n", currObj, newRReg, $3->base_reg_num, $3->offSet);
                                           }
                                        }
                                        else{
                                           newRReg = $3->base_reg_num; //If $2 is just a number, just pass its register
                                        }

					$$ = emit_relat(outFile, newLReg, $2, newRReg);
                                }
;

easyExpr : simpleExpr {$$ = $1;
                       //printf("Full easyExpr detected\n");
                      }
         | '-' simpleExpr { 
                            /*if($2->isVar == 0){
                              int currObj = getObjCount();
                              //$$->value = $2->value * -1;
                              $$->base_reg_num = $2->base_reg_num;
                              fprintf(outFile, "%d r%d := -r%d\n", currObj, $$->base_reg_num, $2->base_reg_num);
                              $$->isVar = 1;
                              $$->isLocal = 0;
                              $$->offSet = 0;
                            } 
                            else*/
                              $$ = $2;
                              if ($2->isLocal){
                              int currObj = getObjCount();
			      $$->base_reg_num = getRegNum();
                              fprintf(outFile, "%d r%d := contents b, %d\n", currObj, $$->base_reg_num, $2->offSet);
                              currObj = getObjCount();
                              fprintf(outFile, "%d r%d := -r%d\n", currObj, $$->base_reg_num, $$->base_reg_num);
			      //$$->isVar = 1;
                              $$->isLocal = 0;
                              $$->offSet = 0; 
                            }
                            else if ($2->offSet == 0){
                              int currObj = getObjCount();
                              //$$->base_reg_num = $2->base_reg_num;
                              fprintf(outFile, "%d r%d := -r%d\n", currObj, $$->base_reg_num, $2->base_reg_num);
			      //$$->isVar = 1;
                              //$$->isLocal = 0;
                              //$$->offSet = 0; 
                            }
                            else{
                              int currObj = getObjCount();
                              //$$->base_reg_num = getRegNum();
                              fprintf(outFile, "%d r%d := contents r%d, %d\n", currObj, $$->base_reg_num, $2->base_reg_num, $2->offSet);
                              currObj = getObjCount();
			      fprintf(outFile, "%d r%d := -r%d\n", currObj, $$->base_reg_num, $$->base_reg_num);
			      $$->isVar = 1;
                              $$->isLocal = 0;
                              $$->offSet = 0; 
                            }
			  //$$ = $2;
                          }
;

simpleExpr : term {$$ = $1;
                   //printf("Full simpleExpr detected\n");
                  }
           | simpleExpr adding_op term {  if($1->isVar == 0 && $3->isVar == 0){
                                             if($2 == '+'){
                                              $$->value = $1->value + $3->value;
                                              $$->base_reg_num = getRegNum();
                                              int currObj = getObjCount();
                                   	      fprintf(outFile, "%d r%d := %d\n", currObj, $$->base_reg_num, $$->value);
                                              $$->isVar = 0;
                                              $$->isLocal = 0;
                                              $$->offSet = 0;
                                             }
                                            else if($2 == '-'){
                                              $$->value = $1->value - $3->value;
                                              $$->base_reg_num = getRegNum();
                                              int currObj = getObjCount();
                                              fprintf(outFile, "%d r%d := %d\n", currObj, $$->base_reg_num, $$->value);
                                              $$->isVar = 0;
                                              $$->isLocal = 0;
                                              $$->offSet = 0;
                                            }
                                          }
                                          else{
					   $$ = emit_mult(outFile, $1, $2, $3);
                                          }
                                       }
;



term :  factor {$$ = $1;
                //printf("Full term detected\n");
               }
     | term multi_op factor {    printf("Multiplication term discovered\n");
                                 if($1->isVar == 0 && $3->isVar == 0){
                                 if($2 == '*'){
                                   $$->value = $1->value * $3->value;
                                   $$->base_reg_num = getRegNum();
                                   int currObj = getObjCount();
                                   fprintf(outFile, "%d r%d := %d\n", currObj, $$->base_reg_num, $$->value);
                                   $$->isVar = 0;
                                   $$->isLocal = 0;
                                   $$->offSet = 0;
                                 }
                                 else if($2 == '/'){
                                   $$->value = $1->value / $3->value;
                                   $$->base_reg_num = getRegNum();
                                   int currObj = getObjCount();
                                   fprintf(outFile, "%d r%d := %d\n", currObj, $$->base_reg_num, $$->value);
                                   $$->isVar = 0;
                                   $$->isLocal = 0;
                                   $$->offSet = 0;
                                 }
                              }
			      else{
				printf("About to multiply/divide\n");
				$$ = emit_mult(outFile, $1, $2, $3);
                                printf("Multiply complete\n");
                              }
                            }
;

factor : primary {$$ = $1;
                  printf("Full Expression detected\n");
                  }
       | factor EXP primary { $$ = emit_expo(outFile, $1, $3);}
       | NOT primary {int currObj = getObjCount();
                      
                      if($2->isLocal){
                        $2->base_reg_num = getRegNum();
                        fprintf(outFile, "%d r%d := NOT contents b, %d\n", currObj, $2->base_reg_num, $2->offSet);
                        $2->isLocal = 0;
                        $2->offSet = 0;
                      } else if($2->offSet == 0){
			   fprintf(outFile, "%d r%d := NOT r%d\n", currObj, $2->base_reg_num, $2->base_reg_num);
                      } else {
                           int new_reg = getRegNum();
                           fprintf(outFile, "%d r%d := NOT contents r%d, %d\n", currObj, new_reg, $2->base_reg_num, $2->offSet);
                           $2->base_reg_num = new_reg;
                           $2->offSet = 0;
                      }
                      $$ = $2;
                     }
                      
;

primary : NUMBER { expTree = malloc(sizeof(struct to_pass));
                  expTree->isVar = 0;
                  expTree->value = $1;
                  expTree->isLocal = 0;
                  expTree->base_reg_num = getRegNum();
                  expTree->offSet = 0; //Use offSet == 0 to test if expr is a number or a non local ID
                  expTree->next = NULL;
                  int currObj = getObjCount();
                  fprintf(outFile, "%d r%d = %d\n", currObj, expTree->base_reg_num, $1);
                  $$ = expTree;}
        | ID {
              expTree = malloc(sizeof(struct to_pass));
              expTree->isVar = 1;
              int walkback = 0;
              struct node* result = search_stack($1, &walkback);
	      if(result == NULL){
		 printf("Variable: %s not found\n");
              } else if(strcmp(result->kind, "literal") == 0){
		   expTree->isVar = 0;
                   expTree->value = result->value;
                   expTree->isLocal = 0;
                   expTree->base_reg_num = getRegNum();
                   expTree->offSet = 0;
                   expTree->next = NULL;
                   int currObj = getObjCount();
                   fprintf(outFile, "%d r%d = %d\n", currObj, expTree->base_reg_num, expTree->value);
                   $$ = expTree;
              }
	      else{
	         printf("In assignment, found variable %s on right side of the statement with walkback of %d\n", result->symbol, walkback);
                 expTree->offSet = result->offSet;
                 if(walkback > 0){
                    int current_reg = getRegNum();
		    emit_walkback(outFile, current_reg, walkback, 0);
                    expTree->isLocal = 0;
                    expTree->base_reg_num = current_reg;
                    expTree->next = NULL;
                 } else {
                   expTree->isLocal = 1;
                   expTree->next = NULL;
                 }
                 
              }
              $$ = expTree;}
        | '(' expr ')' {$$ = $2;}
        | ID '(' expr ')' { 
                           int walkback = 0;
                           expTree = malloc(sizeof(struct to_pass));
                           struct node* result = search_stack($1, &walkback); 
                           if(result == NULL){
                              yyerror("Undefined reference to ID\n");
                           } else if (strcmp(result->kind, "array") == 0){
			     

                           }
	   		   
                          }
;

bool_op : AND {$$ = assString("AND");}
        | OR {$$ = assString("OR");}
;

relat_op :  EQ {$$ = assString("="); }
         |  NEQ {$$ = assString("/=");}
         |  LT {$$ = assString("<");}
         |  GT {$$ = assString(">");}
         |  GTE {$$ = assString(">=");}
         |  LTE {$$ = assString("<=");}
;

adding_op : '+' {$$ = '+';}
          | '-' {$$ = '-';}
;

multi_op : '*' {$$ = '*';}
         | '/' {$$ = '/';}
;
const_expr : NUMBER {printf("Recognized constant number\n");}
;
%%
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "binTree.h"
#include "list.h"
#include "symtable_util.h"
#include "listStack.h"
extern int lineno;
idnodeptr theList = NULL;
int treeOffset = 4;
int ifBase[100];
int ifCount = 0;
FILE *outFile; 
struct to_pass *expTree;
struct patch *patchList;

main()
{
   outFile = fopen("machine_code.txt", "w");
   outerContext();
   prologue(outFile);
   printf("Just wrote file prologue\n");
   printInOrder(binStack[stack_top].tree);
   printf("About to scan.......\n");
   yyparse();
   patchList = sort(patchList);
   printPatch(patchList, 1);
   destroy_stack(binStack);
   destroyPatch(&patchList);
   fclose(outFile);
}
