* ==================================================================
* JsonFoxIssue66Tests.prg
*
* Lo que afirma esta suite: los tres arreglos que salieron de la
* revisión de Hernán Cano en el issue #66 de JSONFox (octubre de 2026).
*
*   1. Un campo Double (tipo B) sale en CursorToJSON como número. Antes
*      estaba en el grupo de las cadenas, GetString convertía el número
*      en "" y el JSON llevaba "d":"" en lugar de "d":3.25.
*
*   2. MasterDetailToJSON conserva su propio error. Rellenaba lError y
*      luego llamaba a Stringify (Encode en la clase del .app), que
*      empieza con ResetError y lo borraba: el llamante veía lError .F.
*
*   3. GetString con tlParseUTF8 deja &, +, -, # y % como están. Había
*      cinco STRTRAN que cambiaban cada carácter por sí mismo; se
*      quitaron y este test sujeta que la salida no cambia.
*
* Dos clases: la del autocontenido (JsonFox.prg, lo que se distribuye
* como .fxp) y la del .app (JSONClass, cargada desde src\).
*
* cApiRoot: ruta al proyecto. Ajustar si se mueve.
* ==================================================================

DEFINE CLASS JsonFoxIssue66Tests AS Custom
    cApiRoot = "C:\Desarrollo\IrwinRodriguez.dev\JSONFox\"
    oJson = .NULL.

    PROCEDURE SetUp() HELP []
        LOCAL lcRoot
        lcRoot = THIS.cApiRoot
        SET PATH TO (lcRoot) ADDITIVE
        SET PROCEDURE TO (lcRoot + "JsonFox.prg") ADDITIVE
        THIS.oJson = CREATEOBJECT("JSONFox")
    ENDPROC

    PROCEDURE TearDown() HELP []
        THIS.oJson = .NULL.
        USE IN SELECT("qDoble")
    ENDPROC

    PROCEDURE Test_CursorToJSON_CampoDobleEsUnNumero() HELP [Fact]
        LOCAL lcJson
        CREATE CURSOR qDoble (id I, d B(2))
        INSERT INTO qDoble VALUES (1, 3.25)
        lcJson = THIS.oJson.CursorToJSON("qDoble", .F., SET("Datasession"), .T.)

        __assert.False(THIS.oJson.lError, THIS.oJson.cLastError)
        __assert.True('"d":3.25' $ lcJson, lcJson)
        __assert.False('"d":""' $ lcJson, "el Double no es una cadena vacía")
    ENDPROC

    PROCEDURE Test_MasterDetailToJSON_ConservaSuError() HELP [Fact]
        THIS.oJson.MasterDetailToJSON("qMaestroQueNoExiste", "qDetalle", "1=1", "detalle", SET("Datasession"))

        __assert.True(THIS.oJson.lError, "un maestro que no existe deja lError")
        __assert.NotEmpty(THIS.oJson.cLastError, "y el mensaje")
    ENDPROC

    PROCEDURE Test_Stringify_ParseUtf8DejaLosSignosComoEstan() HELP [Fact]
        LOCAL loObj, lcJson
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "s", "a&b+c-d#e%f")
        lcJson = THIS.oJson.Stringify(loObj, "", .T., .T.)

        __assert.True('"a&b+c-d#e%f"' $ lcJson, lcJson)
    ENDPROC

ENDDEFINE

DEFINE CLASS JsonFoxIssue66AppTests AS Custom
    cApiRoot = "C:\Desarrollo\IrwinRodriguez.dev\JSONFox\"
    oJson = .NULL.

    PROCEDURE SetUp() HELP []
        LOCAL lcSrc
        lcSrc = THIS.cApiRoot + "src\"
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
    ENDPROC

    PROCEDURE TearDown() HELP []
        THIS.oJson = .NULL.
    ENDPROC

    PROCEDURE Test_App_MasterDetailToJSON_ConservaSuError() HELP [Fact]
        THIS.oJson.MasterDetailToJSON("qMaestroQueNoExiste", "qDetalle", "1=1", "detalle", SET("Datasession"))

        __assert.True(THIS.oJson.lError, "un maestro que no existe deja lError")
        __assert.NotEmpty(THIS.oJson.LastErrorText, "y el mensaje")
    ENDPROC

ENDDEFINE
