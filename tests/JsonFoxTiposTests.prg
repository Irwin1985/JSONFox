* ==================================================================
* JsonFoxTiposTests.prg
*
* Lo que afirma esta suite: que CursorToJSON escribe bien cada tipo de
* campo y que JSONToCursor lo devuelve sin perder nada, de modo que
* CursorToJSON -> JSONToCursor -> CursorToJSON da el mismo JSON.
*
* POR QUÉ EXISTE: FoxDock midió CursorToJSON contra la 13.1.1 con una
* tabla de un campo de cada tipo (FoxDock\medidas\p6b-m0-codepage.prg,
* 30-10-2026) y escribió su propio JSON porque no se fiaba. Medido otra
* vez contra la 13.1.3 (medidas\p6b-m0-fallos.prg, su crudo en
* medidas\out\): el Double y los enteros ya estaban bien, y quedaba esto:
*
*   1. Varbinary (Q) y Blob (W) salían como "". Ahora, en base64.
*   2. Lo que pasa de 127 se escapaba por el BYTE: el € (0x80 en 1252)
*      salía \u0080, que es un carácter de control. Ahora por el carácter
*      Unicode (\u20AC), y los de control (< 32) como \u00XX.
*   3. Un Double salía con 15 cifras: 1/3 y 0.1 + 0.2 no volvían al mismo
*      Double, y 1E-20 salía 0. Ahora, el decimal más corto que vuelve al
*      mismo Double (15, 16 o 17 cifras).
*   4. JSONToCursor: un número con exponente o con más de 15 cifras
*      significativas va a un campo B; una columna con decimales distintos
*      en cada fila, también. Antes perdía decimales (un null en la primera
*      fila), desbordaba (12345 y luego 1.5) o dejaba 1e-7 en 0.
*
* Dos clases: la del autocontenido (JsonFox.prg, lo que se distribuye
* como .fxp) y la del .app (JSONClass, cargada desde src\).
*
* cApiRoot: ruta al proyecto. Ajustar si se mueve.
* ==================================================================

#DEFINE CRLF CHR(13) + CHR(10)

DEFINE CLASS JsonFoxTiposTests AS Custom
    cApiRoot = "C:\Desarrollo\IrwinRodriguez.dev\JSONFox\"
    oJson = .NULL.
    cPoint = "."

    PROCEDURE SetUp() HELP []
        SET PROCEDURE TO (THIS.cApiRoot + "JsonFox.prg") ADDITIVE
        THIS.oJson = CREATEOBJECT("JSONFox")
        THIS.cPoint = SET("POINT")
    ENDPROC

    PROCEDURE TearDown() HELP []
        SET POINT TO (THIS.cPoint)
        THIS.oJson = .NULL.
        USE IN SELECT("qTipos")
        USE IN SELECT("qVuelta")
    ENDPROC

    PROCEDURE Test_CursorToJSON_VarbinaryYBlobEnBase64() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qTipos (q Q(4) NULL, w W NULL)
        INSERT INTO qTipos VALUES (0h41420043, 0h78797A00FF)
        INSERT INTO qTipos VALUES (0h, .NULL.)
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"q":"QUIAQw==","w":"eHl6AP8="},{"q":"","w":null}]', lcJson)
    ENDPROC

* Ya estaba bien en la 13.1.3 (issue #65): se sujeta porque FoxDock lo
* midió mal en la 13.1.1.
    PROCEDURE Test_CursorToJSON_EnteroSinDecimales() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qTipos (i I, n N(10,0))
        INSERT INTO qTipos VALUES (42, 42)
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"i":42,"n":42}]', lcJson)
    ENDPROC

    PROCEDURE Test_CursorToJSON_EuroEsU20AC() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qTipos (s C(5))
        INSERT INTO qTipos VALUES ("€ñéüš")
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"s":"\u20AC\u00F1\u00E9\u00FC\u0161"}]', lcJson)
    ENDPROC

    PROCEDURE Test_CursorToJSON_CaracteresDeControl() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qTipos (s C(4))
        INSERT INTO qTipos VALUES ("a" + CHR(1) + CHR(31) + "b")
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"s":"a\u0001\u001Fb"}]', lcJson)
    ENDPROC

    PROCEDURE Test_Stringify_EuroEsU20AC() HELP [Fact]
        LOCAL loObj, lcJson
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "s", "5 €")
        lcJson = THIS.oJson.Stringify(loObj)

        __assert.True('"5 \u20AC"' $ lcJson, lcJson)
    ENDPROC

