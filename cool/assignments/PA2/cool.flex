/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}

%x comments
%x comment
%x str
%x sym

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN          <-
INT             [0-9]+
IDTAIL          [[:alnum:]_]
BLANK           [\x20\n\f\r\t\v]
SYMBOL "+"|"/"|"-"|"*"|"="|"<"|">"|"."|"~"|","|";"|":"|"("|")"|"@"|"{"|"}"|"["|"]"
%%

 /*
  *  Nested comments
  */
"(*"               { BEGIN(comments);}
<comments><<EOF>>  { snprintf(string_buf, MAX_STR_CONST, "EOF in comment, line %d", curr_lineno); cool_yylval.error_msg = string_buf; BEGIN(INITIAL); return ERROR;}
<comments>\n       { ++curr_lineno; }
<comments>[^"*)"\n]* 
<comments>"*)"     { BEGIN(INITIAL);}


"--"               { BEGIN(comment);}
<comment><<EOF>>   { BEGIN(INITIAL);}
<comment>\n        { ++curr_lineno; BEGIN(INITIAL);}
<comment>[^\n]*

 /*
  *  The multiple-character operators.
  */


 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
(?i:class)         { return CLASS; }
(?i:else)          { return ELSE; }
(?i:fi)            { return FI; }
(?i:if)            { return IF; }
(?i:in)            { return IN; }
(?i:inherits)      { return INHERITS; }
(?i:isvoid)        { return ISVOID; }
(?i:let)           { return LET; }
(?i:loop)          { return LOOP; }
(?i:pool)          { return POOL; }
(?i:then)          { return THEN; }
(?i:while)         { return WHILE; }
(?i:case)          { return CASE; }
(?i:esac)          { return ESAC; }
(?i:new)           { return NEW; }
(?i:of)            { return OF; }
(?i:not)           { return NOT; }
t(?i:rue)          { cool_yylval.boolean = 1; return BOOL_CONST; }
f(?i:alse)         { cool_yylval.boolean = 0; return BOOL_CONST; }


{DARROW}        { return (DARROW);   }
{ASSIGN}        { return  ASSIGN;    }
[a-z]{IDTAIL}*  { cool_yylval.symbol = idtable.add_string(yytext); return  OBJECTID; }
[A-Z]{IDTAIL}*  { cool_yylval.symbol = idtable.add_string(yytext); return  TYPEID; }
{INT}           { cool_yylval.symbol = inttable.add_string(yytext); return  INT_CONST; }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\"           { string_buf_ptr = string_buf; BEGIN(str); }
<str>\"      { *string_buf_ptr = 0; cool_yylval.symbol = stringtable.add_string(string_buf); BEGIN(INITIAL); return STR_CONST;}     
<str><<EOF>> { snprintf(string_buf, MAX_STR_CONST, "EOF in const string, line %d", curr_lineno); cool_yylval.error_msg = string_buf; return ERROR; }
<str>\n      { snprintf(string_buf, MAX_STR_CONST, "New line must be escaped, line %d", curr_lineno); BEGIN(INITIAL); cool_yylval.error_msg = string_buf; return ERROR;} 
<str>\\n     { if (string_buf_ptr == string_buf + MAX_STR_CONST - 1) { snprintf(string_buf, MAX_STR_CONST, "String const max len, line %d", curr_lineno); cool_yylval.error_msg = string_buf; BEGIN(INITIAL); return ERROR; } *string_buf_ptr++ = '\n'; }
<str>\\t     { if (string_buf_ptr == string_buf + MAX_STR_CONST - 1) { snprintf(string_buf, MAX_STR_CONST, "String const max len, line %d", curr_lineno); cool_yylval.error_msg = string_buf; BEGIN(INITIAL); return ERROR; } *string_buf_ptr++ = '\t'; }
<str>\\r     { if (string_buf_ptr == string_buf + MAX_STR_CONST - 1) { snprintf(string_buf, MAX_STR_CONST, "String const max len, line %d", curr_lineno); cool_yylval.error_msg = string_buf; BEGIN(INITIAL); return ERROR; } *string_buf_ptr++ = '\r'; }
<str>\\b     { if (string_buf_ptr == string_buf + MAX_STR_CONST - 1) { snprintf(string_buf, MAX_STR_CONST, "String const max len, line %d", curr_lineno); cool_yylval.error_msg = string_buf; BEGIN(INITIAL); return ERROR; } *string_buf_ptr++ = '\b'; }
<str>\\f     { if (string_buf_ptr == string_buf + MAX_STR_CONST - 1) { snprintf(string_buf, MAX_STR_CONST, "String const max len, line %d", curr_lineno); cool_yylval.error_msg = string_buf; BEGIN(INITIAL); return ERROR; } *string_buf_ptr++ = '\f'; }
<str>\\0     { snprintf(string_buf, MAX_STR_CONST, "Null symbol determinate in const string, line %d", curr_lineno); cool_yylval.error_msg = string_buf; BEGIN(INITIAL); return ERROR; } 
<str>\\.     { if (string_buf_ptr == string_buf + MAX_STR_CONST - 1) { snprintf(string_buf, MAX_STR_CONST, "String const max len, line %d", curr_lineno); cool_yylval.error_msg = string_buf; BEGIN(INITIAL); return ERROR; } *string_buf_ptr++ = yytext[1];}
<str>[^\\\n\"]+   {
                       printf("123\n '%s'", yytext);
                       char *yptr = yytext;
                       while ( *yptr )
                       {
                          if (string_buf_ptr == string_buf + MAX_STR_CONST - 1) 
                          { 
                            snprintf(string_buf, MAX_STR_CONST, "String const max len, line %d", curr_lineno); 
                            cool_yylval.error_msg = string_buf; return ERROR; 
                          }
                         *string_buf_ptr++ = *yptr++;
                        }
                      }

'            { string_buf_ptr = string_buf; BEGIN(sym);}
<sym>'       { *string_buf_ptr = '\0'; cool_yylval.symbol = stringtable.add_string(string_buf); BEGIN(INITIAL); return STR_CONST;}
<sym>\\n     { if (string_buf_ptr != string_buf) return ERROR; *string_buf_ptr++ = '\n'; }
<sym>\\t     { if (string_buf_ptr != string_buf) return ERROR; *string_buf_ptr++ = '\t'; }
<sym>\\r     { if (string_buf_ptr != string_buf) return ERROR; *string_buf_ptr++ = '\r'; }
<sym>\\b     { if (string_buf_ptr != string_buf) return ERROR; *string_buf_ptr++ = '\b'; }
<sym>\\f     { if (string_buf_ptr != string_buf) return ERROR; *string_buf_ptr++ = '\f'; }
<sym>\\.     { if (string_buf_ptr != string_buf) return ERROR; *string_buf_ptr++ = yytext[1];}
<sym>[^\\']+ { if (string_buf_ptr != string_buf || strlen(yytext) > 1 ) return ERROR; *string_buf_ptr++ = yytext[0];} 

"\n"         { ++curr_lineno; } 
"*)"         { snprintf(string_buf, MAX_STR_CONST, "Unmatched *), line %d", curr_lineno); cool_yylval.error_msg = string_buf; return ERROR;}
{BLANK}      {}
{SYMBOL}     { return yytext[0]; }
.            { snprintf(string_buf, MAX_STR_CONST, "Non specified symbol '%c', line %d", yytext[0], curr_lineno); cool_yylval.error_msg = string_buf; return ERROR;}
%%