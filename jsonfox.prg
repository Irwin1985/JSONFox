*====================================================================
* JSONFox
*====================================================================
Define Class JsonFox As Custom

	Hidden cJsonOri
	Hidden cJsonStr
	Hidden nPos
	Hidden nLen
	Hidden lValidCall
	Hidden lparseXML
	Hidden nPosXML

	Version			= ''
	LastUpdate		= ''
	Author			= ''
	Email			= ''
	LastErrorText 	= ''
	Flag 			= .F.
	#Define True 	.T.
	#Define False	.F.

	Procedure Init
		With This
			.nPos 		= 0
			.nLen 		= 0
			.lparseXML 	= .F.
			.nPosXML	= 0
			.lValidCall = True
			.Version	= '1.8 (beta)'
			.lValidCall = True
			.LastUpdate	= '2019-04-26 08:48:16 AM'
			.lValidCall = True
			.Author		= 'Irwin RodrÌguez'
			.lValidCall = True
			.Email		= 'rodriguez.irwin@gmail.com'
			.Flag 		= Createobject('FLAG')
		Endwith

*====================================================================
	Procedure decode(tcJsonStr As Memo) As Object
		This.cJsonStr = tcJsonStr
		Return This.__decode()

*====================================================================
	Procedure loadFile(tcJsonFile As String) As Object
		If !File(tcJsonFile)
			This.__setLastErrorText('File not found')
			Return Null
		Else
			This.cJsonStr = Filetostr(tcJsonFile)
		Endif
		Return This.__decode()

*====================================================================
	Procedure ArrayToXML(tvArray As Variant) As String
		cType = Vartype(tvArray)
		If Not Inlist(cType, 'O', 'C')
			This.__setLastErrorText('invalid param')
			Return ''
		Endif

		If cType == 'O'
			tvArray = This.encode(tvArray)
			If Left(tvArray,1) = '{' .And. Substr(tvArray,2,1) <> '['
				tvArray = '[' + tvArray + ']'
			Endif
		Endif

		If Left(tvArray,1) == '{' And Right(tvArray,1) == '}'
			tvArray = '??' + tvArray + '??'
			tvArray = Strextract(tvArray, '??{', '}??')
		Endif

		This.cJsonStr 	= tvArray
		This.lparseXML 	= True
		This.__parse_value()
		If !Empty(This.LastErrorText)
			Return ''
		Endif
		This.lparseXML 	= .F.
		This.nPosXML	= 0

		If Type('aColumns') = 'U'
			This.__setLastErrorText('could not parse XML. Aux var was not created')
			Return ''
		Endif

		cSelect = ''
		cFrom	= ''
		cPiloto = ''

		For i=1 To Alen(aColumns)
			If !Empty(cSelect)
				cSelect = cSelect + ','
			Endif
			cSelect = cSelect + aColumns[i] + '.valor as ' + aColumns[i]
			If i = 1
				cFrom = cFrom + ' (SELECT valor, RECNO() rn FROM ' + aColumns[i] + ') ' + aColumns[i]
			Else
				cFrom = cFrom + ' FULL JOIN (SELECT valor, RECNO() rn FROM ' + aColumns[i] + ') ' + aColumns[i] + ' ON ' + aColumns[i] + '.rn = ' + cPiloto + '.rn'
			Endif
			cPiloto = aColumns[i]
		Endfor
		lcMacro = 'SELECT ' + cSelect + ' FROM ' + cFrom + ' INTO CURSOR qResult'
		&lcMacro
		Local lcOut As String
		lcOut = ''
		=Cursortoxml('qResult','lcOut',1,0,0,'1')
		Close Databases All
		Release aColumns
		Return lcOut

