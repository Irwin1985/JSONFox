#include "JSONFox.h"
* Tokenizer
define class Tokenizer as custom
	pos = 0
	source = ''
	current_char = ''
	line = 0
	function init(tcSource)
		this.source = tcSource
		this.pos = 1
		this.line = 1
		this.current_char = substr(this.source, this.pos, 1)
	endfunc

	function advance
		this.pos = this.pos + 1
		if this.pos > len(this.source)
			this.current_char = T_EOT
		else
			this.current_char = substr(this.source, this.pos, 1)
		endif
	endfunc

	function peek
		lnPeekPos = this.pos + 1
		if lnPeekPos > len(this.source)
			return T_EOT
		else
			return substr(this.source, lnPeekPos, 1)
		endif
	endfunc

	function isLetter(tcLetter)
		return 'a' <= tcLetter and tcLetter <= 'z' or 'A' <= tcLetter and tcLetter <= 'Z'
	endfunc

	function isspace(tcChar)
		return inlist(asc(this.current_char), 9, 10, 13, 32)
	endfunc

	function skip_whitespace
		do while !this.isAtEnd() and this.isspace(this.current_char)
			this.advance()
		enddo
	endfunc

	function identifier
		local lexeme
		lexeme = ''
		do while !this.isAtEnd() and this.isLetter(this.current_char)
			lexeme = lexeme + this.current_char
			this.advance()
		enddo
		if inlist(lexeme, "true", "false", "null")
			return this.newToken(iif(lexeme == 'null', T_NULL, T_BOOLEAN), lexeme)
		else
			this.showError(this.line, "Lexer Error: Unexpected identifier '" + lexeme + "'")
		endif
	endfunc

	function number
		local lexeme, isNegative
		lexeme = ''
		isNegative = (this.current_char == '-')
		if isNegative
			lexeme = '-'
			this.advance()
		endif

		do while !this.isAtEnd() and isdigit(this.current_char)
			lexeme = lexeme + this.current_char
			this.advance()
		enddo

		if this.current_char == '.' and isdigit(this.peek())
			lexeme = lexeme + this.current_char
			this.advance() && eat the dot '.'
			do while !this.isAtEnd() and isdigit(this.current_char)
				lexeme = lexeme + this.current_char
				this.advance()
			enddo
		endif
		return this.newToken(T_NUMBER, lexeme)
	endfunc

	function string
		lexeme = ''
		lcPeek = ''
		this.advance() && advance the first '"'
		do while !this.isAtEnd()
			if this.current_char = '\'
				lcPeek = this.peek()
				do case
				case lcPeek = '\'
					this.advance()
					lexeme = lexeme + '\'
				case lcPeek = '/'
					this.advance()
					lexeme = lexeme + '/'
				case lcPeek = 'n'
					this.advance()
					lexeme = lexeme + LF
				case lcPeek = 'r'
					this.advance()
					lexeme = lexeme + CR
				case lcPeek = 't'
					this.advance()
					lexeme = lexeme + T_TAB
				case lcPeek = '"' and this.pos + 1 < len(this.source)
					this.advance()
					lexeme = lexeme + '"'
				case lcPeek = 'u'
					this.advance()
					lexeme = lexeme + this.getUnicode()
				otherwise
					lexeme = lexeme + '\'
				endcase
			else
				if this.current_char = '"'
					this.advance() && eat the last '"'
					exit
				else
					lexeme = lexeme + this.current_char
				endif
			endif
			this.advance()
		enddo
		return this.newToken(T_STRING, lexeme)
	endfunc

	function next_token
		do while !this.isAtEnd()
			if this.isspace(this.current_char)
				this.skip_whitespace()
				loop
			endif

			if this.current_char == '{'
				this.advance()
				return this.newToken(T_LBRACE, '{')
			endif

			if this.current_char == '}'
				this.advance()
				return this.newToken(T_RBRACE, '}')
			endif

			if this.current_char == '['
				this.advance()
				return this.newToken(T_LBRACKET, '[')
			endif

			if this.current_char == ']'
				this.advance()
				return this.newToken(T_RBRACKET, ']')
			endif

			if this.current_char == ':'
				this.advance()
				return this.newToken(T_COLON, ':')
			endif

			if this.current_char == ','
				this.advance()
				return this.newToken(T_COMMA, ',')
			endif

			if this.current_char == '"'
				return this.string()
			endif

			if (this.current_char == '-' and isdigit(this.peek())) or isdigit(this.current_char)
				return this.number()
			endif

			if this.isLetter(this.current_char)
				return this.identifier()
			endif

			this.showError(0, "Lexer Error: Unknown character '" + transform(this.current_char) + "'")
		enddo
		return this.newToken(T_NONE, T_EOT)
	endfunc

	hidden function getUnicode as Void
		lcHexStr = '\u'
		local lexeme, lcUnicode
		lexeme = ''
		lcUnicode = "0x"
		this.advance() && eat the 'u'
		do while !this.isAtEnd() and (this.isHex(this.current_char) or isdigit(this.current_char))
			if len(lcUnicode) = 6
				exit
			endif
			lcUnicode = lcUnicode + this.current_char
			lcHexStr = lcHexStr + this.current_char
			lexeme = lexeme + this.current_char
			this.advance()
		enddo
		this.pos = this.pos - 1 && shift back the character.
		try
			lcUnicode = chr(&lcUnicode)
		catch
			try
				lcUnicode = strconv(lcHexStr, 16)
			catch
				error "Lexer Error: invalid hex format '" + transform(lcUnicode) + "'"
			endtry
		endtry
		return lcUnicode
	endfunc

	hidden function isHex as Boolean
		lparameters tcLook as string
		return between(asc(tcLook), asc("A"), asc("F")) or between(asc(tcLook), asc("a"), asc("f"))
	endfunc

	hidden function newToken(tnTokenType, tcTokenValue)
		local loToken
		loToken = createobject("Empty")
		=addproperty(loToken, "type", tnTokenType)
		=addproperty(loToken, "value", tcTokenValue)
		return loToken
	endfunc

	function showError(tnLine, tcMessage)
		error "[line" + alltrim(str(tnLine)) + "] Error: " + tcMessage
	endfunc

	function isAtEnd
		return this.pos > len(this.source)
	endfunc

	function tokenStr(toToken)
		local lcType, lcValue
		lcType = ''
		lcValue = alltrim(transform(toToken.value))
		do case
		case toToken.type = 0
			lcType = 'EOF'
			lcValue = ''
		case toToken.type = 1
			lcType = 'LBRACE'
		case toToken.type = 2
			lcType = 'RBRACE'
		case toToken.type = 3
			lcType = 'LBRACKET'
		case toToken.type = 4
			lcType = 'RBRACKET'
		case toToken.type = 5
			lcType = 'COMMA'
		case toToken.type = 6
			lcType = 'COLON'
		case toToken.type = 7
			lcType = 'TRUE'
		case toToken.type = 8
			lcType = 'FALSE'
		case toToken.type = 9
			lcType = 'NULL'
		case toToken.type = 10
			lcType = 'NUMBER'
		case toToken.type = 11
			lcType = 'KEY'
		case toToken.type = 12
			lcType = 'STRING'
		case toToken.type = 13
			lcType = 'LINE'
		case toToken.type = 14
			lcType = 'INTEGER'
		case toToken.type = 15
			lcType = 'FLOAT'
		case toToken.type = 16
			lcType = 'VALUE'
		case toToken.type = 17
			lcType = 'EOF'
		case toToken.type = 18
			lcType = 'BOOLEAN'
		ENDCASE
		
		return "Token(" + lcType + ", '" + lcValue + "')"
	endfunc
enddefine