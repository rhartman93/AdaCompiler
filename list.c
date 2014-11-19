//list.c
//Specification of a linked list

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "list.h"

/*idnodeptr theList = NULL;
  idnodeptr head;*/

void printList(idnodeptr list){
   int test;
   test = (list != NULL);
   /*if(test)
      printf("List is not null\n");
   else
   printf("List is null\n");*/

   if(list != NULL){
      printf("%s\n", list->name);
      printList(list->next);
   }
   return;
}

void destroyList(idnodeptr *aList){//Found at http://breakinterview.com/write-a-function-to-delete-a-linked-list/
   idnodeptr curr = *aList;
   idnodeptr next;
   while(curr != NULL){
      next = curr->next;
      free(curr);
      curr = next;
   }
   //Dereference the pointer to set it to NULL because it was already freed
   *aList = NULL;
}
      
   
void addList(idnodeptr *listRoot, char *nname, idnodeptr *nnext){//Double pointer

   if(*listRoot == NULL){
      //Create node at root of the list
      *listRoot = (idnodeptr) malloc(sizeof(struct idnode));

      //Assign name to said node
      (*listRoot)->name =(char*) malloc(strlen(nname));
      strcpy((*listRoot)->name, nname);

      //Initialize next pointer
      (*listRoot)->next = NULL;
      printf("List item %s added\n", (*listRoot)->name);
      //Set head of list to root
      /*(*listHead) = (*listRoot);
      printf("Just added first list item;\nRoot Name: %s\nHead Name: %s\n", (*listRoot)->name, (*listHead)->name);
      if(*listHead == NULL)
      printf("And now listHead is NULL\n");*/
   }
   else{
      //printf("Working with existing list\n");
      //idnodeptr temp = NULL;
      addList(&(*listRoot)->next, nname, NULL);
      /*temp = (*listRoot);
      while( temp->next != NULL){
	 temp = temp->next;
      }
      temp->next = (idnodeptr) malloc(sizeof(struct idnode));
      temp->name = (char*) malloc(strlen(nname));
      strcpy(temp->name, nname);
      temp->next = NULL;*/
   }
   
   if(nnext != NULL){ //If there is more to add to the list
      idnodeptr listHead = NULL;
      listHead = getEnd((*listRoot));
      printf("Test, Last item in list is %s\n", listHead->name);
      listHead->next = (*nnext);
      //add logic to change head to reflect this
   }
   return;
}

idnodeptr getEnd(idnodeptr listHead){
   idnodeptr end = listHead;
   if(listHead == NULL){
      return NULL;
   }
   else if(listHead->next != NULL){
      return getEnd(listHead->next);
   }
   else {
      return end;
   }
}
/*int main(void){
   char input;
   char *newName;

   newName = (char*) malloc(256);//Some random amount
   head = theList;

   printf("(A)dd\n(P)rint\n(Q)uit");
   scanf("%c", &input);
   while(toupper(input) != 'Q'){
      switch(toupper(input)){
      case 'A':
	 printf("What name would you like to add?: ");
	 scanf("%s", newName);
	 printf("Adding list with name %s\n", newName);
	 if(head == NULL)
	    printf("Going into addList function listHead is NULL\n");
	 addList(&head, &theList, newName, NULL);
	 break;
      case 'P':
	 printList(theList);
	 break;
      case 'Q':
	 continue;
	 break;
      }
      printf("(A)dd\n(P)rint\n(Q)uit");
      scanf("\n%c", &input);
   }
   destroyList(&theList);
   return 0;
}*/
