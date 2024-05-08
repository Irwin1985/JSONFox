#include "JSONFox.h"
&& ======================================================================== &&
&& Class utils
&& JSON Utilities
&& ======================================================================== &&
define class jsonutils as custom
	
	Dimension aPattern[8, 2]
	
	Function init
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

	EndFunc

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
			Case tctype == 'X'
				tcvalue = "null"
			Otherwise
*!*					tcvalue = this.getstring(tcvalue)
				tcValue = this.getString(Iif(tlTrimChars, Alltrim(tcValue), tcValue), tlParseUTF8)
			endcase
			&& IRODG 08/08/2023 Inicio
			*tcvalue = alltrim(tcValue)
			&& IRODG 08/08/2023 Fin
		case tctype $ "YFIN"
			tcvalue = strtran(transform(tcvalue), ',', '.')
		case tctype == 'L'
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
		If !IsDigit(Left(tcString, 1)) and !IsDigit(Right(tcString, 1))
			Return tcString
		EndIf
		* We try to identify a date format
		Local i
		For i = 1 to Alen(this.aPattern, 1)
			_screen.oRegEx.pattern = this.aPattern[i, 1]
			if _screen.oRegEx.Test(tcString)
				return Evl(this.formatDate(tcString, this.aPattern[i, 2]), tcString)
			endif
		EndFor
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
	function getstring as string
		lparameters tcString as string, tlParseUtf8 as Boolean
		&& IRODG 08/08/2023 Inicio
		*tcString = Alltrim(tcString)
		&& IRODG 08/08/2023 Fin		
		tcString = strtran(tcString, '\', '\\' )		
		tcString = strtran(tcString, chr(9),  '\t' )
		tcString = strtran(tcString, chr(10), '\n' )
		tcString = strtran(tcString, chr(13), '\r' )
		If Left(Alltrim(tcString), 1) == '"' and Right(Alltrim(tcString),1) == '"'
			tcString = Substr(tcString, 2, Len(tcString)-2)
		EndIf
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
			tcString = StrTran(tcString,'º','\u00ba')
		EndIf
		If Left(Alltrim(tcString), 1) != '"' and Right(Alltrim(tcString),1) != '"'
			return '"'+tcString+'"'
		EndIf
		Return tcString
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
	EndFunc
	
	Function tokenTypeToStr(tnType)
		do case
		case tnType = 0
			Return 'EOF'
		case tnType = 1
			Return 'LBRACE'
		case tnType = 2
			Return 'RBRACE'
		case tnType = 3
			Return 'LBRACKET'
		case tnType = 4
			Return 'RBRACKET'
		case tnType = 5
			Return 'COMMA'
		case tnType = 6
			Return 'COLON'
		case tnType = 7
			Return 'TRUE'
		case tnType = 8
			Return 'FALSE'
		case tnType = 9
			Return 'NULL'
		case tnType = 10
			Return 'NUMBER'
		case tnType = 11
			Return 'KEY'
		case tnType = 12
			Return 'STRING'
		case tnType = 13
			Return 'LINE'
		case tnType = 14
			Return 'INTEGER'
		case tnType = 15
			Return 'FLOAT'
		case tnType = 16
			Return 'VALUE'
		case tnType = 17
			Return 'EOF'
		case tnType = 18
			return 'BOOLEAN'
		ENDCASE
	EndFunc
enddefine
