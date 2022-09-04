* =========================================
*!*	clear
*!*	Cd f:\desarrollo\github\jsonfox\src\
*!*	If Type('_SCREEN.oRegEx') != 'U'
*!*		=Removeproperty(_Screen, 'oRegEx')
*!*	Endif
*!*	=AddProperty(_Screen, 'oRegEx', Createobject("VBScript.RegExp"))
*!*	_Screen.oRegEx.Global = .T.

*!*	#include "JSONFox.h"

*!*	If File('c:\a1\tokens.txt')
*!*		Delete File 'c:\a1\tokens.txt'
*!*	EndIf

*!*	*Set Step On
*!*	sc = CreateObject("Tokenizer", FileToStr("c:\a1\test.json"))
*!*	tokens = sc.scanTokens()
*!*	For i = 1 to Alen(tokens)
*!*		StrToFile(sc.tokenStr(tokens[i]) + Chr(13) + Chr(10), 'c:\a1\tokens.txt', 1)
*!*		? sc.tokenStr(tokens[i])
*!*	Endfor
* =========================================
#include "JSONFox.h"
* Tokenizer
define class Tokenizer as custom
	Hidden source	
	Hidden start
	Hidden current
	Hidden letters
	Hidden hexLetters
	hidden line
	
	Hidden capacity
	Hidden length
	
	Dimension tokens[1]
	
	function init(tcSource)
		With this
			.length = 1
			.capacity = 0
			.source = tcSource
			.start = 0
			.current = 1
			.letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_'
			.hexLetters = 'abcdefABCDEF'	
			.line = 1
		endwith
	endfunc

	Hidden function advance
		this.current = this.current + 1
		Return substr(this.source, this.current-1, 1)
	endfunc

	Hidden function peek
		If this.isAtEnd() then
			Return 'ÿ'
		EndIf
		return substr(this.source, this.current, 1)		
	EndFunc
	
	Hidden function peekNext
		If this.isAtEnd() then
			Return 'ÿ'
		EndIf
		If (this.current + 1) > Len(this.source)
			Return 'ÿ'
		EndIf
		return substr(this.source, this.current+1, 1)		
	endfunc	

	Hidden function isLetter(tcLetter)
		Return At(tcLetter, this.letters) > 0
	endfunc
	
	Hidden Function skipWhitespace
		Do while !this.isAtEnd() and InList(this.peek(), Chr(9), Chr(10), Chr(13), Chr(32))
			If this.peek() == Chr(10)
				this.line = this.line + 1
			endif
			this.advance()
		enddo
	endfunc

	Hidden function identifier
		Local lexeme
		do while !this.isAtEnd() and this.isLetter(this.peek())
			this.advance()
		EndDo
		lexeme = Substr(this.source, this.start, this.current-this.start)
		if inlist(lexeme, "true", "false", "null")
			return this.addToken(iif(lexeme == 'null', T_NULL, T_BOOLEAN), lexeme)
		else
			this.showError(this.line, "Lexer Error: Unexpected identifier '" + lexeme + "'")
		endif
	endfunc

	Hidden function number
		local lexeme, isNegative
		lexeme = ''
		isNegative = (this.peek() == '-')
		if isNegative
			this.advance()
		endif

		do while !this.isAtEnd() and isdigit(this.peek())
			this.advance()
		enddo

		if this.peek() == '.' and isdigit(this.peekNext())
			this.advance() && eat the dot '.'
			do while !this.isAtEnd() and isdigit(this.peek())
				this.advance()
			enddo
		EndIf
		lexeme = Substr(this.source, this.start, this.current-this.start)
		return this.addToken(T_NUMBER, lexeme)
	endfunc

	Hidden function string
		Local lexeme, ch
		do while !this.isAtEnd()			
			ch = this.peek()
			if ch == '\'
				do case
				case this.peekNext() == '\'
					this.advance()
				case this.peekNext() == '/'
					this.advance()
				case this.peekNext() == 'n'
					this.advance()
				case this.peekNext() == 'r'
					this.advance()
				case this.peekNext() == 't'
					this.advance()
				case this.peekNext() == '"'
					this.advance()
				EndCase
			else
				if ch = '"'
					this.advance()
					exit
				endif
			EndIf
			this.advance()
		EndDo
		
		lexeme = Substr(this.source, this.start+1, this.current-this.start-2)
		this.escapeCharacters(@lexeme)
		this.checkUnicodeFormat(@lexeme)
		

		return this.addToken(T_STRING, lexeme)
	EndFunc

	Procedure escapeCharacters(tcLexeme)
		* Convert all escape sequences
		tcLexeme = Strtran(tcLexeme, '\\', '\')
		tcLexeme = Strtran(tcLexeme, '\/', '/')
		tcLexeme = Strtran(tcLexeme, '\n', Chr(10))
		tcLexeme = Strtran(tcLexeme, '\r', Chr(13))
		tcLexeme = Strtran(tcLexeme, '\t', Chr(9))
		tcLexeme = Strtran(tcLexeme, '\"', '"')
	EndProc
		
	procedure checkUnicodeFormat(tcLexeme)		
		* Look for unicode format
		_Screen.oRegEx.Pattern = "\\u([a-fA-F0-9]{4})"
		Local loResult, lcValue
		_Screen.oRegEx.IgnoreCase = .t.
		_Screen.oRegEx.global = .t.
		loResult = _Screen.oRegEx.Execute(tcLexeme)
		If Type('loResult') == 'O'
			For i = 0 to loResult.Count-1
				lcValue = loResult.Item[i].Value
				Try
					tcLexeme = Strtran(tcLexeme, lcValue, Strconv(lcValue, 16))
				Catch
				EndTry
			EndFor
		EndIf
	EndProc

	Function scanTokens
		Dimension this.tokens[1]
		Do while !this.isAtEnd()
			this.skipWhitespace()
			this.start = this.current
			this.scanToken()
		EndDo
		this.addToken(T_EOF, "")
		this.capacity = this.length-1
		
		* Shrink array
		Dimension this.tokens[this.capacity]
		
		Return @this.tokens
	endfunc

	Hidden function scanToken
		Local ch
		ch = this.advance()
		
		Do case		
		case ch == '{'
			Return this.addToken(T_LBRACE, '{')

		case ch == '}'
			Return this.addToken(T_RBRACE, '}')
		
		case ch == '['
			Return this.addToken(T_LBRACKET, '[')		

		case ch == ']'
			Return this.addToken(T_RBRACKET, ']')

		case ch == ':'
			Return this.addToken(T_COLON, ':')

		case ch == ','
			Return this.addToken(T_COMMA, ',')

		Case ch == '"'
			Return this.string()
			
		Otherwise
			if isdigit(ch) or (ch == '-' and isdigit(this.peekNext()))
				Return this.number()
			endif

			if this.isLetter(ch)
				Return this.identifier()
			endif

			this.showError(0, "Lexer Error: Unknown character '" + transform(ch) + "'")
		endcase		
	EndFunc

	hidden function addToken(tnTokenType, tcTokenValue)
		this.checkCapacity()
		local loToken
		loToken = createobject("Empty")
		=addproperty(loToken, "type", tnTokenType)
		=addproperty(loToken, "value", tcTokenValue)
		=AddProperty(loToken, "line", this.line)
		
		this.tokens[this.length] = loToken
		this.length = this.length + 1		
	EndFunc
	
	Hidden function checkCapacity
		If this.capacity < this.length + 1
			If Empty(this.capacity)
				this.capacity = 8
			Else
				this.capacity = this.capacity * 2
			EndIf			
			Dimension this.tokens[this.capacity]
		EndIf
	endfunc

	function showError(tnLine, tcMessage)
		error "[line" + alltrim(str(tnLine)) + "] Error: " + tcMessage
	endfunc

	function isAtEnd
		return this.current > len(this.source)
	endfunc

	function tokenStr(toToken)
		local lcType, lcValue
		lcType = _screen.jsonUtils.tokenTypeToStr(toToken.type)
		lcValue = alltrim(transform(toToken.value))		
		return "Token(" + lcType + ", '" + lcValue + "') at Line(" + Alltrim(Str(toToken.Line)) + ")"
	EndFunc
enddefine