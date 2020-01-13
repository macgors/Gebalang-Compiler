%{

// #include "compiler.hpp"
#include <string>
#include <iostream>
#include <fstream>
#include <map>
#include <vector>
#include <typeinfo>
#include<bits/stdc++.h> 
#include <stack> 
#include "parser.tab.h"
#include <cstdlib>

using namespace std;
extern int yylex();
extern int yylineno;
extern FILE *yyin;
int yyerror(const string str);
void myyerror(string, char* );
bool isError = false;

enum Type {
	ARRAY, IDENTIFIER, NUMBER
};


typedef struct {
	Type type;
	string name;
    bool isInit, isIterator, isTable;
	long long int memoryOffsetBegin, memoryLen, firstIndexInTable, lastIndexInTable;
} Variable; 
typedef struct {
    long long int beginCondCheckIndex;
    long long int jumpIndex;
    } Jump;

long long int startMemoryIndex = 10;
long long int memoryIndex = startMemoryIndex;
long long int commandIndex = 0;
vector<string> code;
map<string, Variable> variables; 
stack <Jump> jumps; //holds the index of the jump, and the beging of cond checking
stack <Jump> jumpsTest;

stack <long long int> doWhilesBegin;
stack <char*> iterators;
bool used9 = false;//ptr
bool used7 = false;//ptr
bool used6 = false;//ptr
bool used5 = false;// -1 for shifts
bool used4 = false; //+1 for shifts


void addCode(string);
void declareSimpleVariable(char*);
void declareArray(char*,char*,char*);
void store(valVar);
void SudoStore(valVar);
void declareIterator(char*);

//expressions
void constructValue(long long int);
void handleExpresionVal(valVar);
void handleExpresionPLUS(valVar,valVar);
void handleExpresionMINUS(valVar,valVar);
void handleExpresionTIMES(valVar, valVar);
void handleExpresionDIV(valVar, valVar);
void handleExpresionMOD(valVar, valVar);

//conditions
void handleCondEq(valVar, valVar);
void handleCondNeq(valVar, valVar);
void handleCondLe(valVar, valVar);
void handleCondGe(valVar, valVar);
void handleCondLeq(valVar, valVar);
void handleCondGeq(valVar, valVar);
//for shifts
void setUp4ifNeeded();
void setUp5ifNeeded();

%}

%define parse.error verbose

%code requires {
    enum TypeValVar {
	PTR, IDE, VAL
    };
    struct valVar {
    TypeValVar type;
    long long int x;
    char* name;
    };
   
}
%token <str> num
%token <str> DECLARE _BEGIN END IF THEN ELSE ENDIF
%token <str> WHILE DO ENDWHILE ENDDO FOR FROM ENDFOR
%token <str> COLON WRITE READ pidentifier SEMICOLON COMMA TO DOWNTO
%token <str> LB RB ASSIGN EQ LE GE LEQ GEQ NEQ PLUS MINUS TIMES DIV MOD

%type <vv> value
%type <vv> identifier

%union{
    char* str;
    long long int num;
    valVar vv;
}

%%
program:        DECLARE declarations _BEGIN commands END                        {addCode("HALT");}
              | _BEGIN commands END                                             {addCode("HALT");}
              ;

declarations:   declarations COMMA pidentifier                                  {declareSimpleVariable($3);  }
              | declarations COMMA pidentifier LB num COLON num RB              {declareArray($3,$5,$7);     }
              | pidentifier                                                     {declareSimpleVariable($1);  }
              | pidentifier LB num COLON num RB                                 { declareArray($1,$3,$5);   }
              ;

commands:       commands command                                                {}
              | command                                                         {}
              ;

