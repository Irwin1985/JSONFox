#include "JSONFox.h"
&& ======================================================================== &&
&& Stringify
&& EBNF		object 	= '{' format kvp | {',' format kvp} '}'
&& 			format 	= JSPACE * nTimes
&& 			kvp		= KEY ':' value | {',' KEY ':' value}
&&			value	= STRING | NUMBER | BOOLEAN | NULL | array | object
&& 			array	= '[' value | {',' value} ']'
&& ======================================================================== &&
define class JSONStringify as custom

	lexer = .null.
	cur_token = 0
	peek_token = 0
	ParseUtf8 = .f.
	
	function init(toLexer)
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

	* Stringify
	function Stringify as memo
		lparameters tlParseUtf8
		this.ParseUtf8 = tlParseUtf8
		private JSONUtils
		JSONUtils = _screen.JSONUtils
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
	hidden function object(tnSpace)
		this.eat(T_LBRACE)
		if this.cur_token.type != T_RBRACE
			local nSpaceBlock, lcJSON as string
			nSpaceBlock = tnSpace + 1
			lcJSON = '{' + CRLF + this.JSFormat(nSpaceBlock)
			lcJSON = lcJSON + this.kvp(nSpaceBlock)
			do while this.cur_token.type == T_COMMA
				this.eat(T_COMMA)
				lcJSON = lcJSON + ',' + CRLF + this.JSFormat(nSpaceBlock)
				lcJSON = lcJSON + this.kvp(nSpaceBlock)
			enddo
			lcJSON = lcJSON + CRLF + this.JSFormat(tnSpace) + '}'
		else
			lcJSON = '{}'
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
		return '"' + lcProp + '": ' + this.value(tnSpaceIdent)
	endfunc
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
	&& ======================================================================== &&
	hidden function value(tnSpaceBlock)
		local vNewVal
		vNewVal = ''
		do case
		case this.cur_token.type == T_STRING
			vNewVal = this.cur_token.value
			this.eat(T_STRING)
			return JSONUtils.GetString(vNewVal, this.ParseUtf8)

		case this.cur_token.type == T_NUMBER
			lvNewVal = this.cur_token.value
			this.eat(T_NUMBER)
			return lvNewVal

		case this.cur_token.type == T_BOOLEAN
			lvNewVal = this.cur_token.value
			this.eat(T_BOOLEAN)
			return lvNewVal

		case this.cur_token.type == T_LBRACKET
			return this.array(tnSpaceBlock)

		case this.cur_token.type == T_LBRACE
			return this.object(tnSpaceBlock)

		case this.cur_token.type == T_NULL
			this.eat(T_NULL)
			return "null"

		otherwise
			this.eat(this.cur_token.type)
			return this.cur_token.value
		endcase
	endfunc
	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array = '[' value | { ',' value }  ']'
	&& ======================================================================== &&
	hidden function array as VOID
		lparameters tnIdentation as integer
		local lcArrayStr as string
		lcArrayStr = ''
		this.eat(T_LBRACKET)
		if this.cur_token.type != T_RBRACKET
			local lnBlock as integer
			lnBlock = tnIdentation + 1
			lcArrayStr = '[' + CRLF + this.JSFormat(lnBlock)
			lcArrayStr = lcArrayStr + this.value(lnBlock)
			do while this.cur_token.type == T_COMMA
				this.eat(T_COMMA)
				lcArrayStr = lcArrayStr + ',' + CRLF + this.JSFormat(lnBlock)
				lcArrayStr = lcArrayStr + this.value(lnBlock)
			enddo
			lcArrayStr = lcArrayStr + CRLF + this.JSFormat(tnIdentation) + ']'
		else
			lcArrayStr = '[]'
		endif
		this.eat(T_RBRACKET, "Expect ']' after array elements.")
		return lcArrayStr
	endfunc
	&& ======================================================================== &&
	&& Hidden Function JSFormat
	&& ======================================================================== &&
	hidden function JSFormat as string
		lparameters tnSpaceMult as integer
		return space(tnSpaceMult * 2)
	endfunc
enddefine
