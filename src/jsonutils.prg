#include "JSONFox.h"
&& ======================================================================== &&
&& Class utils
&& JSON Utilities
&& ======================================================================== &&
define class jsonutils as custom

	dimension aPattern[8, 2]

	function init
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

		_screen.oRegEx.global = .t.

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
			_screen.oRegEx.pattern = this.aPattern[i, 1]
			if _screen.oRegEx.Test(tcString)
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
	function getString as string
		lparameters tcString as string, tlParseUTF8 as Boolean
&& IRODG 08/08/2023 Inicio
*tcString = Alltrim(tcString)
&& IRODG 08/08/2023 Fin
		tcString = strtran(tcString, '\', '\\' )
		tcString = strtran(tcString, chr(9),  '\t' )
		tcString = strtran(tcString, chr(10), '\n' )
		tcString = strtran(tcString, chr(13), '\r' )
		if left(alltrim(tcString), 1) == '"' and right(alltrim(tcString),1) == '"'
			tcString = substr(tcString, 2, len(tcString)-2)
		endif
		tcString = strtran(tcString, '"', '\"' )

		if tlParseUTF8
			tcString = strtran(tcString,"&","\u0026")
			tcString = strtran(tcString,"+","\u002b")
			tcString = strtran(tcString,"-","\u002d")
			tcString = strtran(tcString,"#","\u0023")
			tcString = strtran(tcString,"%","\u0025")
			tcString = strtran(tcString,"�","\u00b2")
			tcString = strtran(tcString,'�','\u00e0')
			tcString = strtran(tcString,'�','\u00e1')
			tcString = strtran(tcString,'�','\u00e8')
			tcString = strtran(tcString,'�','\u00e9')
			tcString = strtran(tcString,'�','\u00ec')
			tcString = strtran(tcString,'�','\u00ed')
			tcString = strtran(tcString,'�','\u00f2')
			tcString = strtran(tcString,'�','\u00f3')
			tcString = strtran(tcString,'�','\u00f9')
			tcString = strtran(tcString,'�','\u00fa')
			tcString = strtran(tcString,'�','\u00fc')
			tcString = strtran(tcString,'�','\u00c0')
			tcString = strtran(tcString,'�','\u00c1')
			tcString = strtran(tcString,'�','\u00c8')
			tcString = strtran(tcString,'�','\u00c9')
			tcString = strtran(tcString,'�','\u00cc')
			tcString = strtran(tcString,'�','\u00cd')
			tcString = strtran(tcString,'�','\u00d2')
			tcString = strtran(tcString,'�','\u00d3')
			tcString = strtran(tcString,'�','\u00d9')
			tcString = strtran(tcString,'�','\u00da')
			tcString = strtran(tcString,'�','\u00dc')
			tcString = strtran(tcString,'�','\u00f1')
			tcString = strtran(tcString,'�','\u00d1')
			tcString = strtran(tcString,'�','\u00a9')
			tcString = strtran(tcString,'�','\u00ae')
			tcString = strtran(tcString,'�','\u00e7')
			tcString = strtran(tcString,'�','\u00ba')
		endif
		if left(alltrim(tcString), 1) != '"' and right(alltrim(tcString),1) != '"'
			return '"'+tcString+'"'
		endif
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
