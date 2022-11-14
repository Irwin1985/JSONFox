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


	Dimension tokens[1]
	Hidden current
	Hidden previous
	Hidden peek

	&& ======================================================================== &&
	&& Function Init
	&& ======================================================================== &&	
	function init(toScanner)
		this.lError = .f.
		Local laTokens
		laTokens = toScanner.scanTokens()
		=Acopy(laTokens, this.tokens)		
		this.current = 1
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
		if !this.check(T_RBRACE)
			local nSpaceBlock, lcJSON as string
			nSpaceBlock = tnSpace + 1
			lcJSON = "\{" + iif(this.lIndent, CRLF, "") + this.JSFormat(nSpaceBlock)
			lcJSON = lcJSON + this.kvp(nSpaceBlock)
			do while this.match(T_COMMA)
				lcJSON = lcJSON + "," + iif(this.lIndent, CRLF, "") + this.JSFormat(nSpaceBlock)
				lcJSON = lcJSON + this.kvp(nSpaceBlock)
			enddo
			lcJSON = lcJSON + iif(this.lIndent, CRLF, "") + this.JSFormat(tnSpace) + "\}"
		else
			lcJSON = "\{\}"
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
		this.consume(T_STRING, "Expect right key element")
		local lcProp as string
		lcProp = this.previous.value		
		this.consume(T_COLON, "Expect ':' after key element.")

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
		case this.match(T_STRING)
			lexeme = this.previous.value
			vNewVal = '\cf5 "' + lexeme + '"\cf1'
		case this.match(T_NUMBER)
			lexeme = this.previous.value
			vNewVal = "\cf3 " + lexeme + "\cf1"
		case this.match(T_BOOLEAN)
			lexeme = this.previous.value
			vNewVal = "\cf4 " + lexeme + "\cf1"
		case this.match(T_LBRACE)
			vNewVal = this.object(tnSpaceBlock)
		case this.match(T_LBRACKET)
			vNewVal = this.array(tnSpaceBlock)
		case this.match(T_NULL)
			vNewVal = "null"
		otherwise
			this.lError = .t.
			if this.lShowErrors
				error "Parser Error: Unknown token value: '" + _screen.jsonUtils.tokenTypeToStr(this.peek.value) + "'"
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
		if !this.check(T_RBRACKET)
			local lnBlock as integer
			lnBlock = tnIdentation + 1
			lcArrayStr = "[" + iif(this.lIndent, CRLF, "") + this.JSFormat(lnBlock)
			lcArrayStr = lcArrayStr + this.value(lnBlock)
			do while this.match(T_COMMA)
				lcArrayStr = lcArrayStr + "," + iif(this.lIndent, CRLF, "") + this.JSFormat(lnBlock)
				lcArrayStr = lcArrayStr + this.value(lnBlock)
			enddo
			lcArrayStr = lcArrayStr + iif(this.lIndent, CRLF, "") + this.JSFormat(tnIdentation) + "]"
		else
			lcArrayStr = "[]"
		endif
		this.consume(T_RBRACKET, "Expect ']' after array elements.")
		return lcArrayStr
	endfunc
	&& ======================================================================== &&
	&& Hidden Function JSFormat
	&& ======================================================================== &&
	hidden function JSFormat as string
		lparameters tnSpaceMult as integer
		return iif(this.lIndent, space(tnSpaceMult * 2), "")
	endfunc

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
		if empty(tcMessage)
			tcMessage = "Parser Error: expected token '" + _screen.jsonUtils.tokenTypeToStr(tnTokenType) + "' got = '" + _screen.jsonUtils.tokenTypeToStr(this.peek.type) + "'"
		endif
		error tcMessage
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
