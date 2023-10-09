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
			&& IRODG 11/08/2023 Inicio
			* We remove possible invalid characters from the input source.
			tcSource = STRTRAN(tcSource, CHR(0))
			tcSource = STRTRAN(tcSource, CHR(10))
			tcSource = STRTRAN(tcSource, CHR(13))
			&& IRODG 11/08/2023 Fin
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
*!*				If .current == Len(.source)
*!*					lexeme = Substr(.source, .start, (.current+1)-.start)
*!*				Else
*!*					lexeme = Substr(.source, .start, .current-.start)
*!*				endif
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
			endif

			&& Check if number is a Scientific Notation in Tokenizer.Number()
			IF Lower(.peek() + .peekNext()) == "e+" 
			  .advance()
			  .advance()
			  do while isdigit(.peek())
				  .advance()
			  enddo	
			endif
			*****************************************************************			
			
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
					Exit
				Case ch == ',' and InList(.peekNext(), '"', "'") and Type('This._anyType_') == 'C' and Alltrim(this._anyType_) == 'anyType'
					.advance()
					Exit
				endcase
				.advance()
			EndDo
			
			lexeme = Substr(.source, .start+1, .current-.start-2)
			.escapeCharacters(@lexeme)
			.checkUnicodeFormat(@lexeme)			
			return .addToken(T_STRING, lexeme)
		endwith
	EndFunc

	Hidden function currency
		With this
			local lexeme, isNegative
			lexeme = ''
			isNegative = (.peek() == '-')
			if isNegative
				.advance()
			endif

			do while isdigit(.peek())
				.advance()
			EndDo

			* Loop while there is a comma ','
			Do while .t.				
				If .peek() == ',' and IsDigit(.peekNext())
					.advance() && eat the comma ','
					do while isdigit(.peek())
						.advance()
					EndDo
				Else
					exit
				EndIf
			enddo		

			* Check for decimal part
			if .peek() == '.' and isdigit(.peekNext())
				.advance() && eat the dot '.'
				do while isdigit(.peek())
					.advance()
				enddo
			EndIf
			lexeme = Substr(.source, .start+1, .current-.start)
			return .addToken(T_NUMBER, Strtran(lexeme, ','))
		endwith
	endfunc


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
		** This conversion is better (in performance) than Regular Expressions.
		&& IRODG 09/10/2023 Inicio
		local lcUnicode, lcConversion, lbReplace, lnPos
		lnPos = 1
		do while .T.
			lbReplace = .F.
			lcUnicode = substr(tcLexeme, at('\u', tcLexeme, lnPos), 6)
			if len(lcUnicode) == 6
				lbReplace = .T.
			else
				lcUnicode = substr(tcLexeme, at('\U', tcLexeme, lnPos), 6)
				if len(lcUnicode) == 6
					lbReplace = .T.
				endif
			endif
			if lbReplace
				tcLexeme = strtran(tcLexeme, lcUnicode, strtran(strconv(lcUnicode,16), chr(0)))
			else
				exit
			endif
		enddo
		&& IRODG 09/10/2023 Fin
*!*			_Screen.oRegEx.Pattern = "\\u([a-fA-F0-9]{4})"
*!*			Local loResult, lcValue, i
*!*			_Screen.oRegEx.IgnoreCase = .t.
*!*			_Screen.oRegEx.global = .t.
*!*			loResult = _Screen.oRegEx.Execute(tcLexeme)
*!*			If Type('loResult') == 'O'
*!*				For i = 0 to loResult.Count-1
*!*					lcValue = loResult.Item[i].Value
*!*					try
*!*						&& IRODG 09/10/2023 Inicio
*!*						** Replace null character (chr(0)) from conversion result (strconv(lcValue, 16))
*!*	*!*						tcLexeme = Strtran(tcLexeme, lcValue, (strconv(lcValue, 16)))
*!*						tcLexeme = Strtran(tcLexeme, lcValue, strtran((strconv(lcValue, 16)), chr(0)))
*!*						&& IRODG 09/10/2023 Fin
*!*					Catch
*!*					EndTry
*!*				EndFor
*!*			EndIf
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
			Case ch == '$'
				Return .Currency()
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
		return .current > .sourceLen
		EndWith
	endfunc

	function tokenStr(toToken)
		local lcType, lcValue
		lcType = _screen.jsonUtils.tokenTypeToStr(toToken.type)
		lcValue = alltrim(transform(toToken.value))		
		return "Token(" + lcType + ", '" + lcValue + "') at Line(" + Alltrim(Str(toToken.Line)) + ")"
	EndFunc
enddefine