command:        identifier ASSIGN expression SEMICOLON                          {store($1);}
              | IF condition THEN commands                                      { code.at(jumpsTest.top().jumpIndex) += to_string(commandIndex+1); jumpsTest.pop(); 
                                                                                  Jump j; j.jumpIndex = commandIndex; jumpsTest.push(j); addCode("JUMP ");   }
                ELSE commands ENDIF                                             { code.at(jumpsTest.top().jumpIndex) += to_string(commandIndex); jumpsTest.pop(); }
              
              | IF condition THEN commands ENDIF                                { code.at(jumpsTest.top().jumpIndex) += to_string(commandIndex); jumpsTest.pop(); }
              | WHILE condition DO commands ENDWHILE                            { addCode("JUMP "+to_string(jumpsTest.top().beginCondCheckIndex)); 
                                                                                  code.at(jumpsTest.top().jumpIndex) += to_string(commandIndex); jumpsTest.pop(); 
                                                                                }
              | DO                                                              { doWhilesBegin.push(commandIndex);}
                commands WHILE condition ENDDO                                  { addCode("JUMP " +to_string(doWhilesBegin.top())); doWhilesBegin.pop();
                                                                                  code.at(jumpsTest.top().jumpIndex) += to_string(commandIndex); jumpsTest.pop(); 
                                                                                }

              | FOR pidentifier FROM value TO value DO                          { declareIterator($2);  handleExpresionVal($4); 
                                                                                  valVar lim; lim.type = IDE; lim.x = memoryIndex; 
                                                                                  valVar ite; ite.name= $2; ite.type = IDE; ite.x = variables.find($2)->second.memoryOffsetBegin; 
                                                                                  store(ite); 
                                                                                  handleExpresionVal($6); 
                                                                                  addCode("STORE " + to_string(memoryIndex)); 
                                                                                  handleCondLeq(ite,lim); 
                                                                                  memoryIndex++;
                                                                                }
                commands ENDFOR                                                 { valVar ite; ite.type = IDE; 
                                                                                  ite.x = variables.find(iterators.top())->second.memoryOffsetBegin; 
                                                                                  addCode("LOAD " + to_string(ite.x)); addCode("INC");
                                                                                  SudoStore(ite);
                                                                                  addCode("JUMP "+to_string(jumpsTest.top().beginCondCheckIndex)); 
                                                                                  //cout<<jumpsTest.top().jumpIndex<<" asda "<<jumpsTest.top().jumpIndex<<endl;
                                                                                  code.at(jumpsTest.top().jumpIndex) += to_string(commandIndex); jumpsTest.pop(); 
                                                                                  variables.erase(iterators.top());
                                                                                  iterators.pop();
                                                                                }

              | FOR pidentifier FROM value DOWNTO value DO                      { declareIterator($2);  handleExpresionVal($4);
                                                                                  valVar lim; lim.type = IDE; lim.x = memoryIndex; 
                                                                                  valVar ite; ite.type = IDE; ite.x = variables.find($2)->second.memoryOffsetBegin; ite.name= $2;
                                                                                  store(ite);
                                                                                    
                                                                                  handleExpresionVal($6);
                                                                                  
                                                                                  addCode("STORE " + to_string(memoryIndex)); memoryIndex++;
                                                                                  handleCondGeq(ite,lim);
                                                                                  
                                                                                  }
                commands ENDFOR                                                 { valVar ite; ite.type = IDE; 
                                                                                  ite.x = variables.find(iterators.top())->second.memoryOffsetBegin; 
                                                                                  addCode("LOAD " + to_string(ite.x)); addCode("DEC");
                                                                                  store(ite);
                                                                                  addCode("JUMP "+to_string(jumpsTest.top().beginCondCheckIndex)); 
                                                                                  code.at(jumpsTest.top().jumpIndex) += to_string(commandIndex); jumpsTest.pop();
                                                                                  variables.erase(iterators.top());
                                                                                  iterators.pop();}
              | READ identifier SEMICOLON                                       { addCode("GET");
                                                                                  store($2);
                                                                                }
              | WRITE value SEMICOLON                                           {handleExpresionVal($2); addCode("PUT");}
              ;

expression:     value                                                           { handleExpresionVal($1);}
              | value PLUS value                                                { handleExpresionPLUS($1,$3);}
              | value MINUS value                                               { handleExpresionMINUS($1,$3); }
              | value TIMES value                                               { handleExpresionTIMES($1, $3);}
              | value DIV value                                                 { handleExpresionDIV($1, $3);}
              | value MOD value                                                 { handleExpresionMOD($1, $3);}
              ;

condition:      value EQ value                                                  {handleCondEq($1,$3);}
              | value NEQ value                                                 {handleCondNeq($1,$3);}
              | value LE value                                                  {handleCondLe($1,$3);}
              | value GE value                                                  {handleCondGe($1,$3);}
              | value LEQ value                                                 {handleCondLeq($1,$3);}
              | value GEQ value                                                 {handleCondGeq($1,$3);}
              ;

value:          num                                                             {
                                                                                valVar res; res.type = VAL; res.x = atoll($1);
                                                                                $$ = res;
                                                                                }
              | identifier                                                      {  
                                                                                
                                                                                if($1.type == IDE){
                                                                                        if(!variables.find($1.name)->second.isInit) myyerror("Using uninitialized variable ",$1.name);
                                                                                } 
                                                                                $$ = $1;
                                                                                        
                                                                                }
              ;

