*==================================================================
* p6b-m0-fallos.prg -- los cuatro fallos que FoxDock midió en P6b-M0
* (FoxDock\medidas\p6b-m0-codepage.prg, contra la 13.1.1), medidos
* aquí contra lo que hay en el repositorio, con las dos clases:
* el autocontenido (JsonFox.prg) y la del .app (jsonfox.app).
*
*   1. CursorToJSON con B, Q y W.
*   2. I y N(10,0): ¿salen sin decimales?
*   3. Lo que pasa de 127: ¿se escapa el carácter o el byte?
*   4. JSONToCursor con números: qué campo hace, qué Double vuelve, y
*      si CursorToJSON -> JSONToCursor -> CursorToJSON da el mismo JSON.
*
* Uso, en una instancia desechable de FoxAgent:
*   DO C:\Desarrollo\IrwinRodriguez.dev\JSONFox\medidas\p6b-m0-fallos.prg
* El resultado, en medidas\out\p6b-m0-fallos.txt. CP1252, con los acentos
* escritos.
*==================================================================

#DEFINE CRLF CHR(13) + CHR(10)
#DEFINE M_ROOT "C:\Desarrollo\IrwinRodriguez.dev\JSONFox\"

LOCAL lcText, loStd, loApp, lcOut
lcOut = M_ROOT + "medidas\out\p6b-m0-fallos.txt"
IF !DIRECTORY(M_ROOT + "medidas\out")
	MKDIR (M_ROOT + "medidas\out")
ENDIF
SET SAFETY OFF
SET TALK OFF
SET DECIMALS TO 2
CLOSE TABLES ALL

loStd = NEWOBJECT("JSONFox", M_ROOT + "JsonFox.prg")
DO (M_ROOT + "jsonfox.app")
loApp = _Screen.Json
loApp.lShowErrors = .F.

lcText = "p6b-m0-fallos " + TTOC(DATETIME(), 3) + " VERSION(4)=" + VERSION(4) + ;
	" CPCURRENT()=" + TRANSFORM(CPCURRENT()) + CRLF + ;
	"autocontenido " + loStd.version + ", app " + loApp.version + CRLF

*-- La tabla de los trece tipos, y N(10,0) -----------------------------------
MTypes()

*-- 1 y 2. CursorToJSON -------------------------------------------------------
lcText = lcText + CRLF + "== 1 y 2. CursorToJSON(m0types)" + CRLF
lcText = lcText + "-- autocontenido, lError=" + TRANSFORM(loStd.lError) + " " + loStd.cLastError + CRLF + ;
	loStd.CursorToJSON("m0types", .F., SET("Datasession"), .T.) + CRLF
lcText = lcText + "-- app, lError=" + TRANSFORM(loApp.lError) + " " + loApp.LastErrorText + CRLF + ;
	loApp.CursorToJSON("m0types", .F., SET("Datasession"), .T.) + CRLF
GO TOP IN m0types
lcText = lcText + "   VARTYPE(qq)=" + VARTYPE(m0types.qq) + " VARTYPE(ww)=" + VARTYPE(m0types.ww) + ;
	"  STRCONV(qq, 13)=" + STRCONV(m0types.qq, 13) + "  STRCONV(ww, 13)=" + STRCONV(m0types.ww, 13) + CRLF
lcText = lcText + "   STRCONV(REPLICATE('x', 200), 13) lleva CR o LF: " + ;
	TRANSFORM(CHR(13) $ STRCONV(REPLICATE("x", 200), 13) OR CHR(10) $ STRCONV(REPLICATE("x", 200), 13)) + CRLF

*-- 3. Lo que pasa de 127 -----------------------------------------------------
LOCAL lcStr
lcStr = "€ñéüš" + CHR(1) + "x"
CREATE CURSOR m0chars (s C(7))
INSERT INTO m0chars VALUES (lcStr)
lcText = lcText + CRLF + "== 3. una C con " + MHex(lcStr) + " (€ ñ é ü š, CHR(1), x)" + CRLF
lcText = lcText + "-- autocontenido: " + loStd.CursorToJSON("m0chars", .F., SET("Datasession"), .T.) + CRLF
lcText = lcText + "-- app:           " + loApp.CursorToJSON("m0chars", .F., SET("Datasession"), .T.) + CRLF
lcText = lcText + "-- STRCONV(s, 5, 1252, 1) (UTF-16LE): " + MHex(STRCONV(lcStr, 5, 1252, 1)) + CRLF
lcText = lcText + "-- STRCONV(s, 5, CPCURRENT(), 1):     " + MHex(STRCONV(lcStr, 5, CPCURRENT(), 1)) + CRLF
lcText = lcText + "-- y la vuelta, Parse:" + CRLF
lcText = lcText + MParse(loStd, "autocontenido", '"\u20AC\u00F1\u00E9\u00FC\u0161"')
lcText = lcText + MParse(loStd, "autocontenido", '"\u0080"')
lcText = lcText + MParse(loStd, "autocontenido", '"\u4E2D"')
lcText = lcText + MParse(loApp, "app", '"\u20AC\u00F1\u00E9\u00FC\u0161"')
lcText = lcText + MParse(loApp, "app", '"\u4E2D"')
lcText = lcText + "-- STRCONV(CHR(0x2D) + CHR(0x4E), 6, 1252, 1): " + MHex(STRCONV(CHR(0x2D) + CHR(0x4E), 6, 1252, 1)) + CRLF

