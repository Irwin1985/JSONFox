#include "JSONFox.h"
&& ======================================================================== &&
&& JSONToRTF
&& EBNF		object 	= '{' format kvp | {',' format kvp} '}'
&& 			format 	= JSPACE * nTimes
&& 			kvp		= KEY ':' value | {',' KEY ':' value}
&&			value	= STRING | NUMBER | BOOLEAN | NULL | array | object
&& 			array	= '[' value | {',' value} ']'
&& ======================================================================== &&
Define Class JSONToRTF As Custom
	lIndent 	= .t.
	lShowErrors = .T.
	lError 		= .f.
	cErrorMsg 	= ""
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		This.lError = .f.
	Endfunc
&& ======================================================================== &&
&& Function StrToRTF
&& ======================================================================== &&
	Function StrToRTF As Memo
		Lparameters tnIndent as Boolean
		Private JSONUtils
		JSONUtils 		= _Screen.JSONUtils
		This.lIndent 	= tnIndent
		this.lError 	= .F.
		this.cErrorMsg 	= ""
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
				lcJSON = "\{" + Iif(This.lIndent, CRLF, "") + .JSFormat(nSpaceBlock)
				lcJSON = lcJSON + .kvp(nSpaceBlock)
				Do While JSONUtils.match(T_COMMA)
					lcJSON = lcJSON + "," + Iif(This.lIndent, CRLF, "") + .JSFormat(nSpaceBlock)
					lcJSON = lcJSON + .kvp(nSpaceBlock)
				Enddo
				lcJSON = lcJSON + Iif(This.lIndent, CRLF, "") + .JSFormat(tnSpace) + "\}"
			Else
				lcJSON = "\{\}"
			EndIf
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
		With This
			Local lcProp As String
			loElement = JSONUtils.Consume(T_STRING, "Expect right key element")
			lcProp = loElement.Lexeme
			JSONUtils.Consume(T_COLON, "Expect ':' after key element.")

			Return '\cf2 "' + lcProp + '"\cf1: ' + .Value(tnSpaceIdent)
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function Value
&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
&& ======================================================================== &&
	Hidden Function Value As Variant
		Lparameters tnSpaceBlock As Integer
		vNewVal = ""
		With This
			Do Case
			Case JSONUtils.Match(T_STRING)
				vNewVal = '\cf5 "' + _Screen.oPrevious.Lexeme + '"\cf1'
			Case JSONUtils.Match(T_NUMBER)
				vNewVal = "\cf3 " + _Screen.oPrevious.Lexeme + "\cf1"
			Case JSONUtils.Match(T_BOOLEAN)
				vNewVal = "\cf4 " + _Screen.oPrevious.Lexeme + "\cf1"
			Case JSONUtils.Match(T_LBRACE)
				vNewVal = .Object(tnSpaceBlock)
			Case JSONUtils.Match(T_LBRACKET)
				vNewVal = .Array(tnSpaceBlock)
			Case JSONUtils.Match(T_NULL)
				vNewVal = "null"
			Otherwise
				.lError = .T.
				If .lShowErrors
					JSONUtils.jsonError(JSONUtils.peek(), "Unknown token value")
				EndIf
				.cErrorMsg = "Unknown token value"
			Endcase
		Endwith
		Return vNewVal
	Endfunc
&& ======================================================================== &&
&& Function Array
&& EBNF -> 	array = '[' value | { ',' value }  ']'
&& ======================================================================== &&
	Hidden Function Array As VOID
		Lparameters tnIdentation As Integer
		Local lcArrayStr As String
		lcArrayStr = ""
		With This
			If !JSONUtils.Check(T_RBRACKET)
				Local lnBlock As Integer
				lnBlock = tnIdentation + 1
				lcArrayStr = "[" + Iif(This.lIndent, CRLF, "") + .JSFormat(lnBlock)
				lcArrayStr = lcArrayStr + .Value(lnBlock)
				Do While JSONUtils.Match(T_COMMA)
					lcArrayStr = lcArrayStr + "," + Iif(This.lIndent, CRLF, "") + .JSFormat(lnBlock)
					lcArrayStr = lcArrayStr + .Value(lnBlock)
				Enddo
				lcArrayStr = lcArrayStr + Iif(This.lIndent, CRLF, "") + .JSFormat(tnIdentation) + "]"
			Else
				lcArrayStr = "[]"
			EndIf
			JSONUtils.Consume(T_RBRACKET, "Expect ']' after array elements.")
		Endwith
		Return lcArrayStr
	Endfunc
&& ======================================================================== &&
&& Hidden Function JSFormat
&& ======================================================================== &&
	Hidden Function JSFormat As String
		Lparameters tnSpaceMult As Integer
		Return Iif(This.lIndent, Space(tnSpaceMult * 2), "")
	Endfunc
Enddefine