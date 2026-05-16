* test_jsonfox_app.prg
* Test suite for JSONFox APP version (access via _Screen.Json)
* Run: foxunit run --prg tests\test_jsonfox_app.prg --format console

#define PROJ_ROOT "C:\Desarrollo\IrwinRodriguez.dev\JSONFox"

* ============================================================ *
* TestJSONFoxAppParse
* ============================================================ *
DEFINE CLASS TestJSONFoxAppParse AS Custom

    PROCEDURE SetUp
        SET DEFAULT TO (PROJ_ROOT)
        SET PROCEDURE TO "src\JSONUtils"          ADDITIVE
        SET PROCEDURE TO "src\Tokenizer"          ADDITIVE
        SET PROCEDURE TO "src\Parser"             ADDITIVE
        SET PROCEDURE TO "src\JSONStringify"      ADDITIVE
        SET PROCEDURE TO "src\ObjectToJSON"       ADDITIVE
        SET PROCEDURE TO "src\ArrayToCursor"      ADDITIVE
        SET PROCEDURE TO "src\CursorToArray"      ADDITIVE
        SET PROCEDURE TO "src\CursorToJsonObject" ADDITIVE
        SET PROCEDURE TO "src\StructureToJSON"    ADDITIVE
        SET PROCEDURE TO "src\JSONClass"          ADDITIVE
        IF TYPE("_Screen.oRegEx") == "U"
            ADDPROPERTY(_Screen, "oRegEx", CREATEOBJECT("VBScript.RegExp"))
            _Screen.oRegEx.global = .T.
        ENDIF
        IF TYPE("_Screen.JsonUtils") == "U"
            ADDPROPERTY(_Screen, "JsonUtils", CREATEOBJECT("JSONUtils"))
        ENDIF
        IF TYPE("_Screen.Json") == "U"
            ADDPROPERTY(_Screen, "Json", CREATEOBJECT("JSONClass"))
        ENDIF
    ENDPROC

    PROCEDURE TearDown
        TRY
            REMOVEPROPERTY(_Screen, "Json")
        CATCH
        ENDTRY
        TRY
            REMOVEPROPERTY(_Screen, "JsonUtils")
        CATCH
        ENDTRY
        TRY
            REMOVEPROPERTY(_Screen, "oRegEx")
        CATCH
        ENDTRY
    ENDPROC

    PROCEDURE TestParseSimpleObject() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = _Screen.Json.Parse('{"name":"JSONFox","version":13}')
        __assert.IsObject(loObj)
        __assert.Equal("JSONFox", loObj.name)
        __assert.Equal(13, loObj.version)
    ENDPROC

    PROCEDURE TestParseNestedObject() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = _Screen.Json.Parse('{"person":{"name":"Irwin","age":40}}')
        __assert.IsObject(loObj)
        __assert.IsObject(loObj.person)
        __assert.Equal("Irwin", loObj.person.name)
        __assert.Equal(40, loObj.person.age)
    ENDPROC

    PROCEDURE TestParseArray() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loArr
        loArr = _Screen.Json.Parse("[1,2,3]")
        __assert.IsObject(loArr)
        __assert.Equal(3, loArr.count)
        __assert.Equal(1, loArr.item(1))
        __assert.Equal(3, loArr.item(3))
    ENDPROC

    PROCEDURE TestParseBooleanAndNull() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = _Screen.Json.Parse('{"active":true,"deleted":false,"data":null}')
        __assert.True(loObj.active)
        __assert.False(loObj.deleted)
        __assert.True(ISNULL(loObj.data))
    ENDPROC

    PROCEDURE TestParseFloat() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = _Screen.Json.Parse('{"price":19.99}')
        __assert.True(ABS(loObj.price - 19.99) < 0.001, "Float should be ~19.99")
    ENDPROC

    PROCEDURE TestParseScientificNotation() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = _Screen.Json.Parse('{"val":1.5e2}')
        __assert.True(ABS(loObj.val - 150) < 0.001, "1.5e2 should equal 150")
    ENDPROC

    PROCEDURE TestParseEmptyObject() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = _Screen.Json.Parse("{}")
        __assert.IsObject(loObj)
    ENDPROC

    PROCEDURE TestParseEmptyArray() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loArr
        loArr = _Screen.Json.Parse("[]")
        __assert.IsObject(loArr)
        __assert.Equal(0, loArr.count)
    ENDPROC

    PROCEDURE TestParseInvalidJsonSetsError() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loResult, lbError
        _Screen.Json.lShowErrors = .F.
        lbError = .F.
        TRY
            loResult = _Screen.Json.Parse("{ bad json !! }")
            lbError  = _Screen.Json.lError
        CATCH
            lbError = .T.
        ENDTRY
        __assert.True(lbError, "Bad JSON must set lError or throw")
    ENDPROC

