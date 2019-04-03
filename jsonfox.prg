*---------------------------------------------------------------------------------------------------------------*
*
* @title:		Librería JsonFOX
* @description:	Librería 100% desarrollada en Visual FoxPro 9.0 para serializar/deserializar objetos JSON y XML.
* 				ideal para el trabajo en capas y comunicación con interfaces desarrolladas en Visual FoxPro 9.0
*				ya que mediante el mecanismo de serialización de XML la hace eficiente para el pase de cursores
*				serializados.
*
* @version:		1.5 (beta)
* @author:		Irwin Rodríguez
* @email:		rodriguez.irwin@gmail.com
* @license:		MIT
* @inspired_by:	#VFPJSON JSON library for VFP
*
*
* -------------------------------------------------------------------------
* Version Log:
*
* Release 2019-04-02	v.1.5		- Fix en método ArrayToXML al pasar Array de objetos JSON.
*
* Release 2019-04-01	v.1.4		- El método ArrayToXML recibe String y Array de objetos JSON como parametros.
*
* Release 2019-03-31	v.1.3		- Analizador inteligente para tipos de datos DATE y DATETIME
*
* Release 2019-03-30	v.1.2		- Liberación formal en https://github.com/Irwin1985/JSONFox
*---------------------------------------------------------------------------------------------------------------*
DEFINE CLASS jsonfox AS CUSTOM OLEPUBLIC

	HIDDEN cJsonOri
	HIDDEN cJsonStr
	HIDDEN nPos
	HIDDEN nLen
	HIDDEN lValidCall
	HIDDEN lparseXML
	HIDDEN nPosXML

	VERSION			= ""
	LastUpdate		= ""
	Author			= ""
	Email			= ""
	LastErrorText 	= ""
	FLAG = .F.

	PROCEDURE INIT
		THIS.nPos 		= 0
		THIS.nLen 		= 0
		THIS.lparseXML 	= .F.
		THIS.nPosXML	= 0
		THIS.lValidCall = .T.
		THIS.VERSION	= "1.5 (beta)"
		THIS.lValidCall = .T.
		THIS.LastUpdate	= "2019-04-02 06:22:45 PM"
		THIS.lValidCall = .T.
		THIS.Author		= "Irwin Rodríguez"
		THIS.lValidCall = .T.
		THIS.Email		= "rodriguez.irwin@gmail.com"
*-- State Flag
		THIS.FLAG 		= CREATEOBJECT("FLAG")
	ENDPROC

*--	decode into an object using a JSON string valid format.
	FUNCTION decode(tcJsonStr AS MEMO) AS OBJECT HELPSTRING "Decodifica una cadena en formato JSON."
		THIS.cJsonStr = tcJsonStr
		RETURN THIS.__decode()
	ENDFUNC

*-- loads a file with a JSON valid format and decodes it into an object.
	FUNCTION loadFile(tcJsonFile AS STRING) AS OBJECT HELPSTRING "Decodifica un archivo con formato JSON."
		IF !FILE(tcJsonFile)
			THIS.__setLastErrorText("File not found")
			RETURN NULL
		ELSE &&!FILE(tcJsonFile)
			THIS.cJsonStr = FILETOSTR(tcJsonFile)
		ENDIF &&!FILE(tcJsonFile)
		RETURN THIS.__decode()
	ENDFUNC