identifier:     pidentifier                                                     {   if (variables.find($1) == variables.end()){ myyerror("Undeclared variable: ",$1);} 
                                                                                    if(variables.find($1)->second.type != IDENTIFIER) myyerror("Illegal variable-style usage of array ",$1);
                                                                                    valVar adr; adr.type = IDE; adr.x = variables.find($1)->second.memoryOffsetBegin; adr.name = $1;
                                                                                    $$ =  adr;
                                                                                    
                                                                                }
              | pidentifier LB pidentifier RB                                   {if (variables.find($1) == variables.end() || variables.find($3) == variables.end()){ myyerror("Undeclared variable ",$3);}
                                                                                if(!variables.find($3)->second.isInit&& !variables.find($3)->second.isIterator) myyerror("Using uninitialized variable ",$3);
                                                                                if(variables.find($1)->second.type != ARRAY) myyerror("Illegal array-style usage of variable ",$1);
                                                                                if(variables.find($3)->second.type != IDENTIFIER) myyerror("Array used like non-array type ",$3);
                                                                                Variable i = variables.find($1)->second;
                                                                                constructValue(i.memoryOffsetBegin - i.firstIndexInTable);

                                                                                long long int i1 = variables.find($3)->second.memoryOffsetBegin;
                                                                                
                                                                             
                                                                                addCode("ADD " + to_string(i1));
                                                                                valVar res; res.type=PTR;
                                                                                if(used6 && used7 && used9) yyerror("FATAL ERROR, CONTACT A GOD OF YOUR CHOICE.");
                                                                                if(!used9){
                                                                                
                                                                                    addCode("STORE 9");
                                                                                    res.x = 9;
                                                                                    used9 = true;
                                                                                }
                                                                                else if(!used7){
                                                                                
                                                                                    addCode("STORE 7");
                                                                                    res.x = 7;
                                                                                    used7 = true;
                                                                                } 
                                                                                else if(!used6){
                                                                                
                                                                                    addCode("STORE 6");
                                                                                    res.x = 6;
                                                                                    used6 = true;
                                                                                }
                                                                                
                                                                               
                                                                                $$ = res;
                                                                                

                                                                                }
              | pidentifier LB num RB                                           {  if (variables.find($1) == variables.end()){ myyerror("Undeclared variable ", $1);}
                                                                                  Variable var  = variables.find($1)->second;
                                                                                  if(variables.find($1)->second.type != ARRAY) myyerror("Illegal array-style usage of variable ",$1);
                                                                               
                                                                                  if(var.lastIndexInTable < stoll($3) || var.firstIndexInTable > stoll($3) ) myyerror("Index outside declared array ", $1);
                                                                                  valVar adr; adr.type = IDE; adr.x = var.memoryOffsetBegin + ( stoll($3) - var.firstIndexInTable);
                                                                                   adr.name = $1;
                                                                                  $$ =  adr;
                                                                                

                                                                                 }
              ;

%%



void declareSimpleVariable(char* _name){

    // Type type;
	// string name;
    // bool isInit, isIterator, isTable;
	// long long int memoryOffsetBegin, memoryLen, firstIndexInTable, lastIndexInTable;
   if (variables.find(_name) != variables.end()){
      myyerror("Repeated variable declaration: ", _name);
    }   
    Variable var;
    var.type = IDENTIFIER;
    var.name = _name;
    var.isInit = false;
    var.isIterator = false;
    var.isTable = false;
    var.memoryOffsetBegin = memoryIndex;
    var.memoryLen = 1;
    variables.insert(make_pair(_name, var));
    memoryIndex += var.memoryLen;
}
void declareIterator(char* _name){

    // Type type;
	// string name;
    // bool isInit, isIterator, isTable;
	// long long int memoryOffsetBegin, memoryLen, firstIndexInTable, lastIndexInTable;
   if (variables.find(_name) != variables.end()){        
        myyerror("Repeated variable declaration: ", _name);
    }   
    Variable var;
    var.type = IDENTIFIER;
    var.name = _name;
    var.isInit = true;
    var.isIterator = true;
    var.isTable = false;
    var.memoryOffsetBegin = memoryIndex;
    var.memoryLen = 1;
    variables.insert(make_pair(_name, var));
    memoryIndex += var.memoryLen;
    iterators.push(_name);
}