* La ida (CursorToJSON) y la vuelta (Parse) casan.
    PROCEDURE Test_IdaYVuelta_Caracteres() HELP [Fact]
        LOCAL lcJson, loObj
        CREATE CURSOR qTipos (s C(6))
        INSERT INTO qTipos VALUES ("€ñéüšŸ")
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)
        loObj = THIS.oJson.Parse(lcJson)

        __assert.Equal("€ñéüšŸ", loObj[1].s)
    ENDPROC

* 1/3 y 0.1 + 0.2 necesitan 16 y 17 cifras; 1E-20 salía 0.
    PROCEDURE Test_CursorToJSON_DobleMasCortoQueVuelve() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qTipos (d B(2))
        INSERT INTO qTipos VALUES (1/3)
        INSERT INTO qTipos VALUES (0.1 + 0.2)
        INSERT INTO qTipos VALUES (1E-20)
        INSERT INTO qTipos VALUES (2.5)
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"d":0.3333333333333333},{"d":0.30000000000000004},{"d":0.00000000000000000001},{"d":2.5}]', lcJson)
    ENDPROC

    PROCEDURE Test_CursorToJSON_DobleConComaDecimal() HELP [Fact]
        LOCAL lcJson
        SET POINT TO ','
        CREATE CURSOR qTipos (d B(2))
        INSERT INTO qTipos VALUES (0.1 + 0.2)
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"d":0.30000000000000004}]', lcJson)
    ENDPROC

* El Double vuelve bit a bit: BINTOC, porque el == de VFP da 0.1 + 0.2
* igual a 0.3.
    PROCEDURE Test_JSONToCursor_DobleVuelveIgual() HELP [Fact]
        LOCAL lcJson, lcIda, lcVuelta
        CREATE CURSOR qTipos (d B(2))
        INSERT INTO qTipos VALUES (1/3)
        INSERT INTO qTipos VALUES (0.1 + 0.2)
        INSERT INTO qTipos VALUES (1E-20)
        INSERT INTO qTipos VALUES (0)
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))
        lcIda = ""
        lcVuelta = ""
        SELECT qTipos
        SCAN
            lcIda = lcIda + BINTOC(qTipos.d, "B")
        ENDSCAN
        SELECT qVuelta
        SCAN
            lcVuelta = lcVuelta + BINTOC(qVuelta.d, "B")
        ENDSCAN

        __assert.Equal("B", JsonFoxTiposCampo("qVuelta"))
        __assert.Equal(STRCONV(lcIda, 15), STRCONV(lcVuelta, 15))
    ENDPROC

* Un 0 en una columna de Double sale 0, y vuelve 0, no 0.00000.
    PROCEDURE Test_JSONToCursor_DecimalesDistintosVanAB() HELP [Fact]
        LOCAL lcJson
        lcJson = '[{"x":3.14159},{"x":0},{"x":2.5}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))

        __assert.Equal("B", JsonFoxTiposCampo("qVuelta"))
        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

* Con los mismos decimales en todas las filas sigue siendo N(w,d).
    PROCEDURE Test_JSONToCursor_MismosDecimalesEsNumerico() HELP [Fact]
        LOCAL lcJson, laF[1]
        lcJson = '[{"x":1234.50},{"x":-0.25},{"x":null}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))
        AFIELDS(laF, "qVuelta")

        __assert.Equal("N(7,2)", laF[1, 2] + "(" + TRANSFORM(laF[1, 3]) + "," + TRANSFORM(laF[1, 4]) + ")")
        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

* Un null en la primera fila se llevaba los decimales: 3.14 volvía 3.
    PROCEDURE Test_JSONToCursor_NullPrimeroNoPierdeDecimales() HELP [Fact]
        LOCAL lcJson
        lcJson = '[{"x":null},{"x":3.14}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))

        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

* 12345 y luego 1.5 hacían un N(3,1), y el 12345 desbordaba.
    PROCEDURE Test_JSONToCursor_EnteroYDecimalNoDesbordan() HELP [Fact]
        LOCAL lcJson
        lcJson = '[{"x":12345},{"x":1.5}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))

        __assert.False(THIS.oJson.lError, THIS.oJson.cLastError)
        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