*-- 4. JSONToCursor y los números -----------------------------------------------
lcText = lcText + CRLF + "== 4. JSONToCursor y los números" + CRLF
CREATE CURSOR m0dbl (d B(2))
INSERT INTO m0dbl VALUES (1/3)
INSERT INTO m0dbl VALUES (0.1 + 0.2)
INSERT INTO m0dbl VALUES (0)
INSERT INTO m0dbl VALUES (2.5)
INSERT INTO m0dbl VALUES (1E-20)
INSERT INTO m0dbl VALUES (123456789.123)
lcText = lcText + MRound(loStd, "autocontenido", "m0dbl")
lcText = lcText + MRound(loApp, "app", "m0dbl")

lcText = lcText + CRLF + "-- 4b. la tabla de los trece tipos, ida, vuelta e ida" + CRLF
MTypes()
lcText = lcText + MRound(loStd, "autocontenido", "m0types")
MTypes()
lcText = lcText + MRound(loApp, "app", "m0types")

lcText = lcText + CRLF + "-- 4c. JSON a mano" + CRLF
lcText = lcText + MFromJson(loStd, '[{"x":0.30000000000000004},{"x":0.3333333333333333}]')
lcText = lcText + MFromJson(loStd, '[{"x":null},{"x":3.14}]')
lcText = lcText + MFromJson(loStd, '[{"x":1.5},{"x":12345.25}]')
lcText = lcText + MFromJson(loStd, '[{"x":12345},{"x":1.5}]')
lcText = lcText + MFromJson(loStd, '[{"x":1e-7},{"x":2E+3}]')
lcText = lcText + MFromJson(loStd, '[{"x":-3000000000}]')
lcText = lcText + MFromJson(loStd, '[{"x":12345678901234567890.5}]')

lcText = lcText + CRLF + "-- 4d. el literal de VFP y los bits" + CRLF
lcText = lcText + "   BINTOC(0.1 + 0.2)=" + MHex(BINTOC(0.1 + 0.2, "B")) + ;
	"  EVALUATE('0.30000000000000004')=" + MHex(BINTOC(EVALUATE("0.30000000000000004"), "B")) + ;
	"  EVALUATE('0.3')=" + MHex(BINTOC(EVALUATE("0.3"), "B")) + CRLF
lcText = lcText + "   BINTOC(1/3)=" + MHex(BINTOC(1/3, "B")) + ;
	"  EVALUATE('0.3333333333333333')=" + MHex(BINTOC(EVALUATE("0.3333333333333333"), "B")) + ;
	"  EVALUATE('0.333333333333333')=" + MHex(BINTOC(EVALUATE("0.333333333333333"), "B")) + CRLF
LOCAL lcBuf, lnLen
DECLARE INTEGER _snprintf IN msvcrt AS M0Snprintf STRING @cBuf, INTEGER nCount, STRING cFmt, DOUBLE nValue
lcBuf = REPLICATE(CHR(0), 64)
lnLen = M0Snprintf(@lcBuf, 63, "%.17g", 0.1 + 0.2)
lcText = lcText + "   _snprintf('%.17g', 0.1 + 0.2)=" + LEFT(lcBuf, lnLen)
lcBuf = REPLICATE(CHR(0), 64)
lnLen = M0Snprintf(@lcBuf, 63, "%.17g", 1E-20)
lcText = lcText + "  ('%.17g', 1E-20)=" + LEFT(lcBuf, lnLen) + ;
	"  EVALUATE('1e-20') == 1E-20: " + TRANSFORM(BINTOC(EVALUATE("1e-20"), "B") == BINTOC(1E-20, "B")) + CRLF
CLEAR DLLS "M0Snprintf"
TRY
	CREATE CURSOR m0w (b B(18), n N(20,18))
	lcText = lcText + "   B(18) y N(20,18): se pueden crear" + CRLF
CATCH TO loEx
	lcText = lcText + "   B(18) y N(20,18): " + loEx.Message + CRLF
ENDTRY
TRY
	CREATE CURSOR m0w (n N(21,2))
	lcText = lcText + "   N(21,2): se puede crear" + CRLF
CATCH TO loEx
	lcText = lcText + "   N(21,2): " + loEx.Message + CRLF
ENDTRY

CLOSE TABLES ALL
STRTOFILE(lcText, lcOut)
RETURN lcText