ENDDEFINE


* ============================================================ *
* TestJSONFoxAppStringify
* ============================================================ *
DEFINE CLASS TestJSONFoxAppStringify AS Custom

    PROCEDURE SetUp
        SET DEFAULT TO (PROJ_ROOT)
        SET PROCEDURE TO "src\JSONUtils"          ADDITIVE
        SET PROCEDURE TO "src\Tokenizer"          ADDITIVE
        SET PROCEDURE TO "src\Parser"             ADDITIVE
        SET PROCEDURE TO "src\JSONStringify"      ADDITIVE
        SET PROCEDURE TO "src\ObjectToJSON"       ADDITIVE
        SET PROCEDURE TO "src\ArrayToCursor"      ADDITIVE
        SET PROCEDURE TO "src\CursorToArray"      ADDITIVE
        SET PROCEDURE TO "src\CursorToJsonObject" ADDITIVE
        SET PROCEDURE TO "src\StructureToJSON"    ADDITIVE
        SET PROCEDURE TO "src\JSONClass"          ADDITIVE
        IF TYPE("_Screen.oRegEx") == "U"
            ADDPROPERTY(_Screen, "oRegEx", CREATEOBJECT("VBScript.RegExp"))
            _Screen.oRegEx.global = .T.
        ENDIF
        IF TYPE("_Screen.JsonUtils") == "U"
            ADDPROPERTY(_Screen, "JsonUtils", CREATEOBJECT("JSONUtils"))
        ENDIF
        IF TYPE("_Screen.Json") == "U"
            ADDPROPERTY(_Screen, "Json", CREATEOBJECT("JSONClass"))
        ENDIF
    ENDPROC

    PROCEDURE TearDown
        TRY
            REMOVEPROPERTY(_Screen, "Json")
        CATCH
        ENDTRY
        TRY
            REMOVEPROPERTY(_Screen, "JsonUtils")
        CATCH
        ENDTRY
        TRY
            REMOVEPROPERTY(_Screen, "oRegEx")
        CATCH
        ENDTRY
    ENDPROC

    PROCEDURE TestStringifySimpleJson() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL lcResult
        lcResult = _Screen.Json.Stringify('{"name":"JSONFox","version":13}')
        __assert.NotEmpty(lcResult)
        __assert.True('"name"' $ lcResult, "Should contain key name")
        __assert.True('"JSONFox"' $ lcResult, "Should contain value JSONFox")
    ENDPROC

    PROCEDURE TestStringifyObject() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL loObj, lcResult
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "lang", "VFP")
        ADDPROPERTY(loObj, "year", 1992)
        lcResult = _Screen.Json.Stringify(@loObj)
        __assert.NotEmpty(lcResult)
        __assert.True('"lang"' $ lcResult)
        __assert.True('"VFP"'  $ lcResult)
    ENDPROC

    PROCEDURE TestRoundTrip() HELP [Fact, Trait("Category", "RoundTrip")]
        LOCAL loObj, lcJson, loBack
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "key", "value")
        ADDPROPERTY(loObj, "num", 42)
        lcJson = _Screen.Json.Stringify(@loObj)
        loBack = _Screen.Json.Parse(lcJson)
        __assert.Equal("value", loBack.key)
        __assert.Equal(42,      loBack.num)
    ENDPROC

ENDDEFINE


