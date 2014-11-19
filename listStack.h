
#ifndef __PLIST__
#define __PLIST__
struct patch {
   int line;
   int jump;
   struct patch *next;
};

/*struct toPatch {
   int line;
   struct toPatch *next;
   };*/

struct patch *toPatchStack[50]; //Stack
extern int patch_top;

void pAppend(struct patch **root, int currLine);
void tpAppend(struct patch **root, int currLine, int currJump);
void printPatch(struct patch *root, int final);
void destroyPatch(struct patch **root);
void pPush();
void pPop();
struct patch *sort( struct patch *start );
struct patch *list_switch( struct patch *l1, struct patch *l2 );
void addJump(struct patch *root, int line, int jump);

#endif
