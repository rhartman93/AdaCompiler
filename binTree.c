//binTree.c
//BinaryTree specification for symbol table

#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include "binTree.h"

int stack_top = 0;

void destroy_tree(struct node *root){
   if(root != NULL){ 
      //printf("Tree not null, We Goin Back In\nDestroy Left");
      destroy_tree(root->left);
      //printf("Destroy Right\n");
      destroy_tree(root->right);
      //printf("Freeing tree\n");
      free(root);
   }
   

   return;
}//End destroy_tree

int insert(char *newSymbol, struct node **tree){//Pointer to a pointer
   if(*tree == NULL){
      //printf("Adding %s to  empty tree\n", newSymbol);
      (*tree) = (struct node*) malloc(sizeof(struct node));
      (*tree)->symbol = malloc(sizeof(newSymbol) + 1);
	strcpy((*tree)->symbol, newSymbol);
      (*tree)->left = NULL;
      (*tree)->right = NULL;
      int inserted = 1;
      return inserted;
   }//If the tree you are trying to insert into is empty, create the first node
   else if(strcmp(newSymbol, (*tree)->symbol) < 0){
      //printf("Adding %s to left of %s\n", newSymbol, (*tree)->symbol);
      insert(newSymbol, &(*tree)->left);
   }
   else if(strcmp(newSymbol, (*tree)->symbol) > 0){
      //printf("Adding %s to right of %s\n", newSymbol, (*tree)->symbol);
      insert(newSymbol, &(*tree)->right);
   }
   else{
      //printf("Symbol: %s already in tree", (*tree)->symbol);
      int inserted = 0;
      return inserted;
   }
}//End insert

struct node *search(char *sSymbol, struct node *leaf){ 
//Returns pointer to node that has the search term, returns null pointer otherwise
   if(leaf){
      if(strcmp(sSymbol, leaf->symbol) == 0){
	 //printf("Thing is actually found\n");
	 return leaf;
      }
      else if(strcmp(sSymbol, leaf->symbol) < 0){
	 //printf("Symbol less than leaf\n");
	 return search(sSymbol, leaf->left);
      }
      else{
	 //printf("Symbol greater than leaf\n");
	 return search(sSymbol, leaf->right);
      }
   } 
   else{
      //printf("Symbol not found\n");
      return NULL;
   }
   return NULL;
} //end search

struct node *findMin(struct node *tree){
   
   if(!tree){   
      return NULL;
   }
   else if(tree->left){
      //printf("Recursively going to left child\n");
      return findMin(tree->left);
   }
   else{
      return tree;
   }
   
  
} //End findMin

void printInOrder(struct node *daList){
   
   if(daList == NULL){
      return;
   } else {
      printInOrder(daList->left);
      printf("\nTree item: %s - %s ", daList->symbol, daList->kind);
      if(daList->pType != NULL){
	 printf("w/ parent type %s\n", daList->pType->symbol);
      }
      if(strcmp(daList->kind, "object") == 0 || strcmp(daList->kind, "parameter") == 0){
	 printf("With offset: %d\n", daList->offSet);
      }
      if((strcmp(daList->kind, "type") || (strcmp(daList->kind, "array"))) == 0 && strcmp(daList->symbol, "exception") != 0){
	 printf("With size: %d\n", daList->size);
      }
      if(strcmp(daList->kind, "literal") == 0){
	 printf("With value: %d\n", daList->value);
      }
      printInOrder(daList->right);
   }

   return;
}

struct node *findMax(struct node *tree){
   printf("Current symbol: %s\n", tree->symbol);
   if(!tree){
      return NULL;
   }
   else if(tree->right){
      return findMax(tree->right);
   }
   else{
      return tree;
   }
} //End findMax

/*void deleteNode(int dSymbol, struct node *tree){ //Delete node with dSymbol in the tree
   struct node toDelete = search(dSymbol, tree);
   if(toDelete == NULL){
      printf("Symbol not found\n");
   }
   else if({
      
   }


   }*/
void push(char *nName){
   if(stack_top < 99){
      stack_top++;
      binStack[stack_top].tree = NULL;
      binStack[stack_top].name = malloc(sizeof(nName));
      strcpy(binStack[stack_top].name, nName);
   }
   else{
      printf("Stack Overflow\n");
   }
   return;
}

void pop(){
   if(stack_top > -1){
      //printf("Destroying current tree\n");
      destroy_tree(binStack[stack_top].tree);
      stack_top--;
   }
   else{
      printf("Stack Underflow\n");
   }
}

void destroy_stack(){
   while(stack_top > -1){
      printf("Destroying Stack[%d]\n", stack_top);
      pop();
      
   }
   return;
}

struct node *search_stack(char *sSymbol, int *offSet){
   int temp = stack_top;
   int found = 0;
   struct node *result;
   result = malloc(sizeof(struct node));
   while((temp > -1) && !found){
      result = search(sSymbol, binStack[temp].tree);
      found = (result != NULL);
      temp--;
   }

   if(found){
      *offSet = stack_top - temp - 1; //Subtracting 1 because temp is decremented by default in the loop
   }
   else{
      *offSet = -1;
   }
   return result;
}

int largestOffset(struct node *currTree){
   if(currTree != NULL){
      int overallMax;
      int maxLeft = largestOffset(currTree->left);
      int maxRight = largestOffset(currTree->right);
      
      overallMax = max(maxLeft, maxRight);
      if( !(strcmp(currTree->kind, "parameter") == 0)){
	 overallMax = max(overallMax, currTree->offSet + currTree->size);
      }
      return overallMax;
   }
   else{
      return -1;
   }
      
}

int max(int a, int b){
   if (a > b){
      return a;
   }
   else if (b > a){
      return b;
   }
   else{
      return a; //If the numbers are the same return the first one
   }
}
