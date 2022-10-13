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
	sourceLen = 0
	
	
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
			.sourceLen = Len(tcSource)
		endwith
	endfunc

	Hidden function advance
		With this
			.current = .current + 1
			Return substr(.source, .current-1, 1)
		endwith
	endfunc

	Hidden function peek
		With this
			If .isAtEnd()
				Return 'ÿ'
			EndIf
			return substr(.source, .current, 1)
		endwith
	EndFunc
	
	Hidden function peekNext
		With this
			If (.current + 1) > .sourceLen
				Return 'ÿ'
			EndIf
			return substr(.source, .current+1, 1)
		endwith
	endfunc	
	
	Hidden Function skipWhitespace
		With this
			LOCAL ch
			Do while InList(.peek(), Chr(9), Chr(10), Chr(13), Chr(32))
				ch = .advance()
				If ch == Chr(10)
					.line = .line + 1
				endif
			EndDo
		endwith
	endfunc

	Hidden function identifier
		With this
			Local lexeme
			do while At(.peek(), .letters) > 0
				.advance()
			EndDo
			lexeme = Substr(.source, .start, .current-.start)
			if inlist(lexeme, "true", "false", "null")
				return .addToken(iif(lexeme == 'null', T_NULL, T_BOOLEAN), lexeme)
			else
				.showError(.line, "Lexer Error: Unexpected identifier '" + lexeme + "'")
			EndIf
		EndWith
	endfunc

	Hidden function number
		With this
			local lexeme, isNegative
			lexeme = ''
			isNegative = (.peek() == '-')
			if isNegative
				.advance()
			endif

			do while isdigit(.peek())
				.advance()
			enddo

			if .peek() == '.' and isdigit(.peekNext())
				.advance() && eat the dot '.'
				do while isdigit(.peek())
					.advance()
				enddo
			EndIf
			lexeme = Substr(.source, .start, .current-.start)
			return .addToken(T_NUMBER, lexeme)
		endwith
	endfunc

	Hidden function string
		With this
			Local lexeme, ch
			do while !.isAtEnd()			
				ch = .peek()
				Do case
				case ch == '\' and InList(.peekNext(), '\', '/', 'n', 'r', 't', '"', "'")
					.advance()
				Case ch = '"'
					.advance()
					exit
				endcase
				.advance()
			EndDo
			
			lexeme = Substr(.source, .start+1, .current-.start-2)
			.escapeCharacters(@lexeme)
			.checkUnicodeFormat(@lexeme)			
			return .addToken(T_STRING, lexeme)
		endwith
	EndFunc

	Procedure escapeCharacters(tcLexeme)
		* Convert all escape sequences
		tcLexeme = Strtran(tcLexeme, '\\', '\')
		tcLexeme = Strtran(tcLexeme, '\/', '/')
		tcLexeme = Strtran(tcLexeme, '\n', Chr(10))
		tcLexeme = Strtran(tcLexeme, '\r', Chr(13))
		tcLexeme = Strtran(tcLexeme, '\t', Chr(9))
		tcLexeme = Strtran(tcLexeme, '\"', '"')
		tcLexeme = Strtran(tcLexeme, "\'", "'")
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
		With this
			Dimension .tokens[1]	
			Do while !.isAtEnd()
				.skipWhitespace()
				.start = .current
				.scanToken()
			EndDo
			.addToken(T_EOF, "")
			.capacity = .length-1
			
			* Shrink array
			Dimension .tokens[.capacity]
			
			Return @.tokens
		EndWith
	endfunc

	Hidden function scanToken
		With this
			Local ch
			ch = .advance()			
			Do case		
			case ch == '{'
				Return .addToken(T_LBRACE, ch)

			case ch == '}'
				Return .addToken(T_RBRACE, ch)
			
			case ch == '['
				Return .addToken(T_LBRACKET, ch)		

			case ch == ']'
				Return .addToken(T_RBRACKET, ch)

			case ch == ':'
				Return .addToken(T_COLON, ch)

			case ch == ','
				Return .addToken(T_COMMA, ch)

			Case ch == '"'
				Return .string()				
			Otherwise
				if isdigit(ch) or (ch == '-' and isdigit(.peek()))
					Return .number()
				endif

				if At(ch, .letters) > 0
					Return .identifier()
				endif
				.showError(.line, "Unknown character ['" + transform(ch) + "'], ascii: [" + TRANSFORM(ASC(ch)) + "]")
			EndCase
		EndWith
	EndFunc

	hidden function addToken(tnTokenType, tcTokenValue)
		With this
			.checkCapacity()
			local loToken
			loToken = createobject("Empty")
			=addproperty(loToken, "type", tnTokenType)
			=addproperty(loToken, "value", tcTokenValue)
			=AddProperty(loToken, "line", .line)
			
			.tokens[.length] = loToken
			.length = .length + 1
		EndWith
	EndFunc
	
	Hidden function checkCapacity
		With this
			If .capacity < .length + 1
				If Empty(.capacity)
					.capacity = 8
				Else
					.capacity = .capacity * 2
				EndIf			
				Dimension .tokens[.capacity]
			EndIf
		endwith
	endfunc

	function showError(tnLine, tcMessage)
		error "SYNTAX ERROR: (" + TRANSFORM(tnLine) + ":" + TRANSFORM(this.current) + ")" + tcMessage
	endfunc

	function isAtEnd
		With this
		return .current >= .sourceLen
		EndWith
	endfunc

	function tokenStr(toToken)
		local lcType, lcValue
		lcType = _screen.jsonUtils.tokenTypeToStr(toToken.type)
		lcValue = alltrim(transform(toToken.value))		
		return "Token(" + lcType + ", '" + lcValue + "') at Line(" + Alltrim(Str(toToken.Line)) + ")"
	EndFunc
enddefine