*-- Serialize XML from a valid JSON Array.
	FUNCTION ArrayToXML(tvArray AS Variant) AS STRING HELPSTRING "Serializa una cadena u objeto JSON a una representación en XML"
		cType = VARTYPE(tvArray)
		IF NOT INLIST(cType, "O", "C")
			THIS.__setLastErrorText("invalid param")
			RETURN ''
		ELSE && NOT INLIST(cType, "O", "C")
		ENDIF && NOT INLIST(cType, "O", "C")

		IF cType == "O"
			tvArray = THIS.encode(tvArray)
			IF LEFT(tvArray,1) = "{" .AND. SUBSTR(tvArray,2,1) <> "["
				tvArray = "[" + tvArray + "]"
			ELSE &&LEFT(tvArray,1) = "{" .AND. SUBSTR(tvArray,2,1) <> "["
			ENDIF &&LEFT(tvArray,1) = "{" .AND. SUBSTR(tvArray,2,1) <> "["
		ELSE &&cType == "O"
		ENDIF &&cType == "O"

		IF LEFT(tvArray,1) == "{" AND RIGHT(tvArray,1) == "}"
			tvArray = "??" + tvArray + "??"
			tvArray = STREXTRACT(tvArray, "??{", "}??")
		ELSE &&LEFT(tvArray,1) == "{" AND RIGHT(tvArray,1) == "}"
		ENDIF &&LEFT(tvArray,1) == "{" AND RIGHT(tvArray,1) == "}"

		THIS.cJsonStr 	= tvArray
		THIS.lparseXML 	= .T.
		THIS.__parse_value()
		THIS.lparseXML 	= .F.
		THIS.nPosXML	= 0

		IF TYPE("aColumns") = "U"
			THIS.__setLastErrorText("could not parse XML. Aux var was not created")
			RETURN ''
		ELSE &&TYPE("aColumns") = "U"
		ENDIF &&TYPE("aColumns") = "U"

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
	FUNCTION XMLToJson(tcXML AS MEMO) AS MEMO HELPSTRING "Convierte un XML a una representacion JSON"
		IF EMPTY(tcXML)
			THIS.__setLastErrorText("invalid XML format")
			RETURN ""
		ELSE &&EMPTY(tcXML)
		ENDIF &&EMPTY(tcXML)
		LOCAL lcJsonXML AS MEMO, nCount AS INTEGER
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

