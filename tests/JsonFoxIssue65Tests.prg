* ==================================================================
* JsonFoxIssue65Tests.prg
*
* Lo que afirma esta suite: que JSONFox escribe los números con todos
* sus decimales, diga lo que diga SET DECIMALS (issue #65, octubre de
* 2026).
*
* POR QUÉ EXISTE: CursorToJSON y Stringify escribían los números con
* TRANSFORM(valor, "@T"), que redondea a SET DECIMALS (2 por defecto).
* Un N(10,4) con 1.2345 salía como 1.23, sin error ni aviso. Leer no
* tenía el problema: Parse y JSONToCursor guardan 1.2345.
*
* Ahora CursorToJSON usa los decimales de cada campo (N, F, Y, I) y un
* número suelto (Stringify, o un campo Double) sale con 15 cifras
* significativas, sin ceros a la derecha.
*
* Cada test pone SET DECIMALS TO 2 para no depender de la sesión.
*
* cApiRoot: ruta al proyecto. Ajustar si se mueve.
* ==================================================================

DEFINE CLASS JsonFoxIssue65Tests AS Custom
    cApiRoot = "C:\Desarrollo\IrwinRodriguez.dev\JSONFox\"
    oJson = .NULL.
    nDecimals = 2

    PROCEDURE SetUp() HELP []
        SET PROCEDURE TO (THIS.cApiRoot + "JsonFox.prg") ADDITIVE
        THIS.oJson = CREATEOBJECT("JSONFox")
        THIS.nDecimals = SET("DECIMALS")
        SET DECIMALS TO 2
    ENDPROC

    PROCEDURE TearDown() HELP []
        SET DECIMALS TO (THIS.nDecimals)
        THIS.oJson = .NULL.
        USE IN SELECT("qNum")
    ENDPROC

* El caso del issue: un N(10,4).
    PROCEDURE Test_CursorToJSON_CuatroDecimales() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qNum (n N(10,4))
        INSERT INTO qNum VALUES (1.2345)
        lcJson = THIS.oJson.CursorToJSON("qNum", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"n":1.2345}]', lcJson)
    ENDPROC

    PROCEDURE Test_CursorToJSON_SeisDecimales() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qNum (n N(12,6), f F(12,6))
        INSERT INTO qNum VALUES (1.234567, -0.000001)
        lcJson = THIS.oJson.CursorToJSON("qNum", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"n":1.234567,"f":-0.000001}]', lcJson)
    ENDPROC

* Un entero sale sin decimales (antes, 1.00).
    PROCEDURE Test_CursorToJSON_EnteroSinDecimales() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qNum (cant I, n N(5,0))
        INSERT INTO qNum VALUES (7, 12345)
        lcJson = THIS.oJson.CursorToJSON("qNum", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"cant":7,"n":12345}]', lcJson)
    ENDPROC

* El Double guarda más de lo que enseña: B(2) con 1.23456 son 1.23456.
    PROCEDURE Test_CursorToJSON_DobleConTodaSuPrecision() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qNum (d B(2), y Y)
        INSERT INTO qNum VALUES (1.23456, $12.3456)
        lcJson = THIS.oJson.CursorToJSON("qNum", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"d":1.23456,"y":12.3456}]', lcJson)
    ENDPROC

    PROCEDURE Test_Stringify_NumerosSueltos() HELP [Fact]
        LOCAL loObj, lcJson
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "a", 1.2345)
        ADDPROPERTY(loObj, "b", 1.234567)
        ADDPROPERTY(loObj, "c", 0.1)
        ADDPROPERTY(loObj, "d", -3.5)
        ADDPROPERTY(loObj, "e", 1234567.1)
        ADDPROPERTY(loObj, "f", 1/3)
        ADDPROPERTY(loObj, "g", 100)
        lcJson = STRTRAN(STRTRAN(STRTRAN(THIS.oJson.Stringify(loObj), CHR(13), ""), CHR(10), ""), " ", "")

        __assert.Equal('{"a":1.2345,"b":1.234567,"c":0.1,"d":-3.5,"e":1234567.1,"f":0.333333333333333,"g":100}', lcJson)
    ENDPROC

* Con SET POINT TO ',' el JSON sigue llevando punto.
    PROCEDURE Test_Stringify_ConComaDecimal() HELP [Fact]
        LOCAL loObj, lcJson, lcPoint
        lcPoint = SET("POINT")
        SET POINT TO ','
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "a", 1.2345)
        lcJson = STRTRAN(STRTRAN(STRTRAN(THIS.oJson.Stringify(loObj), CHR(13), ""), CHR(10), ""), " ", "")
        SET POINT TO (lcPoint)

        __assert.Equal('{"a":1.2345}', lcJson)
    ENDPROC

* Ida y vuelta: lo que sale de un N(10,4) vuelve igual.
    PROCEDURE Test_IdaYVuelta() HELP [Fact]
        LOCAL lcJson, loObj
        CREATE CURSOR qNum (n N(10,4))
        INSERT INTO qNum VALUES (98.7654)
        lcJson = THIS.oJson.CursorToJSON("qNum", .F., SET("Datasession"), .T.)
        loObj = THIS.oJson.Parse(lcJson)

        __assert.Equal(987654, ROUND(loObj[1].n * 10000, 0))
    ENDPROC

* Fuera del issue, visto al escribir esta suite: un campo llamado i
* pisaba al contador del bucle dentro del SCAN y CursorToJSON fallaba con
* 'Subscript is outside defined range'.
    PROCEDURE Test_CursorToJSON_CampoLlamadoI() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qNum (i I, x C(3))
        INSERT INTO qNum VALUES (7, "abc")
        lcJson = THIS.oJson.CursorToJSON("qNum", .F., SET("Datasession"), .T.)

        __assert.False(THIS.oJson.lError, THIS.oJson.cLastError)
        __assert.Equal('[{"i":7,"x":"abc"}]', lcJson)
    ENDPROC

* El arreglo no puede dejar SET DECIMALS cambiado.
    PROCEDURE Test_NoTocaSetDecimals() HELP [Fact]
        CREATE CURSOR qNum (n N(10,4))
        INSERT INTO qNum VALUES (1.2345)
        THIS.oJson.CursorToJSON("qNum", .F., SET("Datasession"), .T.)

        __assert.Equal(2, SET("DECIMALS"))
    ENDPROC

ENDDEFINE
