#include "JSONFox.h"
&& ======================================================================== &&
&& Stringify
&& EBNF		object 	= '{' format kvp | {',' format kvp} '}'
&& 			format 	= JSPACE * nTimes
&& 			kvp		= KEY ':' value | {',' KEY ':' value}
&&			value	= STRING | NUMBER | BOOLEAN | NULL | array | object
&& 			array	= '[' value | {',' value} ']'
&& ======================================================================== &&
Define Class JSONStringify As Custom
	#Define CRLF Chr(13) + Chr(10)
	* Stringify
	Function Stringify As Memo
		Private JSONUtils
		JSONUtils = _Screen.JSONUtils
		Return This.Value(0)
	Endfunc
	&& ======================================================================== &&
	&& Function Object
	&& EBNF		object 	= '{' format kvp | {',' format kvp} '}'
	&& 			format 	= JSPACE * nTimes
	&& 			kvp		= KEY ':' value | {',' KEY ':' value}
	&&			value	= STRING | NUMBER | BOOLEAN | NULL | array | object
	&& 			array	= '[' value | {',' value} ']'
	&& ======================================================================== &&
	Hidden Function Object As VOID
		Lparameters tnSpace As Integer
		With This
			If !JSONUtils.Check(T_RBRACE)
				Local nSpaceBlock, lcJSON As String
				nSpaceBlock = tnSpace + 1
				lcJSON = '{' + CRLF + .JSFormat(nSpaceBlock)
				lcJSON = lcJSON + .kvp(nSpaceBlock)
				Do While JSONUtils.match(T_COMMA)
					lcJSON = lcJSON + ',' + CRLF + .JSFormat(nSpaceBlock)
					lcJSON = lcJSON + .kvp(nSpaceBlock)
				Enddo
				lcJSON = lcJSON + CRLF + .JSFormat(tnSpace) + '}'
			Else
				lcJSON = '{}'
			Endif
			JSONUtils.Consume(T_RBRACE, "Expect '}' after json object.")
		Endwith
		Return lcJSON
	Endfunc
	&& ======================================================================== &&
	&& Hidden Function kvp
	&& EBNF		kvp	= KEY ':' value | {',' KEY ':' value}
	&& ======================================================================== &&
	Hidden Function kvp
		Lparameters tnSpaceIdent As Integer
		Local lcProp As String
		loElement = JSONUtils.Consume(T_STRING, "Expect right key element")
		lcProp 	  = loElement.Lexeme
		JSONUtils.Consume(T_COLON, "Expect ':' after key element.")
		Return '"' + lcProp + '": ' + This.Value(tnSpaceIdent)
	Endfunc
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
	&& ======================================================================== &&
	Hidden Function Value As Variant
		Lparameters tnSpaceBlock As Integer
		vNewVal = ''
		Do Case
		Case JSONUtils.Match(T_LBRACE)
			Return This.Object(tnSpaceBlock)
		Case JSONUtils.Match(T_LBRACKET)
			Return This.Array(tnSpaceBlock)
		Case JSONUtils.Match(T_STRING)
			Return JSONUtils.GetString(_Screen.oPrevious.Lexeme)
		Otherwise
			JSONUtils.advance()
			Return _Screen.oPrevious.Lexeme
		endcase
	Endfunc
	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array = '[' value | { ',' value }  ']'
	&& ======================================================================== &&
	Hidden Function Array As VOID
		Lparameters tnIdentation As Integer
		Local lcArrayStr As String
		lcArrayStr = ''
		With This
			If !JSONUtils.Check(T_RBRACKET)
				Local lnBlock As Integer
				lnBlock = tnIdentation + 1
				lcArrayStr = '[' + CRLF + .JSFormat(lnBlock)
				lcArrayStr = lcArrayStr + .Value(lnBlock)
				Do While JSONUtils.Match(T_COMMA)
					lcArrayStr = lcArrayStr + ',' + CRLF + .JSFormat(lnBlock)
					lcArrayStr = lcArrayStr + .Value(lnBlock)
				Enddo
				lcArrayStr = lcArrayStr + CRLF + .JSFormat(tnIdentation) + ']'
			Else
				lcArrayStr = '[]'
			Endif
			JSONUtils.Consume(T_RBRACKET, "Expect ']' after array elements.")
		Endwith
		Return lcArrayStr
	Endfunc
	&& ======================================================================== &&
	&& Hidden Function JSFormat
	&& ======================================================================== &&
	Hidden Function JSFormat As String
		Lparameters tnSpaceMult As Integer
		Return Space(tnSpaceMult * 2)
	Endfunc
Enddefine
