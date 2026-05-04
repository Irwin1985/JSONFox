* JSONFox Constants
*!* #Define T_NONE		'�'
#Define T_NONE		0
#Define T_EOT		chr(4)
#Define T_LBRACE	1
#Define T_RBRACE	2
#Define T_LBRACKET	3
#Define T_RBRACKET	4
#Define T_COMMA	5
#Define T_COLON	6
#Define T_TRUE	7
#Define T_FALSE	8
#Define T_NULL	9
#Define T_NUMBER	10
#Define T_KEY	11
#Define T_STRING	12
#Define T_LINE	13
#Define T_INTEGER	14
#Define T_FLOAT	15
#Define T_VALUE	16
#Define T_EOF	17
#Define T_BOOLEAN	18
#Define CR	Chr(13)
#Define LF	Chr(10)
#Define CRLF	CR + LF
#Define T_TAB	Chr(9)
#Define INTEGER_MAX_CAPACITY	2147483647


* ── src\jsonutils.prg ── *

&& ======================================================================== &&
&& Class utils
&& JSON Utilities
&& ======================================================================== &&
define class jsonutils as custom
	EscapeOptionalChars = .t.
	oRegEx = .null.

	dimension aPattern[8, 2]

	function init
		this.oRegEx = createobject("VBScript.RegExp")
		this.oRegEx.global = .t.
&& Match a date format in the following pattern
&& "YYYY-MM-DD"
		this.aPattern[1,1] = "^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])$"
		this.aPattern[1,2] = .f.

&& Match a date and time format in the following pattern
&& "YYYY-MM-DD HH:MM:SS"
		this.aPattern[2,1] = "^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01]) (00|0?[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9])$"
		this.aPattern[2,2] = .f.

&& Match ISO 8601 date and time formats that include a time zone offset
&& "YYYY-MM-DDTHH:MM:SSZ" OR "YYYY-MM-DDTHH:MM:SS+HH:MM" OR "YYYY-MM-DDTHH:MM:SS-HH:MM"
		this.aPattern[3,1] = "^(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})(\:(\d{2}))?(Z|[+-](\d{2})\:(\d{2}))?$"
		this.aPattern[3,2] = .f.

&& Match a date and time format in ISO 8601 combined with a single-character time zone identifier
&& "YYYY-MM-DDTHH:MM(:SS)?.SSS(W)"
		this.aPattern[4,1] = "^(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})(\:(\d{2}))?[.](\d{3})(\w{1})$"
		this.aPattern[4,2] = .f.

&& "DD/MM/YYYY" OR "DD-MM-YYYY"
		this.aPattern[5,1] = "^([0-2][0-9]|(3)[0-1])[\/-](((0)[0-9])|((1)[0-2]))[\/-]\d{4}$"
		this.aPattern[5,2] = .t.

&& "DD/MM/YYYY HH:MM:SS" or "DD-MM-YYYY HH:MM:SS"
		this.aPattern[06,1] = "^([0-2][0-9]|(3)[0-1])[\/-](((0)[0-9])|((1)[0-2]))[\/-]\d{4} (00|0?[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9])$"
		this.aPattern[06,2] = .t.

&& "DD/MM/YY" or "DD-MM-YY"
		this.aPattern[07,1] = "^([0-2][0-9]|(3)[0-1])[\/-](((0)[0-9])|((1)[0-2]))[\/-]\d{2}$"
		this.aPattern[07,2] = .t.

&& "DD/MM/YY HH:MM:SS" or "DD-MM-YY HH:MM:SS"
		this.aPattern[08,1] =  "^([0-2][0-9]|(3)[0-1])[\/-](((0)[0-9])|((1)[0-2]))[\/-]\d{2} (00|0?[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9])$"
		this.aPattern[08,2] = .t.

	endfunc

&& ======================================================================== &&
&& Function GetValue
&& ======================================================================== &&
	function getValue as string
		lparameters tcvalue as string, tctype as character, tlParseUTF8 as Boolean, tlTrimChars as Boolean
		do case
		case tctype $ "CDTBGMQVWX"
			do case
			case tctype == 'D'
				tcvalue = '"' + strtran(dtoc(tcvalue), '.', '-') + '"'
			case tctype == 'T'
				tcvalue = '"' + strtran(ttoc(tcvalue), '.', '-') + '"'
			case tctype == 'X'
				tcvalue = "null"
			otherwise
				tcvalue = this.getString(iif(tlTrimChars, alltrim(tcvalue), tcvalue), tlParseUTF8)
			endcase
		case tctype $ "YFIN"
			if this.HasDecimals(tcvalue)
				tcvalue = strtran(alltrim(transform(tcvalue, "@T")), ',', '.')
			else
				tcvalue = strtran(alltrim(transform(tcvalue)), ',', '.')
			endif
		case tctype == 'L'
			tcvalue = iif(tcvalue, "true", "false")
		endcase
		return tcvalue
	endfunc

	function HasDecimals(tnValue, tnTolerance)
		if pcount() < 2
			tnTolerance = 0.0000001
		endif
		return abs(tnValue - int(tnValue)) > tnTolerance
	endfunc

&& ======================================================================== &&
&& Function CheckString
&& Check the string content in case it is a date or datetime.
&& String itself or string date / datetime format.
&& ======================================================================== &&
	function CheckString(tcString)
		if !isdigit(left(tcString, 1)) and !isdigit(right(tcString, 1))
			return tcString
		endif
* We try to identify a date format
		local i
		for i = 1 to alen(this.aPattern, 1)
			this.oRegEx.pattern = this.aPattern[i, 1]
			if this.oRegEx.Test(tcString)
				return evl(this.formatDate(tcString, this.aPattern[i, 2]), tcString)
			endif
		endfor
* It is a normal String
		return tcString
	endfunc
&& ======================================================================== &&
&& Function FormatDate
&& return a valid date or datetime date type.
&& ======================================================================== &&
	function formatDate as variant
		lparameters tcDate as string, tlUseDMY as Boolean
		local lDate
		lDate = .null.