*-- deserialize a JSON object.
	FUNCTION encode(vNewProp AS Variant) AS MEMO
		LOCAL lcVarType AS CHARACTER
		lcVarType = VARTYPE(vNewProp)
		DO CASE
		CASE lcVarType == "C"
			vNewProp = ALLTRIM(vNewProp)
			vNewProp = STRTRAN(vNewProp, '\', '\\' )
			vNewProp = STRTRAN(vNewProp, '/', '\/' )
			vNewProp = STRTRAN(vNewProp, CHR(9),  '\t' )
			vNewProp = STRTRAN(vNewProp, CHR(10), '\n' )
			vNewProp = STRTRAN(vNewProp, CHR(13), '\r' )
			vNewProp = STRTRAN(vNewProp, '"', '\"' )
			RETURN '"' + vNewProp + '"'

		CASE lcVarType == "N"
			RETURN TRANSFORM(vNewProp)

		CASE lcVarType == "L"
			RETURN IIF(vNewProp, "true", "false")

		CASE lcVarType == "X"
			RETURN "null"

		CASE lcVarType == "D"
			cCenturyAct = SET("Century")
			SET CENTURY ON
			lcDate = '"' + ALLTRIM(STR(YEAR(vNewProp))) + '-' + PADL(ALLTRIM(STR(MONTH(vNewProp))),2,'0') + '-' + PADL(ALLTRIM(STR(DAY(vNewProp))),2,'0') + '"'
			SET CENTURY &cCenturyAct
			RETURN lcDate

		CASE lcVarType == "T"
			cCenturyAct = SET("Century")
			cHourAct 	= SET("Hours")
			SET CENTURY ON
			SET HOURS TO 24
			lcDate = '"' + ALLTRIM(STR(YEAR(vNewVal))) + '-' + PADL(ALLTRIM(STR(MONTH(vNewVal))),2,'0') + '-' + PADL(ALLTRIM(STR(DAY(vNewVal))),2,'0') + SPACE(1) + PADL(ALLTRIM(STR(HOUR(vNewVal))),2,'0') + ':' + PADL(ALLTRIM(STR(MINUTE(vNewVal))),2,'0') + ':' + PADL(ALLTRIM(STR(SEC(vNewVal))),2,'0') + '"'
			SET CENTURY  &cCenturyAct
			SET HOURS TO &cHourAct
			RETURN lcDate

		CASE lcVarType == "O"
			RETURN "{" + EXECSCRIPT(THIS.load_script(), vNewProp, THIS.load_script()) + "}"
		OTHERWISE
		ENDCASE
	ENDFUNC

*-- WARNING: Internal usage only.
	HIDDEN FUNCTION load_script AS MEMO
		TEXT TO lcLoad NOSHOW TEXTMERGE PRETEXT 7
			LPARAMETERS toObj, tcExecScript
			LOCAL vNewVal
			vNewVal = toObj
			LOCAL lcPtyName, lcJsonStr, cReturn, arrPty[1]
			=AMEMBERS(arrPty,vNewVal)
			cReturn = ""
			FOR EACH lcPtyName IN arrPty
				IF TYPE("ALEN(vNewVal." + lcPtyName + ")") == "N"
					LOCAL i,lnSize
					lcJsonStr 	= ''
					lnSize 	= EVAL('ALen(vNewVal.'+lcPtyName+')')
					FOR i=1 TO lnSize
						lcMacro = 'lcJsonStr = lcJsonStr + "," + ENCODE(vNewVal.' + lcPtyName + '[i], tcExecScript)'
						&lcMacro
					NEXT &&i=1 TO lnSize
					lcJsonStr = "[" + SUBSTR(lcJsonStr,2) + "]"
				ELSE &&TYPE("ALEN(vNewVal." + lcPtyName + ")") == "N"
					lcJsonStr = ENCODE(EVALUATE("vNewVal." + lcPtyName), tcExecScript)
				ENDIF &&TYPE("ALEN(vNewVal." + lcPtyName + ")") == "N"
				IF UPPER(lcPtyName) <> "ARRAY"
					IF LEFT(lcPtyName,1) == "_"
						lcPtyName = SUBSTR(lcPtyName,2)
					ELSE &&LEFT(lcPtyName,1) == "_"
					ENDIF &&LEFT(lcPtyName,1) == "_"
					cReturn = cReturn + ',' + '"' + LOWER(lcPtyName) + '":' + lcJsonStr
				ELSE &&UPPER(lcPtyName) <> "ARRAY"
					cReturn = cReturn + ',' + lcJsonStr
				ENDIF &&UPPER(lcPtyName) <> "ARRAY"
			NEXT &&EACH lcPtyName IN arrPty
			lcRet = SUBSTR(cReturn,2)
			RETURN lcRet

			*-- WARNING: Internal usage only.
			FUNCTION encode AS MEMO
				LPARAMETERS vNewVal, tcExecScript
				LOCAL cTipo AS CHARACTER
				IF TYPE('ALen(vNewVal)') == "N"
					cTipo = "A"
				ELSE &&TYPE('ALen(vNewVal)') == "N"
					cTipo = VARTYPE(vNewVal)
				ENDIF &&TYPE('ALen(vNewVal)') == "N"
				DO CASE
				CASE cTipo == "D"
					cCenturyAct = SET("Century")
					SET CENTURY ON
					lcDate = '"' + ALLTRIM(STR(YEAR(vNewVal))) + '-' + PADL(ALLTRIM(STR(MONTH(vNewVal))),2,'0') + '-' + PADL(ALLTRIM(STR(DAY(vNewVal))),2,'0') + '"'
					SET CENTURY &cCenturyAct
					RETURN lcDate
				CASE cTipo == "T"
					cCenturyAct = SET("Century")
					cHourAct 	= SET("Hours")
					SET CENTURY ON
					SET HOURS TO 24
					lcDate = '"' + ALLTRIM(STR(YEAR(vNewVal))) + '-' + PADL(ALLTRIM(STR(MONTH(vNewVal))),2,'0') + '-' + PADL(ALLTRIM(STR(DAY(vNewVal))),2,'0') + SPACE(1) + PADL(ALLTRIM(STR(HOUR(vNewVal))),2,'0') + ':' + PADL(ALLTRIM(STR(MINUTE(vNewVal))),2,'0') + ':' + PADL(ALLTRIM(STR(SEC(vNewVal))),2,'0') + '"'
					SET CENTURY  &cCenturyAct
					SET HOURS TO &cHourAct
					RETURN lcDate
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
*-- FUNCTION __decode
	HIDDEN FUNCTION __decode AS OBJECT
		THIS.cJsonOri = THIS.cJsonStr
		THIS.__cleanJsonString()
		THIS.nPos = 1
		THIS.nLen = LEN(THIS.cJsonOri)
		IF THIS.__validate_json_format()
			RETURN THIS.__parse_object()
		ELSE &&THIS.__validate_json_format()
			THIS.__setLastErrorText("invalid JSON format")
			RETURN NULL
		ENDIF &&THIS.__validate_json_format()
	ENDFUNC
*-- FUNCTION __parse_object
	HIDDEN FUNCTION __parse_object AS OBJECT
		LOCAL oCurObj AS OBJECT, lcPropName AS STRING, lcType AS STRING, vNewVal AS Variant
		oCurObj = CREATEOBJECT("__custom_object")
		THIS.__eat_json(2)
		DO WHILE .T.
			lcPropName = THIS.__parse_string(.T.)
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
			THIS.FLAG.ACTIVE = .T.
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
		ENDDO &&WHILE .T.
		RETURN oCurObj
	ENDFUNC
*-- FUNCTION __parse_value
	HIDDEN FUNCTION __parse_value AS Variant
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
*-- FUNCTION __parse_array
	HIDDEN FUNCTION __parse_array AS OBJECT
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
		ENDDO &&WHILE .T.
		RETURN aCustomArr
	ENDFUNC
*-- FUNCTION __parse_number
	HIDDEN FUNCTION __parse_number AS NUMBER
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
		ENDDO &&WHILE .T.
		SET DECIMALS TO 10
		nValNumber = VAL(cNumber)
		IF bIsNegative
			RETURN nValNumber * -1
		ELSE &&bIsNegative
			RETURN nValNumber
		ENDIF &&bIsNegative
	ENDFUNC
*-- FUNCTION __parse_expr
	HIDDEN FUNCTION __parse_expr AS Variant
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
*-- FUNCTION __parse_string
	HIDDEN FUNCTION __parse_string AS MEMO
		LPARAMETERS tlisNameAttr
		LOCAL lcValue AS STRING, dDate AS Variant
		lcValue = ""
		IF THIS.__get_Token() <> '"'
			THIS.__setLastErrorText('Expected " - Got undefined')
			RETURN ''
		ELSE &&THIS.__get_Token() <> '"'
		ENDIF &&THIS.__get_Token() <> '"'
		lcValue = STREXTRACT(THIS.cJsonStr, '"', '"', 1)
		IF OCCURS("-", lcValue) == 2 .AND. NOT tlisNameAttr
			lDate = THIS.__checkDate(lcValue)
			IF !ISNULL(lDate)
				dDate = lDate
			ELSE &&!ISNULL(lDate)
			ENDIF &&!ISNULL(lDate)
		ELSE &&OCCURS("-", lcValue) == 2 .AND. NOT tlisNameAttr
		ENDIF &&OCCURS("-", lcValue) == 2 .AND. NOT tlisNameAttr
		IF EMPTY(lcValue)
			THIS.__setLastErrorText('Invalid string value')
			RETURN ''
		ELSE &&EMPTY(lcValue)
		ENDIF &&EMPTY(lcValue)
		THIS.__eat_json(LEN(lcValue) + 3) && El nombre más los delimitadores '"'/'"' y una posicion más para saltarse el último ".
		RETURN IIF(EMPTY(dDate),lcValue,dDate)
	ENDFUNC
*-- PROCEDURE __parse_XML
	HIDDEN PROCEDURE __parse_XML
		LPARAMETERS tcColumn, tvNewVal
		IF THIS.lparseXML
			lcType = VARTYPE(tvNewVal)
			IF !USED(ALLTRIM(tcColumn))
				lcAlter = "L" && Logical by Default
				lDate 	= NULL
				DO CASE
				CASE lcType = "C" AND OCCURS("-", tvNewVal) == 2 && Date or DateTime
					lDate 	= THIS.__checkDate(tvNewVal)
					IF !ISNULL(lDate)
						lcType 	 = VARTYPE(lDate)
						lcAlter  = lcType + " NULL"
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
				CASE lcType = "T"
					lcAlter = "T NULL"
				OTHERWISE
				ENDCASE
				THIS.nPosXML = THIS.nPosXML + 1
				IF TYPE("aColumns") == "U"
					PUBLIC aColumns
				ELSE &&TYPE("aColumns") == "U"
				ENDIF &&TYPE("aColumns") == "U"
				DIMENSION aColumns[THIS.nPosXML]
				aColumns[THIS.nPosXML] = tcColumn
				lcMacro = "CREATE CURSOR " + ALLTRIM(tcColumn) + " (valor " + lcAlter + ")"
				&lcMacro
			ELSE &&!USED(ALLTRIM(tcColumn))
			ENDIF &&!USED(ALLTRIM(tcColumn))
			IF lcType == "C" AND OCCURS("-", tvNewVal) == 2
				lDate 	= THIS.__checkDate(tvNewVal)
				IF !ISNULL(lDate)
					tvNewVal = lDate
				ELSE &&!ISNULL(lDate)
				ENDIF &&!ISNULL(lDate)
			ELSE &&lcType == "C" AND OCCURS("-", tvNewVal) == 2
			ENDIF &&lcType == "C" AND OCCURS("-", tvNewVal) == 2
			TRY
				INSERT INTO &tcColumn (valor) VALUES(tvNewVal)
			CATCH
				INSERT INTO &tcColumn (valor) VALUES(NULL)
			ENDTRY
		ELSE &&THIS.lparseXML
		ENDIF &&THIS.lparseXML
	ENDFUNC
*-- FUNCTION __checkDate
	HIDDEN FUNCTION __checkDate AS Variant
		LPARAMETERS tsDate AS STRING
		LOCAL cStr AS STRING, lIsDateTime AS boolean, lDate AS Variant
		cStr 		= ""
		lIsDateTime = .F.
		lDate		= NULL
		cStr 		= STRTRAN(tsDate, "-")
		IF OCCURS(":", tsDate) == 2
			lIsDateTime = .T.
			cStr 		= STRTRAN(cStr, ":")
			cStr 		= STRTRAN(UPPER(cStr), "AM")
			cStr 		= STRTRAN(UPPER(cStr), "PM")
			cStr 		= STRTRAN(UPPER(cStr), SPACE(1))
		ELSE &&OCCURS(":", tsDate) == 2
		ENDIF &&OCCURS(":", tsDate) == 2
		FOR i=1 TO LEN(cStr) STEP 1
			IF ISDIGIT(SUBSTR(cStr, i, 1))
				LOOP
			ELSE &&ISDIGIT(SUBSTR(cStr, i, 1))
				RETURN NULL
			ENDIF &&ISDIGIT(SUBSTR(cStr, i, 1))
		ENDFOR &&i=1 TO LEN(cStr) STEP 1
		IF VAL(LEFT(tsDate,4)) > 0 AND VAL(STREXTRACT(tsDate, "-", "-",1)) > 0 AND VAL(RIGHT(tsDate,2)) > 0
			IF !lIsDateTime
				lDate = DATE(VAL(LEFT(tsDate,4)), VAL(STREXTRACT(tsDate, "-", "-",1)), VAL(RIGHT(tsDate,2)))
			ELSE &&!lIsDateTime
*-- WARNING: Valid string datetime format is yyyy-mm-dd hh:mm:ss
				lDate = DATETIME(VAL(LEFT(tsDate,4)), VAL(STREXTRACT(tsDate, "-", "-",1)), VAL(STREXTRACT(tsDate, "-", SPACE(1),2)), VAL(SUBSTR(tsDate, 12, 2)), VAL(STREXTRACT(tsDate, ":", ":",1)), VAL(RIGHT(tsDate,2)))
			ENDIF &&!lIsDateTime
		ELSE &&VAL(LEFT(tsDate,4)) > 0 AND VAL(STREXTRACT(tsDate, "-", "-",1)) > 0 AND VAL(RIGHT(tsDate,2)) > 0
			IF !lIsDateTime
				lDate = {//}
			ELSE &&!lIsDateTime
				lDate = {//::}
			ENDIF &&!lIsDateTime
		ENDIF &&VAL(LEFT(tsDate,4)) > 0 AND VAL(STREXTRACT(tsDate, "-", "-",1)) > 0 AND VAL(RIGHT(tsDate,2)) > 0
		RETURN lDate
	ENDFUNC
*-- PROCEDURE __eat_json
	HIDDEN PROCEDURE __eat_json(tnPosition AS INTEGER)
		THIS.cJsonStr = ALLTRIM(SUBSTR(THIS.cJsonStr, tnPosition, LEN(THIS.cJsonStr)))
	ENDPROC
*-- FUNCTION __get_Token
	HIDDEN FUNCTION __get_Token AS STRING
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
		ENDDO &&WHILE .T.
	ENDFUNC
*-- FUNCTION __validate_json_format
	HIDDEN FUNCTION __validate_json_format AS boolean
		RETURN (LEFT(THIS.cJsonStr,1) == "{" AND RIGHT(THIS.cJsonStr, 1) == "}")
	ENDFUNC
*-- FUNCTION __cleanJsonString
	HIDDEN FUNCTION __cleanJsonString
		THIS.cJsonStr = STRTRAN(THIS.cJsonStr, CHR(9))
		THIS.cJsonStr = STRTRAN(THIS.cJsonStr, CHR(10))
		THIS.cJsonStr = STRTRAN(THIS.cJsonStr, CHR(13))
		THIS.cJsonStr = ALLTRIM(THIS.__html_entity_decode(THIS.cJsonStr))
	ENDFUNC
*-- FUNCTION __html_entity_decode(cText AS MEMO)
	HIDDEN FUNCTION __html_entity_decode(cText AS MEMO) AS MEMO
		cText = STRTRAN(cText, "\u00a0", "Â")
		cText = STRTRAN(cText, "\u00a1", "¡")
		cText = STRTRAN(cText, "\u00a2", "¢")
		cText = STRTRAN(cText, "\u00a3", "£")
		cText = STRTRAN(cText, "\u00a4", "¤")
		cText = STRTRAN(cText, "\u00a5", "¥")
		cText = STRTRAN(cText, "\u00a6", "¦")
		cText = STRTRAN(cText, "\u00a7", "§")
		cText = STRTRAN(cText, "\u00a8", "¨")
		cText = STRTRAN(cText, "\u00a9", "©")
		cText = STRTRAN(cText, "\u00aa", "ª")
		cText = STRTRAN(cText, "\u00ab", "«")
		cText = STRTRAN(cText, "\u00ac", "¬")
		cText = STRTRAN(cText, "\u00ae", "®")
		cText = STRTRAN(cText, "\u00af", "¯")
		cText = STRTRAN(cText, "\u00b0", "°")
		cText = STRTRAN(cText, "\u00b1", "±")
		cText = STRTRAN(cText, "\u00b2", "²")
		cText = STRTRAN(cText, "\u00b3", "³")
		cText = STRTRAN(cText, "\u00b4", "´")
		cText = STRTRAN(cText, "\u00b5", "µ")
		cText = STRTRAN(cText, "\u00b6", "¶")
		cText = STRTRAN(cText, "\u00b7", "·")
		cText = STRTRAN(cText, "\u00b8", "¸")
		cText = STRTRAN(cText, "\u00b9", "¹")
		cText = STRTRAN(cText, "\u00ba", "º")
		cText = STRTRAN(cText, "\u00bb", "»")
		cText = STRTRAN(cText, "\u00bc", "¼")
		cText = STRTRAN(cText, "\u00bd", "½")
		cText = STRTRAN(cText, "\u00be", "¾")
		cText = STRTRAN(cText, "\u00bf", "¿")
		cText = STRTRAN(cText, "\u00c0", "À")
		cText = STRTRAN(cText, "\u00c1", "Á")
		cText = STRTRAN(cText, "\u00c2", "Â")
		cText = STRTRAN(cText, "\u00c3", "Ã")
		cText = STRTRAN(cText, "\u00c4", "Ä")
		cText = STRTRAN(cText, "\u00c5", "Å")
		cText = STRTRAN(cText, "\u00c6", "Æ")
		cText = STRTRAN(cText, "\u00c7", "Ç")
		cText = STRTRAN(cText, "\u00c8", "È")
		cText = STRTRAN(cText, "\u00c9", "É")
		cText = STRTRAN(cText, "\u00ca", "Ê")
		cText = STRTRAN(cText, "\u00cb", "Ë")
		cText = STRTRAN(cText, "\u00cc", "Ì")
		cText = STRTRAN(cText, "\u00cd", "Í")
		cText = STRTRAN(cText, "\u00ce", "Î")
		cText = STRTRAN(cText, "\u00cf", "Ï")
		cText = STRTRAN(cText, "\u00d0", "Ð")
		cText = STRTRAN(cText, "\u00d1", "Ñ")
		cText = STRTRAN(cText, "\u00d2", "Ò")
		cText = STRTRAN(cText, "\u00d3", "Ó")
		cText = STRTRAN(cText, "\u00d4", "Ô")
		cText = STRTRAN(cText, "\u00d5", "Õ")
		cText = STRTRAN(cText, "\u00d6", "Ö")
		cText = STRTRAN(cText, "\u00d7", "×")
		cText = STRTRAN(cText, "\u00d8", "Ø")
		cText = STRTRAN(cText, "\u00d9", "Ù")
		cText = STRTRAN(cText, "\u00da", "Ú")
		cText = STRTRAN(cText, "\u00db", "Û")
		cText = STRTRAN(cText, "\u00dc", "Ü")
		cText = STRTRAN(cText, "\u00dd", "Ý")
		cText = STRTRAN(cText, "\u00de", "Þ")
		cText = STRTRAN(cText, "\u00df", "ß")
		cText = STRTRAN(cText, "\u00e0", "à")
		cText = STRTRAN(cText, "\u00e1", "á")
		cText = STRTRAN(cText, "\u00e2", "â")
		cText = STRTRAN(cText, "\u00e3", "ã")
		cText = STRTRAN(cText, "\u00e4", "ä")
		cText = STRTRAN(cText, "\u00e5", "å")
		cText = STRTRAN(cText, "\u00e6", "æ")
		cText = STRTRAN(cText, "\u00e7", "ç")
		cText = STRTRAN(cText, "\u00e8", "è")
		cText = STRTRAN(cText, "\u00e9", "é")
		cText = STRTRAN(cText, "\u00ea", "ê")
		cText = STRTRAN(cText, "\u00eb", "ë")
		cText = STRTRAN(cText, "\u00ec", "ì")
		cText = STRTRAN(cText, "\u00ed", "í")
		cText = STRTRAN(cText, "\u00ee", "î")
		cText = STRTRAN(cText, "\u00ef", "ï")
		cText = STRTRAN(cText, "\u00f0", "ð")
		cText = STRTRAN(cText, "\u00f1", "ñ")
		cText = STRTRAN(cText, "\u00f2", "ò")
		cText = STRTRAN(cText, "\u00f3", "ó")
		cText = STRTRAN(cText, "\u00f4", "ô")
		cText = STRTRAN(cText, "\u00f5", "õ")
		cText = STRTRAN(cText, "\u00f6", "ö")
		cText = STRTRAN(cText, "\u00f7", "÷")
		cText = STRTRAN(cText, "\u00f8", "ø")
		cText = STRTRAN(cText, "\u00f9", "ù")
		cText = STRTRAN(cText, "\u00fa", "ú")
		cText = STRTRAN(cText, "\u00fb", "û")
		cText = STRTRAN(cText, "\u00fc", "ü")
		cText = STRTRAN(cText, "\u00fd", "ý")
		cText = STRTRAN(cText, "\u00fe", "þ")
		cText = STRTRAN(cText, "\u00ff", "ÿ")
		cText = STRTRAN(cText, "\u0026", "&")
		cText = STRTRAN(cText, "\u2019", "'")
		cText = STRTRAN(cText, "\u003A", ":")
		cText = STRTRAN(cText, "\u002B", "+")
		cText = STRTRAN(cText, "\u002D", "-")
		cText = STRTRAN(cText, "\u0023", "#")
		cText = STRTRAN(cText, "\u0025", "%")
		RETURN cText
	ENDFUNC
*-- PROCEDURE __setLastErrorText(tcErrorText AS STRING)
	HIDDEN PROCEDURE __setLastErrorText(tcErrorText AS STRING)
		THIS.lValidCall = .T.
		IF !EMPTY(tcErrorText)
			THIS.LastErrorText = "Error: parse error on line " + ALLTRIM(STR(THIS.nPos,6,0)) + ": " + tcErrorText
		ELSE &&!EMPTY(tcErrorText)
			THIS.LastErrorText = ""
		ENDIF &&!EMPTY(tcErrorText)
	ENDPROC
*-- PROCEDURE LastErrorText_Assign
	HIDDEN PROCEDURE LastErrorText_Assign
		LPARAMETERS vNewVal
		IF THIS.lValidCall
			THIS.lValidCall = .F.
			THIS.LastErrorText = m.vNewVal
		ELSE &&THIS.lValidCall
		ENDIF &&THIS.lValidCall
	ENDPROC
*-- PROCEDURE Version_Assign
	HIDDEN PROCEDURE Version_Assign
		LPARAMETERS vNewVal
		IF THIS.lValidCall
			THIS.lValidCall = .F.
			THIS.VERSION = m.vNewVal
		ELSE &&THIS.lValidCall
		ENDIF &&THIS.lValidCall
	ENDPROC
*-- FUNCTION Version_Access
	HIDDEN FUNCTION Version_Access
		RETURN THIS.VERSION
	ENDFUNC
*-- PROCEDURE LastUpdate_Assign
	HIDDEN PROCEDURE LastUpdate_Assign
		LPARAMETERS vNewVal
		IF THIS.lValidCall
			THIS.lValidCall = .F.
			THIS.LastUpdate = m.vNewVal
		ELSE &&THIS.lValidCall
		ENDIF &&THIS.lValidCall
	ENDPROC
*-- FUNCTION LastUpdate_Access
	HIDDEN FUNCTION LastUpdate_Access
		RETURN THIS.LastUpdate
	ENDFUNC
*-- PROCEDURE Author_Assign
	HIDDEN PROCEDURE Author_Assign
		LPARAMETERS vNewVal
		IF THIS.lValidCall
			THIS.lValidCall = .F.
			THIS.Author = m.vNewVal
		ELSE &&THIS.lValidCall
		ENDIF &&THIS.lValidCall
	ENDPROC
*-- FUNCTION Author_Access
	HIDDEN FUNCTION Author_Access
		RETURN THIS.Author
	ENDFUNC
*-- PROCEDURE Email_Assign
	HIDDEN PROCEDURE Email_Assign
		LPARAMETERS vNewVal
		IF THIS.lValidCall
			THIS.lValidCall = .F.
			THIS.Email = m.vNewVal
		ELSE &&THIS.lValidCall
		ENDIF &&THIS.lValidCall
	ENDPROC
*-- FUNCTION Email_Access
	HIDDEN FUNCTION Email_Access
		RETURN THIS.Email
	ENDFUNC
ENDDEFINE
*-- DEFINE CLASS __custom_array AS CUSTOM
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
*-- PROCEDURE INIT
	PROCEDURE INIT
		THIS.nArrLen = 0
	ENDPROC
*-- FUNCTION array_push(vNewVal AS Variant)
	FUNCTION array_push(vNewVal AS Variant)
		THIS.nArrLen = THIS.nArrLen + 1
		DIMENSION THIS.ARRAY[THIS.nArrLen]
		THIS.ARRAY[this.nArrLen] = vNewVal
	ENDFUNC
*-- getvalue(tnIndex AS INTEGER)
	FUNCTION getvalue(tnIndex AS INTEGER) HELPSTRING "Obtiene el contenido del array dado su índice."
		TRY
			nLen = THIS.ARRAY[tnIndex]
		CATCH
			nLen = NULL
		ENDTRY
		RETURN nLen
	ENDFUNC
*-- FUNCTION LEN
	FUNCTION LEN
		RETURN THIS.nArrLen
	ENDFUNC
ENDDEFINE
*-- DEFINE CLASS __custom_object AS CUSTOM
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
*-- PROCEDURE setProperty(tcName AS STRING, tvNewVal AS Variant, tcType AS STRING, vFlag AS OBJECT)
	PROCEDURE setProperty(tcName AS STRING, tvNewVal AS Variant, tcType AS STRING, vFlag AS OBJECT)
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
*-- FUNCTION valueOf(tcName AS STRING)
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
*-- DEFINE CLASS FLAG AS CUSTOM
DEFINE CLASS FLAG AS CUSTOM
	ACTIVE = .F.
ENDDEFINE
