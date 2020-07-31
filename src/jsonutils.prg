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
		If Occurs(':', tcDate) >= 2 .And. Len(Alltrim(tcDate)) <= 25
			lIsDateTime = .T.
			Do case
			case "." $ tcDate and "T" $ tcDate && JavaScript built-in JSON object format. 'YYYY-mm-ddTHH:mm:ss.ms'
				cStr = strtran(tcDate, "T")
				cStr = Substr(cStr, 1, At(".", cStr) - 1)
				cStr = Strtran(cStr, '-')
				cStr = Strtran(cStr, ':')
				tcDate = Substr(strtran(tcDate, "T", Space(1)), 1, At(".", tcDate) - 1)
			Case "T" $ tcDate and Occurs(':', tcDate) = 3 && ISO 8601 format. 'YYYY-mm-ddTHH:mm:ss-ms:00'
				cStr = strtran(tcDate, "T")
				cStr = Substr(cStr, 1, At("-", cStr, 3) - 1)
				cStr = Strtran(cStr, '-')
				cStr = Strtran(cStr, ':')
				tcDate = Substr(strtran(tcDate, "T", Space(1)), 1, At("-", tcDate, 3) - 1)
			Otherwise
				cStr = Strtran(cStr, ':')
				cStr = Strtran(Lower(cStr), 'am')
				cStr = Strtran(Lower(cStr), 'pm')
				cStr = Strtran(cStr, Space(1))
				tcDate = Substr(tcDate, 1, At(Space(1), tcDate, 2) - 1)
			endcase
		Endif
		For i=1 To Len(cStr) Step 1
			If Isdigit(Substr(cStr, i, 1))
				Loop
			Else
				Return .Null.
			Endif
		EndFor
		lcYear  = Left(tcDate, 4)
		lcMonth = Strextract(tcDate, '-', '-', 1)
		If !lIsDateTime
			lcDay = Right(tcDate, 2)
		Else
			lcDay = Strextract(tcDate, '-', Space(1), 2)
		EndIf
		If Val(lcYear) > 0 And Val(lcMonth) > 0 And Val(lcDay) > 0
			If !lIsDateTime
				lDate = Date(Val(lcYear), Val(lcMonth), Val(lcDay))
			Else
				lcHour = Substr(tcDate, 12, 2)
				lcMin  = Strextract(tcDate, ':', ':', 1)
				lcSecs = Right(tcDate, 2)
				lDate  = Datetime(Val(lcYear), Val(lcMonth), Val(lcDay), Val(lcHour), Val(lcMin), Val(lcSecs))
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
