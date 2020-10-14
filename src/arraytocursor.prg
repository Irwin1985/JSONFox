#include "JSONFox.h"
&& ======================================================================== &&
&& ArrayToCursor Parser
&& ======================================================================== &&
Define Class ArrayToCursor As Session
	#Define STRING_MAX_SIZE		254
	Hidden sc
	Hidden utils
	CurName = ""
	Dimension aValues(1)
	Hidden nCounter
	nSessionID = 0
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		Lparameters toSC As Object
		Set Procedure To "JsonUtils" Additive
		With This
			.sc    		= toSC
			.nCounter 	= 0
			.utils 		= Createobject("JsonUtils")
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function Array
&& EBNF -> 	array  	= '[' object | { ',' object }  ']'
&& ======================================================================== &&
	Function Array As Void
		With This
			.Reset()
			.utils.Match(.sc, T_LEFTBRACKET)
			.Object()
			.InsertData()

			Do While .sc.Token.Code = T_COMMA
				.nCounter = 0
				.sc.NextToken()
				.Object()
				.InsertData()
			Enddo

			.utils.Match(.sc, T_RIGHTBRACKET)
			.CheckTypeLen()
			Use In (Select("cDataTypes"))
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function Reset
&& ======================================================================== &&
	Function Reset
		With This
			If !Empty(.nSessionID)
				Set DataSession To .nSessionID
				Create Cursor cDataTypes (cProp c(40), cType c(1))
			Endif
			If Used(.CurName)
				Select (.CurName)
				Use
			Endif
			.nCounter = 0
			Dimension .aValues(1)
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function CheckTypeLen
&& ======================================================================== &&
	Function CheckTypeLen As Void
		gnFieldcount = Afields(gaMyArray, This.CurName)
		For nCount = 1 To gnFieldcount
			If gaMyArray(nCount, 2) = "C"
				This.AlterCharColumn(gaMyArray(nCount, 1))
			Endif
		Endfor
	Endfunc
&& ======================================================================== &&
&& Function AlterCharColumn
&& ======================================================================== &&
	Function AlterCharColumn(tcColumn As String) As Void
		Try
			Dimension aMax(1)
			aMax[1] = 0
			cmd = "Select Max(Len(Alltrim(" + tcColumn + "))) From " + This.CurName + " Into Array aMax"
			&cmd
			If aMax[1] > 0
				cmd = "Alter table " + This.CurName  + " alter column " + tcColumn + " c(" + Alltrim(Str(aMax[1])) + ")"
				&cmd
			Endif
		Catch To loErr
			Wait loErr.Message Window Nowait
		Finally
			Release aMax
		Endtry
	Endfunc
&& ======================================================================== &&
&& Function Object
&& EBNF -> 	object 	= '{' kvp | { ',' kvp} '}'
&& ======================================================================== &&
	Hidden Function Object As Void
		With This
			.utils.Match(.sc, T_LEFTCURLEYBRACKET)
			.kvp()

			Do While .sc.Token.Code = T_COMMA
				.sc.NextToken()
				.kvp()
			Enddo

			.utils.Match(.sc, T_RIGHTCURLEYBRACKET)
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function Kvp
&& EBNF -> 	kvp 	= KEY ':' value
&& 			value	= STRING | NUMBER | BOOLEAN	| NULL
&& ======================================================================== &&
	Hidden Function kvp As Void
		With This
			lcProp = .sc.Token.Value
			.sc.NextToken()
			.utils.Match(.sc, T_COLON)
			If Inlist(.sc.Token.Code, T_STRING, T_INTEGER, T_FLOAT, T_TRUE, T_FALSE, T_NULL)
				lcValue = .Value()
				.nCounter = .nCounter + 1
				Dimension .aValues(.nCounter)
				.aValues[.nCounter] = lcValue

				lcType = Vartype(lcValue)
				Do Case
				Case lcType = "N"
					lcType = Iif(Occurs(".", Transform(lcValue)) > 0, "N", "I")
				Case lcType = "C"
					If Len(lcValue) > STRING_MAX_SIZE
						lcType = "M"
					Else
						If Occurs('-', lcValue) >= 2 && Check for date or datetime.
							lDate = .utils.FormatDate(lcValue)
							If !Isnull(lDate)
								lcValue = lDate
								lcType  = Vartype(lcValue)
								.aValues[.nCounter] = lcValue
							Endif
						Endif
					Endif
				Endcase
				Insert Into cDataTypes (cProp, cType) Values (.utils.CheckProp(lcProp), lcType)
			Else
				lcMsg = "Parse error on line " + Alltrim(Str(.sc.Token.LineNumber)) + ": Expecting 'STRING | NUMBER | BOOLEAN | NULL' got '" + .sc.TokenToStr(.sc.Token.Code) + "'"
				Error lcMsg
			Endif
		Endwith
	Endfunc