* 1e-7 iba a un Integer y se quedaba en 0.
    PROCEDURE Test_JSONToCursor_Exponente() HELP [Fact]
        THIS.oJson.JSONToCursor('[{"x":1e-7},{"x":2E+3}]', "qVuelta", SET("Datasession"))

        __assert.Equal("B", JsonFoxTiposCampo("qVuelta"))
        __assert.Equal('[{"x":0.0000001},{"x":2000}]', THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

    PROCEDURE Test_JSONToCursor_EnteroNegativoGrande() HELP [Fact]
        LOCAL lcJson
        lcJson = '[{"x":-3000000000},{"x":7}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))

        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

* Un N no pasa de 20 de ancho: antes, «Field width or number of decimal
* places is invalid» y no había cursor.
    PROCEDURE Test_JSONToCursor_MasDeVeinteDeAncho() HELP [Fact]
        THIS.oJson.JSONToCursor('[{"x":0.000000000000000000123}]', "qVuelta", SET("Datasession"))

        __assert.False(THIS.oJson.lError, THIS.oJson.cLastError)
        __assert.Equal("B", JsonFoxTiposCampo("qVuelta"))
        __assert.Equal(BINTOC(0.000000000000000000123, "B"), BINTOC(qVuelta.x, "B"))
    ENDPROC

    PROCEDURE Test_IdaVueltaIda_TrecesTipos() HELP [Fact]
        LOCAL lcIda, lcVuelta
        JsonFoxTiposTabla("qTipos")
        lcIda = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)
        THIS.oJson.JSONToCursor(lcIda, "qVuelta", SET("Datasession"))
        lcVuelta = THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.)

        __assert.False(THIS.oJson.lError, THIS.oJson.cLastError)
        __assert.Equal(lcIda, lcVuelta)
    ENDPROC

    PROCEDURE Test_Parse_Exponente() HELP [Fact]
        __assert.Equal(BINTOC(1E-7, "B"), BINTOC(THIS.oJson.Parse("1e-7"), "B"))
    ENDPROC

* Un null en la primera fila mandaba el campo al final del cursor.
    PROCEDURE Test_JSONToCursor_NullPrimeroConservaElOrden() HELP [Fact]
        LOCAL lcJson
        lcJson = '[{"a":null,"b":"x"},{"a":2,"b":"y"}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))

        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

ENDDEFINE