void declareArray(char* _name, char* index1, char* index2){
    
  if (variables.find(_name) != variables.end()){
         myyerror("Repeated variable declaration: ", _name);
    }   
  if(stoll(index1)>stoll(index2)){
      myyerror("Left index > Rigth index in array ", _name);
  }
    Variable var;
    var.type = ARRAY;
    var.name = _name;
    var.isInit = true;
    var.isIterator = false;
    var.isTable = true;
    var.memoryOffsetBegin = memoryIndex;
    var.memoryLen = stoll(index2) - stoll(index1) + 1;
    var.lastIndexInTable = stoll(index2);
    var.firstIndexInTable = stoll(index1);
    variables.insert(make_pair(_name, var));
    memoryIndex += var.memoryLen;
}
void store(valVar adr){  
    if(adr.type == IDE){        
         if(variables.find(adr.name)->second.isIterator && !variables.find(adr.name)->second.isInit ) myyerror("Illegal modification of local iterator ",adr.name);
         addCode("STORE " + to_string(adr.x));
         variables.find(adr.name)->second.isInit = true;
         }
         
    else if (adr.type == PTR) addCode("STOREI " + to_string(adr.x));
    used6 = false;
    used7 = false;
    used9 = false;
}
void SudoStore(valVar adr){
    
    if(adr.type == IDE){
         addCode("STORE " + to_string(adr.x));
         variables.find(adr.name)->second.isInit = true;
         }
    else if (adr.type == PTR) addCode("STOREI " + to_string(adr.x));
    used6 = false;
    used7 = false;
    used9 = false;
}
void constructValue(long long int x){
    // O(log n), works for negative.
    addCode("SUB 0 ");
    if(x == 0){  return;}
    if(abs(x) < 35){
        if(x >0){
            for(long long int i = 0; i < abs(x); i++ ){
                addCode("INC");
            }
        }
        else{
            for(long long int i = 0; i < abs(x); i++ ){
                addCode("DEC");
            }
        }
        return;
    }
    
    setUp4ifNeeded();
    
    unsigned long long int x1= abs(x);
    string str;
    for( ; x1 > 0 ; x1 /= 2 ) str += char( x1%2 + '0' ) ;
    addCode("SUB 0");
    reverse(str.begin(),str.end());
    for(unsigned int i= 0;i<str.length()-1;i++){
        if(str[i] == '1'){
            if(x>0) addCode("INC");
            if(x<0) addCode("DEC");
            addCode("SHIFT 4");
        }
        else{
            addCode("SHIFT 4");
        }
    }
    if(str[str.length()-1] == '1') {
        if(x>0) addCode("INC");
        if(x<0) addCode("DEC");
    }

    
}

void handleExpresionVal(valVar a){ //PUT WHATEVERS INSIDE INTO ACC, THE WAY GOD INTENDED
    if(a.type == IDE){addCode("LOAD " + to_string(a.x));}
    else if(a.type == PTR){addCode("LOADI " + to_string(a.x));}
    else if(a.type == VAL){constructValue(a.x);}
    else if(a.type == PTR){
        if(a.x == 7) used7 = false;
        if(a.x == 6 ) used6 = false;
        if(a.x == 9) used9 = false;
    }
}
void handleExpresionPLUS(valVar a,valVar b){
    if(a.type == VAL && b.type == VAL) constructValue(a.x + b.x);
    if(a.type == VAL && b.type == IDE){ constructValue(a.x); addCode("ADD " + to_string(b.x));    }
    if(b.type == VAL && a.type == IDE){ constructValue(b.x); addCode("ADD " + to_string(a.x));    }
    if(a.type == IDE && b.type == IDE) {addCode("LOAD " + to_string(b.x)); addCode("ADD " + to_string(a.x)); }
    if(a.type == PTR && b.type == IDE) {addCode("LOADI "+to_string(a.x)); addCode("ADD "+ to_string(b.x)); }
    if(b.type == PTR && a.type == IDE) {addCode("LOADI "+to_string(b.x)); addCode("ADD "+ to_string(a.x)); }
    if(a.type == PTR && b.type == PTR){
        addCode("LOADI "+to_string(a.x)); 
        addCode("STORE 1");
        addCode("LOADI "+to_string(b.x)); 
        addCode("ADD 1");
        
    }
    if(a.type == VAL && b.type == PTR){
        constructValue(a.x);
        addCode("STORE 1");
        addCode("LOADI "+to_string(b.x)); 
        addCode("ADD 1");
    }
     if(b.type == VAL && a.type == PTR){
        constructValue(b.x);
        addCode("STORE 1");
        addCode("LOADI "+to_string(a.x)); 
        addCode("ADD 1");
    } 
      used6 = false;
    used7 = false;
    used9 = false;
}
void handleExpresionMINUS(valVar a,valVar b){
    if(a.type == VAL && b.type == VAL) constructValue(a.x - b.x);
    if(a.type == VAL && b.type == IDE){ constructValue(a.x); addCode("SUB " + to_string(b.x));    }
    if(b.type == VAL && a.type == IDE){
         constructValue(b.x); 
         addCode("STORE 1");
         addCode("LOAD " + to_string(a.x)); 
         addCode("SUB 1"); 
        }
    if(a.type == IDE && b.type == IDE) {addCode("LOAD " + to_string(a.x)); addCode("SUB " + to_string(b.x)); }
    if(a.type == PTR && b.type == IDE) {addCode("LOADI "+to_string(a.x)); addCode("SUB "+ to_string(b.x)); }
    if(b.type == PTR && a.type == IDE) {addCode("LOADI "+to_string(b.x)); addCode("SUB "+ to_string(a.x)); }
    if(a.type == PTR && b.type == PTR){
        addCode("LOADI "+to_string(b.x)); 
        addCode("STORE 1");
        addCode("LOADI "+to_string(a.x)); 
        addCode("SUB 1");
    }
    if(a.type == VAL && b.type == PTR){
        constructValue(a.x);
        addCode("STORE 1");
        addCode("LOADI "+to_string(b.x)); 
        addCode("SUB 1");
    }
     if(b.type == VAL && a.type == PTR){
        constructValue(b.x);
        addCode("STORE 1");
        addCode("LOADI "+to_string(a.x)); 
        addCode("SUB 1");
    }
    used6 = false;
    used7 = false;
    used9 = false;
}

