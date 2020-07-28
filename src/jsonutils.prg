&& ======================================================================== &&
&& Class utils
&& JSON Utilities
&& ======================================================================== &&
Define Class JSONUtils As Custom
&& ======================================================================== &&
&& Function Match
&& ======================================================================== &&
	Function Match As Void
		Lparameters toSC As Object, tnToken As Integer
		If toSC.Token.Code = tnToken
			toSC.NextToken()
		Else
			lcMsg = "Parse error on line " + Alltrim(Str(toSC.Token.LineNumber)) + ": Expecting '" + toSC.TokenToStr(tnToken) + "' got '" + toSC.TokenToStr(toSC.Token.Code) + "'"
			Error lcMsg
		Endif
	Endfunc
&& ======================================================================== &&
&& Function GetValue
&& ======================================================================== &&
	Function GetValue As String
		Lparameters tcValue As String, tcType As Character
		Do Case
		Case tcType $ "CDTBGMQVWX"
			Do Case
			Case tcType = "D"
				tcValue = '"' + Strtran(Dtoc(tcValue), ".", "-") + '"'
			Case tcType = "T"
				tcValue = '"' + Strtran(Ttoc(tcValue), ".", "-") + '"'
			Otherwise
				If tcType = "X"
					tcValue = "null"
				Else
					tcValue = This.GetString(tcValue)
				Endif
			Endcase
			tcValue = Alltrim(tcValue)
		Case tcType $ "YFIN"
			tcValue = Transform(tcValue)
		Case tcType = "L"
			tcValue = Iif(tcValue, "true", "false")
		Endcase
		Return tcValue
	Endfunc
&& ======================================================================== &&
&& Function FormatDate
&& return a valid date or datetime date type.
&& ======================================================================== &&
	Function FormatDate As Variant
		Lparameters tcDate As String
		Local cStr As String, lIsDateTime As Boolean, lDate As Variant
		cStr 		= ''
		lIsDateTime = .F.
		lDate		= .Null.
		cStr 		= Strtran(tcDate, '-')
		If Occurs(':', tcDate) = 2 .And. Len(Alltrim(tcDate)) <= 22
			lIsDateTime = .T.
			cStr 		= Strtran(cStr, ':')
			cStr 		= Strtran(Lower(cStr), 'am')
			cStr 		= Strtran(Lower(cStr), 'pm')
			cStr 		= Strtran(cStr, Space(1))
		Endif
		For i=1 To Len(cStr) Step 1
			If Isdigit(Substr(cStr, i, 1))
				Loop
			Else
				Return .Null.
			Endif
		Endfor
		If Val(Left(tcDate,4)) > 0 And Val(Strextract(tcDate, '-', '-',1)) > 0 And Val(Right(tcDate,2)) > 0
			If !lIsDateTime
				lDate = Date(Val(Left(tcDate,4)), Val(Strextract(tcDate, '-', '-',1)), Val(Right(tcDate,2)))
			Else
				lDate = Datetime(Val(Left(tcDate,4)), Val(Strextract(tcDate, '-', '-',1)), Val(Strextract(tcDate, '-', Space(1),2)), Val(Substr(tcDate, 12, 2)), Val(Strextract(tcDate, ':', ':',1)), Val(Right(tcDate,2)))
			Endif
		Else
			lDate = Iif(!lIsDateTime, {//}, {//::})
		Endif
		Return lDate
	Endfunc
&& ======================================================================== &&
&& Function GetString
&& ======================================================================== &&
	Function GetString As String
		Lparameters tcString As String
		tcString = Allt(tcString)
		tcString = Strtran(tcString, '\', '\\' )
		tcString = Strtran(tcString, '/', '\/' )
		tcString = Strtran(tcString, Chr(9),  '\t' )
		tcString = Strtran(tcString, Chr(10), '\n' )
		tcString = Strtran(tcString, Chr(13), '\r' )
		tcString = Strtran(tcString, '"', '\"' )
		Return '"' +tcString + '"'
	EndFunc
&& ======================================================================== &&
&& Function CheckProp
&& Check the object property name for invalid format (replace with '_')
&& ======================================================================== &&
	Function CheckProp(tcProp As String) As String
		Local lcFinalProp As String
		lcFinalProp = ""
		For i = 1 To Len(tcProp)
			lcChar = Substr(tcProp, i, 1)
			If (i = 1 and IsDigit(lcChar)) or (!Isalpha(lcChar) and !IsDigit(lcChar))
				lcFinalProp = lcFinalProp + "_"
			else
				lcFinalProp = lcFinalProp + lcChar
			EndIf
		Endfor
		Return Alltrim(lcFinalProp)
	Endfunc
Enddefine
