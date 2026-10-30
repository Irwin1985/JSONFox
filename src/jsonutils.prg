#include "JSONFox.h"
&& ======================================================================== &&
&& Class utils
&& JSON Utilities
&& ======================================================================== &&
define class jsonutils as custom
	EscapeOptionalChars = .t.
	oRegEx = .null.
	* Los caracteres que van tal cual en una cadena JSON: el ASCII imprimible.
	cPlainChars = ""

	dimension aPattern[8, 2]

	function init
		local lnChar
		for lnChar = 32 to 127
			this.cPlainChars = this.cPlainChars + chr(lnChar)
		endfor
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
		case tctype $ "CDTGMQVWX"
			do case
			case tctype == 'D'
				tcvalue = '"' + left(ttoc(tcvalue,3),10) + '"'
			case tctype == 'T'
				tcvalue = '"' + ttoc(tcvalue,3) + '"'
			case tctype == 'X'
				tcvalue = "null"
			case tctype == 'Q'
				* Varbinary y Blob (VARTYPE da Q a los dos) en base64, como
				* CursorToJSON. Antes, "": GetString no lee lo que no es C.
				tcvalue = '"' + strconv(tcvalue, 13) + '"'
			otherwise
				tcvalue = this.getString(iif(tlTrimChars, alltrim(tcvalue), tcvalue), tlParseUTF8)
			endcase
		case tctype $ "YFINB"
			if this.HasDecimals(tcvalue)
				tcvalue = this.NumberToJson(tcvalue)
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
&& Function NumberToJson
&& Un número escrito como lo quiere JSON: con punto decimal y con todos sus
&& decimales. TRANSFORM(x, "@T") redondeaba a SET DECIMALS, que vale 2 por
&& defecto, y un N(10,4) con 1.2345 salía como 1.23 (issue #65).
&& tnDecimals: los decimales del campo. Sin él (un número suelto, o un
&& Double, que guarda más de lo que enseña) se escribe con 15 cifras
&& significativas, las que un double guarda sin ruido, y sin los ceros de
&& la derecha.
&& ======================================================================== &&
	function NumberToJson(tnValue, tnDecimals)
		local lcNum, llTrim, lnIntDigits
		* Con m. por lo mismo que GetString: se la llama dentro de un SCAN.
		llTrim = vartype(m.tnDecimals) != 'N'
		if m.llTrim
			lnIntDigits = iif(int(abs(m.tnValue)) = 0, 0, len(alltrim(str(int(abs(m.tnValue)), 40, 0))))
			tnDecimals  = max(0, 15 - m.lnIntDigits)
		endif
		lcNum = alltrim(str(m.tnValue, 40, min(m.tnDecimals, 18)))
		if set("POINT") != '.'
			lcNum = strtran(m.lcNum, set("POINT"), '.')
		endif
		if m.llTrim and '.' $ m.lcNum and !('E' $ upper(m.lcNum))
			lcNum = rtrim(rtrim(m.lcNum, 0, '0'), 0, '.')
		endif
		return m.lcNum
	endfunc

&& ======================================================================== &&
&& Function DoubleToJson
&& Un Double (campo B) con el decimal más corto que vuelve al MISMO Double:
&& 15 cifras significativas y, si no basta, 16 o 17. Con 15 fijas, 1/3 y
&& 0.1 + 0.2 volvían a otro Double y 1E-20 salía 0 (FoxDock, P6b-M0).
&& Vuelve como lo lee JSONToCursor, con EVALUATE, y se compara con BINTOC
&& porque el == de VFP da 0.1 + 0.2 igual a 0.3. Sin exponente entre 1e-20
&& y 1e20, como DataTable.DoubleText de FoxDock. Un infinito, que JSON no
&& tiene, sale null.
&& ======================================================================== &&
	function DoubleToJson(tnValue)
		local lcRef, lnDigits, lcNum, lvBack
		lcRef = bintoc(m.tnValue, "B")
		for lnDigits = 15 to 17
			lcNum = this.PlainNumber(this.FormatG(m.tnValue, m.lnDigits))
			try
				lvBack = evaluate(m.lcNum)
			catch
				lvBack = .null.
			endtry
			if vartype(m.lvBack) != 'N' or bintoc(m.lvBack, "B") == m.lcRef
				exit
			endif
		endfor
		return iif(vartype(m.lvBack) == 'N', m.lcNum, "null")
	endfunc

&& FormatG: el %.<n>g de msvcrt (STR no da más de 16 cifras).
	hidden function FormatG(tnValue, tnDigits)
		local lcBuf, lcFormat, lnLen
		lcBuf = replicate(chr(0), 64)
		lcFormat = "%." + transform(m.tnDigits) + "g"
		try
			lnLen = JsonFoxSnprintf(@lcBuf, 63, m.lcFormat, m.tnValue)
		catch
			* La primera vez, o después de un CLEAR DLLS del programa que
			* nos usa.
			declare integer _snprintf in msvcrt as JsonFoxSnprintf ;
				string @cBuf, integer nCount, string cFormat, double nValue
			lnLen = JsonFoxSnprintf(@lcBuf, 63, m.lcFormat, m.tnValue)
		endtry
		return left(m.lcBuf, max(0, m.lnLen))
	endfunc

&& PlainNumber: el número de %g sin exponente (msvcrt escribe 1e-020 y
&& 1e+020) si el exponente no pasa de 20; si pasa, con él (1.5e+300).
	hidden function PlainNumber(tcNum)
		local lnE, lcMant, lnExp, lcSign, lcDigits, lnPoint
		lnE = at("e", m.tcNum)
		if m.lnE = 0
			return m.tcNum
		endif
		lcMant = left(m.tcNum, m.lnE - 1)
		lnExp = int(val(substr(m.tcNum, m.lnE + 1)))
		if abs(m.lnExp) > 20
			return m.lcMant + "e" + iif(m.lnExp > 0, "+", "-") + transform(abs(m.lnExp))
		endif
		lcSign = iif(left(m.lcMant, 1) == "-", "-", "")
		lcMant = chrtran(m.lcMant, "-", "")
		lcDigits = chrtran(m.lcMant, ".", "")
		lnPoint = iif(at(".", m.lcMant) = 0, len(m.lcMant), at(".", m.lcMant) - 1) + m.lnExp
		do case
		case m.lnPoint <= 0
			return m.lcSign + "0." + replicate("0", -m.lnPoint) + m.lcDigits
		case m.lnPoint >= len(m.lcDigits)
			return m.lcSign + m.lcDigits + replicate("0", m.lnPoint - len(m.lcDigits))
		endcase
		return m.lcSign + left(m.lcDigits, m.lnPoint) + "." + substr(m.lcDigits, m.lnPoint + 1)
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
* Todo con m.: a GetString se la llama dentro del SCAN de CursorToArray, y
* ahí un campo pisa a la variable del mismo nombre. Con un campo llamado i,
* SUBSTR(tcString, i, 1) leía el campo y la cadena salía vacía.
		local llEscapeOptionalChars

* Get optional escape config from the class
		llEscapeOptionalChars = this.EscapeOptionalChars

* Validate input parameter
		tcString = iif(vartype(m.tcString) != "C", "", m.tcString)

* MANDATORY ESCAPES per RFC 8259 standard
		tcString = strtran(m.tcString, '\', '\\' )  && Backslash
		tcString = strtran(m.tcString, chr(8),  '\b' )   && Backspace
		tcString = strtran(m.tcString, chr(9),  '\t' )  && Tab
		tcString = strtran(m.tcString, chr(10), '\n' )  && Newline
		tcString = strtran(m.tcString, chr(12), '\f' )   && Form feed
		tcString = strtran(m.tcString, chr(13), '\r' )  && Carriage return

* Handle quotes
		if left(alltrim(m.tcString), 1) == '"' and right(alltrim(m.tcString),1) == '"'
			tcString = substr(m.tcString, 2, len(m.tcString)-2)
		endif
		tcString = strtran(m.tcString, '"', '\"' )  && Double quotes (mandatory)

* Lo que no es ASCII imprimible, como \uXXXX del carácter Unicode.
		if len(chrtran(m.tcString, this.cPlainChars, "")) > 0
			tcString = this.EscapeUnicode(m.tcString)
		endif

		* Add quotes if missing
		LOCAL lnLen, lcLastChar, lcPrevChar

		lnLen = LEN(m.tcString)
		lcLastChar = RIGHT(m.tcString, 1)
		lcPrevChar = IIF(m.lnLen > 1, SUBSTR(m.tcString, m.lnLen-1, 1), "")

		* Check if starts and ends with unescaped quote
		IF LEFT(m.tcString, 1) != '"' OR m.lcLastChar != '"' OR m.lcPrevChar = "\"
			RETURN '"' + m.tcString + '"'
		ENDIF

		return m.tcString
	endfunc
&& ======================================================================== &&
&& Function EscapeUnicode
&& Cada carácter que no es ASCII imprimible, como \uXXXX de su código
&& Unicode. Se escapaba el BYTE: el € (0x80 en 1252) salía \u0080, que en
&& JSON es un carácter de control (FoxDock, P6b-M0). La cadena pasa a
&& UTF-16 desde CPCURRENT(), la página de los valores que VFP ya leyó, y el
&& tokenizer hace la vuelta con la misma. Los de control (< 32) que no
&& tienen escape corto también van así: JSON no los deja ir sueltos.
&& ======================================================================== &&
	function EscapeUnicode(tcString)
		local lcWide, lcOut, lnPos, lnCode
		lcWide = strconv(m.tcString, 5, cpcurrent(), 1)
		lcOut = ""
		for lnPos = 1 to len(m.lcWide) - 1 step 2
			lnCode = asc(substr(m.lcWide, m.lnPos, 1)) + 256 * asc(substr(m.lcWide, m.lnPos + 1, 1))
			if between(m.lnCode, 32, 127)
				lcOut = m.lcOut + chr(m.lnCode)
			else
				lcOut = m.lcOut + '\u' + right(transform(m.lnCode, '@0'), 4)
			endif
		endfor
		return m.lcOut
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