&& ======================================================================== &&
&& Function Value
&& EBNF -> 	value = STRING | NUMBER | BOOLEAN | NULL
&& ======================================================================== &&
	Hidden Function Value As Variant
		vNewVal = ""
		With This
			Do Case
			Case .sc.Token.Code = T_STRING
				vNewVal = .sc.Token.Value
			Case .sc.Token.Code = T_INTEGER
				vNewVal = Int(.sc.Token.Value)
			Case .sc.Token.Code = T_FLOAT
				vNewVal = .sc.Token.Value
			Case .sc.Token.Code = T_TRUE
				vNewVal = .sc.Token.Value
			Case .sc.Token.Code = T_FALSE
				vNewVal = .sc.Token.Value
			Case .sc.Token.Code = T_NULL
				vNewVal = .sc.Token.Value
			Otherwise
				lcMsg = "Parse error on line " + Alltrim(Str(.sc.Token.LineNumber)) + ": Unexpected Token '" + .sc.TokenToStr(.sc.Token.Code) + "'"
				Error lcMsg
			Endcase
		Endwith
		.sc.NextToken()
		Return vNewVal
	Endfunc
&& ======================================================================== &&
&& Hidden Function InsertData
&& ======================================================================== &&
	Hidden Function InsertData
		If !Used(This.CurName)
			This.CreateCursor()
		Endif
		cQuery  = "INSERT INTO " + This.CurName + " VALUES ("
		nIndex  = 0
		lcComma = Space(1)
		For i = 1 To Alen(This.aValues, 1)
			nIndex = nIndex + 1
			If nIndex > 1
				lcComma = ","
			Endif
			cQuery = cQuery + lcComma + "This.aValues(" + Alltrim(Str(i)) + ")"
		Endfor
		cQuery = cQuery + ")"
		&cQuery
	Endfunc
&& ======================================================================== &&
&& Hidden Function CreateCursor
&& ======================================================================== &&
	Hidden Function CreateCursor
		cQuery  = "CREATE CURSOR " + This.CurName + " ("
		nIndex  = 0
		lcComma = Space(1)
		Select cDataTypes
		Scan
			nIndex = nIndex + 1
			If nIndex > 1
				lcComma = ","
			Endif
			cQuery = cQuery + lcComma + Alltrim(cDataTypes.cProp) + Space(1)
			Do Case
			Case cDataTypes.cType $ "XC"
				lcType = Strtran(cDataTypes.cType, "X", "C")
				cQuery = cQuery + lcType + " (250) NULL"
			Case cDataTypes.cType = "N"
				cQuery = cQuery + cDataTypes.cType + " (18,5) NULL"
			Otherwise
				cQuery = cQuery + cDataTypes.cType
			Endcase
		Endscan
		cQuery = cQuery + ")"
		&cQuery
	Endfunc
&& ======================================================================== &&
&& Function Destroy
&& ======================================================================== &&
	Function Destroy
		Try
			This.sc = .Null.
		Catch
		Endtry
		Try
			This.utils = .Null.
		Catch
		Endtry
		Try
			Clear Class JsonUtils
		Catch
		Endtry
		Try
			Release Procedure JsonUtils
		Catch
		Endtry
	Endfunc
Enddefine
