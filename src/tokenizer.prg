#include "JSONFox.h"
* Tokenizer
define class Tokenizer as custom
	hidden source
	hidden start
	hidden current
	hidden letters
	hidden hexLetters
	hidden line

	hidden capacity
	hidden length

	dimension tokens[1]
	sourceLen = 0
	oUtils = .null.

	function init(tcSource)
		with this
			.length = 1
			.capacity = 0
&& IRODG 11/08/2023 Inicio
* We remove possible invalid characters from the input source.
			tcSource = strtran(tcSource, chr(0))
			tcSource = strtran(tcSource, chr(10))
			tcSource = strtran(tcSource, chr(13))
&& IRODG 11/08/2023 Fin
			.source = tcSource
			.start = 0
			.current = 1
			.letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_'
			.hexLetters = 'abcdefABCDEF'
			.line = 1
			.sourceLen = len(tcSource)
		endwith
	endfunc

	hidden function advance
		with this
			.current = .current + 1
			return substr(.source, .current-1, 1)
		endwith
	endfunc

	hidden function peek
		with this
			if .isAtEnd()
				return chr(0)
			endif
			return substr(.source, .current, 1)
		endwith
	endfunc

	hidden function peekNext
		with this
			if (.current + 1) > .sourceLen
				return chr(0)
			endif
			return substr(.source, .current+1, 1)
		endwith
	endfunc

	hidden function skipWhitespace
		with this
			local ch
			do while inlist(.peek(), chr(9), chr(10), chr(13), chr(32))
				ch = .advance()
				if ch == chr(10)
					.line = .line + 1
				endif
			enddo
		endwith
	endfunc

	hidden function identifier
		with this
			local lexeme
			do while at(.peek(), .letters) > 0
				.advance()
			enddo
			lexeme = substr(.source, .start, .current-.start)
			if inlist(lexeme, "true", "false", "null")
				return .addToken(iif(lexeme == 'null', T_NULL, T_BOOLEAN), lexeme)
			else
				.showError(.line, "Lexer Error: Unexpected identifier '" + lexeme + "'")
			endif
		endwith
	endfunc

	hidden function number(tChar as Character)
		with this
			local lexeme, isNegative
			lexeme = ''

			isNegative = tChar == '-'

			do while isdigit(.peek())
				.advance()
			enddo

			if .peek() == '.' and isdigit(.peekNext())
				.advance() && eat the dot '.'
				do while isdigit(.peek())
					.advance()
				enddo
			endif

&& Check if number is a Scientific Notation
			if lower(.peek()) == "e"
				.advance() && eat 'e' or 'E'

				&& Optional sign
				if .peek() == '+' or .peek() == '-'
					.advance()
				endif

				&& Must have at least one digit
				if !isdigit(.peek())
					&& Error: malformed scientific notation
					.showError(.line, "Invalid scientific notation")
					return
				endif

				do while isdigit(.peek())
					.advance()
				enddo
			endif

			lexeme = substr(.source, .start, .current-.start)
			return .addToken(T_NUMBER, lexeme)
		endwith
	endfunc

	hidden function string
		with this
			local lexeme, ch
			do while !.isAtEnd()
				ch = .peek()
				do case
				case ch == '\' and inlist(.peekNext(), '\', '/', 'n', 'r', 't', '"', "'")
					.advance()
				case ch = '"'
					.advance()
					exit
				case ch == ',' and inlist(.peekNext(), '"', "'") and type('This._anyType_') == 'C' and alltrim(this._anyType_) == 'anyType'
					.advance()
					exit
				endcase
				.advance()
			enddo

			lexeme = substr(.source, .start+1, .current-.start-2)
			.escapeCharacters(@lexeme)
			.checkUnicodeFormat(@lexeme)
			return .addToken(T_STRING, lexeme)
		endwith
	endfunc

	hidden function currency
		with this
			local lexeme, isNegative
			lexeme = ''
			isNegative = (.peek() == '-')
			if isNegative
				.advance()
			endif

			do while isdigit(.peek())
				.advance()
			enddo

* Loop while there is a comma ','
			do while .t.
				if .peek() == ',' and isdigit(.peekNext())
					.advance() && eat the comma ','
					do while isdigit(.peek())
						.advance()
					enddo
				else
					exit
				endif
			enddo

