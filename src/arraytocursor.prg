#include "JSONFox.h"
* ArrayToCursor
Define Class ArrayToCursor As Session
	#Define STRING_MAX_SIZE	254

	curname 	= ""
	nSessionID 	= 0
	nColumns 	= 0
	hashMap 	= .Null.
	cFieldList 	= ""

	Dimension aTableStruct(1)
	tableStructCounter = 0

	* Init
	Function Init
		This.hashMap = Createobject("Empty")
		=AddProperty(This.hashMap, "field", '')
		=AddProperty(This.hashMap, "value", '')
	Endfunc
	&& ======================================================================== &&
	&& Function Array
	&& EBNF -> 	array  	= '[' object | { ',' object }  ']'
	&& ======================================================================== &&
	Function Array As Void
		Private oMap, JSONUtils
		oMap 		= This.hashMap
		JSONUtils 	= _Screen.JSONUtils

		With This
			If Empty(This.nSessionID)
				This.nSessionID = Set("Datasession")
			Endif
			Set DataSession To (This.nSessionID)

			JSONUtils.Consume(T_LBRACKET, "Expect '[' before Array definition.")
			nGlobalRow = 1
			Dimension arrMap(nGlobalRow)
			arrMap[nGlobalRow] = .Object()

			Do While JSONUtils.match(T_COMMA)
				nGlobalRow = nGlobalRow + 1
				Dimension arrMap(nGlobalRow)
				arrMap[nGlobalRow] = .Object()
			Enddo

			JSONUtils.Consume(T_RBRACKET, "Expect ']' after Array definition.")
		Endwith
		This.InsertData()
	Endfunc
	&& ======================================================================== &&
	&& Function Object
	&& EBNF -> 	object 	= '{' kvp | { ',' kvp} '}'
	&& ======================================================================== &&
	Hidden Function Object As Void
		JSONUtils.Consume(T_LBRACE, "Expect '{' before json object.")
		oCollection = Createobject("Collection")

		This.kvp()
		oCollection.Add(oMap.Value, oMap.Field)

		Do While JSONUtils.match(T_COMMA)
			This.kvp()
			oCollection.Add(oMap.Value, oMap.Field)
		Enddo
		JSONUtils.Consume(T_RBRACE, "Expect '}' after json object.")
		Return oCollection
	Endfunc
	&& ======================================================================== &&
	&& Function Kvp
	&& EBNF -> 	kvp 	= KEY ':' value
	&& 			value	= STRING | NUMBER | BOOLEAN	| NULL
	&& ======================================================================== &&
	Hidden Function kvp
		loElement = JSONUtils.Consume(T_STRING, "Expect right key element")
		lcProp 	  = loElement.Lexeme
		JSONUtils.Consume(T_COLON, "Expect ':' after key element.")
		If 		JSONUtils.match(T_STRING) 	Or ;
				JSONUtils.match(T_NUMBER) 	Or ;
				JSONUtils.match(T_BOOLEAN) 	Or ;
				JSONUtils.match(T_NULL)

			lxValue = This.Value()
			lcType  = Vartype(lxValue)
			Do Case
			Case lcType = "N"
				lcType = Iif(Occurs(".", Transform(lxValue)) > 0, "N", "I")
			Case lcType = "C"
				If Len(lxValue) > STRING_MAX_SIZE
					lcType = "M"
				Else
					If Occurs('-', lxValue) >= 2 && Check for date or datetime.
						lDate = JSONUtils.FormatDate(lxValue)
						If !Isnull(lDate)
							lxValue = lDate
							lcType  = Vartype(lxValue)
						Endif
					Endif
				Endif
			Endcase
			lcFieldName = Lower(JSONUtils.CheckProp(lcProp))

			This.CheckStructure(lcFieldName, lcType, Iif(lcType == "C", Len(lxValue), 0))
		Else
			JSONUtils.jsonError(_Screen.oPeek, "Unknown token value")
		Endif
		* Update Map
		oMap.Field = lcFieldName
		oMap.Value = lxValue
	Endfunc
	&& ======================================================================== &&
	&& Function Value
	&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | NULL
	&& ======================================================================== &&
	Hidden Function Value As Variant
		With This
			lnPrevType = _Screen.oPrevious.Type
			Do Case
			Case lnPrevType = T_STRING
				Return _Screen.oPrevious.Lexeme

			Case lnPrevType = T_NUMBER
				nVal = Val(_Screen.oPrevious.Lexeme)
				Return Iif(At('.', _Screen.oPrevious.Lexeme) > 0, nVal, Int(nVal))

			Case lnPrevType = T_BOOLEAN
				Return (_Screen.oPrevious.Lexeme == 'true')

			Case lnPrevType = T_NULL
				Return .Null.

			Otherwise
				JSONUtils.jsonError(_Screen.oPrevious, "Unknown token value")
			Endcase
		Endwith
	Endfunc
	* InsertData
	Hidden Function InsertData
		This.CreateCursor()
		Dimension aValues(1)
		aValues[1] = ''
		lcFieldList = This.cFieldList
		For i = 1 To Alen(arrMap, 1)
			o = arrMap[i]
			cValues = ''
			For j = 1 To Getwordcount(lcFieldList, ",")
				cField = Getwordnum(lcFieldList, j, ",")
				xValue = This.DefaultValue(cField)
				Try
					xValue = o.Item(cField)
				Catch
				Endtry
				Dimension aValues(j)
				aValues[j] = xValue
				cValues = cValues + Iif(j > 1, ",", '') + "aValues(" + Alltrim(Str(j)) + ")"
			Endfor
			cInsert = "INSERT INTO " + This.curname + "(" + lcFieldList + ") VALUES(" + cValues + ")"
			Try
				&cInsert
			Catch To loEx
				Wait loEx.Message Window
			Endtry
		Endfor
	Endfunc
	* CreateCursor
	Hidden Function CreateCursor
		cQuery  = "CREATE CURSOR " + This.curname + " ("
		nIndex  = 0
		lcComma = ""
		Local lcFieldList
		lcFieldList = This.cFieldList
		
		For j = 1 To Getwordcount(lcFieldList, ",")
			nIndex  = nIndex + 1
			lcComma = Iif(nIndex > 1, ",", Space(1))

			cField = Getwordnum(lcFieldList, j, ",")
			lcType = This.FieldType(cField)
			lcLen  = This.FieldLen(cField)

			cQuery = cQuery + lcComma + cField + Space(1)

			* Use Logical (faster) type for .Null. Columns.
			lcType  = Strtran(lcType, "X", "L")
			lcFlags = Iif(lcType == "C", "(" + Alltrim(Str(lcLen)) + ")", '')
			If lcType == "N"
				lcFlags = "(18,5)" && Integer Length 18 and Decimal length 5
			Endif
			cQuery = cQuery + lcType + lcFlags + " NULL"
		Endfor
		cQuery = cQuery + ")"
		Try
			&cQuery
		Catch To loEx
			Wait loEx.Message Window
		Endtry
	Endfunc

	* CheckStructure
	Function CheckStructure(tcFieldName, tcType, tnLength)
		* Find or Insert the field.
		nFieldIdx = Ascan(This.aTableStruct, tcFieldName)
		If nFieldIdx > 0
			* Check for .NULL. type and Update
			lcFieldType = Getwordnum(This.aTableStruct[nFieldIdx], 2, "|")
			If lcFieldType = "X"
				newVal = Getwordnum(This.aTableStruct[nFieldIdx], 1, "|")
				newVal = newVal + "|" + tcType
				newVal = newVal + "|" + Alltrim(Str(tnLength))
				This.aTableStruct[nFieldIdx] = newVal
			Endif
			* Check for Length and Update
			If lcFieldType = "C"
				lnFieldLen = Val(Getwordnum(This.aTableStruct[nFieldIdx], 3, "|"))
				If tnLength > lnFieldLen
					newVal = Getwordnum(This.aTableStruct[nFieldIdx], 1, "|")
					newVal = newVal + "|" + tcType
					newVal = newVal + "|" + Alltrim(Str(tnLength))
					This.aTableStruct[nFieldIdx] = newVal
				Endif
			Endif
		Else
			* Insert new field.
			This.tableStructCounter = This.tableStructCounter + 1
			Dimension This.aTableStruct(This.tableStructCounter)
			newVal = tcFieldName
			newVal = newVal + "|" + tcType
			If tcType == "C"
				newVal = newVal + "|" + Alltrim(Str(tnLength))
			Endif
			This.aTableStruct(This.tableStructCounter) = newVal
		Endif
	EndFunc

	* FieldType
	Hidden Function FieldType(tcField)
		nFieldIdx = Ascan(This.aTableStruct, tcField)
		lcType    = 'X'
		If nFieldIdx > 0
			lcType = Getwordnum(This.aTableStruct[nFieldIdx], 2, "|")
		Endif
		Return lcType
	Endfunc

	* FieldLength
	Hidden Function FieldLen(tcField)
		nFieldIdx = Ascan(This.aTableStruct, tcField)
		lnLen     = 0
		If nFieldIdx > 0
			lnLen = Val(Getwordnum(This.aTableStruct[nFieldIdx], 3, "|"))
		Endif
		Return lnLen
	Endfunc

	* DefaultValue
	Hidden Function DefaultValue(tcField)
		lcType = This.FieldType(tcField)
		Do Case
		Case lcType $ "CDTBGMQVWX"
			Do Case
			Case lcType = "D"
				Return Ctod("{}")
			Case lcType = "T"
				Return Ctot("{//::}")
			Otherwise
				If lcType = "X"
					Return .Null.
				Else
					Return ""
				Endif
			Endcase
		Case lcType $ "YFIN"
			Return 0
		Case lcType = 'L'
			Return .F.
		Otherwise
			Return .Null.
		Endcase
	Endfunc
	* cFieldList_Access
	Function cFieldList_Access
		Local lcFieldList
		lcFieldList = ''
		For i = 1 To Alen(This.aTableStruct, 1)
			lcFieldList = lcFieldList + Iif(i > 1, ',', '') + Getwordnum(This.aTableStruct[i], 1, "|")
		Endfor
		Return lcFieldList
	Endfunc
Enddefine
