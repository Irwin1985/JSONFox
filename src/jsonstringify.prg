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

	ParseUtf8 = .f.
	TrimChars = .f.

	Dimension tokens[1]
	Hidden current
	Hidden previous
	Hidden peek
	
	function init(toScanner)
		Local laTokens
		laTokens = toScanner.scanTokens()
		=Acopy(laTokens, this.tokens)		
		this.current = 1
	endfunc
	
	* Stringify
	function Stringify as memo
		lparameters tlParseUtf8, tlTrimChars
		this.ParseUtf8 = tlParseUtf8
		this.TrimChars = tlTrimChars

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
		if !this.check(T_RBRACE)
			local nSpaceBlock, lcJSON as string
			nSpaceBlock = tnSpace + 1
			lcJSON = '{' + CRLF + this.JSFormat(nSpaceBlock)
			lcJSON = lcJSON + this.kvp(nSpaceBlock)
			do while this.match(T_COMMA)
				lcJSON = lcJSON + ',' + CRLF + this.JSFormat(nSpaceBlock)
				lcJSON = lcJSON + this.kvp(nSpaceBlock)
			enddo
			lcJSON = lcJSON + CRLF + this.JSFormat(tnSpace) + '}'
		else
			lcJSON = '{}'
		endif
		this.consume(T_RBRACE, "Expect '}' after json object.")
		return lcJSON
	endfunc
	&& ======================================================================== &&
	&& Hidden Function kvp
	&& EBNF		kvp	= KEY ':' value | {',' KEY ':' value}
	&& ======================================================================== &&
	hidden function kvp
		lparameters tnSpaceIdent as integer
		local lcProp as string
		this.consume(T_STRING, "Expect right key element")
*!*			lcProp = this.previous.value
		lcProp = _screen.JSONUtils.GetString(this.previous.value, this.ParseUtf8)
		this.consume(T_COLON, "Expect ':' after key element.")		
		*return '"' + lcProp + '": ' + this.value(tnSpaceIdent)
		return lcProp + ': ' + this.value(tnSpaceIdent)
	endfunc
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
	&& ======================================================================== &&
	hidden function value(tnSpaceBlock)
		do case
		case this.match(T_STRING)
*!*				return _screen.JSONUtils.GetString(this.previous.value, this.ParseUtf8)
			return _screen.JSONUtils.GetString(Iif(this.TrimChars, Alltrim(this.previous.value), this.previous.value), this.ParseUtf8)			

		case this.match(T_NUMBER)
			return this.previous.value

		case this.match(T_BOOLEAN)
			return this.previous.value

		case this.match(T_LBRACKET)
			return this.array(tnSpaceBlock)

		case this.match(T_LBRACE)
			return this.object(tnSpaceBlock)

		case this.match(T_NULL)
			return "null"

		otherwise
			this.consume(this.cur_token.type, '')
			return this.previous.value
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
		if !this.check(T_RBRACKET)
			local lnBlock as integer
			lnBlock = tnIdentation + 1
			lcArrayStr = '[' + CRLF + this.JSFormat(lnBlock)
			lcArrayStr = lcArrayStr + this.value(lnBlock)
			do while this.match(T_COMMA)
				lcArrayStr = lcArrayStr + ',' + CRLF + this.JSFormat(lnBlock)
				lcArrayStr = lcArrayStr + this.value(lnBlock)
			enddo
			lcArrayStr = lcArrayStr + CRLF + this.JSFormat(tnIdentation) + ']'
		else
			lcArrayStr = '[]'
		endif
		this.consume(T_RBRACKET, "Expect ']' after array elements.")
		return lcArrayStr
	endfunc
	&& ======================================================================== &&
	&& Hidden Function JSFormat
	&& ======================================================================== &&
	hidden function JSFormat as string
		lparameters tnSpaceMult as integer
		return space(tnSpaceMult * 2)
	EndFunc

	Function match(tnTokenType)
		If this.check(tnTokenType)
			this.advance()
			Return .t.
		EndIf
		Return .f.
	EndFunc

	Hidden Function consume(tnTokenType, tcMessage)
		If this.check(tnTokenType)
			Return this.advance()
		EndIf
		if empty(tcErrorMessage)
			tcErrorMessage = "Parser Error: expected token '" + _screen.jsonUtils.tokenTypeToStr(tnTokenType) + "' got = '" + _screen.jsonUtils.tokenTypeToStr(this.peek.type) + "'"
		endif
		error tcErrorMessage
	endfunc

	Hidden Function check(tnTokenType)
		If this.isAtEnd()
			Return .f.
		EndIf
		Return this.peek.type == tnTokenType
	EndFunc 

	Hidden Function advance
		If !this.isAtEnd()
			this.current = this.current + 1
		EndIf
		Return this.tokens[this.current-1]
	endfunc

	Hidden Function isAtEnd
		Return this.peek.type == T_EOF
	endfunc

	Hidden Function peek_access
		Return this.tokens[this.current]
	endfunc

	Hidden Function previous_access
		Return this.tokens[this.current-1]
	EndFunc
	
enddefine
