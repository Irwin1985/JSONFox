* test_jsonfox_standalone.prg
* Test suite for the standalone JSONFox.fxp version
* Requires: DO build_jsonfox.prg first (or run test_build.prg)
* Run: foxunit run --prg tests\test_jsonfox_standalone.prg --format console

#define PROJ_ROOT "C:\Desarrollo\IrwinRodriguez.dev\JSONFox"
#define FXP_PATH  "C:\Desarrollo\IrwinRodriguez.dev\JSONFox\JsonFox.fxp"

* ============================================================ *
* TestStandaloneParse
* ============================================================ *
DEFINE CLASS TestStandaloneParse AS Custom

    oJson = .NULL.

    PROCEDURE SetUp
        SET DEFAULT TO (PROJ_ROOT)
        this.oJson = NEWOBJECT("JSONFox", FXP_PATH)
        __assert.IsObject(this.oJson, "JSONFox must instantiate correctly")
    ENDPROC

    PROCEDURE TearDown
        this.oJson = .NULL.
    ENDPROC

    PROCEDURE TestParseSimpleObject() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"name":"JSONFox","version":13}')
        __assert.IsObject(loObj)
        __assert.Equal("JSONFox", loObj.name)
        __assert.Equal(13, loObj.version)
    ENDPROC

    PROCEDURE TestParseNestedObject() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"person":{"name":"Irwin","age":40}}')
        __assert.IsObject(loObj)
        __assert.IsObject(loObj.person)
        __assert.Equal("Irwin", loObj.person.name)
        __assert.Equal(40, loObj.person.age)
    ENDPROC

    PROCEDURE TestParseArray() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loArr
        loArr = this.oJson.Parse("[1,2,3]")
        __assert.IsObject(loArr)
        __assert.Equal(3, loArr.count)
        __assert.Equal(1, loArr.item(1))
        __assert.Equal(3, loArr.item(3))
    ENDPROC

    PROCEDURE TestParseBooleanAndNull() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"active":true,"deleted":false,"data":null}')
        __assert.True(loObj.active)
        __assert.False(loObj.deleted)
        __assert.True(ISNULL(loObj.data))
    ENDPROC

    PROCEDURE TestParseFloat() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"price":19.99}')
        __assert.True(ABS(loObj.price - 19.99) < 0.001, "Float should be ~19.99")
    ENDPROC

    PROCEDURE TestParseScientificNotation() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"val":1.5e2}')
        __assert.True(ABS(loObj.val - 150) < 0.001, "1.5e2 should equal 150")
    ENDPROC

    PROCEDURE TestParseNegativeNumber() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"balance":-42.5}')
        __assert.True(ABS(loObj.balance - (-42.5)) < 0.001)
    ENDPROC

    PROCEDURE TestParseStringWithEscapes() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"msg":"line1\nline2\ttab"}')
        __assert.NotEmpty(loObj.msg)
        __assert.True(CHR(10) $ loObj.msg, "Should contain newline")
        __assert.True(CHR(9)  $ loObj.msg, "Should contain tab")
    ENDPROC

    PROCEDURE TestParseEmptyObject() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse("{}")
        __assert.IsObject(loObj)
        __assert.False(this.oJson.lError)
    ENDPROC

    PROCEDURE TestParseEmptyArray() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loArr
        loArr = this.oJson.Parse("[]")
        __assert.IsObject(loArr)
        __assert.Equal(0, loArr.count)
    ENDPROC

    PROCEDURE TestParseArrayOfObjects() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loArr
        loArr = this.oJson.Parse('[{"x":1},{"x":2},{"x":3}]')
        __assert.IsObject(loArr)
        __assert.Equal(3, loArr.count)
        __assert.Equal(1, loArr.item(1).x)
        __assert.Equal(3, loArr.item(3).x)
    ENDPROC

    PROCEDURE TestInvalidJsonThrowsOrSetsError() HELP [Fact, Trait("Category", "ErrorHandling")]
        LOCAL loResult, lbErrorSet
        lbErrorSet = .F.
        TRY
            loResult   = this.oJson.Parse("{ bad json !! }")
            lbErrorSet = this.oJson.lError
        CATCH
            lbErrorSet = .T.
        ENDTRY
        __assert.True(lbErrorSet, "Malformed JSON must set lError or throw")
    ENDPROC

    PROCEDURE TestErrorFlagsResetBetweenCalls() HELP [Fact, Trait("Category", "ErrorHandling")]
        TRY
            this.oJson.Parse("{{{{")
        CATCH
        ENDTRY
        LOCAL loObj
        loObj = this.oJson.Parse('{"ok":true}')
        __assert.True(loObj.ok)
        __assert.False(this.oJson.lError, "lError must be reset after successful Parse")
    ENDPROC

