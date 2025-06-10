#include "JSONFox.h"
* ArrayToCursor
Define Class ArrayToCursor As Session
	#Define STRING_MAX_SIZE	254

	curname 	 = ""
	nSessionID 	 = 0
	oTableStruct = .Null.
	
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
					lxValue.Value = _Screen.JSONUtils.CheckString(lxValue.Value)
					lcType  = Vartype(lxValue.Value)
				Endif
				If lcType == 'C'
					lnFieldLength = Iif(Empty(Len(lxValue.Value)), 1, Len(lxValue.Value))
				Endif
			Endcase
			lcFieldName = Lower(_Screen.JSONUtils.CheckProp(lcProp))
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
				loToken.value = iif(at('.', lcValue) > 0, Val(lcValue), int(Val(lcValue)))

			case .match(T_BOOLEAN)
				loToken.type = 'L'
				loToken.literal = .previous.value
				loToken.value = (.previous.value == 'true')
			case .match(T_NULL)
				loToken.type = 'X'
				loToken.literal = 'null'
				loToken.value = .null.
			Otherwise
				Error "Parser Error: This token is invalid in for cursor conversion: '" + _screen.jsonUtils.tokenTypeToStr(.peek.type) + "'"
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
				tcMessage = "Parser Error: expected token '" + _screen.jsonUtils.tokenTypeToStr(tnTokenType) + "' got = '" + _screen.jsonUtils.tokenTypeToStr(.peek.type) + "'"
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
