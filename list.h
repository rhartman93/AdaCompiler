//list.h
//Header file for linked list


typedef struct idnode {
   char *name;
   struct idnode *next;
} *idnodeptr;

void printList(idnodeptr list);

void destroyList(idnodeptr *aList);

void addList(idnodeptr *listRoot, char *nname, idnodeptr *nnext);

idnodeptr getEnd(idnodeptr listHead);
