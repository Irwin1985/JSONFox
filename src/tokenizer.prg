#include "JSONFox.h"
* Tokenizer
Define Class Tokenizer As Custom
	Source 	= ""
	Start 	= 0
	Current = 0
	Line 	= 0
	counter = 0
	* Tokenize
	Function Tokenize(tcSource)
		This.Source = tcSource
		This.Start = 0
		This.Current = 1
		This.Line = 1
		
		this.counter = 0
		Dimension _Screen.tokens[1]
		Do While !This.isAtEnd()
			this.start = this.current
			This.scanToken()
		Enddo
		* EOF Token
		*This.newToken(T_EOF, "EOF")
	Endfunc

	* isAtEnd
	Function isAtEnd
		Return This.Current > Len(This.Source)
	Endfunc

	* scanToken
	Function scanToken
		Local ch
		ch = This.advance()
		Do Case
		Case ch == '{'
			this.newToken(T_LBRACE, '{')
		Case ch == '}'
			this.newToken(T_RBRACE, '}')
		Case ch == '['
			this.newToken(T_LBRACKET, '[')
		Case ch == ']'
			this.newToken(T_RBRACKET, ']')
		Case ch == ':'
			this.newToken(T_COLON, ':')
		Case ch == ','
			this.newToken(T_COMMA, ',')
		Case ch == LF
			this.line = this.line + 1
		Case InList(Asc(ch), 13, 9, 32)
			* break
		Case ch == '"'
			This.String()
		Otherwise
			Do case
			case IsDigit(ch)
				this.Number()
			Case this.isLetter(ch)
				this.identifier()
			Otherwise
				this.showError(this.line, "Unexpected character '" + Transform(ch) + "'")
			endcase
		Endcase
	EndFunc
	* identifier
	Function identifier
		Do while this.isLetter(this.peek())
			this.advance()
		EndDo
		lexeme = Substr(this.source, this.start, this.current - this.start)
		If InList(lexeme, "true", "false", "null")
			this.newToken(Iif(lexeme == 'null', T_NULL, T_BOOLEAN), lexeme)
		Else
			this.showError(this.line, "Unexpected identifier '" + lexeme + "'")
		endif
	endfunc
	* number
	Function number
		Do while IsDigit(this.peek())
			this.advance()
		EndDo

		If this.peek() == '.' and IsDigit(this.peekNext())
			this.advance()
			Do while (IsDigit(this.peek()))
				this.advance()
			EndDo
		EndIf
		literal = Substr(this.source, this.start, this.current - this.start)
		this.newToken(T_NUMBER, literal)
	EndFunc
	* string
	Function String
		Local s, c
		s = ''
		Do While !This.isAtEnd()
			c = This.advance()			
			If c = '\'
				peek = this.advance()	
				Do case
				Case peek = '\'
					s = s + '\'
				Case peek = 'n'
					s = s + LF
				Case peek = 'r'
					s = s + CR
				Case peek = 't'
					s = s + T_TAB
				Case peek = '"'
					s = s + '"'
				Case peek = 'u'
					s = s + this.getUnicode()
				Otherwise
					s = s + '\'
				endcase
			Else
				If c = '"'
					Exit
				Else
					s = s + c
				endif
			EndIf
		EndDo
		this.newToken(T_STRING, s)
	EndFunc
	* peek
	Function peek
		If this.current > Len(this.source)
			Return Chr(255)
		EndIf
		Return Substr(this.source, this.current, 1)
	EndFunc
	* peekNext
	Function peekNext
		If this.current + 1 > Len(this.source)
			Return Chr(255)
		EndIf
		Return Substr(this.source, this.current + 1, 1)
	EndFunc
	* advance
	Function advance
		This.Current = This.Current + 1
		Return Substr(This.Source, This.Current - 1, 1)
	EndFunc
	* getUnicode
	Hidden Function getUnicode As Void
		lcHexStr = '\u'
		c = This.advance()
		Local lcUnicode As String
		lcUnicode = "0x"
		Do While !this.isAtEnd() and (this.isHex(c) Or Isdigit(c))
			If Len(lcUnicode) = 6
				Exit
			Endif
			lcUnicode = lcUnicode + c
			lcHexStr = lcHexStr + c
			c = this.advance()
		Enddo
		Try
			lcUnicode = Chr(&lcUnicode)
		Catch
			Try
				lcUnicode = Strconv(lcHexStr, 16)
			Catch
				Error "parse error: invalid hex format '" + Transform(lcUnicode) + "'"
			EndTry
		Endtry
		Return lcUnicode
	EndFunc
	* isHex
	Hidden Function isHex As Boolean
		Lparameters tcLook As String
		Return Between(Asc(tcLook), Asc("A"), Asc("F")) Or Between(Asc(tcLook), Asc("a"), Asc("f"))
	EndFunc
	* Create new token
	Hidden Function newToken(tnTokenType, tcTokenValue)
		* Add token
		token = Createobject("Empty")
		
		=AddProperty(token, "type", tnTokenType)
		=AddProperty(token, "lexeme", tcTokenValue)
		=AddProperty(token, "literal", tcTokenValue)
		=AddProperty(token, "line", this.start)
		
		this.counter = this.counter + 1
		Dimension _Screen.tokens[this.counter]
		_Screen.tokens[this.counter] = token
	EndFunc
	* PrettyPrint
	Function PrettyPrint
		For i=1 To Alen(_Screen.tokens, 1)
			token = _Screen.tokens[i]
			?"Type:",token.Type, "Lit: ", token.literal, "Line: ", token.line
		EndFor
	EndFunc
	* showError
	Function showError(tnLine, tcMessage)
		Error "[line" + Alltrim(Str(tnLine)) + "] Error: " + tcMessage
	EndFunc
	* isLetter
	Function isLetter(ch)
		Return 'a' <= ch and ch <= 'z' or 'A' <= ch and ch <= 'Z'
	EndFunc	
EndDefine