ENDDEFINE


* ============================================================ *
* TestStandaloneStringify
* ============================================================ *
DEFINE CLASS TestStandaloneStringify AS Custom

    oJson = .NULL.

    PROCEDURE SetUp
        SET DEFAULT TO (PROJ_ROOT)
        this.oJson = NEWOBJECT("JSONFox", FXP_PATH)
    ENDPROC

    PROCEDURE TearDown
        this.oJson = .NULL.
    ENDPROC

    PROCEDURE TestStringifyJson() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL lcResult
        lcResult = this.oJson.Stringify('{"name":"JSONFox","version":13}')
        __assert.NotEmpty(lcResult)
        __assert.True('"name"' $ lcResult)
        __assert.True('"JSONFox"' $ lcResult)
    ENDPROC

    PROCEDURE TestStringifyObject() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL loObj, lcResult
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "lang", "VFP")
        ADDPROPERTY(loObj, "year", 1992)
        lcResult = this.oJson.Stringify(@loObj)
        __assert.NotEmpty(lcResult)
        __assert.True('"lang"' $ lcResult)
        __assert.True('"VFP"'  $ lcResult)
        __assert.True("1992"   $ lcResult)
    ENDPROC

    PROCEDURE TestRoundTrip() HELP [Fact, Trait("Category", "RoundTrip")]
        LOCAL loObj, lcJson, loBack
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "key",  "value")
        ADDPROPERTY(loObj, "num",  42)
        ADDPROPERTY(loObj, "flag", .T.)
        lcJson = this.oJson.Stringify(@loObj)
        loBack = this.oJson.Parse(lcJson)
        __assert.Equal("value", loBack.key)
        __assert.Equal(42,      loBack.num)
        __assert.True(loBack.flag)
    ENDPROC

    PROCEDURE TestStringifyNull() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL loObj, lcResult
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "data", .NULL.)
        lcResult = this.oJson.Stringify(@loObj)
        __assert.True("null" $ lcResult)
    ENDPROC

ENDDEFINE


* ============================================================ *
* TestStandaloneCursor
* ============================================================ *
DEFINE CLASS TestStandaloneCursor AS Custom

    oJson = .NULL.

    PROCEDURE SetUp
        SET DEFAULT TO (PROJ_ROOT)
        this.oJson = NEWOBJECT("JSONFox", FXP_PATH)
    ENDPROC

    PROCEDURE TearDown
        CLOSE TABLES ALL
        this.oJson = .NULL.
    ENDPROC

    PROCEDURE TestJsonToCursor() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lcJson, lnSess
        lnSess = SET("Datasession")
        lcJson = '[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]'
        this.oJson.JSONToCursor(lcJson, "qTest", lnSess)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.True(USED("qTest"), "Cursor qTest should be open")
        __assert.Equal(2, RECCOUNT("qTest"))
        SELECT qTest
        GO TOP
        __assert.Equal(1,       qTest.id)
        __assert.Equal("Alice", ALLTRIM(qTest.name))
    ENDPROC

    PROCEDURE TestCursorToJson() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lcJson, lnSess
        lnSess = SET("Datasession")
        CREATE CURSOR qProd (id I, name C(20))
        INSERT INTO qProd VALUES (1, "Product A")
        INSERT INTO qProd VALUES (2, "Product B")
        lcJson = this.oJson.CursorToJSON("qProd", .F., lnSess, .T.)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.NotEmpty(lcJson)
        __assert.True('"id"' $ lcJson)
        __assert.True("Product A" $ lcJson)
    ENDPROC

    PROCEDURE TestCursorRoundTrip() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lcJson, lnSess, lnCount
        lnSess = SET("Datasession")
        CREATE CURSOR qOrig (sku C(10), qty I, price N(10,2))
        INSERT INTO qOrig VALUES ("SKU-001", 5, 99.99)
        INSERT INTO qOrig VALUES ("SKU-002", 3, 19.50)
        lnCount = RECCOUNT("qOrig")
        lcJson = this.oJson.CursorToJSON("qOrig", .F., lnSess, .T.)
        __assert.NotEmpty(lcJson)
        this.oJson.JSONToCursor(lcJson, "qBack", lnSess)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.True(USED("qBack"))
        __assert.Equal(lnCount, RECCOUNT("qBack"))
    ENDPROC

    PROCEDURE TestCursorToJsonCurrentRow() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lcJson, lnSess
        lnSess = SET("Datasession")
        CREATE CURSOR qItems (id I, name C(20))
        INSERT INTO qItems VALUES (1, "Alfa")
        INSERT INTO qItems VALUES (2, "Beta")
        SELECT qItems
        GO TOP
        SKIP
        lcJson = this.oJson.CursorToJSON("qItems", .T., lnSess, .T.)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.True("Beta" $ lcJson, "Must contain current row Beta")
        __assert.False("Alfa" $ lcJson, "Must not contain first row Alfa")
    ENDPROC

    PROCEDURE TestJsonToCursorInvalidJson() HELP [Fact, Trait("Category", "ErrorHandling")]
        LOCAL lbError
        lbError = .F.
        TRY
            this.oJson.JSONToCursor("not valid", "qBad", SET("Datasession"))
            lbError = this.oJson.lError
        CATCH
            lbError = .T.
        ENDTRY
        __assert.True(lbError, "Invalid JSON should set lError or throw")
    ENDPROC

    PROCEDURE TestUnknownCursorSetsError() HELP [Fact, Trait("Category", "ErrorHandling")]
        this.oJson.CursorToJSON("qNonExistent", .F., SET("Datasession"), .T.)
        __assert.True(this.oJson.lError, "Unknown cursor must set lError")
        __assert.NotEmpty(this.oJson.cLastError)
    ENDPROC

    PROCEDURE TestCursorStructure() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lcResult, lnSess
        lnSess = SET("Datasession")
        CREATE CURSOR qStruct (id I, name C(30), active L, price N(10,2))
        lcResult = this.oJson.CursorStructure("qStruct", lnSess, .F., .F.)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.NotEmpty(lcResult)
        __assert.True('"qstruct"' $ LOWER(lcResult))
    ENDPROC