* La misma suite con la clase del .app. Va aparte, y no hereda de la de
* arriba, para que se lea sola. Fuera el JsonFox.prg que dejó la otra
* clase: con él en SET PROCEDURE, JSONClass encontraba sus CursorToArray
* y ArrayToCursor antes que los de src\.
DEFINE CLASS JsonFoxTiposAppTests AS Custom
    cApiRoot = "C:\Desarrollo\IrwinRodriguez.dev\JSONFox\"
    oJson = .NULL.
    cPoint = "."

    PROCEDURE SetUp() HELP []
        LOCAL lcSrc
        lcSrc = THIS.cApiRoot + "src\"
        TRY
            RELEASE PROCEDURE (THIS.cApiRoot + "JsonFox.prg")
        CATCH
        ENDTRY
        SET PROCEDURE TO (lcSrc + "JSONUtils")          ADDITIVE
        SET PROCEDURE TO (lcSrc + "Tokenizer")          ADDITIVE
        SET PROCEDURE TO (lcSrc + "Parser")             ADDITIVE
        SET PROCEDURE TO (lcSrc + "JSONStringify")      ADDITIVE
        SET PROCEDURE TO (lcSrc + "ObjectToJSON")       ADDITIVE
        SET PROCEDURE TO (lcSrc + "ArrayToCursor")      ADDITIVE
        SET PROCEDURE TO (lcSrc + "CursorToArray")      ADDITIVE
        SET PROCEDURE TO (lcSrc + "CursorToJsonObject") ADDITIVE
        SET PROCEDURE TO (lcSrc + "StructureToJSON")    ADDITIVE
        SET PROCEDURE TO (lcSrc + "JSONClass")          ADDITIVE
        IF TYPE("_Screen.oRegEx") == "U"
            ADDPROPERTY(_Screen, "oRegEx", CREATEOBJECT("VBScript.RegExp"))
            _Screen.oRegEx.global = .T.
        ENDIF
        IF TYPE("_Screen.JsonUtils") == "U"
            ADDPROPERTY(_Screen, "JsonUtils", CREATEOBJECT("JSONUtils"))
        ENDIF
        THIS.oJson = CREATEOBJECT("JSONClass")
        THIS.oJson.lShowErrors = .F.
        THIS.cPoint = SET("POINT")
    ENDPROC

    PROCEDURE TearDown() HELP []
        SET POINT TO (THIS.cPoint)
        THIS.oJson = .NULL.
        USE IN SELECT("qTipos")
        USE IN SELECT("qVuelta")
    ENDPROC

    PROCEDURE Test_App_CursorToJSON_VarbinaryYBlobEnBase64() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qTipos (q Q(4) NULL, w W NULL)
        INSERT INTO qTipos VALUES (0h41420043, 0h78797A00FF)
        INSERT INTO qTipos VALUES (0h, .NULL.)
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"q":"QUIAQw==","w":"eHl6AP8="},{"q":"","w":null}]', lcJson)
    ENDPROC

    PROCEDURE Test_App_CursorToJSON_EnteroSinDecimales() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qTipos (i I, n N(10,0))
        INSERT INTO qTipos VALUES (42, 42)
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"i":42,"n":42}]', lcJson)
    ENDPROC

    PROCEDURE Test_App_CursorToJSON_EuroEsU20AC() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qTipos (s C(5))
        INSERT INTO qTipos VALUES ("€ñéüš")
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"s":"\u20AC\u00F1\u00E9\u00FC\u0161"}]', lcJson)
    ENDPROC

    PROCEDURE Test_App_CursorToJSON_CaracteresDeControl() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qTipos (s C(4))
        INSERT INTO qTipos VALUES ("a" + CHR(1) + CHR(31) + "b")
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"s":"a\u0001\u001Fb"}]', lcJson)
    ENDPROC

    PROCEDURE Test_App_Stringify_EuroEsU20AC() HELP [Fact]
        LOCAL loObj, lcJson
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "s", "5 €")
        lcJson = THIS.oJson.Stringify(loObj)

        __assert.True('"5 \u20AC"' $ lcJson, lcJson)
    ENDPROC

    PROCEDURE Test_App_IdaYVuelta_Caracteres() HELP [Fact]
        LOCAL lcJson, loObj
        CREATE CURSOR qTipos (s C(6))
        INSERT INTO qTipos VALUES ("€ñéüšŸ")
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)
        loObj = THIS.oJson.Parse(lcJson)

        __assert.Equal("€ñéüšŸ", loObj[1].s)
    ENDPROC

    PROCEDURE Test_App_CursorToJSON_DobleMasCortoQueVuelve() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qTipos (d B(2))
        INSERT INTO qTipos VALUES (1/3)
        INSERT INTO qTipos VALUES (0.1 + 0.2)
        INSERT INTO qTipos VALUES (1E-20)
        INSERT INTO qTipos VALUES (2.5)
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"d":0.3333333333333333},{"d":0.30000000000000004},{"d":0.00000000000000000001},{"d":2.5}]', lcJson)
    ENDPROC

    PROCEDURE Test_App_CursorToJSON_DobleConComaDecimal() HELP [Fact]
        LOCAL lcJson
        SET POINT TO ','
        CREATE CURSOR qTipos (d B(2))
        INSERT INTO qTipos VALUES (0.1 + 0.2)
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)

        __assert.Equal('[{"d":0.30000000000000004}]', lcJson)
    ENDPROC

    PROCEDURE Test_App_JSONToCursor_DobleVuelveIgual() HELP [Fact]
        LOCAL lcJson, lcIda, lcVuelta
        CREATE CURSOR qTipos (d B(2))
        INSERT INTO qTipos VALUES (1/3)
        INSERT INTO qTipos VALUES (0.1 + 0.2)
        INSERT INTO qTipos VALUES (1E-20)
        INSERT INTO qTipos VALUES (0)
        lcJson = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))
        lcIda = ""
        lcVuelta = ""
        SELECT qTipos
        SCAN
            lcIda = lcIda + BINTOC(qTipos.d, "B")
        ENDSCAN
        SELECT qVuelta
        SCAN
            lcVuelta = lcVuelta + BINTOC(qVuelta.d, "B")
        ENDSCAN

        __assert.Equal("B", JsonFoxTiposCampo("qVuelta"))
        __assert.Equal(STRCONV(lcIda, 15), STRCONV(lcVuelta, 15))
    ENDPROC

    PROCEDURE Test_App_JSONToCursor_DecimalesDistintosVanAB() HELP [Fact]
        LOCAL lcJson
        lcJson = '[{"x":3.14159},{"x":0},{"x":2.5}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))

        __assert.Equal("B", JsonFoxTiposCampo("qVuelta"))
        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

    PROCEDURE Test_App_JSONToCursor_MismosDecimalesEsNumerico() HELP [Fact]
        LOCAL lcJson, laF[1]
        lcJson = '[{"x":1234.50},{"x":-0.25},{"x":null}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))
        AFIELDS(laF, "qVuelta")

        __assert.Equal("N(7,2)", laF[1, 2] + "(" + TRANSFORM(laF[1, 3]) + "," + TRANSFORM(laF[1, 4]) + ")")
        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

    PROCEDURE Test_App_JSONToCursor_NullPrimeroNoPierdeDecimales() HELP [Fact]
        LOCAL lcJson
        lcJson = '[{"x":null},{"x":3.14}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))

        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

    PROCEDURE Test_App_JSONToCursor_EnteroYDecimalNoDesbordan() HELP [Fact]
        LOCAL lcJson
        lcJson = '[{"x":12345},{"x":1.5}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))

        __assert.False(THIS.oJson.lError, THIS.oJson.LastErrorText)
        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

    PROCEDURE Test_App_JSONToCursor_Exponente() HELP [Fact]
        THIS.oJson.JSONToCursor('[{"x":1e-7},{"x":2E+3}]', "qVuelta", SET("Datasession"))

        __assert.Equal("B", JsonFoxTiposCampo("qVuelta"))
        __assert.Equal('[{"x":0.0000001},{"x":2000}]', THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

    PROCEDURE Test_App_JSONToCursor_EnteroNegativoGrande() HELP [Fact]
        LOCAL lcJson
        lcJson = '[{"x":-3000000000},{"x":7}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))

        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

    PROCEDURE Test_App_JSONToCursor_MasDeVeinteDeAncho() HELP [Fact]
        THIS.oJson.JSONToCursor('[{"x":0.000000000000000000123}]', "qVuelta", SET("Datasession"))

        __assert.False(THIS.oJson.lError, THIS.oJson.LastErrorText)
        __assert.Equal("B", JsonFoxTiposCampo("qVuelta"))
        __assert.Equal(BINTOC(0.000000000000000000123, "B"), BINTOC(qVuelta.x, "B"))
    ENDPROC

    PROCEDURE Test_App_IdaVueltaIda_TrecesTipos() HELP [Fact]
        LOCAL lcIda, lcVuelta
        JsonFoxTiposTabla("qTipos")
        lcIda = THIS.oJson.CursorToJSON("qTipos", .F., SET("Datasession"), .T.)
        THIS.oJson.JSONToCursor(lcIda, "qVuelta", SET("Datasession"))
        lcVuelta = THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.)

        __assert.False(THIS.oJson.lError, THIS.oJson.LastErrorText)
        __assert.Equal(lcIda, lcVuelta)
    ENDPROC

    PROCEDURE Test_App_Parse_Exponente() HELP [Fact]
        __assert.Equal(BINTOC(1E-7, "B"), BINTOC(THIS.oJson.Parse("1e-7"), "B"))
    ENDPROC

