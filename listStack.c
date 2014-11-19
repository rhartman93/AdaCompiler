#include <stdio.h>
#include <stdlib.h>
#include "listStack.h"

int patch_top = -1;

void pAppend(struct patch **root, int currLine){
   if(*root == NULL){
      *root = (struct patch *) malloc(sizeof(struct patch));
      (*root)->line = currLine;
      (*root)->next = NULL;
   }
   else{
      pAppend(&(*root)->next, currLine);
   }

   return;
}

void tpAppend(struct patch **root, int currLine, int currJump){
      if(*root == NULL){
      *root = (struct patch *) malloc(sizeof(struct patch));
      (*root)->line = currLine;
      (*root)->jump = currJump;
      (*root)->next = NULL;
   }
   else{
      tpAppend(&(*root)->next, currLine, currJump);
   }

   return;
}

void printPatch(struct patch *root, int final){
   if(root != NULL){
      printf("%d", root->line);
      if(final){
	 printf("->%d\n", root->jump);
      } else{
	 printf("\n");
      }
      printPatch(root->next, final);
   }
}

void destroyPatch(struct patch **root){
   struct patch *curr = *root;
   struct patch *next;
   while(curr != NULL){
      next = curr->next;
      free(curr);
      curr = next;
   }
   *root = NULL;
}

void pPush(){
   if(patch_top < 49){
      patch_top++;
      toPatchStack[patch_top] = NULL;
      //pAppend(&toPatchStack[patch_top], currLine);
   }
   else{
      printf("Stack Overflow\n");
   }

   return;
}

void pPop(){
   if(patch_top >= 0){
      destroyPatch(&toPatchStack[patch_top]);
      patch_top--;
   }
   else{
      printf("Stack Underflow\n");
   }
   return;
}

//Linked List Bubble Sort from
//http://faculty.salina.k-state.edu/tim/CMST302/study_guide/topic7/bubble.html

struct patch *sort( struct patch *start )
{
    struct patch *p, *q, *top;
    int changed = 1;

    /*
    * We need an extra item at the top of the list just to help
    * with assigning switched data to the 'next' of a previous item.
    * It (top) gets deleted after the data is sorted.
    */

    if( (top = malloc(sizeof(struct patch))) == NULL) {
        fprintf( stderr, "Memory Allocation error.\n" );
        // In Windows, replace following with a return statement.
        exit(1);
    }

    top->next = start;
    if( start != NULL && start->next != NULL ) {
        /*
        * This is a survival technique with the variable changed.
        *
        * Variable q is always one item behind p. We need q, so
        * that we can make the assignment q->next = list_switch( ... ).
        */

        while( changed ) {
            changed = 0;
            q = top;
            p = top->next;
            while( p->next != NULL ) {
                /* push bigger items down */
                if( p->line > p->next->line ) {
                    q->next = list_switch( p, p->next );
                    changed = 1;
                }
                q = p;
                if( p->next != NULL )
                    p = p->next;
            }
        }
    }
    p = top->next;
    free( top );
    return p;
}

struct patch *list_switch( struct patch *l1, struct patch *l2 )
{
    l1->next = l2->next;
    l2->next = l1;
    return l2;
}

void addJump(struct patch *root, int line, int jump){
   if(root == NULL){
      printf("Could not find the line\n");
   }
   else if(root->line == line){
      root->jump = jump;
   }
   else{
      addJump(root->next, line, jump);
   }
   return;

}