ENDDEFINE


* ============================================================ *
* TestStandaloneUnattended
* ============================================================ *
DEFINE CLASS TestStandaloneUnattended AS Custom

    oJson = .NULL.

    PROCEDURE SetUp
        SET DEFAULT TO (PROJ_ROOT)
        this.oJson = NEWOBJECT("JSONFox", FXP_PATH)
    ENDPROC

    PROCEDURE TearDown
        this.oJson = .NULL.
    ENDPROC

    PROCEDURE TestNoScreenPropsCreated() HELP [Fact, Trait("Category", "Unattended")]
        __assert.True(TYPE("_Screen.Json")      == "U", "_Screen.Json must not exist")
        __assert.True(TYPE("_Screen.JsonUtils") == "U", "_Screen.JsonUtils must not exist")
    ENDPROC

    PROCEDURE TestLErrorAndCLastError() HELP [Fact, Trait("Category", "Unattended")]
        this.oJson.CursorToJSON("qNoExiste", .F., SET("Datasession"), .T.)
        __assert.True(this.oJson.lError,     "lError should be .T.")
        __assert.NotEmpty(this.oJson.cLastError)
    ENDPROC

    PROCEDURE TestLErrorResetOnSuccess() HELP [Fact, Trait("Category", "Unattended")]
        this.oJson.CursorToJSON("qNoExiste", .F., SET("Datasession"), .T.)
        LOCAL loObj
        loObj = this.oJson.Parse('{"ok":true}')
        __assert.False(this.oJson.lError)
    ENDPROC

    PROCEDURE TestMultipleInstancesIndependent() HELP [Fact, Trait("Category", "Unattended")]
        LOCAL o1, o2, loObj1, loObj2
        o1 = NEWOBJECT("JSONFox", FXP_PATH)
        o2 = NEWOBJECT("JSONFox", FXP_PATH)
        loObj1 = o1.Parse('{"src":"one"}')
        loObj2 = o2.Parse('{"src":"two"}')
        __assert.Equal("one", loObj1.src)
        __assert.Equal("two", loObj2.src)
        __assert.False(o1.lError)
        __assert.False(o2.lError)
    ENDPROC

    PROCEDURE TestVersionProperty() HELP [Fact, Trait("Category", "Unattended")]
        __assert.NotEmpty(this.oJson.version)
        __assert.True("13" $ this.oJson.version)
    ENDPROC

ENDDEFINE
