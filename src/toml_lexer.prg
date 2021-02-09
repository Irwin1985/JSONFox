#include toml.h
define class TomlLexer as custom
	source = ''
	pos = 0
	line = 0
	col = 0
	current_char = ''
	last_token = .Null.

	function last_token_access
		if isnull(this.last_token)
			return this.new_token(T_EOF, T_NONE)
		else
			return this.last_token
		endif
	endfunc
	function init(source)
		this.source = iif(right(source, 1) != LF, source + CR + LF, source)
		this.pos = 1
		this.current_char = substr(this.source, this.pos, 1)
		this.line = 1
		this.col = 1
	endfunc
	function lexer_error
		error "Unknown character '" + transform(this.current_char) + "'"
	endfunc
	function advance
		this.pos = this.pos + 1
		if this.pos > len(this.source)
			this.current_char = T_NONE
		else
			this.current_char = substr(this.source, this.pos, 1)
			this.col = this.col + 1
		endif
		if this.current_char == LF
			this.line = this.line + 1
			this.col = 1
		endif
	endfunc
	function peek
		local peek_pos
		peek_pos = this.pos + 1
		if peek_pos > len(this.source)
			return T_NONE
		else
			return substr(this.source, peek_pos, 1)
		endif
	endfunc
	function is_number(ch)
		return isdigit(ch) or inlist(ch, '-', '.')
	endfunc
	function is_letter(ch)
		return isalpha(ch) or isdigit(ch) or ch == '_' or ch == '-'
	endfunc
	function skip_whitespace
		do while this.current_char != T_NONE and inlist(this.current_char, T_SPACE, T_TAB)
			this.advance()
		enddo
	endfunc
	function skip_comments
		do while this.current_char != LF
			this.advance()
		enddo
		if this.current_char == T_NONE
			error "Unexpected End Of File"
		endif
		this.advance()
	endfunc
	function string
		local result
		result = ''
		this.advance() && eat begining "
		do while this.current_char != T_NONE
			if this.current_char == '\'
				peek_char = this.advance()
				do case
				case peek_char == 'r'
					result = result + chr(13)
				case peek_char == 'n'
					result = result + chr(10)
				case peek_char == 't'
					result = result + chr(9)
				case peek_char == '"'
					result = result + '"'
				otherwise
					result = result + '\' + peek_char
				endcase
				this.advance()
				loop
			endif
			if this.current_char == '"'
				exit
			endif
			result = result + this.current_char
			this.advance()
		enddo
		if this.current_char == T_NONE
			error "Unterminated string"
		endif
		this.advance() && eat closing "
		return this.new_token(T_STRING, result)
	endfunc
	function number
		LOCAL result, token_type
		result = ''
		token_type = T_NUMBER
		do while this.current_char != T_NONE and this.is_number(this.current_char)
			result = result + this.current_char
			this.advance()
		enddo
		if at('-', result) > 0
			return this.new_token(T_DATE, result)
		else			
			return this.new_token(T_NUMBER, val(result))
		endif
	endfunc
	function identifier
		LOCAL result, token_type
		result = ''
		token_type = T_IDENT
		do while this.current_char != T_NONE and this.is_letter(this.current_char)
			result = result + this.current_char
			this.advance()
		enddo
		
		if inlist(result, 'false', 'true')
			token_type = T_BOOLEAN
		endif
		return this.new_token(token_type, result)
	endfunc
	function new_token(type, value)
		LOCAL token
		token = createobject("empty")
		addproperty(token, "type", type)
		addproperty(token, "value", value)
		this.last_token = token
		return token
	endfunc
	function get_next_token
		do while this.current_char != T_NONE
			if inlist(this.current_char, T_SPACE, T_TAB)
				this.skip_whitespace()
				loop
			endif
			if this.current_char == T_HASH
				this.skip_comments()
				loop
			endif
			if this.current_char == T_DBQUOTE
				return this.string()
			endif
			if isdigit(this.current_char)
				return this.number()
			endif
			if this.is_letter(this.current_char)
				return this.identifier()
			endif
			if this.current_char == '['
				this.advance()
				return this.new_token(T_LBRACKET, '[')
			endif
			if this.current_char == ']'
				this.advance()
				return this.new_token(T_RBRACKET, ']')
			endif
			if this.current_char == '{'
				this.advance()
				return this.new_token(T_LBRACE, '{')
			endif
			if this.current_char == '}'
				this.advance()
				return this.new_token(T_RBRACE, '}')
			endif
			if this.current_char == '='
				this.advance()
				return this.new_token(T_ASSIGN, '=')
			endif
			if this.current_char == '.'
				this.advance()
				return this.new_token(T_DOT, '.')
			endif
			if this.current_char == ':'
				this.advance()
				return this.new_token(T_COLON, ':')
			endif
			if this.current_char == ','
				this.advance()
				return this.new_token(T_COMMA, ',')
			endif
			if this.current_char == CR
				this.advance() && eat CR
				this.advance() && eat LF
				if !isnull(this.last_token) and this.last_token.type != T_NEW_LINE
					return this.new_token(T_NEW_LINE, T_NEW_LINE)
				else					
					* skip aditional CR and LF
					loop
				endif
			endif
			this.lexer_error()
		enddo
		return this.new_token(T_EOF, T_NONE)
	endfunc
enddefine