&& IRODG 20210313 ISSUE # 14
		do case
		case 'T' $ tcDate && JavaScript or ISO 8601 format.
			do case
			case '+' $ tcDate
				tcDate = getwordnum(tcDate, 1, '+')
			case at('-', tcDate, 3) > 0
				tcDate = substr(tcDate, 1, at('-', tcDate, 3)-1)
			otherwise
			endcase
			try
				setDateAct = set('Date')
				set date ymd
				lDate = ctot('^'+tcDate)
			catch
				lDate = {//::}
			finally
				set date &setDateAct
			endtry
		case occurs(':', tcDate) >= 2 && VFP Date Time Format. 'YYYY-mm-dd HH:mm:ss' and also 'dd-mm-yyyy hh:mm:ss'
			try
				setDateAct = set('Date')
*	set date ymd
&& (DCA) - 12/09/2023 - Also verify if the DateTime is DMY Format
				if !tlUseDMY
					set date ymd
				else
					set date dmy
				endif

				lDate = ctot(tcDate)
			catch
				lDate = {//::}
			finally
				set date &setDateAct
			endtry
		otherwise
			try
				setDateAct = set('Date')
				if !tlUseDMY
					set date ymd
				else
					set date dmy
				endif
				lDate = ctod(tcDate)
			catch
				lDate = {//}
			finally
				set date &setDateAct
			endtry
		endcase
		return lDate
&& IRODG 20210313 ISSUE # 14
	endfunc
&& ======================================================================== &&
&& Function GetString
&& ======================================================================== &&
&& ======================================================================== &&
&& Function GetString
&& ======================================================================== &&
	function getString as string
		lparameters tcString as string, tlParseUTF8 as Boolean
		local llEscapeOptionalChars

* Obtener la configuraci�n de escape opcional desde la clase
		llEscapeOptionalChars = this.EscapeOptionalChars

* Validar par�metro de entrada
		tcString = iif(vartype(tcString) != "C", "", tcString)

* ESCAPES OBLIGATORIOS seg�n el est�ndar RFC 8259
		tcString = strtran(tcString, '\', '\\' )  && Barra invertida
		tcString = strtran(tcString, chr(8),  '\b' )   && Backspace		
		tcString = strtran(tcString, chr(9),  '\t' )  && Tabulaci�n
		tcString = strtran(tcString, chr(10), '\n' )  && Nueva l�nea
		tcString = strtran(tcString, chr(12), '\f' )   && Form feed
		tcString = strtran(tcString, chr(13), '\r' )  && Retorno de carro		

* Manejo de comillas
		if left(alltrim(tcString), 1) == '"' and right(alltrim(tcString),1) == '"'
			tcString = substr(tcString, 2, len(tcString)-2)
		endif
		tcString = strtran(tcString, '"', '\"' )  && Comillas dobles (obligatorio)

* Escapar TODOS los caracteres > 127 autom�ticamente
		local i, nChar, lcChar, lcResult
		lcResult = ""
		for i=1 to len(tcString)
			lcChar = substr(tcString,i,1)
			nChar = asc(lcChar)
			
			if nChar > 127
				* convertir a escape Unicode \uXXXX
				lcResult = lcResult + '\u' + right('0000' + transform(nChar, '@0'), 4)				
			else
				lcResult = lcResult + lcChar
			endif
		next
		
		tcString = lcResult

		* ESCAPES OPCIONALES
		if tlParseUTF8
			* Caracteres especiales
			tcString = strtran(tcString,"&","\u0026")
			tcString = strtran(tcString,"+","\u002b")
			tcString = strtran(tcString,"-","\u002d")
			tcString = strtran(tcString,"#","\u0023")
			tcString = strtran(tcString,"%","\u0025")
		endif

		* A�adir comillas si no las tiene
		LOCAL lnLen, lcLastChar, lcPrevChar

		lnLen = LEN(tcString)
		lcLastChar = RIGHT(tcString, 1)
		lcPrevChar = IIF(lnLen > 1, SUBSTR(tcString, lnLen-1, 1), "")

		* Verificar si inicia con comilla y termina con comilla NO escapada
		IF LEFT(tcString, 1) != '"' OR lcLastChar != '"' OR lcPrevChar = "\"
		    RETURN '"' + tcString + '"'
		ENDIF

		return tcString
	endfunc
&& ======================================================================== &&
&& Function CheckProp
&& Check the object property name for invalid format (replace space with '_')
&& ======================================================================== &&
	function checkprop(tcprop as string) as string
		local lcfinalprop, i, lcchar
		lcfinalprop = ''
		for i = 1 to len(tcprop)
			lcchar = substr(tcprop, i, 1)
			if (i = 1 and isdigit(lcchar)) or (!isalpha(lcchar) and !isdigit(lcchar))
				lcfinalprop = lcfinalprop + "_"
			else
				lcfinalprop = lcfinalprop + lcchar
			endif
		endfor
		return alltrim(lcfinalprop)
	endfunc

	function tokenTypeToStr(tnType)
		do case
		case tnType = 0
			return 'EOF'
		case tnType = 1
			return 'LBRACE'
		case tnType = 2
			return 'RBRACE'
		case tnType = 3
			return 'LBRACKET'
		case tnType = 4
			return 'RBRACKET'
		case tnType = 5
			return 'COMMA'
		case tnType = 6
			return 'COLON'
		case tnType = 7
			return 'TRUE'
		case tnType = 8
			return 'FALSE'
		case tnType = 9
			return 'NULL'
		case tnType = 10
			return 'NUMBER'
		case tnType = 11
			return 'KEY'
		case tnType = 12
			return 'STRING'
		case tnType = 13
			return 'LINE'
		case tnType = 14
			return 'INTEGER'
		case tnType = 15
			return 'FLOAT'
		case tnType = 16
			return 'VALUE'
		case tnType = 17
			return 'EOF'
		case tnType = 18
			return 'BOOLEAN'
		endcase
	endfunc
enddefine


* ── src\tokenizer.prg ── *

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
				return '�'
			endif
			return substr(.source, .current, 1)
		endwith
	endfunc

	hidden function peekNext
		with this
			if (.current + 1) > .sourceLen
				return '�'
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
* Si no es una secuencia de escape conocida, mantener ambos caracteres
						lcResult = lcResult + "\" + lcNextChar
					endcase
					i = i + 2 && Avanzar 2 caracteres
				else
					lcResult = lcResult + lcChar
					i = i + 1 && avanzar un car�cter
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
		local lcUnicode, lcConversion, lbReplace, lnPos
		lnPos = 1
		do while .t.
			lbReplace = .f.
			lcUnicode = substr(tcLexeme, at('\u', tcLexeme, lnPos), 6)
			if len(lcUnicode) == 6
				lbReplace = .t.
			else
				lcUnicode = substr(tcLexeme, at('\U', tcLexeme, lnPos), 6)
				if len(lcUnicode) == 6
					lbReplace = .t.
				endif
			endif
			if lbReplace
				tcLexeme = strtran(tcLexeme, lcUnicode, strtran(strconv(lcUnicode,16), chr(0)))
			else
				exit
			endif
		enddo
&& IRODG 09/10/2023 Fin
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

* Crear una copia de los tokens
			local i
			for i = 1 to .capacity
* Si los tokens son objetos, crear copias profundas
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
* Liberar el array de tokens
			if type('this.tokens', 1) == 'A' and alen(this.tokens) > 1
				local i
				for i = 1 to alen(this.tokens)
					if type('this.tokens[i]') = 'O'
* Liberar propiedades del objeto token
						this.tokens[i] = .null.
					endif
				next
* Redimensionar el array a tama�o m�nimo
				dimension this.tokens[1]
				this.tokens[1] = .null.
			endif

* Liberar otras variables que puedan ocupar mucha memoria
			this.source = ""
			this.sourceLen = 0
			this.capacity = 0
			this.length = 1
		endwith
		return .t.
	endfunc

enddefine


* ── src\parser.prg ── *

&& ======================================================================== &&
&& JsonParser
&& EBNF Grammar
&& object = '{' kvp | { ',' kvp } '}'
&& kvp    = KEY ':' value
&& value  = STRING | NUMBER | BOOLEAN | array | object | null
&& array  = '[' value | { ',' value }  ']'
&& ======================================================================== &&
define class Parser as custom
	Hidden current
	Hidden previous
	Hidden peek
	hidden problematicFields
	hidden tokenCollection
	hidden lUseArrayObjects
	oUtils = .null.

	function init(toScanner, tlUseArrayObjects)
		this.tokenCollection = toScanner.scanTokens()
		this.current = 1
		this.lUseArrayObjects = IIF(PCOUNT() > 1, tlUseArrayObjects, .F.)		
		this.problematicFields = createobject("Collection")
		this.problematicFields.Add("messages", "messages")
		this.problematicFields.Add("update", "update")
	endfunc

	function Parse
		private JSONUtils
		JSONUtils = iif(vartype(this.oUtils) == 'O', this.oUtils, _screen.jsonUtils)
		local loParsedObject
		loParsedObject = this.value()
		this.CleanUp()

		return loParsedObject
	endfunc
	&& ======================================================================== &&
	&& Function Object
	&& EBNF -> 	object = '{' kvp ( ',' kvp )* '}'
	&& 			kvp    = KEY ':' value
	&& ======================================================================== &&
	hidden function object as object
		local loObj, loPair, lcMacro
		loObj = createobject('Empty')
		if !this.check(T_RBRACE)
			loPair = this.kvp()
			this.addKeyValuePair(@loObj, @loPair)
			
			do while this.match(T_COMMA)
				loPair = this.kvp()
				this.addKeyValuePair(@loObj, @loPair)
			enddo
		endif
		this.consume(T_RBRACE, "Expect '}' after JSON body.")			
		return loObj
	endfunc
	&& ======================================================================== &&
	&& Function Kvp
	&& EBNF -> 	kvp = KEY ':' value
	&& ======================================================================== &&
	hidden function kvp(toObj)		
		local loPair, lvValue
		
		loPair = CreateObject('Empty')
		=AddProperty(loPair, 'key', '')
	
		this.consume(T_STRING, "Expect key name")
		loPair.key = JSONUtils.CheckProp(this.previous.value)
		this.consume(T_COLON, "Expect ':' after key element.")
		lvValue = this.value()

		if this.lUseArrayObjects
			=AddProperty(loPair, 'value', lvValue)
		else
			If Type('lvValue', 1) != 'A'
				=AddProperty(loPair, 'value', lvValue)
			Else
				=AddProperty(loPair, 'value[1]', .Null.)
				Acopy(lvValue, loPair.value)
			endif
		endif

		Return loPair
	EndFunc

	Hidden function addKeyValuePair(toObject, toPair)
		local lAddObject
		lAddObject = .f.
		if this.lUseArrayObjects
			=AddProperty(toObject, toPair.key, toPair.value)			
		else
			If Type('toPair.value', 1) != 'A'
				=AddProperty(toObject, toPair.key, toPair.value)
			else
				lAddObject = .t.
			endif
		endif

		if lAddObject
			local lcMacro
			if this.problematicFields.GetKey(toPair.key) > 0
				local lcArrayName		
				lcArrayName = toPair.key + "_array"				
				lcMacro = "AddProperty(toObject, '" + lcArrayName + "[1]', .null.)"
				&lcMacro
				
				lcMacro = "Acopy(toPair.value, toObject." + lcArrayName + ")"
				&lcMacro
				
				=addproperty(toObject, "_specialArray_" + lcArrayName, toPair.key)
			else
				Local lcMacro
				lcMacro = "AddProperty(toObject, '" + toPair.key + "[1]', .Null.)"
				&lcMacro
				lcMacro = "Acopy(toPair.value, toObject." + toPair.key + ")"
				&lcMacro
			endif
		endif
	EndFunc
		
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
	&& ======================================================================== &&
	hidden function value
		do case
		case this.match(T_STRING)
			return JSONUtils.CheckString(this.previous.value)
			
		case this.match(T_NUMBER)
			Local lcValue, lcPoint
			lcValue = this.previous.value
			lcPoint = Set("Point")
			
			If lcPoint != '.'
				lcValue = Strtran(lcValue, '.', lcPoint)
			EndIf
			return iif(at(lcPoint, lcValue) > 0, evaluate(lcValue), int(Val(lcValue)))
			
		case this.match(T_BOOLEAN)
			return (this.previous.value == 'true')

		case this.match(T_LBRACE)
			return this.object()

		case this.match(T_LBRACKET)
			if this.lUseArrayObjects
				return this.array()
			endif
			return @this.array()
			
		case this.match(T_NULL)
			return .null.
		otherwise
			error "Parser Error: Unknown token value: '" + JSONUtils.tokenTypeToStr(this.peek.type) + "'"
		EndCase
	endfunc
	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array = '[' value | { ',' value }  ']'
	&& ======================================================================== &&
	hidden function array
		local laArray
		if this.lUseArrayObjects
			laArray = createobject("TParserInternalArrayCollectionBased")
		else
			laArray = createobject("TParserInternalArray")
		endif
		
		If !this.check(T_RBRACKET)
			laArray.Push(this.value())
			do while this.match(T_COMMA)
				laArray.Push(this.value())
			enddo
		endif
		this.consume(T_RBRACKET, "Expect ']' after array elements.")

		if this.lUseArrayObjects
			return laArray
		endif
		return @laArray.getArray()
	endfunc
	
	Function match(tnTokenType)
		If this.check(tnTokenType)
			this.advance()
			Return .t.
		EndIf
		Return .f.
	EndFunc

	Hidden Function consume(tnTokenType, tcMessage)
		If this.check(tnTokenType)
			Return this.advance()
		EndIf
		if empty(tcMessage)
			tcMessage = "Parser Error: expected token '" + JSONUtils.tokenTypeToStr(tnTokenType) + "' got = '" + JSONUtils.tokenTypeToStr(this.peek.type) + "'"
		endif
		error tcMessage
	endfunc

	Hidden Function check(tnTokenType)
		If this.isAtEnd()
			Return .f.
		EndIf
		Return this.peek.type == tnTokenType
	EndFunc 

	Hidden Function advance
		If !this.isAtEnd()
			this.current = this.current + 1
		EndIf
		Return this.tokenCollection.tokens[this.current-1]
	endfunc

	Hidden Function isAtEnd
		Return this.peek.type == T_EOF
	endfunc

	Hidden Function peek_access
		Return this.tokenCollection.tokens[this.current]
	endfunc

	Hidden Function previous_access
		Return this.tokenCollection.tokens[this.current-1]
	endfunc
	
	function CleanUp
		with this
			.TokenCollection = .null.
			.current = 0
			.previous = .null.
			.peek = .null.
		endwith
	endfunc
	
EndDefine

* ============================================================ *
* TParserInternalArray
* ============================================================ *
Define Class TParserInternalArray As Custom
	Dimension aCustomArray[1]
	nIndex = 0
	
	Function Push(tvItem)
		this.nIndex = this.nIndex + 1
		Dimension this.aCustomArray[this.nIndex]
		this.aCustomArray[this.nIndex] = tvItem
	Endfunc
	
	Function GetArray
		Return @this.aCustomArray
	EndFunc
enddefine

* ============================================================ *
* TParserInternalArrayCollectionBased
* ============================================================ *
Define Class TParserInternalArrayCollectionBased As Collection	
	Function Push(tvItem)
		this.Add(tvItem)
	Endfunc	
	
	function Get(tnIndex)
		if between(tnIndex, 1, this.Count)
			return this.Item(tnIndex)
		endif
		
		return .null.
	endfunc
Enddefine

* ── src\jsonstringify.prg ── *

&& ======================================================================== &&
&& Stringify
&& EBNF		object 	= '{' format kvp | {',' format kvp} '}'
&& 			format 	= JSPACE * nTimes
&& 			kvp		= KEY ':' value | {',' KEY ':' value}
&&			value	= STRING | NUMBER | BOOLEAN | NULL | array | object
&& 			array	= '[' value | {',' value} ']'
&& ======================================================================== &&
define class JSONStringify as custom

	ParseUtf8 = .f.
	TrimChars = .f.
	oUtils = .null.

	Hidden current
	Hidden previous
	Hidden peek
	hidden tokenCollection

	function init(toScanner)
		this.tokenCollection = toScanner.scanTokens()
		this.current = 1
	endfunc
	
	* Stringify
	function Stringify as memo
		lparameters tlParseUtf8, tlTrimChars
		private JSONUtils
		JSONUtils = iif(vartype(this.oUtils) == 'O', this.oUtils, _screen.jsonUtils)
		local lcFormatedJson
		this.ParseUtf8 = tlParseUtf8
		this.TrimChars = tlTrimChars
		
		lcFormatedJson = this.value(0)
		this.CleanUp()
		if !empty(lcFormatedJson)
			lcFormatedJson = strconv(lcFormatedJson,9)
		endif
		return lcFormatedJson
	endfunc
	&& ======================================================================== &&
	&& Function Object
	&& EBNF		object 	= '{' format kvp | {',' format kvp} '}'
	&& 			format 	= JSPACE * nTimes
	&& 			kvp		= KEY ':' value | {',' KEY ':' value}
	&&			value	= STRING | NUMBER | BOOLEAN | NULL | array | object
	&& 			array	= '[' value | {',' value} ']'
	&& ======================================================================== &&
	hidden function object(tnSpace)
		if !this.check(T_RBRACE)
			local nSpaceBlock, lcJSON as string
			nSpaceBlock = tnSpace + 1
			lcJSON = '{' + CRLF + this.JSFormat(nSpaceBlock)
			lcJSON = lcJSON + this.kvp(nSpaceBlock)
			do while this.match(T_COMMA)
				lcJSON = lcJSON + ',' + CRLF + this.JSFormat(nSpaceBlock)
				lcJSON = lcJSON + this.kvp(nSpaceBlock)
			enddo
			lcJSON = lcJSON + CRLF + this.JSFormat(tnSpace) + '}'
		else
			lcJSON = '{}'
		endif
		this.consume(T_RBRACE, "Expect '}' after json object.")
		return lcJSON
	endfunc
	&& ======================================================================== &&
	&& Hidden Function kvp
	&& EBNF		kvp	= KEY ':' value | {',' KEY ':' value}
	&& ======================================================================== &&
	hidden function kvp
		lparameters tnSpaceIdent as integer
		local lcProp as string
		this.consume(T_STRING, "Expect right key element")
		lcProp = JSONUtils.GetString(this.previous.value, this.ParseUtf8)
		this.consume(T_COLON, "Expect ':' after key element.")		
		*return '"' + lcProp + '": ' + this.value(tnSpaceIdent)
		return lcProp + ': ' + this.value(tnSpaceIdent)
	endfunc
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | array | object | NULL
	&& ======================================================================== &&
	hidden function value(tnSpaceBlock)
		do case
		case this.match(T_STRING)
			return JSONUtils.GetString(Iif(this.TrimChars, Alltrim(this.previous.value), this.previous.value), this.ParseUtf8)			

		case this.match(T_NUMBER)
			return this.previous.value

		case this.match(T_BOOLEAN)
			return this.previous.value

		case this.match(T_LBRACKET)
			return this.array(tnSpaceBlock)

		case this.match(T_LBRACE)
			return this.object(tnSpaceBlock)

		case this.match(T_NULL)
			return "null"

		otherwise
			this.consume(this.cur_token.type, '')
			return this.previous.value
		endcase
	endfunc
	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array = '[' value | { ',' value }  ']'
	&& ======================================================================== &&
	hidden function array as VOID
		lparameters tnIdentation as integer
		local lcArrayStr as string
		lcArrayStr = ''
		if !this.check(T_RBRACKET)
			local lnBlock as integer
			lnBlock = tnIdentation + 1
			lcArrayStr = '[' + CRLF + this.JSFormat(lnBlock)
			lcArrayStr = lcArrayStr + this.value(lnBlock)
			do while this.match(T_COMMA)
				lcArrayStr = lcArrayStr + ',' + CRLF + this.JSFormat(lnBlock)
				lcArrayStr = lcArrayStr + this.value(lnBlock)
			enddo
			lcArrayStr = lcArrayStr + CRLF + this.JSFormat(tnIdentation) + ']'
		else
			lcArrayStr = '[]'
		endif
		this.consume(T_RBRACKET, "Expect ']' after array elements.")
		return lcArrayStr
	endfunc
	&& ======================================================================== &&
	&& Hidden Function JSFormat
	&& ======================================================================== &&
	hidden function JSFormat as string
		lparameters tnSpaceMult as integer
		return space(tnSpaceMult * 2)
	EndFunc

	Function match(tnTokenType)
		If this.check(tnTokenType)
			this.advance()
			Return .t.
		EndIf
		Return .f.
	EndFunc

	Hidden Function consume(tnTokenType, tcMessage)
		If this.check(tnTokenType)
			Return this.advance()
		EndIf
		if empty(tcErrorMessage)
			tcErrorMessage = "Parser Error: expected token '" + JSONUtils.tokenTypeToStr(tnTokenType) + "' got = '" + JSONUtils.tokenTypeToStr(this.peek.type) + "'"
		endif
		error tcErrorMessage
	endfunc

	Hidden Function check(tnTokenType)
		If this.isAtEnd()
			Return .f.
		EndIf
		Return this.peek.type == tnTokenType
	EndFunc 

	Hidden Function advance
		If !this.isAtEnd()
			this.current = this.current + 1
		EndIf
		Return this.tokenCollection.tokens[this.current-1]
	endfunc

	Hidden Function isAtEnd
		Return this.peek.type == T_EOF
	endfunc

	Hidden Function peek_access
		Return this.tokenCollection.tokens[this.current]
	endfunc

	Hidden Function previous_access
		Return this.tokenCollection.tokens[this.current-1]
	EndFunc
	
	function CleanUp
		with this
			.TokenCollection = .null.
			
			.current = 0
			.previous = .null.
			.peek = 0
		endwith
	endfunc
enddefine


* ── src\objecttojson.prg ── *
* ObjectToJSON
define class ObjectToJSON as session
	#define USER_DEFINED_PEMS	'U'
	#define ALL_MEMBERS			"PHGNUCIBR"
	lCentury = .f.
	cDateAct = ''
	nOrden   = 0
	cFlags 	 = ''
	parseUTF8 = .f.
	TrimChars = .f.
	oUtils = .null.

	* Function Init
	function init
		this.lCentury = set("Century") == "OFF"
		this.cDateAct = set("Date")
		set century on
		set date ansi
		mvcount = 60000
	endfunc
	
	* Encode
	function Encode(toRefObj, tcFlags, tlParseUTF8, tlTrimChars)
		private JSONUtils
		JSONUtils = iif(vartype(this.oUtils) == 'O', this.oUtils, _screen.jsonUtils)
		lPassByRef = .t.
		try
			external array toRefObj
		catch
			lPassByRef = .f.
		endtry
		this.cFlags = evl(tcFlags, USER_DEFINED_PEMS)
		this.parseUTF8 = tlParseUTF8
		this.TrimChars = tlTrimChars
		if lPassByRef
			return this.AnyToJson(@toRefObj)
		else
			return this.AnyToJson(toRefObj)
		endif
	endfunc
	
	function EncodeFromSchema(toRefObj, tcSchema, tlParseUTF8, tlTrimChars)
		
	endfunc
	
	* AnyToJson
	function AnyToJson as memo
		lparameters tValue as Variant
		try
			external array tValue
		catch
		endtry
		do case
		case type("tValue", 1) = 'A'
			local k, j, lcArray
			if alen(tValue, 2) == 0
				*# Unidimensional array
				lcArray = '['
				for k = 1 to alen(tValue)
					lcArray = lcArray + iif(len(lcArray) > 1, ',', '')
					try
						local array laLista[1]
						=acopy(tValue[k], laLista)
						lcArray = lcArray + this.AnyToJson(@laLista)
					catch
						lcArray = lcArray + this.AnyToJson(tValue[k])
					endtry
				endfor
				lcArray = lcArray + ']'
			else
				*# Multidimensional array support
				lcArray = '['
				for k = 1 to alen(tValue, 1)
					lcArray = lcArray + iif(len(lcArray) > 1, ',', '')

					* # begin of rows
					lcArray = lcArray + '['
					for j = 1 to alen(tValue, 2)
						if j > 1
							lcArray = lcArray + ','
						endif
						try
							local array laLista[1]
							=acopy(tValue[k, j], laLista)
							lcArray = lcArray + this.AnyToJson(@laLista)
						catch
							lcArray = lcArray + this.AnyToJson(tValue[k, j])
						endtry
					endfor
					lcArray = lcArray + ']'
					* # end of rows
				endfor
				lcArray = lcArray + ']'
			endif
			return lcArray

		case vartype(tValue) = 'O'
			* Primero verificamos si es una colecci�n para procesarla de manera especial
			llIsCollection = .f.
			try				
				llIsCollection = (tValue.BaseClass == "Collection" and tValue.Class == "Collection" and tValue.Name == "Collection")
			catch
			endtry
			
			if llIsCollection
				* Verificamos si la colecci�n tiene claves (key-value) o solo valores
				local lnCount, i, lcResult, llHasKeys, lcKey
				lnCount = tValue.Count
				llHasKeys = .f.
				
				* Intentamos obtener la clave del primer elemento para determinar si es key-value
				if lnCount > 0
					try
						lcKey = tValue.GetKey(1)
						if !empty(lcKey)
							llHasKeys = .t.
						endif
					catch
					endtry
				endif
				
				if llHasKeys
					* Es una colecci�n con pares clave-valor, la tratamos como objeto
					lcResult = '{'
					for i = 1 to lnCount
						lcKey = tValue.GetKey(i)
						lcResult = lcResult + iif(i > 1, ',', '') + '"' + lcKey + '":' + this.AnyToJson(tValue.Item(i))
					endfor
					lcResult = lcResult + '}'
				else
					* Es una colecci�n solo con valores, la tratamos como array
					lcResult = '['
					for i = 1 to lnCount
						lcResult = lcResult + iif(i > 1, ',', '') + this.AnyToJson(tValue.Item(i))
					endfor
					lcResult = lcResult + ']'
				endif
				
				return lcResult
			else
				* No es una colecci�n, procesamos como un objeto normal
				local j, lcJSONStr, lnTot, i, lcProp, lcOriginalName
				local array gaMembers(1)

				lcJSONStr = '{'
				lnTot = amembers(gaMembers, tValue, 0, this.cFlags)
				
				local array laPropsToProcess[1]
				local lnPropCount, lnIdx
				lnPropCount = 0
				
				* primer paso: identificar y clasificar las propiedades
				for j=1 to lnTot
					lcProp = lower(alltrim(gaMembers[j]))
					* Ignoramos propiedades especiales de array
					if left(lower(lcProp), 14) == "_specialarray_"
						loop
					endif

					lnPropCount = lnPropCount + 1
					dimension laPropsToProcess[lnPropCount,2]
					laPropsToProcess[lnPropCount, 1] = lcProp
					if right(lcProp, 6) == "_array" and type("tValue._specialArray_" + lcProp) == "C"					
						laPropsToProcess[lnPropCount, 2] = "special_array"
					else					
						laPropsToProcess[lnPropCount, 2] = "normal"					
					endif
				next
				
				* segundo paso: procesar las propiedades filtradas
				for lnIdx=1 to lnPropCount
					lcProp = laPropsToProcess[lnIdx, 1]								
					
					if laPropsToProcess[lnIdx, 2] == "special_array"
						lcOriginalName = evaluate("tValue._specialArray_" + lcProp)
						lcJSONStr = lcJSONStr + iif(len(lcJSONStr) > 1, ',', '') + '"' + lcOriginalName + '":'
						try
							local array laLista[1]
							=acopy(tValue. &lcProp, laLista)
							lcJSONStr = lcJSONStr + this.AnyToJson(@laLista)
						catch
							lcJSONStr = lcJSONStr + "[]"
						endtry
					else
						* Es una propiedad normal
						lcJSONStr = lcJSONStr + iif(len(lcJSONStr) > 1, ',', '') + '"' + lcProp + '":'
						try
							local array laLista[1]
							=acopy(tValue. &lcProp, laLista)
							lcJSONStr = lcJSONStr + this.AnyToJson(@laLista)
						catch
							try
								lcJSONStr = lcJSONStr + this.AnyToJson(tValue. &lcProp)
							catch
								lcJSONStr = lcJSONStr + "{}"
							endtry
						endtry
					endif				
				endfor

				lcJSONStr = lcJSONStr + '}'
				return lcJSONStr
			endif
		otherwise
			return JSONUtils.GetValue(tValue, vartype(tValue), this.parseUTF8, this.TrimChars)
		endcase
	endfunc
	
	* Destroy
	function destroy
		if this.lCentury
			set century off
		endif
		lcDateAct = this.cDateAct
		set date &lcDateAct
	endfunc
enddefine

* ── src\arraytocursor.prg ── *

* ArrayToCursor
Define Class ArrayToCursor As Session
	#Define STRING_MAX_SIZE	254

	curname 	 = ""
	nSessionID 	 = 0
	oTableStruct = .Null.
	oUtils       = .null.

	Dimension aRows(1)
	nRowCount = 0

	Hidden current
	Hidden previous
	Hidden peek
	hidden tokenCollection
	
	Hidden capacity
	Hidden length


	function init(toScanner)
		With this
			Local laTokens
			.tokenCollection = toScanner.scanTokens()
			
			.current = 1
			.oTableStruct = Createobject('Collection')

			.length = 1
			.capacity = 0
		endwith
	endfunc

	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array  	= '[' object | { ',' object }  ']'
	&& ======================================================================== &&
	Function Array As Void
		private JSONUtils
		JSONUtils = iif(vartype(this.oUtils) == 'O', this.oUtils, _screen.jsonUtils)
		With this
			If Empty(.nSessionID)
				.nSessionID = Set("Datasession")
			Endif
			Set DataSession To (.nSessionID)

			.consume(T_LBRACKET, "Expect '[' before Array definition.")
			
			If !.match(T_RBRACKET)
				.addRow(.Object())

				Do While .match(T_COMMA)
					.addRow(.Object())
				Enddo
			EndIf
			.consume(T_RBRACKET, "Expect ']' after Array definition.")

			* Shrink array
			.capacity = .length-1
			Dimension .aRows[.capacity]
			
			.InsertData()
			.CleanUp()
		endwith
	EndFunc
	
	hidden function addRow(toValue)
		With this
			.checkCapacity()
			.aRows[.length] = toValue
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
				Dimension .aRows[.capacity]
			EndIf
		EndWith
	endfunc
	
	&& ======================================================================== &&
	&& Function Object
	&& EBNF -> 	object 	= '{' kvp | { ',' kvp} '}'
	&& ======================================================================== &&
	Hidden Function Object As Void
		With this
			Local loCollection, loPair
			.consume(T_LBRACE, "Expect '{' before json object.")
			loCollection = Createobject("Collection")
			
			If !.check(T_RBRACE)
				loPair = .kvp()
				loCollection.Add(loPair.Value, loPair.Field)

				Do While .match(T_COMMA)
					loPair = .kvp()
					loCollection.Add(loPair.Value, loPair.Field)
				EndDo
			endif
			.consume(T_RBRACE, "Expect '}' after json object.")
			
			Return loCollection
		EndWith
	Endfunc
	&& ======================================================================== &&
	&& Function Kvp
	&& EBNF -> 	kvp 	= KEY ':' value
	&& 			value	= STRING | NUMBER | BOOLEAN	| NULL
	&& ======================================================================== &&
	Hidden Function kvp
		With this
			Local lcProp, lxValue, lcType, lnFieldLength, lcFieldName, lnDecimals, loPair

			.consume(T_STRING, "Expect right key element")
			lcProp = .previous.value
			.consume(T_COLON, "Expect ':' after key element.")
			
			lcFieldName = Space(1)		
			lxValue = .Value()
			lcType  = lxValue.Type
			lnFieldLength = 0
			lnDecimals = 0
			Do Case
			Case lcType == 'N'
				local lcNumStr
				lcNumStr = lxValue.Literal
				lcType = Iif(Occurs('.', lcNumStr) > 0 or lxValue.Value > INTEGER_MAX_CAPACITY, 'N', 'I')
				&& >>>>>>> IRODG 03/17/24
				If lcType == 'N'
					lnFieldLength = Len(lcNumStr)
					lnDecimals = len(GetWordNum(lcNumStr,2,'.'))
				EndIf
				&& <<<<<<< IRODG 03/17/24
			Case lcType == 'C'
				If Len(lxValue.Value) > STRING_MAX_SIZE
					lcType = 'M'
				Else
					lxValue.Value = JSONUtils.CheckString(lxValue.Value)
					lcType  = Vartype(lxValue.Value)
				Endif
				If lcType == 'C'
					lnFieldLength = Iif(Empty(Len(lxValue.Value)), 1, Len(lxValue.Value))
				Endif
			Endcase
			lcFieldName = Lower(JSONUtils.CheckProp(lcProp))
			.CheckStructure(lcFieldName, lcType, lnFieldLength, lnDecimals)

			* Set Key-Value pair object
			loPair = CreateObject("Empty")
			=AddProperty(loPair, "field", lcFieldName)
			=AddProperty(loPair, "value", lxValue.Value)
			
			release lxValue
			
			Return loPair
		EndWith
	Endfunc
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | NULL
	&& ======================================================================== &&
	Hidden Function Value As Variant
		With this
			local loToken
			loToken = createobject("Empty")
			addproperty(loToken, "type", "")
			addproperty(loToken, "literal", "")
			addproperty(loToken, "value", .null.)
			
			Do Case
			Case .match(T_STRING)
				loToken.type = 'C'
				loToken.literal = .previous.value
				loToken.value = .previous.value
			case .match(T_NUMBER)
				Local lcValue
				lcValue = .previous.value
				loToken.type = 'N'
				loToken.literal = .previous.value
				loToken.value = iif(at('.', lcValue) > 0, evaluate(lcValue), int(Val(lcValue)))

			case .match(T_BOOLEAN)
				loToken.type = 'L'
				loToken.literal = .previous.value
				loToken.value = (.previous.value == 'true')
			case .match(T_NULL)
				loToken.type = 'X'
				loToken.literal = 'null'
				loToken.value = .null.
			Otherwise
				Error "Parser Error: This token is invalid in for cursor conversion: '" + JSONUtils.tokenTypeToStr(.peek.type) + "'"
			endcase
		endwith
		return loToken
	Endfunc
	* InsertData
	Hidden Function InsertData
		With this
			.CreateCursor()
			Local loMap, i, j, cField, xValue

			For i = 1 To Alen(.aRows, 1)
				loMap = .aRows[i]
				Select (.curname)
				Append BLANK
				For j = 1 to loMap.Count
					cField = loMap.GetKey(j)
					xValue = loMap.Item(j)
					replace (cField) with xValue
				EndFor
			EndFor
			Go top in (.curName)
		EndWith
	Endfunc	
	* CreateCursor
	Hidden Function CreateCursor
		With this
			Local cQuery, lcComma, j, loPair, cField, lcFlags
			cQuery  = "CREATE CURSOR " + .curname + " ("
			lcComma = ''
			j = 0
			loPair = .Null.
			cField = ''
			
			For j = 1 to .oTableStruct.count 
				cField  = .oTableStruct.GetKey(j)
				loPair  = .oTableStruct.Item(j)
				lcComma = Iif(j > 1, ',', Space(1))
				cQuery  = cQuery + lcComma + cField + Space(1)
				lcFlags = ''

				* Use Logical (faster) type for .Null. Columns.
				Do case
				case loPair.FieldType == 'X'
					loPair.FieldType = 'L'
				Case loPair.FieldType == 'C'
					lcFlags = '(' + Alltrim(Str(loPair.FieldLength)) + ')'
				Case loPair.FieldType == 'N'					
					lcFlags = "("+Alltrim(Str(loPair.FieldLength))+","+Alltrim(Str(loPair.FieldDecimals))+")" && Integer part 18 and Decimal part 5
				EndCase
				cQuery = cQuery + loPair.FieldType + lcFlags + " NULL"			
			EndFor
			cQuery = cQuery + ')'
			Try
				&cQuery
			Catch To loEx
				Error loEx.Message
			EndTry
		EndWith
	Endfunc
	* ============================================================= *
	* CheckStructure
	* Adds or Updates an entry key in the oTableStruct dictionary
	* ============================================================= *
	Function CheckStructure(tcFieldName, tcType, tnLength, tnDecimals)
		With this
			Local nFieldIdx, loPair, lbUpdate
			nFieldIdx = .oTableStruct.GetKey(tcFieldName)
			If nFieldIdx > 0
				loPair = .oTableStruct.Item(nFieldIdx)
				* Check for .NULL. type and Update
				Do case
				case loPair.fieldType == 'X'
					loPair.fieldType   = tcType
					loPair.fieldLength = tnLength
					* Remove the key and registry a new one
					.oTableStruct.Remove(nFieldIdx)
					.oTableStruct.Add(loPair, tcFieldName)

				case loPair.fieldType == 'C' && Check string length (always saves the longest)
					If tnLength > loPair.fieldLength
						loPair.fieldLength = tnLength
						* Remove the key and registry a new one
						.oTableStruct.Remove(nFieldIdx)
						.oTableStruct.Add(loPair, tcFieldName)
					EndIf
				&& >>>>>>> IRODG 03/17/24
				case loPair.fieldType == 'N' && Check integer and decimal part length (always saves the longest)
					If tnLength > loPair.fieldLength
						loPair.fieldLength = tnLength
						lbUpdate = .T.
					EndIf
					If tnDecimals > loPair.fieldDecimals
						loPair.fieldDecimals = tnDecimals
						lbUpdate = .T.
					EndIf
					If lbUpdate
						* Remove the key and registry a new one
						.oTableStruct.Remove(nFieldIdx)
						.oTableStruct.Add(loPair, tcFieldName)
					EndIf
				Case loPair.fieldType == 'I' and tcType == 'N' && Check string length (always saves the longest)
					loPair.fieldType = tcType
					If tnLength > loPair.fieldLength
						loPair.fieldLength = tnLength
					EndIf
					If tnDecimals > loPair.fieldDecimals
						loPair.fieldDecimals = tnDecimals
					EndIf
					* Remove the key and registry a new one
					.oTableStruct.Remove(nFieldIdx)
					.oTableStruct.Add(loPair, tcFieldName)
				&& <<<<<<< IRODG 03/17/24
				EndCase
			Else
				* Insert new field.
				loPair = CreateObject('Empty')
				AddProperty(loPair, 'fieldType', tcType)
				AddProperty(loPair, 'fieldLength', tnLength)
				AddProperty(loPair, 'fieldDecimals', tnDecimals)
				.oTableStruct.Add(loPair, tcFieldName)
			EndIf
		EndWith
	EndFunc
		
	Function match(tnTokenType)
		With this
			If .check(tnTokenType)
				.advance()
				Return .t.
			EndIf
			Return .f.
		EndWith
	EndFunc

	Hidden Function consume(tnTokenType, tcMessage)
		With this
			If .check(tnTokenType)
				Return .advance()
			EndIf
			if empty(tcMessage)
				tcMessage = "Parser Error: expected token '" + JSONUtils.tokenTypeToStr(tnTokenType) + "' got = '" + JSONUtils.tokenTypeToStr(.peek.type) + "'"
			endif
			error tcMessage
		endwith
	endfunc

	Hidden Function check(tnTokenType)
		With this
			If .isAtEnd()
				Return .f.
			EndIf
			Return .peek.type == tnTokenType
		EndWith
	EndFunc 

	Hidden Function advance
		With this
			If !.isAtEnd()
				.current = .current + 1
			EndIf
			Return .TokenCollection.tokens[.current-1]
		EndWith
	endfunc

	Hidden Function isAtEnd
		With this.peek
			Return .type == T_EOF
		EndWith
	endfunc

	Hidden Function peek_access
		With this
			Return .TokenCollection.tokens[.current]
		endwith
	endfunc

	Hidden Function previous_access
		With this
			Return .TokenCollection.tokens[.current-1]
		EndWith
	EndFunc

	function CleanUp
		if type('this.aRows',1) == 'A' and alen(this.aRows) > 0
			local i
			for i=1 to alen(this.aRows)
				this.aRows[i] = .null.
			next
			dimension this.aRows[1]
			this.aRows[1] = .null.
		endif
		this.oTableStruct = .null.
		this.length = 1
		this.capacity = 0		
	endfunc

Enddefine


* ── src\cursortoarray.prg ── *
* CursorToArray Parser
define class CursorToArray as session
	nSessionID = 0
	CurName    = ""
	ParseUTF8 = .f.
	TrimChars = .F.
	oUtils    = .null.
	
	* Function CursorToArray
	function CursorToArray as memo
		if !empty(this.nSessionID)
			set datasession to this.nSessionID
		endif
		private JSONUtils
		JSONUtils = iif(vartype(this.oUtils) == 'O', this.oUtils, _screen.JSONUtils)
		local lcOutput as memo, ;
			i as Integer, ;
			lcValue as Variant, ;
			llCentury as Boolean, ;
			llDeleted as Boolean, ;
			lcDateAct as string, ;
			nCounter as Integer, ;
			lnTotField as Integer, ;
			lnTotal as Integer, ;
			lnRecNo as Integer

		lcOutput = "["
		llCentury = set("Century") == "OFF"
		llDeleted = set("Deleted") == "OFF"
		lcDateAct = set("Date")
		set century on
		set deleted on
		set date ansi
		with this
			nCounter = 0
			select (.CurName)
			lnTotField  = afields(aColumns, .CurName)
			lnTotal  	= reccount(.CurName)
			lnRecNo 	= recn(.CurName)
			count for !deleted() to lnTotal
			go lnRecNo
			scan
				nCounter   = nCounter + 1
				lcOutput   = lcOutput + "{"
				for i = 1 to lnTotField
					if i > 1
						lcOutput = lcOutput + ','
					endif
					lcOutput = lcOutput + '"' + lower(aColumns[i, 1]) + '"'
					lcOutput = lcOutput + ':'
					lcValue  = evaluate(.CurName + "." + aColumns[i, 1])
					if vartype(lcValue) = 'X'
						lcValue = "null"
						lcOutput = lcOutput + lcValue
					else
						do case
						case aColumns[i, 2] $ "CDTBGMQVW"
							do case
							case aColumns[i, 2] = 'D'
								if !empty(lcValue)
									lcValue = '"' + strtran(dtoc(lcValue), '.', '-') + '"'
								else
									lcValue = 'null'
								endif
							case aColumns[i, 2] = 'T'
								if !empty(lcValue)
									lcValue = '"' + strtran(ttoc(lcValue), '.', '-') + '"'
								else
									lcValue = 'null'
								endif
							Otherwise
								lcValue = JSONUtils.GetString(Iif(this.TrimChars, Alltrim(lcValue), lcValue), this.ParseUTF8)
							endcase
							lcOutput = lcOutput + Iif(this.TrimChars, Alltrim(lcValue), lcValue)
						case aColumns[i, 2] $ "YFIN"
							lcOutput = lcOutput + alltrim(transform(lcValue, "@T"))
						case aColumns[i, 2] = "L"
							lcOutput = lcOutput + iif(lcValue, "true", "false")
						endcase
					endif
				endfor
				lcOutput = lcOutput + '}' + iif(nCounter < lnTotal, ',', '')
				select (.CurName)
			endscan
		endwith
		lcOutput = lcOutput + "]"
		if llCentury
			set century off
		endif
		if llDeleted
			set deleted off
		endif
		set date &lcDateAct
		return lcOutput
	endfunc
enddefine


* ── src\cursortojsonobject.prg ── *
* CursorToJsonObject Parser
define class CursorToJsonObject as session
	nSessionID = 0
	CurName    = ""
	ParseUTF8 = .f.
	TrimChars = .F.

	* Function CursorToArray
	function CursorToJsonObject as object
		if !empty(this.nSessionID)
			set datasession to this.nSessionID
		EndIf
		Local laArray, loRow, lnRecno
		laArray = createobject("TParserInternalArray")
		
		select (this.CurName)
		lnRecno = Recno()
		Scan
			Scatter memo name loRow
			laArray.Push(loRow)
		EndScan

		Try
			Go lnRecno
		Catch
		EndTry
		return @laArray.getArray()		
	EndFunc
	
	* MasterDetail
	Function MasterDetailToJSON(tcMaster as String, tcDetail as String, tcExpr as String, tcDetailAttribute as String, tnSessionID as Integer) as Object		
		if !empty(tnSessionID)
			set datasession to tnSessionID
		ENDIF
				
		Local laArray, loRow, lnRecno, lbContinue, laDetail, lcMacro, lcCursor,i, lcDetailFields, lcMacro
		laArray = createobject("TParserInternalArray")
		** Set Detail cursor		
		this.nSessionID = tnSessionID
		lcDetailFields = "*"
		If At("<", tcDetail) > 0
			lcDetailFields = Alltrim(strextract(tcDetail,"<",">"))
			tcDetail = Alltrim(GetWordNum(tcDetail,1,"<"))			
		EndIf
		
		select (tcMaster)
		lnRecno = Recno()
		i = 0
		scan
			i = i + 1
			Scatter memo name loRow
			laDetail = .null.
			* Filter detail
			lcCursor = Sys(2015)
			try
				lcMacro = "Select " + lcDetailFields + " from " + tcDetail + " where " + tcExpr + " into cursor " + lcCursor
				&lcMacro
				lbContinue = Used(lcCursor)
			Catch
				lbContinue = .f.
			EndTry
			If !lbContinue
				Loop
			EndIf

			If Reccount(lcCursor) > 0
				this.curName = lcCursor
				laDetail = this.CursorToJsonObject()
				Local array laRows[1]
				Acopy(laDetail, laRows)
				lcMacro = 'AddProperty(loRow, "'+tcDetailAttribute+'[1]", .null.)'
				&lcMacro
				lcMacro = 'Acopy(laRows, loRow.'+tcDetailAttribute+')'
				&lcMacro
			Else
				lcMacro = 'AddProperty(loRow, "'+tcDetailAttribute+'", .null.)'
				&lcMacro
			EndIf
			
			Use in (lcCursor)
			
			laArray.Push(loRow)
		EndScan

		Try
			Go lnRecno in (tcMaster)
		Catch
		EndTry
		IF i>0
			return @laArray.getArray()
		ELSE
			RETURN .null.
		ENDIF
	EndFunc
enddefine

* ── src\structuretojson.prg ── *
* StructureToJSON
Define Class StructureToJSON As Session
	nSessionID = 0
	curName = ""
	lExtended = .F.
	lJustArray = .F.
	oUtils = .null.
* Field constants	
	#Define FIELD_NAME							1
	#Define FIELD_TYPE							2
	#Define FIELD_WIDTH							3
	#Define DECIMAL_PLACES						4
	#Define NULL_VALUES_ALLOWED					5
	#Define CODE_PAGE_TRANSLATION_NOT_ALLOWED	6
	#Define FIELD_VALIDATION_EXPRESSION			7
	#Define FIELD_VALIDATION_TEXT				8
	#Define FIELD_DEFAULT_VALUE					9
	#Define TABLE_VALIDATION_EXPRESSION			10
	#Define TABLE_VALIDATION_TEXT				11
	#Define LONG_TABLE_NAME						12
	#Define INSERT_TRIGGER_EXPRESSION			13
	#Define UPDATE_TRIGGER_EXPRESSION			14
	#Define DELETE_TRIGGER_EXPRESSION			15
	#Define TABLE_COMMENT						16
	#Define NEXTVALUE_FOR_AUTOINCREMENTING		17
	#Define STEP_FOR_AUTOINCREMENTING			18
	#Define CHARACTER_TYPE						'C'
	#Define NUMERIC_TYPE						'N'
	#Define LOGICAL_TYPE						'L'
* StructureToJSON
	Function StructureToJSON As Memo
		If !Empty(This.nSessionID)
			Set DataSession To (This.nSessionID)
		Endif
		Private JSONUtils
		JSONUtils = iif(vartype(this.oUtils) == 'O', this.oUtils, _Screen.JSONUtils)
		Local lcStructJSON As Memo, lcFieldJSON as memo, lnLength As Integer, i as Integer
		If !this.lJustArray
			lcStructJSON = '{"' + Lower(this.curName) + '":['
		Else
			lcStructJSON = '['
		EndIf
		lcFieldJSON  = ''
		lnLength 	 = 0
		If Used(this.curName)
			lnLength = Afields(aStruct, this.curName)
			If lnLength > 0
				For i = 1 To lnLength
					lcFieldJSON = lcFieldJSON + Iif(i==1, '{', ',{')
					lcFieldJSON = lcFieldJSON + '"field_name":' + JSONUtils.GetValue(aStruct[i, FIELD_NAME], CHARACTER_TYPE)
					lcFieldJSON = lcFieldJSON + ',"field_type":' + JSONUtils.GetValue(aStruct[i, FIELD_TYPE], CHARACTER_TYPE)
					lcFieldJSON = lcFieldJSON + ',"field_width":' + JSONUtils.GetValue(aStruct[i, FIELD_WIDTH], NUMERIC_TYPE)
					lcFieldJSON = lcFieldJSON + ',"decimal_places":' + JSONUtils.GetValue(aStruct[i, DECIMAL_PLACES], NUMERIC_TYPE)
					If this.lExtended
						lcFieldJSON = lcFieldJSON + ',"null_values_allowed":' + JSONUtils.GetValue(aStruct[i, NULL_VALUES_ALLOWED], LOGICAL_TYPE)
						lcFieldJSON = lcFieldJSON + ',"code_page_translation_not_allowed":' + JSONUtils.GetValue(aStruct[i, CODE_PAGE_TRANSLATION_NOT_ALLOWED], LOGICAL_TYPE)
						lcFieldJSON = lcFieldJSON + ',"field_validation_expression":' + JSONUtils.GetValue(aStruct[i, FIELD_VALIDATION_EXPRESSION], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"field_validation_text":' + JSONUtils.GetValue(aStruct[i, FIELD_VALIDATION_TEXT], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"field_default_value":' + JSONUtils.GetValue(aStruct[i, FIELD_DEFAULT_VALUE], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"table_validation_expression":' + JSONUtils.GetValue(aStruct[i, TABLE_VALIDATION_EXPRESSION], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"table_validation_text":' + JSONUtils.GetValue(aStruct[i, TABLE_VALIDATION_TEXT], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"long_table_name":' + JSONUtils.GetValue(aStruct[i, LONG_TABLE_NAME], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"insert_trigger_expression":' + JSONUtils.GetValue(aStruct[i, INSERT_TRIGGER_EXPRESSION], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"update_trigger_expression":' + JSONUtils.GetValue(aStruct[i, UPDATE_TRIGGER_EXPRESSION], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"delete_trigger_expression":' + JSONUtils.GetValue(aStruct[i, DELETE_TRIGGER_EXPRESSION], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"table_comment":' + JSONUtils.GetValue(aStruct[i, TABLE_COMMENT], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"nextvalue_for_autoincrementing":' + JSONUtils.GetValue(aStruct[i, NEXTVALUE_FOR_AUTOINCREMENTING], NUMERIC_TYPE)
						lcFieldJSON = lcFieldJSON + ',"step_for_autoincrementing":' + JSONUtils.GetValue(aStruct[i, STEP_FOR_AUTOINCREMENTING], NUMERIC_TYPE)
					EndIf
					lcFieldJSON = lcFieldJSON + '}'
				Endfor
			Endif
		EndIf		
		lcStructJSON = lcStructJSON + lcFieldJSON + ']'
		If !this.lJustArray
			lcStructJSON = lcStructJSON + '}'
		EndIf
		Return lcStructJSON
	Endfunc
Enddefine

* ── src\jsonfox_class.prg ── *
* JSONFox — Self-contained standalone facade
* Usage: jsonFox = NEWOBJECT("JSONFox", "JsonFox.fxp")
define class JSONFox as session
	datasession     = 1
	lError          = .f.
	cLastError      = ""
	UseArrayObjects = .t.
	version         = "13.1"
	hidden oUtils
	hidden lTablePrompt
	dimension aCustomArray[1]

	function init
		this.aCustomArray[1] = .null.
		this.oUtils       = createobject("JSONUtils")
		this.lTablePrompt = set("TablePrompt") == "ON"
		set tableprompt off
	endfunc

	* ── Internal helpers ──────────────────────────────────────────────────── *

	hidden function CreateLexer(tcSource)
		local loLexer
		loLexer = createobject("Tokenizer", tcSource)
		loLexer.oUtils = this.oUtils
		return loLexer
	endfunc

	hidden function ResetError
		this.lError    = .f.
		this.cLastError = ""
	endfunc

	hidden function SetError(tcMsg)
		this.lError    = .t.
		this.cLastError = tcMsg
	endfunc

	hidden function saveEnvironment
		local loEnv
		loEnv = createobject("Collection")
		loEnv.add(set("POINT"),     "point")
		loEnv.add(set("SEPARATOR"), "separator")
		set point to '.'
		set separator to ','
		return loEnv
	endfunc

	hidden procedure restoreEnvironment(toEnv)
		try
			set point to toEnv("point")
			set separator to toEnv("separator")
		catch
		endtry
	endproc

	* ── Public API ───────────────────────────────────────────────────────── *

	* Parse
	* Fail-fast: JSON syntax errors propagate as VFP errors so the caller
	* can wrap in TRY/CATCH if needed; type errors are immediate.
	function Parse(tcJsonStr)
		local loResult, loLexer, loParser
		loResult = .null.
		this.ResetError()
		dimension this.aCustomArray[1]
		this.aCustomArray[1] = .null.
		if !inlist(vartype(tcJsonStr), 'C', 'M')
			error "JSONFox.Parse: argument must be a string."
		endif
		loLexer  = this.CreateLexer(tcJsonStr)
		loParser = createobject("Parser", loLexer, this.UseArrayObjects)
		loParser.oUtils = this.oUtils
		loResult = loParser.Parse()
		store .null. to loLexer, loParser
		release loLexer, loParser
		if type('loResult', 1) == 'A'
			local i
			for i = 1 to alen(loResult, 1)
				dimension this.aCustomArray[i]
				this.aCustomArray[i] = loResult[i]
			endfor
			return @this.aCustomArray
		endif
		return loResult
	endfunc

	* Stringify
	function Stringify(tvNewVal, tcFlags, tlParseUtf8, tlTrimChars)
		local lcResult, lcTypeFlag, llParseUtf8, loObjToJson, loLexer, loParser
		lcResult    = ""
		this.ResetError()
		lcTypeFlag  = vartype(tcFlags)
		llParseUtf8 = iif(lcTypeFlag = 'L', tcFlags, tlParseUtf8)
		if vartype(tvNewVal) = "O"
			loObjToJson = createobject("ObjectToJson")
			loObjToJson.oUtils = this.oUtils
			tvNewVal = loObjToJson.Encode(@tvNewVal, iif(lcTypeFlag != 'C', .f., tcFlags))
			loObjToJson = .null.
			release loObjToJson
		endif
		loLexer  = this.CreateLexer(tvNewVal)
		loParser = createobject("JSONStringify", loLexer)
		loParser.oUtils = this.oUtils
		lcResult = loParser.Stringify(llParseUtf8, tlTrimChars)
		store .null. to loLexer, loParser
		release loLexer, loParser
		return lcResult
	endfunc

	* CursorToJSON — soft errors: invalid/closed cursor sets lError
	function CursorToJSON(tcCursor, tbCurrentRow, tnDataSession, tlJustArray, tlParseUtf8, tlTrimChars)
		local lcResult, lcTmp, lnRecno, loParser
		lcResult = ""
		this.ResetError()
		try
			tcCursor      = evl(tcCursor, alias())
			tnDataSession = evl(tnDataSession, set("Datasession"))
			if empty(tcCursor) or !used(tcCursor)
				this.SetError("CursorToJSON: cursor '" + tcCursor + "' is not in use.")
				return ""
			endif
			set datasession to tnDataSession
			lcTmp = sys(2015)
			if tbCurrentRow
				lnRecno = recno(tcCursor)
				select * from (tcCursor) where recno() = lnRecno into cursor (lcTmp)
			else
				select * from (tcCursor) into cursor (lcTmp)
			endif
			loParser = createobject("CursorToArray")
			loParser.CurName    = lcTmp
			loParser.nSessionID = tnDataSession
			loParser.ParseUTF8  = m.tlParseUtf8
			loParser.TrimChars  = m.tlTrimChars
			loParser.oUtils     = this.oUtils
			lcResult = loParser.CursorToArray()
			loParser = .null.
			release loParser
			use in (select(lcTmp))
		catch to loEx
			this.SetError(loEx.message)
		endtry
		return iif(m.tlJustArray, lcResult, '{"' + lower(alltrim(tcCursor)) + '":' + lcResult + '}')
	endfunc

	* JSONToCursor
	* Fail-fast: empty cursor name; soft: parse/data errors set lError
	function JSONToCursor(tcJsonStr, tcCursor, tnDataSession)
		local loEnv, loLexer, loParser
		this.ResetError()
		if empty(tcCursor)
			error "JSONFox.JSONToCursor: cursor name cannot be empty."
		endif
		loEnv = this.saveEnvironment()
		try
			tnDataSession = evl(tnDataSession, set("Datasession"))
			loLexer  = this.CreateLexer(tcJsonStr)
			loParser = createobject("ArrayToCursor", loLexer)
			loParser.oUtils     = this.oUtils
			loParser.CurName    = tcCursor
			loParser.nSessionID = tnDataSession
			loParser.array()
		catch to loEx
			this.SetError(loEx.message)
		finally
			this.restoreEnvironment(loEnv)
			store .null. to loLexer, loParser
			release loLexer, loParser
		endtry
	endfunc

	* CursorToJSONObject
	function CursorToJSONObject(tcCursor, tbCurrentRow, tnDataSession)
		local loResult, lcTmp, lnRecno, loParser
		loResult = .null.
		this.ResetError()
		try
			tcCursor      = evl(tcCursor, alias())
			tnDataSession = evl(tnDataSession, set("Datasession"))
			if empty(tcCursor) or !used(tcCursor)
				this.SetError("CursorToJSONObject: cursor '" + tcCursor + "' is not in use.")
				return .null.
			endif
			set datasession to tnDataSession
			lcTmp = sys(2015)
			if tbCurrentRow
				lnRecno = recno(tcCursor)
				select * from (tcCursor) where recno() = lnRecno into cursor (lcTmp)
			else
				select * from (tcCursor) into cursor (lcTmp)
			endif
			loParser = createobject("CursorToJsonObject")
			loParser.CurName    = lcTmp
			loParser.nSessionID = tnDataSession
			loResult = loParser.CursorToJSONObject()
			loParser = .null.
			release loParser
			use in (select(lcTmp))
		catch to loEx
			this.SetError(loEx.message)
		endtry
		if type('loResult', 1) == 'A'
			local i
			for i = 1 to alen(loResult, 1)
				dimension this.aCustomArray[i]
				this.aCustomArray[i] = loResult[i]
			endfor
			return @this.aCustomArray
		endif
		return loResult
	endfunc

	* CursorStructure
	function CursorStructure(tcCursor, tnDataSession, tlCopyExtended, tlJustArray)
		local lcResult, loEnv, loClass
		lcResult = ""
		this.ResetError()
		loEnv = this.saveEnvironment()
		try
			tcCursor      = evl(tcCursor, alias())
			tnDataSession = evl(tnDataSession, set("Datasession"))
			if empty(tcCursor)
				this.SetError("CursorStructure: cursor name cannot be empty.")
				return ""
			endif
			loClass = createobject("StructureToJSON")
			loClass.oUtils     = this.oUtils
			loClass.CurName    = tcCursor
			loClass.nSessionID = tnDataSession
			loClass.lExtended  = m.tlCopyExtended
			loClass.lJustArray = m.tlJustArray
			lcResult = loClass.StructureToJSON()
			loClass = .null.
			release loClass
		catch to loEx
			this.SetError(loEx.message)
		finally
			this.restoreEnvironment(loEnv)
		endtry
		return lcResult
	endfunc

	* MasterDetailToJSON
	function MasterDetailToJSON(tcMaster, tcDetail, tcExpr, tcDetailAttribute, tnSessionID)
		local loClass, loResult, lcResult
		lcResult = ""
		this.ResetError()
		try
			tnSessionID = evl(tnSessionID, set("Datasession"))
			set datasession to tnSessionID
			loClass  = createobject("CursorToJsonObject")
			loResult = loClass.MasterDetailToJSON(tcMaster, tcDetail, tcExpr, tcDetailAttribute, tnSessionID)
			loClass  = .null.
			release loClass
		catch to loEx
			this.SetError(loEx.message)
		endtry
		lcResult = this.Stringify(@loResult, "", .t., .t.)
		return lcResult
	endfunc

	* ArrayToXML
	function ArrayToXML(tcArray)
		local lcResult, lcTmp, loObjToJson
		lcResult = ""
		this.ResetError()
		lcTmp = sys(2015)
		if vartype(tcArray) = 'O'
			loObjToJson = createobject("ObjectToJson")
			loObjToJson.oUtils = this.oUtils
			tcArray = loObjToJson.Encode(@tcArray)
			loObjToJson = .null.
			release loObjToJson
		endif
		try
			this.JSONToCursor(tcArray, lcTmp, set("Datasession"))
			if !this.lError and used(lcTmp)
				=cursortoxml(lcTmp, 'lcResult', 1, 0, 0, '1')
			endif
		catch to loEx
			this.SetError(loEx.message)
		finally
			use in (select(lcTmp))
		endtry
		return lcResult
	endfunc

	* XMLToJson
	function XMLToJson(tcXML)
		local lcResult, loParser
		lcResult = ""
		this.ResetError()
		try
			=xmltocursor(tcXML, 'qXML')
			loParser = createobject("CursorToArray")
			loParser.CurName    = "qXML"
			loParser.nSessionID = set("Datasession")
			loParser.ParseUTF8  = .t.
			loParser.TrimChars  = .t.
			loParser.oUtils     = this.oUtils
			lcResult = loParser.CursorToArray()
		catch to loEx
			this.SetError(loEx.message)
		finally
			loParser = .null.
			release loParser
			use in (select("qXML"))
		endtry
		return lcResult
	endfunc

	function destroy
		try
			if this.lTablePrompt
				lcTablePrompt = this.lTablePrompt
				set tableprompt &lcTablePrompt
			endif
		catch
		endtry
	endfunc

enddefine

