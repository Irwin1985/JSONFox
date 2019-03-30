*---------------------------------------------------------------------------------------------------------------*
*
* @title:		Librería JsonFOX
* @description:	Librería 100% desarrollada en Visual FoxPro 9.0 para serializar/deserializar objetos JSON y XML.
* 				ideal para el trabajo en capas y comunicación con interfaces desarrolladas en Visual FoxPro 9.0
*				ya que mediante el mecanismo de serialización de XML la hace eficiente para el pase de cursores
*				serializados.
*
*				Para el trabajo en capas y reutilizar esta libreria se recomienda compilar como DLL. Si no lo
*				desea entonces deberá quitar la palabra "OLEPUBLIC" de la linea 1.
*
* @version:		1.2 (beta)
* @author:		Irwin Rodríguez
* @email:		rodriguez.irwin@gmail.com
* @license:		MIT
* @inspired_by:	#VFPJSON JSON library for VFP
*
*---------------------------------------------------------------------------------------------------------------*
DEFINE CLASS jsonfox AS CUSTOM

	HIDDEN cJsonOri
	HIDDEN cJsonStr
	HIDDEN nPos
	HIDDEN nLen
	HIDDEN lValidCall
	HIDDEN lparseXML
	HIDDEN nPosXML
	
	Version			= ""
	LastUpdate		= ""
	Author			= ""
	Email			= ""
	LastErrorText 	= ""
	FLAG = .F.
	
	PROCEDURE INIT
		THIS.nPos 	= 0
		THIS.nLen 	= 0
		THIS.lparseXML 	= .F.
		THIS.nPosXML	= 0
		THIS.lValidCall = .T.
		THIS.Version	= "1.2 (beta)"
		THIS.lValidCall = .T.
		THIS.LastUpdate	= "30/03/19 01:47:31"
		THIS.lValidCall = .T.
		THIS.Author	= "Irwin Rodríguez"
		THIS.lValidCall = .T.
		THIS.Email	= "rodriguez.irwin@gmail.com"
*-- State Flag
		THIS.FLAG 	= CREATEOBJECT("FLAG")
	ENDPROC

*--	decode into an object using a JSON string valid format.	
	FUNCTION decode(tcJsonStr AS MEMO) HELPSTRING "Decodifica una cadena en formato JSON."
		THIS.cJsonStr = tcJsonStr
		RETURN THIS.__decode()
	ENDFUNC

*-- loads a file with a JSON valid format and decodes it into an object.
	FUNCTION loadFile(tcJsonFile AS STRING) HELPSTRING "Decodifica un archivo con formato JSON."
		IF !FILE(tcJsonFile)
			THIS.__setLastErrorText("File not found")
			RETURN NULL
		ELSE &&!FILE(tcJsonFile)
			THIS.cJsonStr = FILETOSTR(tcJsonFile)
		ENDIF &&!FILE(tcJsonFile)
		RETURN THIS.__decode()
	ENDFUNC

*-- Serialize XML from a valid JSON Array.
	FUNCTION ArrayToXML(tStrArray) HELPSTRING "Serializa una cadena en formato JSON a una representación en XML"

		IF EMPTY(tStrArray)
			THIS.__setLastErrorText("invalid JSON format")
			RETURN NULL
		ELSE &&EMPTY(tStrArray)
		ENDIF &&EMPTY(tStrArray)


		IF LEFT(tStrArray,1) == "{" AND RIGHT(tStrArray,1) == "}"
			tStrArray = "??" + tStrArray + "??"
			tStrArray = STREXTRACT(tStrArray, "??{", "}??")
		ELSE &&LEFT(tStrArray,1) == "{" AND RIGHT(tStrArray,1) == "}"
		ENDIF &&LEFT(tStrArray,1) == "{" AND RIGHT(tStrArray,1) == "}"

		THIS.cJsonStr 	= tStrArray
		THIS.lparseXML 	= .T.
		THIS.__parse_value()
		THIS.lparseXML 	= .F.
		THIS.nPosXML	= 0

		cSelect = ""
		cFrom	= ""
		cPiloto = ""
		FOR i=1 TO ALEN(aColumns)
			IF !EMPTY(cSelect)
				cSelect = cSelect + ","
			ELSE &&!EMPTY(cSelect)
			ENDIF &&!EMPTY(cSelect)
			cSelect = cSelect + aColumns[i] + ".valor as " + aColumns[i]
			IF i = 1
				cFrom = cFrom + " (SELECT valor, RECNO() rn FROM " + aColumns[i] + ") " + aColumns[i]
			ELSE &&i = 1
				cFrom = cFrom + " FULL JOIN (SELECT valor, RECNO() rn FROM " + aColumns[i] + ") " + aColumns[i] + " ON " + aColumns[i] + ".rn = " + cPiloto + ".rn"
			ENDIF &&i = 1
			cPiloto = aColumns[i]
		ENDFOR &&i=1 TO ALEN(aColumns)
		lcMacro = "SELECT " + cSelect + " FROM " + cFrom + " INTO CURSOR qResult"
		&lcMacro
		LOCAL lcOut AS STRING
		lcOut = ""
		=CURSORTOXML("qResult","lcOut",1,0,0,"1")
		CLOSE DATABASES ALL
		RELEASE aColumns
		RETURN lcOut
	ENDFUNC