void handleExpresionTIMES(valVar a, valVar b){
    // 2: a. 3:b, 1: res, 8: sign flag
    if(a.type == VAL && b.type == VAL){
        constructValue(a.x*b.x);
        return;
    }
    addCode("SUB 0");
    addCode("STORE 8");
    if(a.type == VAL){
        if(a.x<0){
            addCode("INC");
            addCode("STORE 8");
        }
        constructValue(abs(a.x));
        addCode("STORE 2");
    }
  

     if(a.type == IDE){
        addCode("LOAD " + to_string(a.x));
        addCode("STORE 2");
        addCode("JNEG "+to_string(commandIndex+2));
        addCode("JUMP " +to_string(commandIndex + 7)); // do konca JGEN
        addCode("SUB " + to_string(a.x));
        addCode("SUB " + to_string(a.x));
        addCode("STORE 2");
        addCode("LOAD 8");
        addCode("INC");
        addCode("STORE 8");
    }
    if(a.type == PTR){
        addCode("LOADI " + to_string(a.x));
        addCode("STORE 2");
        addCode("JNEG "+to_string(commandIndex+2));
        addCode("JUMP " +to_string(commandIndex + 7)); // do konca JGEN
        addCode("SUB 2");
        addCode("SUB 2");
        addCode("STORE 2");
        addCode("LOAD 8");
        addCode("INC");
        addCode("STORE 8");
    }
    if(b.type == VAL){
        if(b.x<0){
            addCode("LOAD 8");
            addCode("INC");
            addCode("STORE 8");
        }
        constructValue(abs(b.x));
        addCode("STORE 3");
    }
     if(b.type == IDE){
       addCode("LOAD " + to_string(b.x));
       addCode("STORE 3");
        addCode("JNEG "+to_string(commandIndex+2));
        addCode("JUMP " +to_string(commandIndex + 7)); // do konca JGEN
        addCode("SUB " + to_string(b.x));
        addCode("SUB " + to_string(b.x));
        addCode("STORE 3");
        addCode("LOAD 8");
        addCode("INC");
        addCode("STORE 8");
    }
    if(b.type == PTR){
         addCode("LOADI " + to_string(b.x));
        addCode("STORE 3");
        addCode("JNEG "+to_string(commandIndex+2));
        addCode("JUMP " +to_string(commandIndex + 7)); // do konca JGEN
        addCode("SUB 3");
        addCode("SUB 3");
        addCode("STORE 3");
        addCode("LOAD 8");
        addCode("INC");
        addCode("STORE 8");
    }

    setUp4ifNeeded();
    setUp5ifNeeded();
    addCode("SUB 0");
    addCode("STORE 1"); // 1 <-- result
    ////END SETUP, fun begins:
    long long int start = commandIndex +1;
    addCode("JUMP "+to_string(commandIndex+15) + " #to end while");
    addCode("LOAD 2");
    addCode("SHIFT 5");
    addCode("SHIFT 4");
    addCode("SUB 2");
    addCode("JZERO "+to_string(commandIndex + 4) +"# to za ifem" );
    addCode("LOAD 1");
    addCode("ADD 3");
    addCode("STORE 1");
    addCode("LOAD 2 #ZA IFEM");
    addCode("SHIFT 5");
    addCode("STORE 2");
    addCode("LOAD 3");
    addCode("ADD 0");
    addCode("STORE 3");
    addCode("LOAD 2 #endwhile");
    addCode("JZERO "+to_string(commandIndex +2));
    addCode("JUMP " + to_string(start));
    //
    addCode("LOAD 8");
    addCode("SUB 4");
    addCode("JZERO " +to_string(commandIndex+3));
    addCode("LOAD 1");
    addCode("JUMP "+to_string(commandIndex+4));
    addCode("LOAD 1");
    addCode("SUB 1");
    addCode("SUB 1");
     
    used6 = false;
    used7 = false;
    used9 = false;
    
}

