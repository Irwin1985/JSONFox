#include "JSONFox.h"
&& ======================================================================== &&
&& JSONToRTF
&& EBNF		object 	= '{' format kvp | {',' format kvp} '}'
&& 			format 	= JSPACE * nTimes
&& 			kvp		= KEY ':' value | {',' KEY ':' value}
&&			value	= STRING | NUMBER | BOOLEAN | NULL | array | object
&& 			array	= '[' value | {',' value} ']'
&& ======================================================================== &&
define class JSONToRTF as custom
	lIndent 	= .t.
	lShowErrors = .t.
	lError 		= .f.
	cErrorMsg 	= ""

	lexer = .null.
	cur_token = 0
	peek_token = 0

	&& ======================================================================== &&
	&& Function Init
	&& ======================================================================== &&
	function init(toLexer)
		this.lError = .f.
		this.lexer = toLexer
		this.next_token()
		this.next_token()
	endfunc

	function next_token
		this.cur_token = this.peek_token
		this.peek_token = this.lexer.next_token()
	endfunc

	function eat(tnTokenType, tcErrorMessage)
		if this.cur_token.type == tnTokenType
			this.next_token()
		else
			if empty(tcErrorMessage)
				tcErrorMessage = "Parser Error: expected token '" + transform(tnTokenType) + "' got = '" + transform(this.cur_token.type) + "'"
			endif
			error tcErrorMessage
		endif
	endfunc

	&& ======================================================================== &&
	&& Function StrToRTF
	&& ======================================================================== &&
	function StrToRTF as memo
		lparameters tnIndent as Boolean
		private JSONUtils
		JSONUtils 		= _screen.JSONUtils
		this.lIndent 	= tnIndent
		this.lError 	= .f.
		this.cErrorMsg 	= ""
		return this.value(0)
	endfunc
	&& ======================================================================== &&
	&& Function Object
	&& EBNF		object 	= '{' format kvp | {',' format kvp} '}'
	&& 			format 	= JSPACE * nTimes
	&& 			kvp		= KEY ':' value | {',' KEY ':' value}
	&&			value	= STRING | NUMBER | BOOLEAN | NULL | array | object
	&& 			array	= '[' value | {',' value} ']'
	&& ======================================================================== &&
	hidden function object as VOID
		lparameters tnSpace as integer
		this.eat(T_LBRACE)
		if this.cur_token.type != T_RBRACE
			local nSpaceBlock, lcJSON as string
			nSpaceBlock = tnSpace + 1
			lcJSON = "\{" + iif(this.lIndent, CRLF, "") + this.JSFormat(nSpaceBlock)
			lcJSON = lcJSON + this.kvp(nSpaceBlock)
			do while this.cur_token.type == T_COMMA
				this.eat(T_COMMA)
				lcJSON = lcJSON + "," + iif(this.lIndent, CRLF, "") + this.JSFormat(nSpaceBlock)
				lcJSON = lcJSON + this.kvp(nSpaceBlock)
			enddo
			lcJSON = lcJSON + iif(this.lIndent, CRLF, "") + this.JSFormat(tnSpace) + "\}"
		else
			lcJSON = "\{\}"
		endif
		this.eat(T_RBRACE, "Expect '}' after json object.")
		return lcJSON
	endfunc
	&& ======================================================================== &&
	&& Hidden Function kvp
	&& EBNF		kvp	= KEY ':' value | {',' KEY ':' value}
	&& ======================================================================== &&
	hidden function kvp
		lparameters tnSpaceIdent as integer
		local lcProp as string
		lcProp = this.cur_token.value
		this.eat(T_STRING, "Expect right key element")
		this.eat(T_COLON, "Expect ':' after key element.")

		return '\cf2 "' + lcProp + '"\cf1: ' + this.value(tnSpaceIdent)
	endfunc
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
	&& ======================================================================== &&
	hidden function value as Variant
		lparameters tnSpaceBlock as integer
		local vNewVal, lexeme
		vNewVal = ''
		lexeme = ''
		do case
		case this.cur_token.type == T_STRING
			lexeme = this.cur_token.value
			this.eat(T_STRING)
			vNewVal = '\cf5 "' + lexeme + '"\cf1'
		case this.cur_token.type == T_NUMBER
			lexeme = this.cur_token.value
			this.eat(T_NUMBER)
			vNewVal = "\cf3 " + lexeme + "\cf1"
		case this.cur_token.type == T_BOOLEAN
			lexeme = this.cur_token.value
			this.eat(T_BOOLEAN)
			vNewVal = "\cf4 " + lexeme + "\cf1"
		case this.cur_token.type == T_LBRACE
			vNewVal = this.object(tnSpaceBlock)
		case this.cur_token.type == T_LBRACKET
			vNewVal = this.array(tnSpaceBlock)
		case this.cur_token.type == T_NULL
			this.eat(T_NULL)
			vNewVal = "null"
		otherwise
			this.lError = .t.
			if this.lShowErrors
				error "Parser Error: Unknown token value: '" + transform(this.cur_token.value) + "'"
			endif
			this.cErrorMsg = "Unknown token value"
		endcase
		return vNewVal
	endfunc
	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array = '[' value | { ',' value }  ']'
	&& ======================================================================== &&
	hidden function array as VOID
		lparameters tnIdentation as integer
		local lcArrayStr as string
		lcArrayStr = ""
		this.eat(T_LBRACKET)
		if this.cur_token.type != T_RBRACKET
			local lnBlock as integer
			lnBlock = tnIdentation + 1
			lcArrayStr = "[" + iif(this.lIndent, CRLF, "") + this.JSFormat(lnBlock)
			lcArrayStr = lcArrayStr + this.value(lnBlock)
			do while this.cur_token.type == T_COMMA
				this.eat(T_COMMA)
				lcArrayStr = lcArrayStr + "," + iif(this.lIndent, CRLF, "") + this.JSFormat(lnBlock)
				lcArrayStr = lcArrayStr + this.value(lnBlock)
			enddo
			lcArrayStr = lcArrayStr + iif(this.lIndent, CRLF, "") + this.JSFormat(tnIdentation) + "]"
		else
			lcArrayStr = "[]"
		endif
		this.eat(T_RBRACKET, "Expect ']' after array elements.")
		return lcArrayStr
	endfunc
	&& ======================================================================== &&
	&& Hidden Function JSFormat
	&& ======================================================================== &&
	hidden function JSFormat as string
		lparameters tnSpaceMult as integer
		return iif(this.lIndent, space(tnSpaceMult * 2), "")
	endfunc
enddefine
