#include "JSONFox.h"
* Tokenizer
define class Tokenizer as custom
	source 	= ""
	start 	= 0
	current = 0
	line 	= 0
	counter = 0
	* Tokenize
	function Tokenize(tcSource)
		this.source = tcSource
		this.start = 0
		this.current = 1
		this.line = 1

		this.counter = 0
		dimension _screen.tokens[1]
		do while !this.isAtEnd()
			this.start = this.current
			this.scanToken()
		enddo
		* EOF Token
		*This.newToken(T_EOF, "EOF")
	endfunc

	* isAtEnd
	function isAtEnd
		return this.current > len(this.source)
	endfunc

	* scanToken
	function scanToken
		local ch
		ch = this.advance()
		do case
		case ch == '{'
			this.newToken(T_LBRACE, '{')
		case ch == '}'
			this.newToken(T_RBRACE, '}')
		case ch == '['
			this.newToken(T_LBRACKET, '[')
		case ch == ']'
			this.newToken(T_RBRACKET, ']')
		case ch == ':'
			this.newToken(T_COLON, ':')
		case ch == ','
			this.newToken(T_COMMA, ',')
		case ch == LF
			this.line = this.line + 1
		case inlist(asc(ch), 13, 9, 32)
			* break
		case ch == '"'
			this.string()
		otherwise
			do case
			case isdigit(ch)
				this.number()
			case this.isLetter(ch)
				this.identifier()
			otherwise
				this.showError(this.line, "Unexpected character '" + transform(ch) + "'")
			endcase
		endcase
	endfunc
	* identifier
	function identifier
		do while this.isLetter(this.peek())
			this.advance()
		enddo
		lexeme = substr(this.source, this.start, this.current - this.start)
		if inlist(lexeme, "true", "false", "null")
			this.newToken(iif(lexeme == 'null', T_NULL, T_BOOLEAN), lexeme)
		else
			this.showError(this.line, "Unexpected identifier '" + lexeme + "'")
		endif
	endfunc
	* number
	function number
		do while isdigit(this.peek())
			this.advance()
		enddo

		if this.peek() == '.' and isdigit(this.peekNext())
			this.advance()
			do while (isdigit(this.peek()))
				this.advance()
			enddo
		endif
		literal = substr(this.source, this.start, this.current - this.start)
		this.newToken(T_NUMBER, literal)
	endfunc
	* string
	function string
		local s, c
		s = ''
		do while !this.isAtEnd()
			c = this.advance()
			if c = '\'
				peek = this.advance()
				do case
				case peek = '\'
					s = s + '\'
				case peek = 'n'
					s = s + LF
				case peek = 'r'
					s = s + CR
				case peek = 't'
					s = s + T_TAB
				case peek = '"'
					s = s + '"'
				case peek = 'u'
					s = s + this.getUnicode()
				otherwise
					s = s + '\'
				endcase
			else
				if c = '"'
					exit
				else
					s = s + c
				endif
			endif
		enddo
		this.newToken(T_STRING, s)
	endfunc
	* peek
	function peek
		if this.current > len(this.source)
			return chr(255)
		endif
		return substr(this.source, this.current, 1)
	endfunc
	* peekNext
	function peekNext
		if this.current + 1 > len(this.source)
			return chr(255)
		endif
		return substr(this.source, this.current + 1, 1)
	endfunc
	* advance
	function advance
		this.current = this.current + 1
		return substr(this.source, this.current - 1, 1)
	endfunc
	* getUnicode
	hidden function getUnicode as Void
		lcHexStr = '\u'
		c = this.advance()
		local lcUnicode as string
		lcUnicode = "0x"
		do while !this.isAtEnd() and (this.isHex(c) or isdigit(c))
			if len(lcUnicode) = 6
				exit
			endif
			lcUnicode = lcUnicode + c
			lcHexStr = lcHexStr + c
			c = this.advance()
		enddo
		try
			lcUnicode = chr(&lcUnicode)
		catch
			try
				lcUnicode = strconv(lcHexStr, 16)
			catch
				error "parse error: invalid hex format '" + transform(lcUnicode) + "'"
			endtry
		endtry
		return lcUnicode
	endfunc
	* isHex
	hidden function isHex as Boolean
		lparameters tcLook as string
		return between(asc(tcLook), asc("A"), asc("F")) or between(asc(tcLook), asc("a"), asc("f"))
	endfunc
	* Create new token
	hidden function newToken(tnTokenType, tcTokenValue)
		* Add token
		lcTokenRef = "JsonToken" + SYS(2015)
		&lcTokenRef = createobject("Empty")

		=addproperty(&lcTokenRef, "type", tnTokenType)
		=addproperty(&lcTokenRef, "lexeme", tcTokenValue)
		=addproperty(&lcTokenRef, "literal", tcTokenValue)
		=addproperty(&lcTokenRef, "line", this.start)

		this.counter = this.counter + 1
		dimension _screen.tokens[this.counter]
		_screen.tokens[this.counter] = &lcTokenRef
	endfunc
	* PrettyPrint
	function PrettyPrint
		for i=1 to alen(_screen.tokens, 1)
			token = _screen.tokens[i]
			?"Type:",token.type, "Lit: ", token.literal, "Line: ", token.line
		endfor
	endfunc
	* showError
	function showError(tnLine, tcMessage)
		error "[line" + alltrim(str(tnLine)) + "] Error: " + tcMessage
	endfunc
	* isLetter
	function isLetter(ch)
		return 'a' <= ch and ch <= 'z' or 'A' <= ch and ch <= 'Z'
	endfunc
enddefine
