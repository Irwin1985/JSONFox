#include "JSONFox.h"
&& ======================================================================== &&
&& Class utils
&& JSON Utilities
&& ======================================================================== &&
define class jsonutils as custom
	* match
	function match(tntype)
		if this.check(tntype)
			this.advance()
			return .t.
		endif
		return .f.
	endfunc

	* Consume
	function consume
		lparameters tntype as integer, tcmessage as string
		if this.check(tntype)
			return this.advance()
		endif
		error this.jsonerror(this.peek(), tcmessage)
	endfunc

	* Check
	function check(tntype)
		if this.isatend()
			return .f.
		else
			return _screen.opeek.type == tntype
		endif
	endfunc

	* Advance
	function advance
		if !this.isatend()
			_screen.curtokenpos = _screen.curtokenpos + 1
		endif
		return this.previous() && retrieve the just eaten token.
	endfunc

	* Previous
	function previous
		_screen.oprevious = _screen.tokens[_screen.curtokenpos - 1]
		return _screen.oprevious
	endfunc

	* IsAtEnd
	function isatend
		lopeek = this.peek()
		return lopeek.type = t_eof
	endfunc

	* Peek
	function peek
		_screen.opeek = _screen.tokens[_screen.curtokenpos]
		return _screen.opeek
	endfunc

	* Error
	function jsonerror(totoken, tcmessage)
		lcmsg = " at '" + totoken.lexeme + "'"
		if totoken.type == t_eof
			lcmsg = " at end"
		endif
		this.jsonreport(totoken.line, lcmsg, tcmessage)
	endfunc
	* Report
	function jsonreport(tnline, tcwhere, tcmessage)
		error "[line " + alltrim(str(tnline)) + "] Error " + tcwhere + ": " + tcmessage
	endfunc
	&& ======================================================================== &&
	&& Function GetValue
	&& ======================================================================== &&
	function getvalue as string
		lparameters tcvalue as string, tctype as character
		do case
		case tctype $ "CDTBGMQVWX"
			do case
			case tctype = "D"
				tcvalue = '"' + strtran(dtoc(tcvalue), ".", "-") + '"'
			case tctype = "T"
				tcvalue = '"' + strtran(ttoc(tcvalue), ".", "-") + '"'
			otherwise
				if tctype = "X"
					tcvalue = "null"
				else
					tcvalue = this.getstring(tcvalue)
				endif
			endcase
			tcvalue = alltrim(tcvalue)
		case tctype $ "YFIN"
			tcvalue = strtran(transform(tcvalue), ',', '.')
		case tctype = "L"
			tcvalue = iif(tcvalue, "true", "false")
		endcase
		return tcvalue
	endfunc
	&& ======================================================================== &&
	&& Function CheckString
	&& Check the string content in case it is a date or datetime.
	&& String itself or string date / datetime format.
	&& ======================================================================== &&
	function CheckString(tcString)
		date_pattern = "^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])$"
		&& IRODG 20210313 ISSUE # 14
		*datetime_pattern = "^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01]) (00|[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9])$"
		*iso_8601_pattern = "^(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})\:(\d{2})[+-](\d{2})\:(\d{2})$"
		datetime_pattern = "^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01]) (00|0?[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9])$"
		iso_8601_pattern = "^(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})(\:(\d{2}))?(Z|[+-](\d{2})\:(\d{2}))?$"
		java_datetime = "^(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})(\:(\d{2}))?[.](\d{3})(\w{1})$"
		dmy_pattern = "^([0-2][0-9]|(3)[0-1])[\/-](((0)[0-9])|((1)[0-2]))[\/-]\d{4}$"
		&& IRODG 20210313 ISSUE # 14

		_screen.oRegEx.global = .t.

		* Regular Date Format
		_screen.oRegEx.pattern = date_pattern
		if _screen.oRegEx.Test(tcString)
			return this.formatDate(tcString)
		endif
		* Regular Date Time Format
		_screen.oRegEx.pattern = datetime_pattern
		if _screen.oRegEx.Test(tcString)
			return this.formatDate(tcString)
		endif
		* ISO8601 Date Time Format
		_screen.oRegEx.pattern = iso_8601_pattern
		if _screen.oRegEx.Test(tcString)
			return this.formatDate(tcString)
		endif
		* JavaScript Date Time Format
		_screen.oRegEx.pattern = java_datetime
		if _screen.oRegEx.Test(tcString)
			return this.formatDate(tcString)
		endif
		* dd-mm-YYYY or dd/mm/YYYY date format.
		_screen.oRegEx.pattern = dmy_pattern
		if _screen.oRegEx.Test(tcString)
			return this.formatDate(tcString, .t.)
		endif

		* Regular String
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
		case occurs(':', tcDate) >= 2 && VFP Date Time Format. 'YYYY-mm-dd HH:mm:ss'
			try
				setDateAct = set('Date')
				set date ymd
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
		*!*			if occurs(':', tcdate) >= 2 .and. len(alltrim(tcdate)) <= 25
		*!*				do case
		*!*				case '.' $ tcdate and 'T' $ tcdate && JavaScript built-in JSON object format. 'YYYY-mm-ddTHH:mm:ss.ms'
		*!*					tcdate = substr(strtran(tcdate, 'T', space(1)), 1, at('.', tcdate) - 1)
		*!*				case 'T' $ tcdate and occurs(':', tcdate) = 3 && ISO 8601 format. 'YYYY-mm-ddTHH:mm:ss-ms:00'
		*!*					tcdate = substr(strtran(tcdate, 'T', space(1)), 1, at('-', tcdate, 3) - 1)
		*!*				otherwise && VFP Date Time Format. 'YYYY-mm-dd HH:mm:ss'
		*!*				endcase
		*!*				try
		*!*					setDateAct = set("Date")
		*!*					set date ymd
		*!*					ldate = ctot(tcdate)
		*!*				catch
		*!*					ldate = {//::}
		*!*				finally
		*!*					set date &setDateAct
		*!*				endtry
		*!*			else
		*!*				try
		*!*					setDateAct = set("Date")
		*!*					if !tlUseDMY
		*!*						set date ymd
		*!*					else
		*!*						set date dmy
		*!*					endif
		*!*					ldate = ctod(tcdate)
		*!*				catch
		*!*					ldate = {//}
		*!*				finally
		*!*					set date &setDateAct
		*!*				endtry
		*!*			endif
		*!*			return ldate
		&& IRODG 20210313 ISSUE # 14
	endfunc
	&& ======================================================================== &&
	&& Function GetString
	&& ======================================================================== &&
	function getstring as string
		lparameters tcString as string, tlParseUtf8 as Boolean
		tcString = allt(tcString)
		tcString = strtran(tcString, '\', '\\' )		
		tcString = strtran(tcString, chr(9),  '\t' )
		tcString = strtran(tcString, chr(10), '\n' )
		tcString = strtran(tcString, chr(13), '\r' )
		tcString = strtran(tcString, '"', '\"' )

		if tlParseUtf8
			tcString = StrTran(tcString,"&","\u0026")
			tcString = StrTran(tcString,"+","\u002b")
			tcString = StrTran(tcString,"-","\u002d")
			tcString = StrTran(tcString,"#","\u0023")
			tcString = StrTran(tcString,"%","\u0025")
			tcString = StrTran(tcString,"²","\u00b2")
			tcString = StrTran(tcString,'à','\u00e0')
			tcString = StrTran(tcString,'á','\u00e1')
			tcString = StrTran(tcString,'è','\u00e8')
			tcString = StrTran(tcString,'é','\u00e9')
			tcString = StrTran(tcString,'ì','\u00ec')
			tcString = StrTran(tcString,'í','\u00ed')
			tcString = StrTran(tcString,'ò','\u00f2')
			tcString = StrTran(tcString,'ó','\u00f3')
			tcString = StrTran(tcString,'ù','\u00f9')
			tcString = StrTran(tcString,'ú','\u00fa')
			tcString = StrTran(tcString,'ü','\u00fc')
			tcString = StrTran(tcString,'À','\u00c0')
			tcString = StrTran(tcString,'Á','\u00c1')
			tcString = StrTran(tcString,'È','\u00c8')
			tcString = StrTran(tcString,'É','\u00c9')
			tcString = StrTran(tcString,'Ì','\u00cc')
			tcString = StrTran(tcString,'Í','\u00cd')
			tcString = StrTran(tcString,'Ò','\u00d2')
			tcString = StrTran(tcString,'Ó','\u00d3')
			tcString = StrTran(tcString,'Ù','\u00d9')
			tcString = StrTran(tcString,'Ú','\u00da')
			tcString = StrTran(tcString,'Ü','\u00dc')
			tcString = StrTran(tcString,'ñ','\u00f1')
			tcString = StrTran(tcString,'Ñ','\u00d1')
			tcString = StrTran(tcString,'©','\u00a9')
			tcString = StrTran(tcString,'®','\u00ae')
			tcString = StrTran(tcString,'ç','\u00e7')
		endif

		return '"' +tcString + '"'
	endfunc
	&& ======================================================================== &&
	&& Function CheckProp
	&& Check the object property name for invalid format (replace with '_')
	&& ======================================================================== &&
	function checkprop(tcprop as string) as string
		local lcfinalprop as string
		lcfinalprop = ""
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
enddefine