*-- Deserialize a XML format into a JSON string.
	FUNCTION XMLToJson(tcXML AS MEMO) HELPSTRING "Convierte un XML a una representacion JSON"
		IF EMPTY(tcXML)
			THIS.__setLastErrorText("invalid XML format")
			RETURN ""
		ELSE &&EMPTY(tcXML)
		ENDIF &&EMPTY(tcXML)
		LOCAL lcJsonXML AS MEMO, nCount as integer
		lcJsonXML 	= ""
		nCount 		= 0
		=XMLTOCURSOR(tcXML, "qXML")
		SELECT qXML
		SCAN
			nCount = nCount + 1
			IF !EMPTY(lcJsonXML)
				lcJsonXML = lcJsonXML + ","
			ELSE &&!EMPTY(lcJsonXML)
			ENDIF &&!EMPTY(lcJsonXML)

			SCATTER NAME loXML MEMO
			lcJsonXML = lcJsonXML + THIS.encode(loXML)
			SELECT qXML
		ENDSCAN		
		IF nCount > 1
			lcJsonXML = "[" + lcJsonXML + "]"
		ELSE &&nCount > 1
		ENDIF &&nCount > 1
		CLOSE DATABASES ALL
		RETURN lcJsonXML
	ENDFUNC

	*-- Serialize a valid JSON format.
	FUNCTION encode(vNewProp as variant)

		DO CASE
		CASE VARTYPE(vNewProp) == "C"
			vNewProp = ALLT(vNewProp)
			vNewProp = STRTRAN(vNewProp, '\', '\\' )
			vNewProp = STRTRAN(vNewProp, '/', '\/' )
			vNewProp = STRTRAN(vNewProp, CHR(9),  '\t' )
			vNewProp = STRTRAN(vNewProp, CHR(10), '\n' )
			vNewProp = STRTRAN(vNewProp, CHR(13), '\r' )
			vNewProp = STRTRAN(vNewProp, '"', '\"' )
			RETURN '"' + vNewProp + '"'

		CASE VARTYPE(vNewProp) == "N"
			RETURN TRANSFORM(vNewProp)

		CASE VARTYPE(vNewProp) == "L"
			RETURN IIF(vNewProp, "true", "false")

		CASE VARTYPE(vNewProp) == "X"
			RETURN "null"

		CASE VARTYPE(vNewProp) == "D"
			RETURN '"' + DTOC(vNewProp) + '"'

		CASE VARTYPE(vNewProp) == "O"
			RETURN "{" + EXECSCRIPT(THIS.load_script(), vNewProp, THIS.load_script()) + "}"
		OTHERWISE
		ENDCASE
	ENDFUNC

	FUNCTION load_script
		TEXT TO lcLoad NOSHOW TEXTMERGE PRETEXT 7
			LPARAMETERS toObj, tcExecScript

			LOCAL vNewVal
			vNewVal = toObj

			LOCAL cProp, cJsonValue, cReturn, aProp[1]
			=AMEMBERS(aProp,vNewVal)
			cReturn = ""
			FOR EACH cProp IN aProp
				IF TYPE("ALEN(vNewVal." + cProp + ")") == "N"
* es un arreglo, recorrerlo usando los [ ] y macro
					LOCAL i,nTotElem
					cJsonValue 	= ''
					nTotElem 	= EVAL('ALen(vNewVal.'+cProp+')')
					FOR i=1 TO nTotElem
						lcMacro = 'cJsonValue = cJsonValue + "," + encode(vNewVal.' + cProp + '[i], tcExecScript)'
						&lcMacro
					NEXT
					cJsonValue = "[" + SUBSTR(cJsonValue,2) + "]"
				ELSE &&TYPE("ALEN(vNewVal." + cProp + ")") == TYPE_NUMERIC
* es otro tipo de dato normal C, N, L
					cJsonValue = encode(EVALUATE("vNewVal." + cProp), tcExecScript)
				ENDIF &&TYPE("ALEN(vNewVal." + cProp + ")") == TYPE_NUMERIC
				IF UPPER(cProp) <> "ARRAY"
					IF LEFT(cProp,1) == '_'
						cProp = SUBSTR(cProp,2)
					ELSE &&LEFT(cProp,1) == '_'
					ENDIF &&LEFT(cProp,1) == '_'
					cReturn = cReturn + ',' + '"' + LOWER(cProp) + '":' + cJsonValue
				ELSE &&UPPER(cProp) <> "ARRAY"
					cReturn = cReturn + ',' + cJsonValue
				ENDIF &&UPPER(cProp) <> "ARRAY"
			NEXT &&EACH cProp IN aProp
			lcRet = SUBSTR(cReturn,2)
			RETURN lcRet

			*-- Internal usage only.
			FUNCTION encode
				LPARAMETERS vNewVal, tcExecScript

				LOCAL cTipo
		* Cuando se manda una arreglo,
				IF TYPE('ALen(vNewVal)') == "N"
					cTipo = "A"
				ELSE &&TYPE('ALen(vNewVal)') == "N"
					cTipo = VARTYPE(vNewVal)
				ENDIF &&TYPE('ALen(vNewVal)') == "N"

				DO CASE
				CASE cTipo == "D"
					RETURN '"' + DTOS(vNewVal) + '"'

				CASE cTipo == "N"
					RETURN TRANSFORM(vNewVal)

				CASE cTipo == "L"
					RETURN IIF(vNewVal, "true", "false")

				CASE cTipo == "X"
					RETURN "null"

				CASE cTipo == "C"
					vNewVal = ALLT(vNewVal)
					vNewVal = STRTRAN(vNewVal, '\', '\\' )
					vNewVal = STRTRAN(vNewVal, '/', '\/' )
					vNewVal = STRTRAN(vNewVal, CHR(9),  '\t' )
					vNewVal = STRTRAN(vNewVal, CHR(10), '\n' )
					vNewVal = STRTRAN(vNewVal, CHR(13), '\r' )
					vNewVal = STRTRAN(vNewVal, '"', '\"' )
					RETURN '"' + vNewVal + '"'

				CASE cTipo == "A"
					LOCAL valor, cReturn
					cReturn = ''
					FOR EACH valor IN vNewVal
						cReturn = cReturn + ',' +  THIS.encode( valor )
					NEXT &&EACH valor IN vNewVal
					RETURN  "[" + SUBSTR(cReturn,2) + "]"

				CASE cTipo == "O"
					lcRet = EXECSCRIPT(tcExecScript, vNewVal, tcExecScript)
					IF LEFT(lcRet,1) <> "["
						lcRet = "{" + lcRet + "}"
					ELSE &&LEFT(lcRet,1) <> "["
					ENDIF &&LEFT(lcRet,1) <> "["
					RETURN lcRet
				OTHERWISE
				ENDCASE
			ENDFUNC
		ENDTEXT
		RETURN lcLoad
	ENDFUNC

	HIDDEN FUNCTION __decode
*-- Guardamos la cadena original
		THIS.cJsonOri = THIS.cJsonStr
		THIS.__cleanJsonString()

		THIS.nPos = 1
		THIS.nLen = LEN(THIS.cJsonOri)

		IF THIS.__validate_json_format()
*-- El primer caracter siempre es un objeto.
			RETURN THIS.__parse_object()
		ELSE &&THIS.__validate_json_format()
			THIS.__setLastErrorText("invalid JSON format")
			RETURN NULL
		ENDIF &&THIS.__validate_json_format()
	ENDFUNC

	HIDDEN FUNCTION __parse_object
		LOCAL oCurObj AS OBJECT, lcPropName AS STRING, lcType AS STRING, vNewVal AS VARIANT
		oCurObj = CREATEOBJECT("__custom_object")
		THIS.__eat_json(2)
		DO WHILE .T.
			lcPropName = THIS.__parse_string()
			IF EMPTY(lcPropName)
				RETURN NULL
			ELSE &&EMPTY(lcPropName)
			ENDIF &&EMPTY(lcPropName)
			IF THIS.__get_Token() <> ':'
				THIS.__setLastErrorText("Expected ':' - Got undefined")
				RETURN NULL
			ELSE &&THIS.__get_Token() <> ':'
			ENDIF &&THIS.__get_Token() <> ':'
			THIS.__eat_json(2)
			lcType  = ''
			vNewVal = THIS.__parse_value(@lcType)
			IF TYPE("vNewVal") == "C" AND EMPTY(vNewVal)
				THIS.__setLastErrorText("Expecting 'STRING', 'NUMBER', 'NULL', 'TRUE', 'FALSE', '{', '[', Got undefined")
				RETURN NULL
			ELSE &&TYPE("vNewVal") == "C" AND EMPTY(vNewVal)
			ENDIF &&TYPE("vNewVal") == "C" AND EMPTY(vNewVal)
			THIS.FLAG.ACTIVE = .T. && enable flag before assign.
			oCurObj.setProperty(lcPropName, vNewVal, lcType, THIS.FLAG)
			THIS.__parse_XML(lcPropName, vNewVal)
			cToken = THIS.__get_Token()
			DO CASE
			CASE cToken == ','
				THIS.__eat_json(2)
				LOOP
			CASE cToken == '}'
				THIS.__eat_json(2)
				EXIT
			OTHERWISE
			ENDCASE
		ENDDO
		RETURN oCurObj
	ENDFUNC

	HIDDEN FUNCTION __parse_value
		LPARAMETERS tcType AS STRING
		LOCAL cToken AS STRING
		cToken = THIS.__get_Token()
		IF !INLIST(cToken, '{', '[', '"', 't', 'f', '-', 'n') AND !ISDIGIT(cToken)
			THIS.__setLastErrorText("Expecting 'STRING', 'NUMBER', 'NULL', 'TRUE', 'FALSE', '{', '[', Got undefined")
			RETURN NULL
		ELSE &&!INLIST(cToken, '{', '[', '"', 't', 'f', '-', 'n') AND !ISDIGIT(cToken)
		ENDIF &&!INLIST(cToken, '{', '[', '"', 't', 'f', '-', 'n') AND !ISDIGIT(cToken)

		DO CASE
		CASE cToken == '{'
			tcType = "O"
			RETURN THIS.__parse_object()

		CASE cToken == '['
			tcType = "A"
			RETURN THIS.__parse_array()

		CASE cToken == '"'
			tcType = "S"
			RETURN THIS.__parse_string()

		CASE cToken == 't'
			tcType = "B"
			RETURN THIS.__parse_expr("true")

		CASE cToken == 'f'
			tcType = "B"
			RETURN THIS.__parse_expr("false")

		CASE cToken == 'n'
			tcType = "N"
			RETURN THIS.__parse_expr("null")

		CASE ISDIGIT(cToken) OR cToken == '-'
			tcType = "I"
			RETURN THIS.__parse_number()

		OTHERWISE
		ENDCASE
	ENDFUNC

	HIDDEN FUNCTION __parse_array
		LOCAL aCustomArr AS OBJECT
		THIS.__eat_json(2)
		aCustomArr = CREATEOBJECT("__custom_array")
		DO WHILE .T.
			lcType  = ''
			vNewVal = THIS.__parse_value(@lcType)
			IF TYPE("vNewVal") == "C" AND EMPTY(vNewVal)
				THIS.__setLastErrorText("Expecting 'STRING', 'NUMBER', 'NULL', 'TRUE', 'FALSE', '{', '[', Got undefined")
				RETURN NULL
			ELSE &&TYPE("vNewVal") == "C" AND EMPTY(vNewVal)
			ENDIF &&TYPE("vNewVal") == "C" AND EMPTY(vNewVal)
			aCustomArr.array_push(vNewVal)
			cToken = THIS.__get_Token()
			DO CASE
			CASE cToken == ',' && Nos comemos el Token e Iteramos el siguiente valor.
				THIS.__eat_json(2)
				LOOP
			CASE cToken == ']' && Nos comemos el Token y retornamos el flujo.
				THIS.__eat_json(2)
				EXIT
			OTHERWISE
			ENDCASE
		ENDDO
		RETURN aCustomArr
	ENDFUNC

	HIDDEN FUNCTION __parse_number
		LOCAL cNumber AS STRING, bIsNegative AS boolean
		bIsNegative = .F.

		IF THIS.__get_Token() == '-'
			bIsNegative = .T.
		ELSE &&THIS.__get_token() == '-'
		ENDIF &&THIS.__get_token() == '-'
		cNumber = ""
		DO WHILE .T.
			cValue 	= THIS.__get_Token()
			IF INLIST(cValue, ',', '}', ']')
				EXIT
			ELSE &&INLIST(cValue, ',', '}', ']')
			ENDIF &&INLIST(cValue, ',', '}', ']')

			cNumber = cNumber + cValue
			THIS.__eat_json(2)
		ENDDO
		SET DECIMALS TO 10
		nValNumber = VAL(cNumber)
		IF bIsNegative
			RETURN nValNumber * -1
		ELSE &&bIsNegative
			RETURN nValNumber
		ENDIF &&bIsNegative
	ENDFUNC
	HIDDEN FUNCTION __parse_expr
		LPARAMETERS tcStr AS STRING
		vNewVal 	= ""
		lnLenExp 	= 0
		DO CASE
		CASE tcStr == 'true'
			lnLenExp = 4
			IF LEFT(THIS.cJsonStr, lnLenExp) == 'true'
				vNewVal = .T.
			ELSE &&LEFT(THIS.cJsonStr, lnLenExp) == 'true'
				vNewVal = ''
			ENDIF &&LEFT(THIS.cJsonStr, lnLenExp) == 'true'

		CASE tcStr == 'false'
			lnLenExp = 5
			IF LEFT(THIS.cJsonStr, lnLenExp) == 'false'
				vNewVal = .F.
			ELSE &&LEFT(THIS.cJsonStr, lnLenExp) == 'false'
				vNewVal = ''
			ENDIF &&LEFT(THIS.cJsonStr, lnLenExp) == 'false'

		CASE tcStr == 'null'
			lnLenExp = 4
			IF LEFT(THIS.cJsonStr, lnLenExp) == 'null'
				vNewVal = NULL
			ELSE &&LEFT(THIS.cJsonStr, lnLenExp) == 'null'
				vNewVal = ''
			ENDIF &&LEFT(THIS.cJsonStr, lnLenExp) == 'null'
		OTHERWISE
		ENDCASE

		IF TYPE("vNewVal") == "C" AND EMPTY(vNewVal)
			IF INLIST(tcStr, 'true', 'false')
				cMsg = "Expecting 'TRUE', 'FALSE', Got undefined"
			ELSE &&INLIST(tcStr, 'true', 'false')
				cMsg = "Expecting 'NULL', Got undefined"
			ENDIF &&INLIST(tcStr, 'true', 'false')
			THIS.__setLastErrorText(cMsg)
			RETURN ''
		ELSE &&TYPE("vNewVal") == "C" AND EMPTY(vNewVal)
		ENDIF &&TYPE("vNewVal") == "C" AND EMPTY(vNewVal)
		lnLenExp = lnLenExp + 1 && El valor más el salto.
		THIS.__eat_json(lnLenExp)
		RETURN vNewVal
	ENDFUNC

	HIDDEN FUNCTION __parse_string
		LOCAL lcValue AS STRING
		lcValue = ""
		IF THIS.__get_Token() <> '"'
			THIS.__setLastErrorText('Expected " - Got undefined')
			RETURN ''
		ELSE &&THIS.__get_Token() <> '"'
		ENDIF &&THIS.__get_Token() <> '"'
		lcValue = STREXTRACT(THIS.cJsonStr, '"', '"', 1)
		IF EMPTY(lcValue)
			THIS.__setLastErrorText('Invalid string value')
			RETURN ''
		ELSE &&EMPTY(lcValue)
		ENDIF &&EMPTY(lcValue)
		THIS.__eat_json(LEN(lcValue) + 3) && El nombre más los delimitadores '"'/'"' y una posicion más para saltarse el último ".
		RETURN lcValue
	ENDFUNC

	HIDDEN PROCEDURE __parse_XML
		LPARAMETERS tcColumn, tvNewVal
		IF THIS.lparseXML
			lcType = VARTYPE(tvNewVal)
			IF !USED(ALLTRIM(tcColumn))
				lcAlter = "L" && Logical by Default
				lDate 	= NULL
				DO CASE
				CASE lcType = "C" AND OCCURS("-",tvNewVal) = 2
					lDate 	= THIS.__checkDate(tvNewVal)
					IF !ISNULL(lDate)
						lcType 	 = "D"
						lcAlter  = "D NULL"
						tvNewVal = lDate
					ELSE &&!ISNULL(lDate)
					ENDIF &&!ISNULL(lDate)
				CASE lcType = "C"
					lcAlter = "C(100) NULL"
				CASE lcType = "N"
					lcAlter = "N(20,10) NULL"
				CASE lcType = "L"
					lcAlter = "L NULL"
				CASE lcType = "D"
					lcAlter = "D NULL"
				OTHERWISE
				ENDCASE
				THIS.nPosXML = THIS.nPosXML + 1
				IF TYPE("aColumns") = "U"
					PUBLIC aColumns
				ELSE &&TYPE("aColumns") = "U"
				ENDIF &&TYPE("aColumns") = "U"
				DIMENSION aColumns[THIS.nPosXML]
				aColumns[THIS.nPosXML] = tcColumn
				lcMacro = "CREATE CURSOR " + ALLTRIM(tcColumn) + " (valor " + lcAlter + ")"
				&lcMacro
			ELSE &&!USED(ALLTRIM(tcColumn))
			ENDIF &&!USED(ALLTRIM(tcColumn))
			IF lcType == "C" AND (OCCURS("-",tvNewVal) == 2)
				lDate 	= THIS.__checkDate(tvNewVal)
				IF !ISNULL(lDate)
					tvNewVal = lDate
				ELSE &&!ISNULL(lDate)
				ENDIF &&!ISNULL(lDate)
			ELSE &&lcType = "C" AND OCCURS("-",tvNewVal) = 2
			ENDIF &&lcType = "C" AND OCCURS("-",tvNewVal) = 2
			TRY
				INSERT INTO &tcColumn (valor) VALUES(tvNewVal)
			CATCH
				INSERT INTO &tcColumn (valor) VALUES(NULL)
			ENDTRY
		ELSE &&THIS.lparseXML
		ENDIF &&THIS.lparseXML
	ENDFUNC
	HIDDEN FUNCTION __checkDate
		LPARAMETERS tsDate AS STRING
		cStr = STRTRAN(tsDate, "-")
		FOR i=1 TO LEN(cStr) STEP 1
			IF ISDIGIT(SUBSTR(cStr, i, 1))
				LOOP
			ELSE &&ISDIGIT(SUBSTR(cStr, i, 1))
				RETURN NULL
			ENDIF &&ISDIGIT(SUBSTR(cStr, i, 1))
		ENDFOR &&i=1 TO LEN(cStr) STEP 1
		IF VAL(LEFT(tsDate,4)) > 0 AND VAL(STREXTRACT(tsDate, "-", "-",1)) > 0 AND VAL(RIGHT(tsDate,2)) > 0
			RETURN DATE(VAL(LEFT(tsDate,4)), VAL(STREXTRACT(tsDate, "-", "-",1)), VAL(RIGHT(tsDate,2)))
		ELSE &&VAL(LEFT(tsDate,4)) > 0 AND VAL(STREXTRACT(tsDate, "-", "-",1)) > 0 AND VAL(RIGHT(tsDate,2)) > 0
			RETURN CTOD('{}')
		ENDIF &&VAL(LEFT(tsDate,4)) > 0 AND VAL(STREXTRACT(tsDate, "-", "-",1)) > 0 AND VAL(RIGHT(tsDate,2)) > 0
	ENDFUNC
	HIDDEN PROCEDURE __eat_json(tnPosition AS INTEGER)
		THIS.cJsonStr = ALLTRIM(SUBSTR(THIS.cJsonStr, tnPosition, LEN(THIS.cJsonStr)))
	ENDPROC
	HIDDEN FUNCTION __get_Token
		LOCAL cToken AS CHARACTER
		cToken = ""
		DO WHILE .T.
			IF THIS.nPos > THIS.nLen
				RETURN NULL
			ELSE &&THIS.nPos > THIS.nLen
			ENDIF &&THIS.nPos > THIS.nLen
			cToken = LEFT(THIS.cJsonStr, 1)
			IF EMPTY(cToken)
				THIS.nPos = THIS.nPos + 1
				LOOP
			ELSE &&EMPTY(cToken)
			ENDIF &&EMPTY(cToken)
			RETURN cToken
		ENDDO
	ENDFUNC

	HIDDEN FUNCTION __validate_json_format
		IF LEFT(THIS.cJsonStr,1) == "{" AND RIGHT(THIS.cJsonStr, 1) == "}"
			RETURN .T.
		ELSE &&LEFT(THIS.cJsonStr,1) == "{" AND RIGHT(THIS.cJsonStr, 1) == "}"
			RETURN .F.
		ENDIF &&LEFT(THIS.cJsonStr,1) == "{" AND RIGHT(THIS.cJsonStr, 1) == "}"
	ENDFUNC
	
	HIDDEN FUNCTION __cleanJsonString
		THIS.cJsonStr = STRTRAN(THIS.cJsonStr, CHR(9))
		THIS.cJsonStr = STRTRAN(THIS.cJsonStr, CHR(10))
		THIS.cJsonStr = STRTRAN(THIS.cJsonStr, CHR(13))
		THIS.cJsonStr = ALLTRIM(THIS.__html_entity_decode(THIS.cJsonStr))
	ENDFUNC

	HIDDEN FUNCTION __html_entity_decode
		LPARAMETERS cText
		cText = STRTRAN(cText, "\u00e1", "á")
		cText = STRTRAN(cText, "\u00e9", "é")
		cText = STRTRAN(cText, "\u00ed", "í")
		cText = STRTRAN(cText, "\u00f3", "ó")
		cText = STRTRAN(cText, "\u00fa", "ú")
		cText = STRTRAN(cText, "\u00c1", "Á")
		cText = STRTRAN(cText, "\u00c9", "É")
		cText = STRTRAN(cText, "\u00cd", "Í")
		cText = STRTRAN(cText, "\u00d3", "Ó")
		cText = STRTRAN(cText, "\u00da", "Ú")
		cText = STRTRAN(cText, "\u00f1", "ñ")
		cText = STRTRAN(cText, "\u00d1", "Ñ")
		cText = STRTRAN(cText, "\u0026", "&")
		cText = STRTRAN(cText, "\u0022", '"')
		cText = STRTRAN(cText, "\u2019", "'")
		cText = STRTRAN(cText, "\u003A", ":")
		cText = STRTRAN(cText, "\u002B", "+")
		cText = STRTRAN(cText, "\u002D", "-")
		cText = STRTRAN(cText, "\u0023", "#")
		cText = STRTRAN(cText, "\u0025", "%")
		cText = STRTRAN(cText, "\u00b2", "²")
		RETURN cText
	ENDFUNC

	HIDDEN PROCEDURE __setLastErrorText
		LPARAMETERS tcErrorText
		THIS.lValidCall = .T.
		IF !EMPTY(tcErrorText)
			THIS.LastErrorText = "Error: parse error on line " + ALLTRIM(STR(THIS.nPos,6,0)) + ": " + tcErrorText
		ELSE &&!EMPTY(tcErrorText)
			THIS.LastErrorText = ""
		ENDIF &&!EMPTY(tcErrorText)
	ENDPROC

	HIDDEN PROCEDURE LastErrorText_Assign
		LPARAMETERS vNewVal
		IF THIS.lValidCall
			THIS.lValidCall = .F.
			THIS.LastErrorText = m.vNewVal
		ELSE &&THIS.lValidCall
		ENDIF &&THIS.lValidCall
	ENDPROC
	
	HIDDEN PROCEDURE Version_Assign
		LPARAMETERS vNewVal
		IF THIS.lValidCall
			THIS.lValidCall = .F.
			THIS.Version = m.vNewVal
		ELSE &&THIS.lValidCall
		ENDIF &&THIS.lValidCall
	ENDPROC
	
	HIDDEN FUNCTION Version_Access
		RETURN THIS.Version
	ENDFUNC

	HIDDEN PROCEDURE LastUpdate_Assign
		LPARAMETERS vNewVal
		IF THIS.lValidCall
			THIS.lValidCall = .F.
			THIS.LastUpdate = m.vNewVal
		ELSE &&THIS.lValidCall
		ENDIF &&THIS.lValidCall
	ENDPROC
	
	HIDDEN FUNCTION LastUpdate_Access
		RETURN THIS.LastUpdate
	ENDFUNC

	HIDDEN PROCEDURE Author_Assign
		LPARAMETERS vNewVal
		IF THIS.lValidCall
			THIS.lValidCall = .F.
			THIS.Author = m.vNewVal
		ELSE &&THIS.lValidCall
		ENDIF &&THIS.lValidCall
	ENDPROC
	
	HIDDEN FUNCTION Author_Access
		RETURN THIS.Author
	ENDFUNC

	HIDDEN PROCEDURE Email_Assign
		LPARAMETERS vNewVal
		IF THIS.lValidCall
			THIS.lValidCall = .F.
			THIS.Email = m.vNewVal
		ELSE &&THIS.lValidCall
		ENDIF &&THIS.lValidCall
	ENDPROC
	
	HIDDEN FUNCTION Email_Access
		RETURN THIS.Email
	ENDFUNC

ENDDEFINE

DEFINE CLASS __custom_array AS CUSTOM
	HIDDEN 					;
		CLASSLIBRARY, 		;
		COMMENT, 			;
		BASECLASS, 			;
		CONTROLCOUNT, 		;
		CONTROLS, 			;
		OBJECT, 			;
		OBJECTS,			;
		HEIGHT, 			;
		HELPCONTEXTID, 		;
		LEFT, 				;
		NAME, 				;
		PARENT, 			;
		PARENTCLASS, 		;
		PICTURE, 			;
		TAG, 				;
		TOP, 				;
		WHATSTHISHELPID, 	;
		WIDTH,				;
		CLASS

	HIDDEN nArrLen

	DIMENSION ARRAY[1]

	PROCEDURE INIT
		THIS.nArrLen = 0
	ENDPROC

	FUNCTION array_push(vNewVal AS VARIANT)
		THIS.nArrLen = THIS.nArrLen + 1
		DIMENSION THIS.ARRAY[THIS.nArrLen]
		THIS.ARRAY[this.nArrLen] = vNewVal

	ENDFUNC

	FUNCTION getvalue(tnIndex AS INTEGER) HELPSTRING "Obtiene el contenido del array dado su índice."
		TRY
			nLen = THIS.ARRAY[tnIndex]
		CATCH
			nLen = NULL
		ENDTRY
		RETURN nLen
	ENDFUNC

	FUNCTION LEN
		RETURN THIS.nArrLen
	ENDFUNC
ENDDEFINE

DEFINE CLASS __custom_object AS CUSTOM
	HIDDEN 					;
		CLASSLIBRARY, 		;
		COMMENT, 			;
		BASECLASS, 			;
		CONTROLCOUNT, 		;
		CONTROLS, 			;
		OBJECTS, 			;
		OBJECT, 			;
		HEIGHT, 			;
		HELPCONTEXTID, 		;
		LEFT, 				;
		NAME, 				;
		PARENT, 			;
		PARENTCLASS, 		;
		PICTURE, 			;
		TAG, 				;
		TOP, 				;
		WHATSTHISHELPID, 	;
		WIDTH,				;
		CLASS

	PROCEDURE setProperty(tcName AS STRING, tvNewVal AS VARIANT, tcType AS STRING, vFlag AS OBJECT)
		IF vFlag.ACTIVE
			vFlag.ACTIVE 	= .F.
			tcName 			= "_" + tcName
			IF VARTYPE(THIS. tcName) = "U"
				THIS.ADDPROPERTY(tcName, tvNewVal)
			ELSE &&VARTYPE(THIS. tcName) = "U"
				THIS. tcName = tvNewVal
			ENDIF &&VARTYPE(THIS. tcName) = "U"
		ELSE &&vFlag.ACTIVE
		ENDIF &&vFlag.ACTIVE
	ENDPROC

	FUNCTION valueOf(tcName AS STRING) HELPSTRING "Obtiene el valor de una propiedad"
		tcName = "_" + tcName
		IF VARTYPE(THIS. &tcName) == "U"
			RETURN ""
		ELSE &&VARTYPE(THIS. &tcName) == "U"
			lcMacro = "RETURN THIS." + tcName
			&lcMacro
		ENDIF &&VARTYPE(THIS. &tcName) == "U"
		RETURN ""
	ENDFUNC
ENDDEFINE

DEFINE CLASS FLAG AS CUSTOM
	ACTIVE = .F.
ENDDEFINE