void handleExpresionDIV(valVar a, valVar b){
        // @1 : result == 0, @2 : remain= a value, @3 - scaled_divisor = b, @6 - multiple = 1, @8-sign flag, @7-a (dividend) value
     if(a.type == VAL && b.type == VAL){
         if(b.x == 0) {constructValue(0); return ;}
        constructValue(a.x/b.x);
        return;
    }
    long long int BzeroJumpIndex = -1;
    addCode("SUB 0");
    addCode("STORE 8");
    if(b.type == VAL){
        if(b.x<0){
            addCode("LOAD 8");
            addCode("INC");
            addCode("STORE 8");
        }
        constructValue(abs(b.x));
        addCode("STORE 3");
    }
     if(b.type == IDE){
       addCode("LOAD " + to_string(b.x));
       BzeroJumpIndex = commandIndex;
       addCode("JZERO ########################");
       addCode("STORE 3");
        addCode("JNEG "+to_string(commandIndex+2));
        addCode("JUMP " +to_string(commandIndex + 7)); // do konca JGEN
        addCode("SUB " + to_string(b.x));
        addCode("SUB " + to_string(b.x));
        addCode("STORE 3");
        addCode("LOAD 8");
        addCode("INC");
        addCode("STORE 8");
    }
    if(b.type == PTR){
        addCode("LOADI " + to_string(b.x));
        BzeroJumpIndex = commandIndex;
        addCode("JZERO ########################");
        addCode("STORE 3");
        addCode("JNEG "+to_string(commandIndex+2));
        addCode("JUMP " +to_string(commandIndex + 7)); // do konca JGEN
        addCode("SUB 3");
        addCode("SUB 3");
        addCode("STORE 3");
        addCode("LOAD 8");
        addCode("INC");
        addCode("STORE 8");
    }

    if(a.type == VAL){
        if(a.x<0){
            addCode("INC");
            addCode("STORE 8");
        }
        constructValue(abs(a.x));
        addCode("STORE 2");
    }
  

     if(a.type == IDE){
        addCode("LOAD " + to_string(a.x));
        addCode("STORE 2");
        addCode("JNEG "+to_string(commandIndex+2));
        addCode("JUMP " +to_string(commandIndex + 7)); // do konca JGEN
        addCode("SUB " + to_string(a.x));
        addCode("SUB " + to_string(a.x));
        addCode("STORE 2");
        addCode("LOAD 8");
        addCode("INC");
        addCode("STORE 8");
    }
    if(a.type == PTR){
        addCode("LOADI " + to_string(a.x));
        addCode("STORE 2");
        addCode("JNEG "+to_string(commandIndex+2));
        addCode("JUMP " +to_string(commandIndex + 7)); // do konca JGEN
        addCode("SUB 2");
        addCode("SUB 2");
        addCode("STORE 2");
        addCode("LOAD 8");
        addCode("INC");
        addCode("STORE 8");
    }
    
    setUp4ifNeeded();
    setUp5ifNeeded();
    addCode("SUB 0");
    addCode("STORE 1"); // 1 <-- result
    addCode("INC");
    addCode("STORE 6");
    addCode("LOAD 2");
    addCode("STORE 7");
    // //setup endded now:
    // addCode("LOAD 1 #setupended");
    // addCode("PUT");
    // addCode("LOAD 2");
    // addCode("PUT");
    // addCode("LOAD 3");
    // addCode("PUT");
    // addCode("LOAD 4");
    // addCode("PUT");
    // addCode("LOAD 5");
    // addCode("PUT");
    // addCode("LOAD 6");
    // addCode("PUT");
    // addCode("LOAD 7");
    // addCode("PUT");
    // addCode("LOAD 8");
    // addCode("PUT");
    // @1 : result == 0, @2 : remain= a value, @3 - scaled_divisor = b, @6 - multiple = 1, @8-sign flag, @7-a (dividend) value
    long long int startWhile = commandIndex;
    addCode("LOAD 7");
    addCode("SUB 3");
    addCode("JPOS "+to_string(commandIndex+2));
    addCode("JUMP " +to_string(commandIndex +8));
    addCode("LOAD 3");
    addCode("SHIFT 4");
    addCode("STORE 3");
    addCode("LOAD 6");
    addCode("SHIFT 4");
    addCode("STORE 6");
    addCode("JUMP " + to_string(startWhile));
    startWhile = commandIndex;
    addCode("LOAD 2");
    addCode("SUB 3");
    addCode("JNEG "+to_string(commandIndex+7));
    addCode("LOAD 2");
    addCode("SUB 3");
    addCode("STORE 2");
    addCode("LOAD 1");
    addCode("ADD 6");
    addCode("STORE 1");
    addCode("LOAD 3");
    addCode("SHIFT 5");
    addCode("STORE 3");
    addCode("LOAD 6");
    addCode("SHIFT 5");
    addCode("STORE 6");
    addCode("JZERO " +to_string(commandIndex+2));
    addCode("JUMP " + to_string(startWhile));
    /// now figure out sign
    addCode("LOAD 8");
    addCode("DEC");
    addCode("JZERO " + to_string(commandIndex+3));
    addCode("LOAD 1");
    addCode("JUMP " +to_string(commandIndex + 11));// wyjdz
    addCode("LOAD 2");
    addCode("JZERO " +to_string(commandIndex+6) + "#JEZRO MODULo"); 
    addCode("LOAD 1");
    addCode("SUB 1");
    addCode("SUB 1");
    addCode("DEC ");
    addCode("JUMP " + to_string(commandIndex+4) );
    addCode("LOAD 1");
    addCode("SUB 1");
    addCode("SUB 1");
    if(BzeroJumpIndex != -1) code.at(BzeroJumpIndex) = "JZERO "+ to_string(commandIndex ) + "#B ZERO";

    used6 = false;
    used7 = false;
    used9 = false;
    
}
void handleExpresionMOD(valVar a, valVar b){
        // @1 : result == 0, @2 : remain= a value, @3 - scaled_divisor = b, @6 - multiple = 1, @8-sign flag, @7-a (dividend) value
        // if a<0 [8]++; if b<0 [8] +=2;
     if(a.type == VAL && b.type == VAL){
         if(b.x == 0) {constructValue(0); return ;}
         
        constructValue((a.x % b.x + b.x) %b.x);
        return;
    }
    long long int BzeroJumpIndex = -1;
    addCode("SUB 0");
    addCode("STORE 8");
    if(b.type == VAL){
        if(b.x<0){
            addCode("LOAD 8");
            addCode("INC");
            addCode("INC");
            addCode("STORE 8");
        }
        constructValue(abs(b.x));
        addCode("STORE 3");
    }
     if(b.type == IDE){
       addCode("LOAD " + to_string(b.x));
       BzeroJumpIndex = commandIndex;
       addCode("JZERO ########################");
       addCode("STORE 3");
        addCode("JNEG "+to_string(commandIndex+2));
        addCode("JUMP " +to_string(commandIndex + 8)); // do konca JGEN
        addCode("SUB " + to_string(b.x));
        addCode("SUB " + to_string(b.x));
        addCode("STORE 3");
        addCode("LOAD 8");
        addCode("INC");
        addCode("INC");
        addCode("STORE 8");
    }
    if(b.type == PTR){
        addCode("LOADI " + to_string(b.x));
        BzeroJumpIndex = commandIndex;
        addCode("JZERO ########################");
        addCode("STORE 3");
        addCode("JNEG "+to_string(commandIndex+2));
        addCode("JUMP " +to_string(commandIndex + 8)); // do konca JGEN
        addCode("SUB 3");
        addCode("SUB 3");
        addCode("STORE 3");
        addCode("LOAD 8");
        addCode("INC");
        addCode("INC");
        addCode("STORE 8");
    }

    if(a.type == VAL){
        addCode("LOAD 8");
        addCode("INC");
        addCode("STORE 8");
        constructValue(abs(a.x));
        addCode("STORE 2");
    }
  

     if(a.type == IDE){
        addCode("LOAD " + to_string(a.x));
        addCode("STORE 2");
        addCode("JNEG "+to_string(commandIndex+2));
        addCode("JUMP " +to_string(commandIndex + 7)); // do konca JGEN
        addCode("SUB " + to_string(a.x));
        addCode("SUB " + to_string(a.x));
        addCode("STORE 2");
        addCode("LOAD 8");
        addCode("INC");
        addCode("STORE 8");
        
    }
    if(a.type == PTR){
        addCode("LOADI " + to_string(a.x));
        addCode("STORE 2");
        addCode("JNEG "+ to_string(commandIndex+2));
        addCode("JUMP " + to_string(commandIndex + 7)); // do konca JGEN
        addCode("SUB 2");
        addCode("SUB 2");
        addCode("STORE 2");
         addCode("LOAD 8");
        addCode("INC");
        addCode("STORE 8");
        
    }
    
    setUp4ifNeeded();
    setUp5ifNeeded();
    addCode("SUB 0");
    addCode("STORE 1"); // 1 <-- result
    addCode("INC");
    addCode("STORE 6");
    addCode("LOAD 2");
    addCode("STORE 7");
   
    // @1 : result == 0, @2 : remain= a value, @3 - scaled_divisor = b, @6 - multiple = 1, @8-sign flag, @7-a (dividend) value
    long long int startWhile = commandIndex;
    addCode("LOAD 7");
    addCode("SUB 3");
    addCode("JPOS "+to_string(commandIndex+2));
    addCode("JUMP " +to_string(commandIndex +8));
    addCode("LOAD 3");
    addCode("SHIFT 4");
    addCode("STORE 3");
    addCode("LOAD 6");
    addCode("SHIFT 4");
    addCode("STORE 6");
    addCode("JUMP " + to_string(startWhile));
    startWhile = commandIndex;
    addCode("LOAD 2");
    addCode("SUB 3");
    addCode("JNEG "+to_string(commandIndex+7));
    addCode("LOAD 2");
    addCode("SUB 3");
    addCode("STORE 2");
    addCode("LOAD 1");
    addCode("ADD 6");
    addCode("STORE 1");
    addCode("LOAD 3");
    addCode("SHIFT 5");
    addCode("STORE 3");
    addCode("LOAD 6");
    addCode("SHIFT 5");
    addCode("STORE 6");
    addCode("JZERO " +to_string(commandIndex+2));
    addCode("JUMP " + to_string(startWhile));
    handleExpresionVal(b);
    addCode("STORE 3"); //store b -> 3
    /// now figure out sign
    addCode("LOAD 8"); 
    addCode("JZERO " + to_string(commandIndex + 15)); //to end(load 1)
    addCode("DEC");
    addCode("JZERO " + to_string(commandIndex + 10)); //to a-,b+
    addCode("DEC");
    addCode("JZERO " + to_string(commandIndex + 5)); //to a+,b-
    //a-, b-, zaneguj mod
    addCode("LOAD 2");
    addCode("SUB 2");
    addCode("SUB 2");
    addCode("JUMP " + to_string(commandIndex + 8)); //to end
    // a+, b-
    addCode("LOAD 2");
    addCode("ADD 3");
    addCode("JUMP " + to_string(commandIndex + 5)); //to end
    // a-,b+
    addCode("LOAD 3");
    addCode("SUB 2");
    addCode("JUMP " + to_string(commandIndex + 2)); //to end
    addCode("LOAD 2");
    //end
    if(BzeroJumpIndex != -1) code.at(BzeroJumpIndex) = "JZERO "+ to_string(commandIndex ) + " #B==ZERO";

    used6 = false;
    used9 = false;
    used7 = false;
    
}


