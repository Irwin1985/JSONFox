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
		datetime_pattern = "^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01]) (00|[0-9]|1[0-9]|2[0-3]):([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9])$"
		iso_8601_pattern = "^(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})\:(\d{2})[+-](\d{2})\:(\d{2})$"
		java_datetime = "^(\d{4})-(\d{2})-(\d{2})T(\d{2})\:(\d{2})\:(\d{2})[.](\d{3})(\w{1})$"
		_screen.oRegEx.Global = .T.

		* Regular Date Format
		_screen.oRegEx.Pattern = date_pattern
		if _screen.oRegEx.Test(tcString)
			return this.formatDate(tcString)
		endif
		* Regular Date Time Format
		_screen.oRegEx.Pattern = datetime_pattern
		if _screen.oRegEx.Test(tcString)
			return this.formatDate(tcString)
		endif
		* ISO8601 Date Time Format
		_screen.oRegEx.Pattern = iso_8601_pattern
		if _screen.oRegEx.Test(tcString)
			return this.formatDate(tcString)
		endif
		* JavaScript Date Time Format
		_screen.oRegEx.Pattern = java_datetime
		if _screen.oRegEx.Test(tcString)
			return this.formatDate(tcString)
		endif
		
		* Normal String
		return tcString
	endfunc
	&& ======================================================================== &&
	&& Function FormatDate
	&& return a valid date or datetime date type.
	&& ======================================================================== &&
	function formatdate as variant
		lparameters tcdate as string
		local ldate
		ldate = .null.
		if occurs(':', tcdate) >= 2 .and. len(alltrim(tcdate)) <= 25
			do case
			case '.' $ tcdate and 'T' $ tcdate && JavaScript built-in JSON object format. 'YYYY-mm-ddTHH:mm:ss.ms'
				tcdate = substr(strtran(tcdate, "T", space(1)), 1, at(".", tcdate) - 1)
			case 'T' $ tcdate and occurs(':', tcdate) = 3 && ISO 8601 format. 'YYYY-mm-ddTHH:mm:ss-ms:00'
				tcdate = substr(strtran(tcdate, 'T', space(1)), 1, at('-', tcdate, 3) - 1)
			otherwise && VFP Date Time Format. 'YYYY-mm-dd HH:mm:ss'
			endcase
			try
				setDateAct = set("Date")
				set date ymd
				ldate = ctot(tcdate)
			catch				
				ldate = {//::}
			finally
				set date &setDateAct
			endtry
		else
			try
				setDateAct = set("Date")
				set date ymd
				ldate = ctod(tcdate)
			catch
				ldate = {//}
			finally
				set date &setDateAct
			endtry
		endif
		return ldate
	endfunc
	&& ======================================================================== &&
	&& Function GetString
	&& ======================================================================== &&
	function getstring as string
		lparameters tcstring as string
		tcstring = allt(tcstring)
		tcstring = strtran(tcstring, '\', '\\' )
		*tcstring = strtran(tcstring, '/', '\/' )
		tcstring = strtran(tcstring, chr(9),  '\t' )
		tcstring = strtran(tcstring, chr(10), '\n' )
		tcstring = strtran(tcstring, chr(13), '\r' )
		tcstring = strtran(tcstring, '"', '\"' )
		return '"' +tcstring + '"'
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
