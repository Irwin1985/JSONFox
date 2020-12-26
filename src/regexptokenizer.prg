#include "JSONFox.h"
* --------------------------------------------
* Regular Expression base Tokenizer
* it should be faster than previous lexer
* --------------------------------------------
Define Class regexptokenizer As Custom
	Hidden _string
	Hidden _cursor
	* Constructor
	Function Init(tcString)
		If !Empty(tcString)
			This._string = tcString
			This._cursor = 1
		EndIf
	Endfunc

	* tokenize
	Function tokenize(tcString)
		If !Empty(tcString)
			this._string = tcString
			Dimension _screen.tokens[1]
		EndIf
		This._cursor = 1
		_screen.curtokenpos = 1
		
		tok = this.getNextToken()
		nIdx = 0
		Do while !IsNull(tok)
			nIdx = nIdx + 1
			Dimension _screen.tokens[nIdx]
			_screen.tokens[nIdx] = tok
			tok = this.getNextToken()
		EndDo
	EndFunc
	
	* getNextToken
	Hidden Function getNextToken
		If !This.hasMoreTokens()
			Return Null
		Endif
		slice = Substr(This._string, This._cursor)
		For i = 1 To Alen(_Screen.Spec, 1)
			lcRegExp 	 = _Screen.Spec[i, 1]
			lnTokenType  = _Screen.Spec[i, 2]
			lcTokenValue = This._match(lcRegExp, slice)
			If Isnull(lcTokenValue)
				Loop
			Endif
			Do Case
			Case lnTokenType == T_NONE
				Return This.getNextToken() && Star over the tokenizer.

			Case lnTokenType == T_STRING
				* Remove '"' delimiter.
				lcTokenValue = Strtran(lcTokenValue, '"')
				* Escape possible hex values.
				_screen.oRegEx.Pattern = "\\u([0-9 a-z]{1,4})"
				oRes = _screen.oRegEx.Execute(lcTokenValue)
				For i=0 To oRes.Count-1
					lcExpr 	  	 = oRes.Item[i].Value
					lcReplace 	 = Strconv(Strtran(lcExpr, '\u'), 16)
					lcTokenValue = Strtran(lcTokenValue, lcExpr, lcReplace)
				Endfor
				With This
					lcTokenValue = .matchAndReplace(lcTokenValue, '\\"', '"')
					lcTokenValue = .matchAndReplace(lcTokenValue, '\\r|\\n', Chr(13) + Chr(10))
					lcTokenValue = .matchAndReplace(lcTokenValue, '\\t', Chr(9))
					lcTokenValue = .matchAndReplace(lcTokenValue, '\\', '\\')
				Endwith
			Endcase
			Return This.newToken(lnTokenType, lcTokenValue)
		Endfor

		Error "Syntax Error: Unexpected token: '" + Transform(Substr(slice,1, 1)) + "' at line: " + Alltrim(Str(this._cursor))
	Endfunc

	* Apply pattern
	Function matchAndReplace(tcString, tcPattern, tcReplace)
		_Screen.oRegEx.Pattern = tcPattern
		Return _Screen.oRegEx.Replace(tcString, tcReplace)
	Endfunc

	* Match a regular expression
	Hidden Function _match(tcRegExp, tcString)

		_screen.oRegEx.Pattern = tcRegExp
		oRes = _screen.oRegEx.Execute(tcString)

		If oRes.Count == 0
			Return .Null.
		Endif

		nLen 	 = oRes.Item[0].Length
		cMatched = oRes.Item[0].Value
		This._cursor = This._cursor + nLen

		Return cMatched
	Endfunc

	* Create new token
	Hidden Function newToken(tnTokenType, tcTokenValue)
		tok = Createobject("Empty")
		=AddProperty(tok, "type", tnTokenType)
		=AddProperty(tok, "lexeme", tcTokenValue)
		=AddProperty(tok, "literal", Transform(tcTokenValue))
		=AddProperty(tok, "line", This._cursor - Len(tcTokenValue))
		Return tok
	EndFunc
	
	* isEOF
	Hidden Function isEOF
		Return This._cursor > Len(This._string)
	Endfunc

	* hasMoreTokens
	Hidden Function hasMoreTokens
		Return !This.isEOF()
	EndFunc

	* PrettyPrint
	Function PrettyPrint
		For i=1 To Alen(_Screen.tokens, 1)
			?"Type:",_Screen.tokens[i].Type, "Lit: ", _Screen.tokens[i].literal
		EndFor
	EndFunc
Enddefine