* Check for decimal part
			if .peek() == '.' and isdigit(.peekNext())
				.advance() && eat the dot '.'
				do while isdigit(.peek())
					.advance()
				enddo
			endif
			lexeme = substr(.source, .start+1, .current-.start)
			return .addToken(T_NUMBER, strtran(lexeme, ','))
		endwith
	endfunc

	procedure escapeCharacters(tcLexeme)
		if len(tcLexeme) < 100
			local lcResult, i, lcChar, lcNextChar
			lcResult = ""
			i = 1

			do while i <= len(tcLexeme)
				lcChar = substr(tcLexeme, i, 1)
				if lcChar == "\" and i < len(tcLexeme)
					lcNextChar = substr(tcLexeme, i + 1, 1)
					do case
					case lcNextChar == "\"
						lcResult = lcResult + "\"
					case lcNextChar == "/"
						lcResult = lcResult + "/"
					case lcNextChar == "n"
						lcResult = lcResult + chr(10)
					case lcNextChar == "r"
						lcResult = lcResult + chr(13)
					case lcNextChar == "t"
						lcResult = lcResult + chr(9)
					case lcNextChar == '"'
						lcResult = lcResult + '"'
					case lcNextChar == "'"
						lcResult = lcResult + "'"
					otherwise
* Unknown escape sequence, keep both characters
						lcResult = lcResult + "\" + lcNextChar
					endcase
					i = i + 2 && Advance 2 chars
				else
					lcResult = lcResult + lcChar
					i = i + 1 && Advance 1 char
				endif
			enddo
			tcLexeme = lcResult
		else
			tcLexeme = strtran(tcLexeme, '\\', '\')
			tcLexeme = strtran(tcLexeme, '\/', '/')
			tcLexeme = strtran(tcLexeme, '\n', chr(10))
			tcLexeme = strtran(tcLexeme, '\r', chr(13))
			tcLexeme = strtran(tcLexeme, '\t', chr(9))
			tcLexeme = strtran(tcLexeme, '\"', '"')
			tcLexeme = strtran(tcLexeme, "\'", "'")
		endif
	endproc

	procedure checkUnicodeFormat(tcLexeme)
* Look for unicode format
** This conversion is better (in performance) than Regular Expressions.
&& IRODG 09/10/2023 Inicio
&& --------------------------------------------------------------------
&& CORREGIDO 2026-08-30: hay que comprobar que sean CUATRO hexadecimales.
&&
&& Antes convertía los seis caracteres que siguen a una barra y una u sin
&& mirar lo que eran, y strconv(...,16) se salta los que no son
&& hexadecimales y usa los que sí. Con eso, una RUTA de Windows se rompía:
&&
&&   C:\Users\rodri\x.dll  ->  C:\rodri\x.dll   (se come "Users" entero)
&&   C:\Unidad\otra.dll    ->  de "\Unida" saca "da" -> chr(218), la U con tilde
&&
&& Pasa porque escapeCharacters ya ha convertido la barra doble en simple
&& ANTES de llegar aquí, así que lo que se ve es una barra literal, no un
&& escape. Y pasa también AL SERIALIZAR, porque Stringify vuelve a
&& tokenizar el JSON que acaba de montar.
&&
&& No se veía porque todo el código de la casa vive en C:\Desarrollo\. Un
&& proyecto creado en el perfil del usuario nacía con el manifiesto partido
&& y el JSON parecía válido.
&&
&& Exigiendo cuatro hexadecimales, \Users y \Unidad dejan de ser escapes y
&& los \u00e1 legítimos siguen funcionando igual.
&& --------------------------------------------------------------------
		local lcUnicode, lcHex, lcChar, lnPos, lnAt
		lnPos = 1
		do while .t.
			&& OJO: en VFP el tercer argumento de AT() es la OCURRENCIA, no
			&& la posicion desde la que buscar. Por eso se busca sobre el
			&& trozo que queda y luego se suma el desplazamiento.
			lnAt = at('\u', lower(substr(tcLexeme, lnPos)))
			if lnAt = 0
				exit
			endif
			lnAt = lnAt + lnPos - 1

			lcHex = substr(tcLexeme, lnAt + 2, 4)
			if len(lcHex) == 4 and this.IsHex4(lcHex)
				lcUnicode = substr(tcLexeme, lnAt, 6)
				lcChar = strtran(strconv(lcUnicode, 16), chr(0))
				tcLexeme = stuff(tcLexeme, lnAt, 6, lcChar)
				&& Seguir DESPUÉS de lo sustituido. El bucle viejo hacía un
				&& strtran global y volvía a empezar; con stuff hay que
				&& avanzar a mano o se relee lo mismo eternamente.
				lnPos = lnAt + max(len(lcChar), 1)
			else
				&& No es un escape: es una barra seguida de una u, como en
				&& C:\Users. Se salta y se sigue buscando.
				lnPos = lnAt + 2
			endif
		enddo
&& IRODG 09/10/2023 Fin
	endproc


	&& Los cuatro caracteres de un \uXXXX. Sin esto, cualquier cosa detrás de
	&& una barra y una u se tomaba por un escape unicode.
	procedure IsHex4(tcHex)
		local llOk, lnI, lcC
		llOk = .t.
		for lnI = 1 to 4
			lcC = upper(substr(tcHex, lnI, 1))
			if !(isdigit(lcC) or inlist(lcC, 'A', 'B', 'C', 'D', 'E', 'F'))
				llOk = .f.
				exit
			endif
		endfor
		return llOk
	endproc

	function scanTokens
		with this
			dimension .tokens[1]
			do while !.isAtEnd()
				.skipWhitespace()
				.start = .current
				.scanToken()
			enddo
			.addToken(T_EOF, "")
			.capacity = .length-1

* Shrink array
			dimension .tokens[.capacity]

			local loTokens
			loTokens = createobject("Empty")
			addproperty(loTokens, "tokens["+alltrim(str(.capacity))+"]", null)

* Create a copy of the tokens
			local i
			for i = 1 to .capacity
* If tokens are objects, create deep copies
				if type('.tokens[i]') = 'O'
					loTokens.tokens[i] = createobject("Empty")
					=addproperty(loTokens.tokens[i], "type", .tokens[i].type)
					=addproperty(loTokens.tokens[i], "value", .tokens[i].value)
					=addproperty(loTokens.tokens[i], "line", .tokens[i].line)
				else
					loTokens.tokens[i] = .tokens[i]
				endif
			next

			.CleanUp()

			return loTokens
		endwith
	endfunc

	hidden function scanToken
		with this
			local ch
			ch = .advance()
			do case
			case ch == '{'
				return .addToken(T_LBRACE, ch)

			case ch == '}'
				return .addToken(T_RBRACE, ch)

			case ch == '['
				return .addToken(T_LBRACKET, ch)

			case ch == ']'
				return .addToken(T_RBRACKET, ch)

			case ch == ':'
				return .addToken(T_COLON, ch)

			case ch == ','
				return .addToken(T_COMMA, ch)

			case ch == '"'
				return .string()
			case ch == '$'
				return .currency()
			otherwise
				if isdigit(ch) or (ch == '-' and isdigit(.peek()))
					return .number(ch)
				endif

				if at(ch, .letters) > 0
					return .identifier()
				endif
				.showError(.line, "Unknown character ['" + transform(ch) + "'], ascii: [" + transform(asc(ch)) + "]")
			endcase
		endwith
	endfunc

	hidden function addToken(tnTokenType, tcTokenValue)
		with this
			.checkCapacity()

			local loToken
			loToken = createobject("Empty")
			=addproperty(loToken, "type", tnTokenType)
			=addproperty(loToken, "value", tcTokenValue)
			=addproperty(loToken, "line", .line)

			.tokens[.length] = loToken
			.length = .length + 1
		endwith
	endfunc

	hidden function checkCapacity
		with this
			if .capacity < .length + 1
				if empty(.capacity)
					.capacity = 8
				else
					.capacity = .capacity * 2
				endif
				dimension .tokens[.capacity]
			endif
		endwith
	endfunc

	function showError(tnLine, tcMessage)
		error "SYNTAX ERROR: (" + transform(tnLine) + ":" + transform(this.current) + ")" + tcMessage
	endfunc

	function isAtEnd
		with this
			return .current > .sourceLen
		endwith
	endfunc

	function tokenStr(toToken)
		local lcType, lcValue, loUtils
		loUtils = iif(vartype(this.oUtils) == 'O', this.oUtils, _screen.jsonUtils)
		lcType = loUtils.tokenTypeToStr(toToken.type)
		lcValue = alltrim(transform(toToken.value))
		return "Token(" + lcType + ", '" + lcValue + "') at Line(" + alltrim(str(toToken.line)) + ")"
	endfunc

	function CleanUp
		with this
* Release token array
			if type('this.tokens', 1) == 'A' and alen(this.tokens) > 1
				local i
				for i = 1 to alen(this.tokens)
					if type('this.tokens[i]') = 'O'
* Release token object properties
						this.tokens[i] = .null.
					endif
				next
* Resize array to minimum size
				dimension this.tokens[1]
				this.tokens[1] = .null.
			endif

* Release variables that may hold large amounts of memory
			this.source = ""
			this.sourceLen = 0
			this.capacity = 0
			this.length = 1
		endwith
		return .t.
	endfunc

enddefine
