Grammars
==========

ANTLR 4 grammars used for parsing Grace in Naylang.

Lexer Grammar
--------

```antlr
lexer grammar GraceLexer;
tokens {
	DUMMY
}

WS : [ \r\t\n]+ -> skip ;
INT: Digit+;
Digit: [0-9];

METHOD: 'method ';
VAR_ASSIGN: ':=';
VAR: 'var ';
DEF: 'def ';
PREFIX: 'prefix';
OBJECT: 'object';

COMMA: ',';
DOT: '.';
DELIMITER: ';';
QUOTE: '"';
EXCLAMATION: '!';
RIGHT_ARROW: '->';
OPEN_PAREN: '(';
CLOSE_PAREN: ')';
OPEN_BRACE: '{';
CLOSE_BRACE: '}';
OPEN_BRACKET: '[';
CLOSE_BRACKET: ']';

CONCAT: '++';
PLUS: '+';
MINUS: '-';
MUL: '*';
DIV: '/';
MOD: '%';
POW: '^';
EQUAL: '=';

TRUE: 'true';
FALSE: 'false';

// Should be defined last, so that reserved words stay reserved
ID: LETTER (LETTER | '0'..'9')*;
fragment LETTER : [a-zA-Z\u0080-\uFFFF];
```

Parser Grammar
--------

```antlr
parser grammar GraceParser;

options {
	tokenVocab = GraceLexer;
}

/*
 * Parser Rules
 */
program: (statement)*;
statement: expression DELIMITER | declaration; //| control;

declaration : variableDeclaration
            | constantDeclaration
            | methodDeclaration
            ;

variableDeclaration: VAR identifier (VAR_ASSIGN expression)? DELIMITER;
constantDeclaration: DEF identifier EQUAL expression DELIMITER;
methodDeclaration: prefixMethod
                 | userMethod
                 ;

prefixMethod: METHOD PREFIX (EXCLAMATION | MINUS)  methodBody;
userMethod: METHOD methodSignature methodBody;

methodSignature: methodSignaturePart+;
methodSignaturePart: identifier (OPEN_PAREN formalParameterList CLOSE_PAREN)?;
formalParameterList: formalParameter (COMMA formalParameter)*;
formalParameter: identifier;

methodBody: OPEN_BRACE methodBodyLine* CLOSE_BRACE;
methodBodyLine: variableDeclaration | constantDeclaration | expression DELIMITER; //| control;

// Using left-recursion and implicit operator precendence. ANTLR 4 Reference, page 70
expression  : rec=expression op=(MUL | DIV) param=expression        #MulDivExp
            | rec=expression op=(PLUS | MINUS) param=expression     #AddSubExp
            | explicitRequest                                       #ExplicitReqExp
            | implicitRequest                                       #ImplicitReqExp
            | prefix_op rec=expression                              #PrefixExp
            | rec=expression infix_op param=expression              #InficExp
            | value                                                 #ValueExp
            ;

explicitRequest : rec=implicitRequest DOT req=implicitRequest #ImplReqExplReq
                | rec=value DOT req=implicitRequest           #ValueExplReq
                ;

implicitRequest : multipartRequest              #MethImplReq
                | identifier effectiveParameter #OneParamImplReq // e.g. `print "Hello"`
                | identifier                    #IdentifierImplReq //variables or 0 params methods
                ;
multipartRequest: methodRequestPart+;
methodRequestPart: methodIdentifier OPEN_PAREN effectiveParameterList? CLOSE_PAREN;
effectiveParameterList: effectiveParameter (COMMA effectiveParameter)*;
effectiveParameter: expression;
methodIdentifier: infix_op | identifier | prefix_op;

value   : objectConstructor #ObjConstructorVal
        | block             #BlockVal
        | lineup            #LineupVal
        | primitive         #PrimitiveValue
        ;

objectConstructor: OBJECT OPEN_BRACE (statement)* CLOSE_BRACE;
block: OPEN_BRACE (params=formalParameterList RIGHT_ARROW)? body=methodBodyLine* CLOSE_BRACE;
lineup: OPEN_BRACKET lineupContents? CLOSE_BRACKET;
lineupContents: expression (COMMA expression)*;

primitive   : number
            | boolean
            | string
            ;

identifier: ID;
number: INT;
boolean: TRUE | FALSE;
string: QUOTE content=.*? QUOTE;
prefix_op: MINUS | EXCLAMATION;
infix_op: MOD | POW | CONCAT;
```