* ============================================================ *
* TestJSONFoxAppCursor
* ============================================================ *
DEFINE CLASS TestJSONFoxAppCursor AS Custom

    PROCEDURE SetUp
        SET DEFAULT TO (PROJ_ROOT)
        SET PROCEDURE TO "src\JSONUtils"          ADDITIVE
        SET PROCEDURE TO "src\Tokenizer"          ADDITIVE
        SET PROCEDURE TO "src\Parser"             ADDITIVE
        SET PROCEDURE TO "src\JSONStringify"      ADDITIVE
        SET PROCEDURE TO "src\ObjectToJSON"       ADDITIVE
        SET PROCEDURE TO "src\ArrayToCursor"      ADDITIVE
        SET PROCEDURE TO "src\CursorToArray"      ADDITIVE
        SET PROCEDURE TO "src\CursorToJsonObject" ADDITIVE
        SET PROCEDURE TO "src\StructureToJSON"    ADDITIVE
        SET PROCEDURE TO "src\JSONClass"          ADDITIVE
        IF TYPE("_Screen.oRegEx") == "U"
            ADDPROPERTY(_Screen, "oRegEx", CREATEOBJECT("VBScript.RegExp"))
            _Screen.oRegEx.global = .T.
        ENDIF
        IF TYPE("_Screen.JsonUtils") == "U"
            ADDPROPERTY(_Screen, "JsonUtils", CREATEOBJECT("JSONUtils"))
        ENDIF
        IF TYPE("_Screen.Json") == "U"
            ADDPROPERTY(_Screen, "Json", CREATEOBJECT("JSONClass"))
        ENDIF
    ENDPROC

    PROCEDURE TearDown
        CLOSE TABLES ALL
        TRY
            REMOVEPROPERTY(_Screen, "Json")
        CATCH
        ENDTRY
        TRY
            REMOVEPROPERTY(_Screen, "JsonUtils")
        CATCH
        ENDTRY
        TRY
            REMOVEPROPERTY(_Screen, "oRegEx")
        CATCH
        ENDTRY
    ENDPROC

    PROCEDURE TestJsonToCursor() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lcJson
        lcJson = '[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]'
        _Screen.Json.JSONToCursor(lcJson, "qTest", SET("Datasession"))
        __assert.True(USED("qTest"), "Cursor qTest should be open")
        __assert.Equal(2, RECCOUNT("qTest"))
        SELECT qTest
        GO TOP
        __assert.Equal(1, qTest.id)
        __assert.Equal("Alice", ALLTRIM(qTest.name))
    ENDPROC

    PROCEDURE TestCursorToJson() HELP [Fact, Trait("Category", "Cursor")]
        CREATE CURSOR qProd (id I, name C(20))
        INSERT INTO qProd VALUES (1, "Producto A")
        INSERT INTO qProd VALUES (2, "Producto B")
        LOCAL lcJson
        lcJson = _Screen.Json.CursorToJSON("qProd", .F., SET("Datasession"), .T.)
        __assert.NotEmpty(lcJson)
        __assert.True('"id"' $ lcJson)
        __assert.True("Producto A" $ lcJson)
    ENDPROC

    PROCEDURE TestCursorRoundTrip() HELP [Fact, Trait("Category", "Cursor")]
        CREATE CURSOR qOrig (sku C(10), qty I, price N(10,2))
        INSERT INTO qOrig VALUES ("SKU-001", 5, 99.99)
        INSERT INTO qOrig VALUES ("SKU-002", 3, 19.50)
        LOCAL lcJson
        lcJson = _Screen.Json.CursorToJSON("qOrig", .F., SET("Datasession"), .T.)
        _Screen.Json.JSONToCursor(lcJson, "qBack", SET("Datasession"))
        __assert.True(USED("qBack"))
        __assert.Equal(RECCOUNT("qOrig"), RECCOUNT("qBack"))
    ENDPROC

    PROCEDURE TestJsonToCursorInvalidJson() HELP [Fact, Trait("Category", "Cursor")]
        _Screen.Json.lShowErrors = .F.
        LOCAL lbError
        lbError = .F.
        TRY
            _Screen.Json.JSONToCursor("not valid", "qBad", SET("Datasession"))
            lbError = _Screen.Json.lError
        CATCH
            lbError = .T.
        ENDTRY
        __assert.True(lbError, "Invalid JSON should set lError or throw")
    ENDPROC

ENDDEFINE
