//BinTree.h
//Header file for Binary Tree Symbol Table

#ifndef __BTREE__
#define __BTREE__


struct node {
   char *symbol; //name of the symbol
   char *kind; 
   struct node *left; //left child
   struct node *right; //right child
   struct node *pType; //Pointer to parent type in outer context
   int value; //If its a number, the the integer value
   int size; //Size of this type
   int offSet;
   char *mode; //If parameter, its mode
   struct node *next; //If parameter, the next parameter
   char *compType; //If an array type, the type of components
   int lower, upper; //Lower and upper indicies of the array
   int ARsize; //The size of all the decls and Activation Record of a procedure
   int prg_start; //The instruction counter when a procedure starts
};

struct stack_entry{
   char *name;
   struct node *tree;
};


struct stack_entry binStack[100];
extern int stack_top; //Starts with empty tree on stack

void destroy_tree(struct node *root);

int insert(char *newSymbol, struct node **tree);

void printInOrder(struct node *daList);

struct node *search(char *sSymbol, struct node *leaf);

struct node *findMax(struct node *tree);

void push(char *nName);

void pop();

void destroy_stack();

struct node *search_stack(char *sSymbol, int *offSet);

int largestOffset(struct node *currTree);

int max(int a, int b);
#endif
