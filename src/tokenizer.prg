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

* escapeCharacters: deshace los escapes de una cadena JSON en UNA sola
* pasada de izquierda a derecha (RFC 8259). Cada barra se consume con
* lo que la sigue, y lo que sale ya no se vuelve a mirar.
*
* CORREGIDO 2026-09-19. Hasta aquí eran DOS pasadas -- esta y
* checkUnicodeFormat() --, y la segunda volvía a interpretar lo que la
* primera había dejado como texto: el JSON "x\\u0022" daba x" en vez de
* x\u0022. Los arreglos del 30 y el 31 de agosto (exigir cuatro
* hexadecimales, y un marcador en la rama de cadenas largas) tapaban
* las rutas de Windows pero no esto, y el 31 solo llegó al JsonFox.prg
* ensamblado, no aquí. Con una pasada no hacen falta ninguno de los dos:
* una barra escapada es una barra y lo que la sigue ya no se relee.
* Medido el 2026-09-18 (FoxMind, ronda 13). Fijado por
* tests\JsonFoxUnescapeTests.prg.
*
* \uXXXX pasa de UTF-16 a la página 1252 por STRCONV(..., 6, 1252, 1);
* un par sustituto se convierte entero. Lo que no es un escape conocido
* se deja tal cual, barra incluida.
	procedure escapeCharacters(tcLexeme)
		local lcIn, lcOut, lnLen, lnPos, lnOcc, lnAt, lcNext, lnSkip

		if at("\", tcLexeme) = 0
			return
		endif

		lcIn = tcLexeme
		lcOut = ""
		lnLen = len(lcIn)
		lnPos = 1
		lnOcc = 1

		do while .t.
			lnAt = at("\", lcIn, lnOcc)
			if lnAt = 0
				lcOut = lcOut + substr(lcIn, lnPos)
				exit
			endif
			if lnAt < lnPos
* Una barra ya consumida por el escape anterior (la segunda de \\).
				lnOcc = lnOcc + 1
				loop
			endif

			lcOut = lcOut + substr(lcIn, lnPos, lnAt - lnPos)
			lcNext = substr(lcIn, lnAt + 1, 1)
			lnSkip = 2

			do case
			case lcNext == '"'
				lcOut = lcOut + '"'
			case lcNext == "\"
				lcOut = lcOut + "\"
			case lcNext == "/"
				lcOut = lcOut + "/"
			case lcNext == "b"
				lcOut = lcOut + chr(8)
			case lcNext == "f"
				lcOut = lcOut + chr(12)
			case lcNext == "n"
				lcOut = lcOut + chr(10)
			case lcNext == "r"
				lcOut = lcOut + chr(13)
			case lcNext == "t"
				lcOut = lcOut + chr(9)
			case lcNext == "'"
				lcOut = lcOut + "'"
			case (lcNext == "u" or lcNext == "U") and this.isHex4(substr(lcIn, lnAt + 2, 4))
				lnSkip = this.appendUnicode(lcIn, lnAt, @lcOut)
			otherwise
* Un escape que no existe se queda tal cual, barra incluida.
				lcOut = lcOut + "\" + lcNext
			endcase

			lnPos = lnAt + lnSkip
			lnOcc = lnOcc + 1
			if lnPos > lnLen
				exit
			endif
		enddo

		tcLexeme = lcOut
	endproc

* appendUnicode: \uXXXX (y su pareja si es un sustituto alto) a la
* página 1252. Devuelve cuántos caracteres de la entrada consumió.
	hidden function appendUnicode(tcIn, tnAt, tcOut)
		local lnCode, lnLow, lcUtf16, lnSkip

		lnCode = this.hex4ToInt(substr(tcIn, tnAt + 2, 4))
		lcUtf16 = chr(bitand(lnCode, 0xFF)) + chr(bitrshift(lnCode, 8))
		lnSkip = 6

		if between(lnCode, 0xD800, 0xDBFF) and upper(substr(tcIn, tnAt + 6, 2)) == "\U" ;
				and this.isHex4(substr(tcIn, tnAt + 8, 4))
			lnLow = this.hex4ToInt(substr(tcIn, tnAt + 8, 4))
			if between(lnLow, 0xDC00, 0xDFFF)
				lcUtf16 = lcUtf16 + chr(bitand(lnLow, 0xFF)) + chr(bitrshift(lnLow, 8))
				lnSkip = 12
			endif
		endif

		if lnCode < 128
			tcOut = tcOut + chr(lnCode)
		else
			tcOut = tcOut + strconv(lcUtf16, 6, 1252, 1)
		endif

		return lnSkip
	endfunc

* isHex4: los cuatro caracteres de un \uXXXX. Sin esto, cualquier cosa
* detrás de una barra y una u se tomaba por un escape unicode.
	hidden function isHex4(tcText)
		local lnI

		if len(tcText) != 4
			return .f.
		endif
		for lnI = 1 to 4
			if !(upper(substr(tcText, lnI, 1)) $ "0123456789ABCDEF")
				return .f.
			endif
		next
		return .t.
	endfunc

* hex4ToInt: cuatro dígitos hex (ya validados por isHex4) a entero. Sin
* EVALUATE(): los consumidores con invariante de seguridad los cuentan.
	hidden function hex4ToInt(tcHex)
		local lnI, lnValue

		lnValue = 0
		for lnI = 1 to 4
			lnValue = lnValue * 16 + at(upper(substr(tcHex, lnI, 1)), "0123456789ABCDEF") - 1
		next
		return lnValue
	endfunc

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