*-- La tabla de los trece tipos (y un N(10,0)), con una fila llena y otra de NULL.
PROCEDURE MTypes
	USE IN SELECT("m0types")
	CREATE CURSOR m0types (cc C(6) NULL, vv V(10) NULL, mm M NULL, nn N(8,2) NULL, n0 N(10,0) NULL, ;
		ff F(10,3) NULL, ii I NULL, bb B(3) NULL, yy Y NULL, dd D NULL, tt T NULL, ll L NULL, ;
		qq Q(4) NULL, ww W NULL)
	INSERT INTO m0types VALUES ("Muñoz", "€ñéü", "a" + CRLF + "b", 1234.5, 42, 3.125, 42, 3.14159, ;
		19.99, {^1990-05-17}, {^2026-10-30 10:20:30}, .T., 0h41420043, 0h78797A00FF)
	INSERT INTO m0types VALUES (.NULL., .NULL., .NULL., .NULL., .NULL., .NULL., .NULL., .NULL., ;
		.NULL., .NULL., .NULL., .NULL., .NULL., .NULL.)
ENDPROC

*-- Parse de una cadena JSON, en hexadecimal.
PROCEDURE MParse
	LPARAMETERS toJson, tcWho, tcJson
	LOCAL lvVal
	lvVal = toJson.Parse(tcJson)
	RETURN "   " + tcWho + " Parse(" + tcJson + ") = " + IIF(VARTYPE(lvVal) == "C", MHex(lvVal), VARTYPE(lvVal)) + CRLF
ENDPROC

*-- CursorToJSON -> JSONToCursor -> CursorToJSON, con la estructura y los bits de los B.
PROCEDURE MRound
	LPARAMETERS toJson, tcWho, tcCursor
	LOCAL lcJ1, lcJ2, lcOut, laF[1], lnI, lnN, lcBack, lcErr
	lcBack = "m0back"
	lcJ1 = toJson.CursorToJSON(tcCursor, .F., SET("Datasession"), .T.)
	USE IN SELECT(lcBack)
	toJson.JSONToCursor(lcJ1, lcBack, SET("Datasession"))
	lcErr = IIF(PEMSTATUS(toJson, "cLastError", 5), toJson.cLastError, toJson.LastErrorText)
	lcOut = "   " + tcWho + " " + tcCursor + CRLF + "   ida:    " + lcJ1 + CRLF
	IF !USED(lcBack)
		RETURN lcOut + "   JSONToCursor no hizo cursor: " + lcErr + CRLF
	ENDIF
	lcJ2 = toJson.CursorToJSON(lcBack, .F., SET("Datasession"), .T.)
	lcOut = lcOut + "   vuelta: " + lcJ2 + CRLF + "   iguales: " + TRANSFORM(lcJ1 == lcJ2) + CRLF + "   campos:"
	lnN = AFIELDS(laF, lcBack)
	FOR lnI = 1 TO lnN
		lcOut = lcOut + " " + LOWER(laF[lnI, 1]) + " " + laF[lnI, 2] + "(" + TRANSFORM(laF[lnI, 3]) + "," + TRANSFORM(laF[lnI, 4]) + ")"
	ENDFOR
	lcOut = lcOut + CRLF
	IF tcCursor == "m0dbl"
		lcOut = lcOut + "   bits (original | vuelta):" + CRLF
		SELECT (tcCursor)
		GO TOP
		SELECT (lcBack)
		GO TOP
		DO WHILE !EOF(tcCursor) AND !EOF(lcBack)
			lcOut = lcOut + "     " + MHex(BINTOC(EVALUATE(tcCursor + ".d"), "B")) + " | " + ;
				MHex(BINTOC(EVALUATE(lcBack + ".d"), "B")) + "  " + ;
				IIF(BINTOC(EVALUATE(tcCursor + ".d"), "B") == BINTOC(EVALUATE(lcBack + ".d"), "B"), "igual", "DISTINTO") + CRLF
			SKIP IN (tcCursor)
			SKIP IN (lcBack)
		ENDDO
	ENDIF
	USE IN SELECT(lcBack)
	RETURN lcOut
ENDPROC

*-- JSONToCursor de un JSON escrito a mano: el campo y lo que sale otra vez.
PROCEDURE MFromJson
	LPARAMETERS toJson, tcJson
	LOCAL laF[1], lcOut
	USE IN SELECT("m0hand")
	toJson.JSONToCursor(tcJson, "m0hand", SET("Datasession"))
	lcOut = "   " + tcJson + " -> "
	IF !USED("m0hand")
		RETURN lcOut + "sin cursor: " + toJson.cLastError + CRLF
	ENDIF
	AFIELDS(laF, "m0hand")
	lcOut = lcOut + laF[1, 2] + "(" + TRANSFORM(laF[1, 3]) + "," + TRANSFORM(laF[1, 4]) + ") -> " + ;
		toJson.CursorToJSON("m0hand", .F., SET("Datasession"), .T.) + ;
		IIF(toJson.lError, "  lError: " + toJson.cLastError, "") + CRLF
	USE IN m0hand
	RETURN lcOut
ENDPROC

PROCEDURE MHex
	LPARAMETERS tcS
	LOCAL lnI, lcOut
	lcOut = ""
	FOR lnI = 1 TO LEN(tcS)
		lcOut = lcOut + RIGHT(TRANSFORM(ASC(SUBSTR(tcS, lnI, 1)), "@0"), 2) + " "
	ENDFOR
	RETURN RTRIM(lcOut)
ENDPROC