*====================================================================
	Procedure XMLToJson(tcXML As Memo) As Memo
		If Empty(tcXML)
			This.__setLastErrorText('invalid XML format')
			Return ''
		Endif
		Local lcJsonXML As Memo, nCount As Integer
		lcJsonXML 	= ''
		nCount 		= 0
		=Xmltocursor(tcXML, 'qXML')
		Select qXML
		Scan
			nCount = nCount + 1
			If !Empty(lcJsonXML)
				lcJsonXML = lcJsonXML + ','
			Endif

			Scatter Name loXML Memo
			lcJsonXML = lcJsonXML + This.encode(loXML)
			Select qXML
		Endscan
		If nCount > 1
			lcJsonXML = '[' + lcJsonXML + ']'
		Endif
		Close Databases All
		Return lcJsonXML

*====================================================================
	Procedure encode(vNewProp As Variant) As Memo
		Local lcVarType As Character
		lcVarType = Vartype(vNewProp)
		Do Case
		Case lcVarType == 'C'
			vNewProp = Alltrim(vNewProp)
			vNewProp = Strtran(vNewProp, '\', '\\' )
			vNewProp = Strtran(vNewProp, '/', '\/' )
			vNewProp = Strtran(vNewProp, Chr(9),  '\t' )
			vNewProp = Strtran(vNewProp, Chr(10), '\n' )
			vNewProp = Strtran(vNewProp, Chr(13), '\r' )
			vNewProp = Strtran(vNewProp, '"', '\"' )
			Return '"' + vNewProp + '"'

		Case lcVarType == 'N'
			Return Transform(vNewProp)

		Case lcVarType == 'L'
			Return Iif(vNewProp, 'true', 'false')

		Case lcVarType == 'X'
			Return 'null'

		Case lcVarType == 'D'
			cCenturyAct = Set('Century')
			Set Century On
			lcDate = '"' + Alltrim(Str(Year(vNewProp))) + '-' + Padl(Alltrim(Str(Month(vNewProp))),2,'0') + '-' + Padl(Alltrim(Str(Day(vNewProp))),2,'0') + '"'
			Set Century &cCenturyAct
			Return lcDate

		Case lcVarType == 'T'
			cCenturyAct = Set('Century')
			cHourAct 	= Set('Hours')
			Set Century On
			Set Hours To 24
			lcDate = '"' + Alltrim(Str(Year(vNewVal))) + '-' + Padl(Alltrim(Str(Month(vNewVal))),2,'0') + '-' + Padl(Alltrim(Str(Day(vNewVal))),2,'0') + Space(1) + Padl(Alltrim(Str(Hour(vNewVal))),2,'0') + ':' + Padl(Alltrim(Str(Minute(vNewVal))),2,'0') + ':' + Padl(Alltrim(Str(Sec(vNewVal))),2,'0') + '"'
			Set Century  &cCenturyAct
			Set Hours To &cHourAct
			Return lcDate

		Case lcVarType == 'O'
			Return '{' + Execscript(This.load_script(), vNewProp, This.load_script()) + '}'
		Otherwise
		Endcase

*====================================================================
	Hidden Procedure load_script As Memo
		TEXT To lcLoad NoShow TextMerge PreText 7
			Lparameters toObj, tcExecScript
			Local vNewVal
			vNewVal = toObj
			Local lcPtyName, lcJsonStr, cReturn, arrPty[1]
			=Amembers(arrPty,vNewVal)
			cReturn = ''
			For Each lcPtyName In arrPty
				If Type('Alen(vNewVal.' + lcPtyName + ')') == 'N'
					Local i,lnSize
					lcJsonStr 	= ''
					lnSize 	= Eval('Alen(vNewVal.'+lcPtyName+')')
					For i=1 To lnSize
						lcMacro = 'lcJsonStr = lcJsonStr + "," + Encode(vNewVal.' + lcPtyName + '[i], tcExecScript)'
						&lcMacro
					Next
					lcJsonStr = '[' + Substr(lcJsonStr,2) + ']'
				Else
					lcJsonStr = Encode(Evaluate('vNewVal.' + lcPtyName), tcExecScript)
				Endif
				If Lower(lcPtyName) <> 'array'
					If Left(lcPtyName,1) == '_'
						lcPtyName = Substr(lcPtyName,2)
					Endif
					cReturn = cReturn + ',' + '"' + Lower(lcPtyName) + '":' + lcJsonStr
				Else
					cReturn = cReturn + ',' + lcJsonStr
				Endif
			Next
			lcRet = Substr(cReturn,2)
			Return lcRet

			*====================================================================
			Procedure encode As Memo
				Lparameters vNewVal, tcExecScript
				Local cTipo As Character
				If Type('ALen(vNewVal)') == 'N'
					cTipo = 'A'
				Else
					cTipo = Vartype(vNewVal)
				Endif
				Do Case
				Case cTipo == 'D'
					cCenturyAct = Set('Century')
					Set Century On
					lcDate = '"' + Alltrim(Str(Year(vNewVal))) + '-' + Padl(Alltrim(Str(Month(vNewVal))),2,'0') + '-' + Padl(Alltrim(Str(Day(vNewVal))),2,'0') + '"'
					Set Century &cCenturyAct
					Return lcDate
				Case cTipo == 'T'
					cCenturyAct = Set('Century')
					cHourAct 	= Set('Hours')
					Set Century On
					Set Hours To 24
					lcDate = '"' + Alltrim(Str(Year(vNewVal))) + '-' + Padl(Alltrim(Str(Month(vNewVal))),2,'0') + '-' + Padl(Alltrim(Str(Day(vNewVal))),2,'0') + Space(1) + Padl(Alltrim(Str(Hour(vNewVal))),2,'0') + ':' + Padl(Alltrim(Str(Minute(vNewVal))),2,'0') + ':' + Padl(Alltrim(Str(Sec(vNewVal))),2,'0') + '"'
					Set Century  &cCenturyAct
					Set Hours To &cHourAct
					Return lcDate
				Case cTipo == 'N'
					Return Transform(vNewVal)
				Case cTipo == 'L'
					Return Iif(vNewVal, 'true', 'false')
				Case cTipo == 'X'
					Return 'null'
				Case cTipo == 'C'
					vNewVal = Allt(vNewVal)
					vNewVal = Strtran(vNewVal, '\', '\\' )
					vNewVal = Strtran(vNewVal, '/', '\/' )
					vNewVal = Strtran(vNewVal, Chr(9),  '\t' )
					vNewVal = Strtran(vNewVal, Chr(10), '\n' )
					vNewVal = Strtran(vNewVal, Chr(13), '\r' )
					vNewVal = Strtran(vNewVal, '"', '\"' )
					Return '"' + vNewVal + '"'
				Case cTipo == 'A'
					Local valor, cReturn
					cReturn = ''
					For Each valor In vNewVal
						cReturn = cReturn + ',' +  This.encode( valor )
					Next
					Return  '[' + Substr(cReturn,2) + ']'
				Case cTipo == 'O'
					lcRet = Execscript(tcExecScript, vNewVal, tcExecScript)
					If Left(lcRet,1) <> '['
						lcRet = '{' + lcRet + '}'
					Endif
					Return lcRet
				Otherwise
				Endcase

			*====================================================================
		EndText
		Return lcLoad

*====================================================================
	Hidden Procedure __decode As Object
		This.cJsonOri = This.cJsonStr
		This.__cleanJsonString()
		This.nPos = 1
		This.nLen = Len(This.cJsonOri)
		If This.__validate_json_format()
			Return This.__parse_object()
		Else
			This.__setLastErrorText('invalid JSON format')
			Return Null
		Endif

*====================================================================
	Hidden Procedure __parse_object As Object
		Local oCurObj As Object, lcPropName As String, lcType As String, vNewVal As Variant
		oCurObj = Createobject('__custom_object')
		This.__eat_json(2)
		Do While True
			lcPropName = This.__parse_string(True)
			If Empty(lcPropName)
				Return Null
			Endif
			If This.__get_Token() <> ':'
				This.__setLastErrorText("Expected ':' - Got undefined")
				Return Null
			Endif
			This.__eat_json(2)
			lcType  = ''
			vNewVal = This.__parse_value(@lcType)
			This.Flag.Active = True
			oCurObj.setProperty(lcPropName, vNewVal, lcType, This.Flag)
			This.__parse_XML(lcPropName, vNewVal)
			cToken = This.__get_Token()
			Do Case
			Case cToken == ','
				This.__eat_json(2)
				Loop
			Case cToken == '}'
				This.__eat_json(2)
				Exit
			Otherwise
			Endcase
		Enddo
		Return oCurObj

*====================================================================
	Hidden Procedure __parse_value As Variant
		Lparameters tcType As String
		Local cToken As String
		cToken = This.__get_Token()
		If !Inlist(cToken, '{', '[', '"', 't', 'f', '-', 'n') And !Isdigit(cToken)
			This.__setLastErrorText("Expecting 'STRING', 'NUMBER', 'NULL', 'TRUE', 'FALSE', '{', '[', Got undefined")
			Return Null
		Endif

		Do Case
		Case cToken == '{'
			tcType = 'O'
			Return This.__parse_object()
		Case cToken == '['
			tcType = 'A'
			Return This.__parse_array()
		Case cToken == '"'
			tcType = 'S'
			Return This.__parse_string()
		Case cToken == 't'
			tcType = 'B'
			Return This.__parse_expr('true')
		Case cToken == 'f'
			tcType = 'B'
			Return This.__parse_expr('false')
		Case cToken == 'n'
			tcType = 'N'
			Return This.__parse_expr('null')
		Case Isdigit(cToken) Or cToken == '-'
			tcType = 'I'
			Return This.__parse_number()
		Otherwise
		Endcase

*====================================================================
	Hidden Procedure __parse_array As Object
		Local aCustomArr As Object
		This.__eat_json(2)
		aCustomArr = Createobject('__custom_array')
		Do While True
			lcType  = ''
			vNewVal = This.__parse_value(@lcType)
			aCustomArr.array_push(vNewVal)
			cToken = This.__get_Token()
			Do Case
			Case cToken == ','
				This.__eat_json(2)
				Loop
			Case cToken == ']'
				This.__eat_json(2)
				Exit
			Otherwise
			Endcase
		Enddo
		Return aCustomArr

*====================================================================
	Hidden Procedure __parse_number As Number
		Local cNumber As String, bIsNegative As boolean
		bIsNegative = .F.
		If This.__get_Token() == '-'
			bIsNegative = True
		Endif
		cNumber = ''
		Do While True
			cValue 	= This.__get_Token()
			If Inlist(cValue, ',', '}', ']')
				Exit
			Endif
			cNumber = cNumber + cValue
			This.__eat_json(2)
		Enddo
		Set Decimals To 10
		nValNumber = Val(cNumber)
		Return Iif(bIsNegative, nValNumber * -1, nValNumber)

*====================================================================
	Hidden Procedure __parse_expr As Variant
		Lparameters tcStr As String
		vNewVal 	= ''
		lnLenExp 	= 0
		Do Case
		Case tcStr == 'true'
			lnLenExp = 4
			If Left(This.cJsonStr, lnLenExp) == 'true'
				vNewVal = True
			Else
				vNewVal = ''
			Endif
		Case tcStr == 'false'
			lnLenExp = 5
			If Left(This.cJsonStr, lnLenExp) == 'false'
				vNewVal = .F.
			Else
				vNewVal = ''
			Endif
		Case tcStr == 'null'
			lnLenExp = 4
			If Left(This.cJsonStr, lnLenExp) == 'null'
				vNewVal = Null
			Else
				vNewVal = ''
			Endif
		Otherwise
		Endcase
		If Type('vNewVal') == 'C' And Empty(vNewVal)
			If Inlist(tcStr, 'true', 'false')
				cMsg = "Expecting 'TRUE', 'FALSE', Got undefined"
			Else
				cMsg = "Expecting 'NULL', Got undefined"
			Endif
			This.__setLastErrorText(cMsg)
			Return ''
		Endif
		lnLenExp = lnLenExp + 1
		This.__eat_json(lnLenExp)
		Return vNewVal

*====================================================================
	Hidden Procedure __parse_string As Memo
		Lparameters tlisNameAttr
		Local lcValue As String, dDate As Variant
		lcValue = ''
		If This.__get_Token() <> '"'
			This.__setLastErrorText('Expected " - Got undefined')
			Return ''
		Endif
		lcValue = Strextract(This.cJsonStr, '"', '"', 1)
		MessageBox("policia parse_string: " + lcValue)
		If Occurs('-', lcValue) == 2 .And. Not tlisNameAttr
			lDate = This.__checkDate(lcValue)
			If !Isnull(lDate)
				dDate = lDate
			Endif
		Endif
		This.__eat_json(Len(lcValue) + 3)
		Return Iif(Empty(dDate),lcValue,dDate)

*====================================================================
	Hidden Procedure __parse_XML
		Lparameters tcColumn, tvNewVal
		Local lContinue As boolean
		lContinue = True
		If This.lparseXML
			lcType = Vartype(tvNewVal)
			If !Used(Alltrim(tcColumn))
				lcAlter = 'L'
				lDate 	= Null
				Do Case
				Case lcType = 'C' And Occurs('-', tvNewVal) == 2
					lDate 	= This.__checkDate(tvNewVal)
					If !Isnull(lDate)
						lcType 	 = Vartype(lDate)
						lcAlter  = lcType + ' NULL'
						tvNewVal = lDate
					Endif
				Case lcType = 'C'
					lcAlter = 'C(100) NULL'
				Case lcType = 'N'
					lcAlter = 'N(20,10) NULL'
				Case lcType = 'L'
					lcAlter = 'L NULL'
				Case lcType = 'D'
					lcAlter = 'D NULL'
				Case lcType = 'T'
					lcAlter = 'T NULL'
				Otherwise
				Endcase
				This.nPosXML = This.nPosXML + 1
				If Type('aColumns') == 'U'
					Public aColumns
				Endif
				Dimension aColumns[THIS.nPosXML]
				aColumns[THIS.nPosXML] = tcColumn
				lcMacro = 'CREATE CURSOR ' + Alltrim(tcColumn) + ' (valor ' + lcAlter + ')'
				Try
					&lcMacro
				Catch To oErr
					lContinue = .F.
					This.__setLastErrorText('Invalid cursor name or field')
				Endtry
			Endif
			If !lContinue
				Return ''
			Endif
			If lcType == 'C' And Occurs('-', tvNewVal) == 2
				lDate 	= This.__checkDate(tvNewVal)
				If !Isnull(lDate)
					tvNewVal = lDate
				Endif
			Endif
			Try
				Insert Into &tcColumn (valor) Values(tvNewVal)
			Catch
				Insert Into &tcColumn (valor) Values(Null)
			Endtry
		Endif

*====================================================================
	Hidden Procedure __checkDate As Variant
		Lparameters tsDate As String
		Local cStr As String, lIsDateTime As boolean, lDate As Variant
		cStr 		= ''
		lIsDateTime = .F.
		lDate		= Null
		cStr 		= Strtran(tsDate, '-')
		If Occurs(':', tsDate) == 2
			lIsDateTime = True
			cStr 		= Strtran(cStr, ':')
			cStr 		= Strtran(Lower(cStr), 'am')
			cStr 		= Strtran(Lower(cStr), 'pm')
			cStr 		= Strtran(cStr, Space(1))
		Endif
		For i=1 To Len(cStr) Step 1
			If Isdigit(Substr(cStr, i, 1))
				Loop
			Else
				Return Null
			Endif
		Endfor
		If Val(Left(tsDate,4)) > 0 And Val(Strextract(tsDate, '-', '-',1)) > 0 And Val(Right(tsDate,2)) > 0
			If !lIsDateTime
				lDate = Date(Val(Left(tsDate,4)), Val(Strextract(tsDate, '-', '-',1)), Val(Right(tsDate,2)))
			Else
				lDate = Datetime(Val(Left(tsDate,4)), Val(Strextract(tsDate, '-', '-',1)), Val(Strextract(tsDate, '-', Space(1),2)), Val(Substr(tsDate, 12, 2)), Val(Strextract(tsDate, ':', ':',1)), Val(Right(tsDate,2)))
			Endif
		Else
			lDate = Iif(!lIsDateTime, {//}, {//::})
		Endif
		Return lDate

*====================================================================
	Hidden Procedure __eat_json(tnPosition As Integer)
		This.cJsonStr = Alltrim(Substr(This.cJsonStr, tnPosition, Len(This.cJsonStr)))

*====================================================================
	Hidden Procedure __get_Token As String
		Local cToken As Character
		cToken = ''
		Do While True
			If This.nPos > This.nLen
				Return Null
			Endif
			cToken = Left(This.cJsonStr, 1)
			If Empty(cToken)
				This.nPos = This.nPos + 1
				Loop
			Endif
			Return cToken
		Enddo

*====================================================================
	Hidden Procedure __validate_json_format As boolean
		Return (Left(This.cJsonStr,1) == '{' And Right(This.cJsonStr, 1) == '}')

*====================================================================
	Hidden Procedure __cleanJsonString
		With this
			.cJsonStr = Strtran(.cJsonStr, Chr(9))
			.cJsonStr = Strtran(.cJsonStr, Chr(10))
			.cJsonStr = Strtran(.cJsonStr, Chr(13))
			.cJsonStr = Alltrim(.__html_entity_decode(.cJsonStr))
		EndWith

*====================================================================
	Hidden Procedure __html_entity_decode(cText As Memo) As Memo
		cText = Strtran(cText, "\u00e1", "·")
		cText = Strtran(cText, "\u00e9", "È")
		cText = Strtran(cText, "\u00ed", "Ì")
		cText = Strtran(cText, "\u00f3", "Û")
		cText = Strtran(cText, "\u00fa", "˙")
		cText = Strtran(cText, "\u00c1", "¡")
		cText = Strtran(cText, "\u00c9", "…")
		cText = Strtran(cText, "\u00cd", "Õ")
		cText = Strtran(cText, "\u00d3", "”")
		cText = Strtran(cText, "\u00da", "⁄")
		cText = Strtran(cText, "\u00f1", "Ò")
		cText = Strtran(cText, "\u00d1", "—")
		cText = Strtran(cText, "\u0026", "&")
		cText = Strtran(cText, "\u2019", "'")
		cText = Strtran(cText, "\u003A", ":")
		cText = Strtran(cText, "\u002B", "+")
		cText = Strtran(cText, "\u002D", "-")
		cText = Strtran(cText, "\u0023", "#")
		cText = Strtran(cText, "\u0025", "%")
		cText = Strtran(cText, "\u0022", '"')
		cText = Strtran(cText, "\u0025", "%")
		cText = Strtran(cText, "\u00b2", "≤")
		cText = Strtran(cText, "√°", "·")
		cText = Strtran(cText, "√Å",  "¡")
		cText = Strtran(cText, "√©", "È")
		cText = Strtran(cText, "√â", "…")
		cText = Strtran(cText, "√≠", "Ì")
		cText = Strtran(cText, "√ç",  "Õ")
		cText = Strtran(cText, "√≥", "Û")
		cText = Strtran(cText, "√ì", "”")
		cText = Strtran(cText, "√∫", "˙")
		cText = Strtran(cText, "√ö", "⁄")
		Return cText

*====================================================================
	Hidden Procedure __setLastErrorText(tcErrorText As String)
		This.lValidCall = True
		This.LastErrorText = Iif(!Empty(tcErrorText), 'Error: parse error on line ' + Alltrim(Str(This.nPos,6,0)) + ': ' + tcErrorText, '')

*====================================================================
	Hidden Procedure LastErrorText_Assign(vNewVal)
		If This.lValidCall
			This.lValidCall = .F.
			This.LastErrorText = m.vNewVal
		Endif

*====================================================================
	Hidden Procedure Version_Assign(vNewVal)
		If This.lValidCall
			This.lValidCall = .F.
			This.Version = m.vNewVal
		Endif

*====================================================================
	Hidden Procedure Version_Access
		Return This.Version

*====================================================================
	Hidden Procedure LastUpdate_Assign(vNewVal)
		If This.lValidCall
			This.lValidCall = .F.
			This.LastUpdate = m.vNewVal
		Endif

*====================================================================
	Hidden Procedure LastUpdate_Access
		Return This.LastUpdate

*====================================================================
	Hidden Procedure Author_Assign(vNewVal)
		If This.lValidCall
			This.lValidCall = .F.
			This.Author = m.vNewVal
		Endif

*====================================================================
	Hidden Procedure Author_Access
		Return This.Author

*====================================================================
	Hidden Procedure Email_Assign(vNewVal)
		If This.lValidCall
			This.lValidCall = .F.
			This.Email = m.vNewVal
		Endif

*====================================================================
	Hidden Procedure Email_Access
		Return This.Email

*====================================================================
Enddefine
*====================================================================
* This class is used as Array Helper
*====================================================================
Define Class __custom_array As Custom
	Hidden 				;
	Classlibrary, 		;
	Comment, 			;
	Baseclass, 			;
	Controlcount, 		;
	Controls, 			;
	Object, 			;
	Objects,			;
	Height, 			;
	Helpcontextid, 		;
	Left, 				;
	Name, 				;
	Parent, 			;
	Parentclass, 		;
	Picture, 			;
	Tag, 				;
	Top, 				;
	Whatsthishelpid, 	;
	Width,				;
	Class
	Hidden nArrLen
	Dimension Array[1]

	Procedure Init
		This.nArrLen = 0

*====================================================================
	Procedure array_push(vNewVal As Variant)
		This.nArrLen = This.nArrLen + 1
		Dimension This.Array[THIS.nArrLen]
		This.Array[this.nArrLen] = vNewVal

*====================================================================
	Procedure getvalue(tnIndex As Integer)
		Try
			nLen = This.Array[tnIndex]
		Catch
			nLen = Null
		Endtry
		Return nLen

*====================================================================
	Procedure Len
		Return This.nArrLen

*====================================================================
Enddefine
*====================================================================
* This class is used as object helper
*====================================================================
Define Class __custom_object As Custom
	Hidden 					;
	Classlibrary, 		;
	Comment, 			;
	Baseclass, 			;
	Controlcount, 		;
	Controls, 			;
	Objects, 			;
	Object, 			;
	Height, 			;
	Helpcontextid, 		;
	Left, 				;
	Name, 				;
	Parent, 			;
	Parentclass, 		;
	Picture, 			;
	Tag, 				;
	Top, 				;
	Whatsthishelpid, 	;
	Width,				;
	Class

*====================================================================
	Procedure setProperty(tcName As String, tvNewVal As Variant, tcType As String, vFlag As Object)
		If vFlag.Active
			vFlag.Active 	= .F.
			tcName 			= '_' + tcName
			If Vartype(This. tcName) = 'U'
				This.AddProperty(tcName, tvNewVal)
			Else
				This. tcName = tvNewVal
			Endif
		Endif

*====================================================================
	Procedure valueOf(tcName As String)
		tcName = '_' + tcName
		If Vartype(This. &tcName) == 'U'
			Return ''
		Else
			lcMacro = 'Return This.' + tcName
			&lcMacro
		Endif
		Return ''

*====================================================================
Enddefine
*====================================================================
* This class is used internally
*====================================================================
Define Class Flag As Custom
	Active = .F.
Enddefine