void setUp4ifNeeded(){
     if(!used4){
            addCode("SUB 0");
            used4 = true;
            addCode("INC");
            addCode("STORE 4");
        }

}
void setUp5ifNeeded(){
    if(!used5){
            addCode("SUB 0");
            used5 = true;
            addCode("DEC");
            addCode("STORE 5");
        }
}

void handleCondEq(valVar a, valVar b){
    Jump j; j.beginCondCheckIndex = commandIndex;
    handleExpresionMINUS(a,b);
    addCode("JZERO "+ to_string(commandIndex+2)); //true
    j.jumpIndex = commandIndex;
    addCode("JUMP ");
    jumpsTest.push(j);
}
void handleCondNeq(valVar a, valVar b){
    Jump j; j.beginCondCheckIndex = commandIndex;
    handleExpresionMINUS(a,b);
    j.jumpIndex = commandIndex;
    addCode("JZERO "); //false
    jumpsTest.push(j);
}
void handleCondLe(valVar a, valVar b){
    Jump j; j.beginCondCheckIndex = commandIndex;
    handleExpresionMINUS(b,a);
    addCode("JPOS "+ to_string(commandIndex+2));
    j.jumpIndex = commandIndex;
    addCode("JUMP ");
    jumpsTest.push(j);
}
void handleCondGe(valVar a, valVar b){
    Jump j; j.beginCondCheckIndex = commandIndex;
    handleExpresionMINUS(a,b);
    addCode("JPOS "+ to_string(commandIndex+2)); //true
    j.jumpIndex = commandIndex;
    addCode("JUMP ");
    jumpsTest.push(j);
}
void handleCondLeq(valVar a, valVar b){
    Jump j; j.beginCondCheckIndex = commandIndex;
    handleExpresionMINUS(b,a);
    j.jumpIndex = commandIndex;
    //cout<<commandIndex<<endl;
    addCode("JNEG "); //false
    jumpsTest.push(j);
   // jumpsTest.push(j);
    
}
void handleCondGeq(valVar a, valVar b){
    Jump j; j.beginCondCheckIndex = commandIndex;
    handleExpresionMINUS(a,b);
    j.jumpIndex = commandIndex;
    addCode("JNEG "); //false
    jumpsTest.push(j);
}