* Un null en la primera fila mandaba el campo al final del cursor.
    PROCEDURE Test_App_JSONToCursor_NullPrimeroConservaElOrden() HELP [Fact]
        LOCAL lcJson
        lcJson = '[{"a":null,"b":"x"},{"a":2,"b":"y"}]'
        THIS.oJson.JSONToCursor(lcJson, "qVuelta", SET("Datasession"))

        __assert.Equal(lcJson, THIS.oJson.CursorToJSON("qVuelta", .F., SET("Datasession"), .T.))
    ENDPROC

ENDDEFINE

* La tabla de los trece tipos de P6b-M0 (y un N(10,0)), con una fila
* llena y otra de NULL.
PROCEDURE JsonFoxTiposTabla
    LPARAMETERS tcAlias
    USE IN SELECT(tcAlias)
    CREATE CURSOR (tcAlias) (cc C(6) NULL, vv V(10) NULL, mm M NULL, nn N(8,2) NULL, n0 N(10,0) NULL, ;
        ff F(10,3) NULL, ii I NULL, bb B(3) NULL, yy Y NULL, dd D NULL, tt T NULL, ll L NULL, ;
        qq Q(4) NULL, ww W NULL)
    INSERT INTO (tcAlias) VALUES ("Muñoz", "€ñéü", "a" + CRLF + "b", 1234.5, 42, 3.125, 42, 3.14159, ;
        19.99, {^1990-05-17}, {^2026-10-30 10:20:30}, .T., 0h41420043, 0h78797A00FF)
    INSERT INTO (tcAlias) VALUES (.NULL., .NULL., .NULL., .NULL., .NULL., .NULL., .NULL., .NULL., ;
        .NULL., .NULL., .NULL., .NULL., .NULL., .NULL.)
ENDPROC

* El tipo del primer campo, de AFIELDS: TYPE() de un campo B da "N".
FUNCTION JsonFoxTiposCampo
    LPARAMETERS tcAlias
    LOCAL laF[1]
    AFIELDS(laF, tcAlias)
    RETURN laF[1, 2]
ENDFUNC