/// \\\\\////


void addCode(string s){
   // cout<<s<<endl;
    code.push_back(s);
    commandIndex++;
}
void printCode(string filename){
    ofstream out_code(filename);
	unsigned long long int i;
	for(i = 0; i < code.size(); i++)
        out_code << code.at(i) << endl;
}

int yyerror(string err) {
    cout << "\e[1m\x1B[31m[ERROR]\e[0m \e[1m[LINE " << yylineno << "] \e[1m\x1B[31m" << err << ".\e[0m\n" << endl;
   exit(1);
}
void myyerror(string error, char* info){
    error+="'";
    error.append(info);
    error+="'";
    yyerror(error);
}
///////////////////////////////////
///////         MAIN        ///////
///////////////////////////////////
int main(int argv, char* argc[]) {
    if( argv != 3 ) {
        cerr << "\nUSAGE:      kompilator   plik_wejsciowy.imp   plik_wyjsciowy.mr \n Compilation terminated." << endl;
        return 1;
    }

    yyin = fopen(argc[1], "r");
    if (yyin == NULL)
        { cout<<("File does not exist\n"); exit(1);} 
    yyparse();
    //cout<<"IN MAIN "<<jumpsTest.size()<<endl;
   // cout<<"IN MAIN "<<jumpsTest.size()<<endl;
    if(isError){
         cout << "kompilator: \033[31mCompilation failed.\033[0m\n"<< endl;
         exit(1);
    }
    printCode(argc[2]);
    cout << "kompilator: \033[32mCompiled succesfully.\033[0m\n"<< endl;
	return 0;
}
