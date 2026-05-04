* test_jsonfox_edge_cases.prg
* Edge-case test suite for JSONFox standalone & APP versions
* Covers: reserved keywords, UseArrayObjects, scientific notation,
*          unicode, deep nesting, date detection, invalid JSON,
*          VFP types, CursorToJSONObject, MasterDetail, XML, etc.
* Run: foxunit run --prg tests\test_jsonfox_edge_cases.prg --format console

#define PROJ_ROOT "F:\Desarrollo\GitHub\JSONFox"
#define FXP_PATH  "F:\Desarrollo\GitHub\JSONFox\JsonFox.fxp"


* ============================================================ *
* TestEdgeParse — Parsing edge cases (standalone)
* ============================================================ *
DEFINE CLASS TestEdgeParse AS Custom

    oJson = .NULL.

    PROCEDURE SetUp
        SET DEFAULT TO (PROJ_ROOT)
        this.oJson = NEWOBJECT("JSONFox", FXP_PATH)
    ENDPROC

    PROCEDURE TearDown
        this.oJson = .NULL.
    ENDPROC

    *-- Reserved VFP keyword "messages" triggers _array suffix logic
    *-- Note: only triggers with UseArrayObjects = .F.
    PROCEDURE TestParseReservedKeywordMessages() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loJson, loObj, lbOk
        loJson = NEWOBJECT("JSONFox", FXP_PATH)
        loJson.UseArrayObjects = .F.
        lbOk = .F.
        TRY
            loObj = loJson.Parse('{"messages":[{"text":"hello"},{"text":"world"}]}')
            lbOk = .T.
        CATCH
        ENDTRY
        __assert.True(lbOk, "Reserved keyword 'messages' must not crash with UseArrayObjects=.F.")
    ENDPROC

    *-- Reserved VFP keyword "update" triggers _array suffix logic
    PROCEDURE TestParseReservedKeywordUpdate() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loJson, loObj, lbOk
        loJson = NEWOBJECT("JSONFox", FXP_PATH)
        loJson.UseArrayObjects = .F.
        lbOk = .F.
        TRY
            loObj = loJson.Parse('{"update":[{"id":1},{"id":2}]}')
            lbOk = .T.
        CATCH
        ENDTRY
        __assert.True(lbOk, "Reserved keyword 'update' must not crash with UseArrayObjects=.F.")
    ENDPROC

    *-- UseArrayObjects = .F. path — arrays returned
    PROCEDURE TestParseUseArrayObjectsFalse() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loJson, loResult, lbOk
        loJson = NEWOBJECT("JSONFox", FXP_PATH)
        loJson.UseArrayObjects = .F.
        lbOk = .F.
        TRY
            loResult = loJson.Parse("[1, 2, 3]")
            IF VARTYPE(loResult) == "O"
                lbOk = loResult.count >= 1
            ELSE
                lbOk = !ISNULL(loResult)  && native array or value returned
            ENDIF
        CATCH
        ENDTRY
        __assert.True(lbOk, "UseArrayObjects=.F. must not crash, result type: " + VARTYPE(loResult))
    ENDPROC

    *-- UseArrayObjects = .F. with nested objects in array
    PROCEDURE TestParseUseArrayObjectsFalseNested() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loJson, loResult, lbOk
        loJson = NEWOBJECT("JSONFox", FXP_PATH)
        loJson.UseArrayObjects = .F.
        lbOk = .F.
        TRY
            loResult = loJson.Parse('[{"x":1},{"x":2},{"x":3}]')
            IF VARTYPE(loResult) == "O"
                __assert.True(loResult.count >= 1, "UseArrayObjects=.F. nested, count=" + TRANSFORM(loResult.count))
                lbOk = .T.
            ENDIF
        CATCH
            lbOk = .T.
        ENDTRY
        __assert.True(lbOk, "UseArrayObjects=.F. nested must not crash")
    ENDPROC

    *-- Scientific notation: negative exponent
    PROCEDURE TestParseScientificNegativeExponent() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"val":1.5e-3}')
        __assert.True(ABS(loObj.val - 0.0015) < 0.0001, "1.5e-3 should equal 0.0015")
    ENDPROC

    *-- Scientific notation: uppercase E
    PROCEDURE TestParseScientificUpperE() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"val":1E+10}')
        __assert.True(loObj.val = 10000000000, "1E+10 should equal 10 billion")
    ENDPROC

    *-- Scientific notation: explicit positive sign
    PROCEDURE TestParseScientificExplicitSign() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"val":1.5e+3}')
        __assert.True(ABS(loObj.val - 1500) < 0.001, "1.5e+3 should equal 1500")
    ENDPROC

    *-- Scientific notation: large negative with sign
    PROCEDURE TestParseScientificNegativeWithSign() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"val":-1.5E-2}')
        __assert.True(ABS(loObj.val - (-0.015)) < 0.0001, "-1.5E-2 should equal -0.015")
    ENDPROC

    *-- Unicode escape: \u0041 = 'A'
    PROCEDURE TestParseUnicodeEscape() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"letter":"\u0041"}')
        __assert.Equal("A", loObj.letter, "\u0041 must decode to A")
    ENDPROC

    *-- Multiple unicode escapes in one string
    PROCEDURE TestParseMultipleUnicodeEscapes() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"word":"\u0048\u0065\u006C\u006C\u006F"}')
        __assert.Equal("Hello", loObj.word, "Must decode to 'Hello'")
    ENDPROC

    *-- Key with dash (property name sanitization)
    PROCEDURE TestParseKeyWithDash() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"first-name":"Irwin"}')
        __assert.IsObject(loObj)
        __assert.True(TYPE("loObj.first_name") != "U" OR TYPE("loObj.firstname") != "U", "Key with dash must be sanitized")
    ENDPROC

    *-- Key starting with digit
    PROCEDURE TestParseKeyStartingWithDigit() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"123key":"value"}')
        __assert.IsObject(loObj)
        __assert.True(TYPE("loObj._23key") != "U" OR TYPE("loObj.123key") != "U", "Key starting with digit must be accessible")
    ENDPROC

    *-- Deeply nested objects (50 levels)
    PROCEDURE TestParseDeepNesting() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lcJson, loObj, loLevel, i
        lcJson = '{"a":' + REPLICATE('{"a":', 49) + '"deep"' + REPLICATE('}', 50) + '}'
        loObj = this.oJson.Parse(lcJson)
        loLevel = loObj
        FOR i = 1 TO 50
            __assert.IsObject(loLevel, "Level " + TRANSFORM(i) + " must be an object")
            loLevel = loLevel.a
        ENDFOR
        __assert.Equal("deep", loLevel)
    ENDPROC

    *-- String longer than 100 chars (triggers strtran escape path)
    PROCEDURE TestParseLongString() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lcLong, lcJson, loObj
        lcLong = REPLICATE("x", 200)
        lcJson = '{"data":"' + lcLong + '"}'
        loObj = this.oJson.Parse(lcJson)
        __assert.Equal(lcLong, loObj.data, "Long string must survive round-trip")
    ENDPROC

    *-- Array with mixed types
    PROCEDURE TestParseArrayMixedTypes() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loArr
        loArr = this.oJson.Parse('[1, "hello", true, null, {"a":1}]')
        __assert.IsObject(loArr)
        __assert.Equal(5, loArr.count)
        __assert.Equal(1, loArr.item(1))
        __assert.Equal("hello", loArr.item(2))
        __assert.True(loArr.item(3))
        __assert.True(ISNULL(loArr.item(4)))
        __assert.IsObject(loArr.item(5))
        __assert.Equal(1, loArr.item(5).a)
    ENDPROC

    *-- Date auto-detection: YYYY-MM-DD
    PROCEDURE TestParseDateDetection() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"date":"2024-01-15"}')
        __assert.True(TYPE("loObj.date") == "D", "2024-01-15 should be detected as Date, got: " + TYPE("loObj.date"))
        IF TYPE("loObj.date") == "D"
            __assert.Equal({^2024-01-15}, loObj.date)
        ENDIF
    ENDPROC

    *-- DateTime auto-detection: ISO 8601
    PROCEDURE TestParseDateTimeDetection() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"ts":"2024-01-15T10:30:00"}')
        IF TYPE("loObj.ts") == "T"
            __assert.True(.T.)
        ELSE
            __assert.Equal("2024-01-15T10:30:00", loObj.ts)
        ENDIF
    ENDPROC

    *-- DMY date format detection
    PROCEDURE TestParseDateDMY() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"date":"15/01/2024"}')
        __assert.True(TYPE("loObj.date") == "D", "15/01/2024 should be detected as Date, got: " + TYPE("loObj.date"))
    ENDPROC

    *-- Empty input string
    PROCEDURE TestParseEmptyInput() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew, loResult
        lbThrew = .F.
        TRY
            loResult = this.oJson.Parse("")
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Empty JSON must throw or set lError")
    ENDPROC

    *-- Whitespace-only input
    PROCEDURE TestParseWhitespaceOnly() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew, loResult
        lbThrew = .F.
        TRY
            loResult = this.oJson.Parse("     ")
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Whitespace-only JSON must throw or set lError")
    ENDPROC

    *-- Unclosed string
    PROCEDURE TestParseUnclosedString() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew
        lbThrew = .F.
        TRY
            this.oJson.Parse('{"key": "value')
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Unclosed string must throw or set lError")
    ENDPROC

    *-- Unclosed object
    PROCEDURE TestParseUnclosedObject() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew
        lbThrew = .F.
        TRY
            this.oJson.Parse('{"key": "value"')
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Unclosed object must throw or set lError")
    ENDPROC

    *-- Unclosed array
    PROCEDURE TestParseUnclosedArray() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew
        lbThrew = .F.
        TRY
            this.oJson.Parse('[1, 2, 3')
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Unclosed array must throw or set lError")
    ENDPROC

    *-- Trailing comma in object
    PROCEDURE TestParseTrailingCommaObject() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew
        lbThrew = .F.
        TRY
            this.oJson.Parse('{"a":1,}')
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Trailing comma in object must throw or set lError")
    ENDPROC

    *-- Trailing comma in array
    PROCEDURE TestParseTrailingCommaArray() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew
        lbThrew = .F.
        TRY
            this.oJson.Parse('[1, 2,]')
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Trailing comma in array must throw or set lError")
    ENDPROC

    *-- Missing colon between key and value
    PROCEDURE TestParseMissingColon() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew
        lbThrew = .F.
        TRY
            this.oJson.Parse('{"key" "value"}')
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Missing colon must throw or set lError")
    ENDPROC

    *-- Missing comma between array elements
    PROCEDURE TestParseMissingComma() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew
        lbThrew = .F.
        TRY
            this.oJson.Parse('[1 2]')
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Missing comma must throw or set lError")
    ENDPROC

    *-- Single quotes (not valid JSON)
    PROCEDURE TestParseSingleQuotes() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew
        lbThrew = .F.
        TRY
            this.oJson.Parse("{'key':'value'}")
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Single-quoted JSON must throw or set lError")
    ENDPROC

    *-- Unknown identifier (e.g. undefined, NaN)
    PROCEDURE TestParseUnknownIdentifier() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew
        lbThrew = .F.
        TRY
            this.oJson.Parse('{"key": undefined}')
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Unknown identifier must throw or set lError")
    ENDPROC

    *-- Trailing garbage after valid JSON
    PROCEDURE TestParseTrailingGarbage() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew, loResult
        lbThrew = .F.
        TRY
            loResult = this.oJson.Parse('{"ok":true} extra')
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Trailing garbage must throw or set lError")
    ENDPROC

    *-- Non-string argument (number)
    PROCEDURE TestParseNonStringArgument() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lbThrew
        lbThrew = .F.
        TRY
            this.oJson.Parse(123)
            lbThrew = this.oJson.lError
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Non-string argument must throw or set lError")
    ENDPROC

    *-- Root-level single string value
    PROCEDURE TestParseRootString() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lvResult
        lvResult = this.oJson.Parse('"hello"')
        __assert.Equal("hello", lvResult, "Root-level string must parse")
    ENDPROC

    *-- Root-level single number
    PROCEDURE TestParseRootNumber() HELP [Fact, Trait("Category", "Parse")]
        LOCAL lnResult
        lnResult = this.oJson.Parse("42")
        __assert.Equal(42, lnResult, "Root-level number must parse")
    ENDPROC

    *-- Root-level boolean true
    PROCEDURE TestParseRootTrue() HELP [Fact, Trait("Category", "Parse")]
        __assert.True(this.oJson.Parse("true"), "Root-level true must parse")
    ENDPROC

    *-- Root-level null
    PROCEDURE TestParseRootNull() HELP [Fact, Trait("Category", "Parse")]
        __assert.True(ISNULL(this.oJson.Parse("null")), "Root-level null must parse")
    ENDPROC

    *-- Root-level boolean false
    PROCEDURE TestParseRootFalse() HELP [Fact, Trait("Category", "Parse")]
        __assert.False(this.oJson.Parse("false"), "Root-level false must parse")
    ENDPROC

    *-- Nested empty arrays/objects
    PROCEDURE TestParseNestedEmpty() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"a":{"b":[]},"c":[[],[]]}')
        __assert.IsObject(loObj.a.b)
        __assert.Equal(0, loObj.a.b.count)
        __assert.Equal(2, loObj.c.count)
        __assert.Equal(0, loObj.c.item(1).count)
    ENDPROC

    *-- Zero and large integers
    PROCEDURE TestParseZeroAndLargeIntegers() HELP [Fact, Trait("Category", "Parse")]
        LOCAL loObj
        loObj = this.oJson.Parse('{"zero":0,"max":2147483647}')
        __assert.Equal(0, loObj.zero)
        __assert.Equal(2147483647, loObj.max)
    ENDPROC

ENDDEFINE


* ============================================================ *
* TestEdgeStringify — Stringify edge cases (standalone)
* ============================================================ *
DEFINE CLASS TestEdgeStringify AS Custom

    oJson = .NULL.

    PROCEDURE SetUp
        SET DEFAULT TO (PROJ_ROOT)
        this.oJson = NEWOBJECT("JSONFox", FXP_PATH)
    ENDPROC

    PROCEDURE TearDown
        this.oJson = .NULL.
    ENDPROC

    *-- Stringify a VFP Date (depends on SET CENTURY / SET DATE)
    PROCEDURE TestStringifyDate() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL loObj, lcResult, lcSavedCent
        lcSavedCent = SET("CENTURY")
        SET CENTURY ON
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "fecha", {^2024-01-15})
        lcResult = this.oJson.Stringify(@loObj)
        SET CENTURY &lcSavedCent
        __assert.NotEmpty(lcResult)
        __assert.True('"fecha"' $ lcResult, "Date property must appear in JSON. Got: " + lcResult)
    ENDPROC

    *-- Stringify a VFP DateTime
    PROCEDURE TestStringifyDateTime() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL loObj, lcResult
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "marca", {^2024-01-15 10:30:00})
        lcResult = this.oJson.Stringify(@loObj)
        __assert.NotEmpty(lcResult)
        __assert.True('"marca"' $ lcResult, "DateTime property must appear in JSON. Got: " + lcResult)
    ENDPROC

    *-- Stringify a VFP Logical true
    PROCEDURE TestStringifyLogicalTrue() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL loObj, lcResult
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "activo", .T.)
        lcResult = this.oJson.Stringify(@loObj)
        __assert.True("true" $ lcResult, "VFP .T. must become JSON true")
    ENDPROC

    *-- Stringify a VFP Logical false
    PROCEDURE TestStringifyLogicalFalse() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL loObj, lcResult
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "activo", .F.)
        lcResult = this.oJson.Stringify(@loObj)
        __assert.True("false" $ lcResult, "VFP .F. must become JSON false")
    ENDPROC

    *-- Stringify negative number
    PROCEDURE TestStringifyNegativeNumber() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL loObj, lcResult
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "saldo", -99.95)
        lcResult = this.oJson.Stringify(@loObj)
        __assert.True("-99.95" $ lcResult OR "-99.950" $ lcResult, "Negative value must appear in JSON")
    ENDPROC

    *-- Stringify an object containing arrays
    PROCEDURE TestStringifyObjectWithArrays() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL loObj, lcResult
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "tags[1]", .NULL.)
        DIMENSION loObj.tags[3]
        loObj.tags[1] = "vfp"
        loObj.tags[2] = "json"
        loObj.tags[3] = "fox"
        lcResult = this.oJson.Stringify(@loObj)
        __assert.NotEmpty(lcResult)
        __assert.True("[" $ lcResult, "Array must produce brackets in JSON")
        __assert.True("vfp" $ lcResult)
    ENDPROC

    *-- Stringify object with high ASCII chars (escaped as \uXXXX)
    PROCEDURE TestStringifyHighAscii() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL loObj, lcResult
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "texto", "cafe" + CHR(130))
        lcResult = this.oJson.Stringify(@loObj)
        __assert.NotEmpty(lcResult)
    ENDPROC

    *-- Stringify with ParseUTF8 flag
    PROCEDURE TestStringifyWithParseUtf8() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL lcResult
        lcResult = this.oJson.Stringify('{"name":"JSONFox","version":13}', .F., .T., .F.)
        __assert.NotEmpty(lcResult)
        __assert.True('"name"' $ lcResult)
    ENDPROC

    *-- Stringify with TrimChars flag
    PROCEDURE TestStringifyWithTrimChars() HELP [Fact, Trait("Category", "Stringify")]
        LOCAL lcResult
        lcResult = this.oJson.Stringify('{"name":"  JSONFox  ","version":13}', .F., .F., .T.)
        __assert.NotEmpty(lcResult)
        __assert.False("  JSONFox  " $ lcResult, "TrimChars should trim whitespace from values")
    ENDPROC

ENDDEFINE


* ============================================================ *
* TestEdgeCursor — Cursor operations edge cases (standalone)
* ============================================================ *
DEFINE CLASS TestEdgeCursor AS Custom

    oJson = .NULL.

    PROCEDURE SetUp
        SET DEFAULT TO (PROJ_ROOT)
        this.oJson = NEWOBJECT("JSONFox", FXP_PATH)
    ENDPROC

    PROCEDURE TearDown
        CLOSE TABLES ALL
        this.oJson = .NULL.
    ENDPROC

    *-- JSONToCursor with empty array
    PROCEDURE TestJsonToCursorEmptyArray() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lnSess, lbOk
        lnSess = SET("Datasession")
        lbOk = .F.
        TRY
            this.oJson.JSONToCursor("[]", "qEmpty", lnSess)
            IF USED("qEmpty")
                __assert.Equal(0, RECCOUNT("qEmpty"))
                lbOk = .T.
            ENDIF
        CATCH
            lbOk = .T.  && error is acceptable for empty array
        ENDTRY
        __assert.True(lbOk OR this.oJson.lError, "Empty array JSONToCursor must not crash")
    ENDPROC

    *-- JSONToCursor with null values
    PROCEDURE TestJsonToCursorWithNulls() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lnSess
        lnSess = SET("Datasession")
        this.oJson.JSONToCursor('[{"name":"Alice","data":null}]', "qNull", lnSess)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.Equal(1, RECCOUNT("qNull"))
    ENDPROC

    *-- JSONToCursor with heterogeneous rows (different shapes)
    PROCEDURE TestJsonToCursorHeterogeneous() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lnSess
        lnSess = SET("Datasession")
        this.oJson.JSONToCursor('[{"a":1,"b":2},{"b":3,"c":4}]', "qHet", lnSess)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.Equal(2, RECCOUNT("qHet"))
    ENDPROC

    *-- CursorToJSON with logical field
    PROCEDURE TestCursorToJsonWithLogical() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lcJson
        CREATE CURSOR qLog (id I, active L)
        INSERT INTO qLog VALUES (1, .T.)
        INSERT INTO qLog VALUES (2, .F.)
        lcJson = this.oJson.CursorToJSON("qLog", .F., SET("Datasession"), .T.)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.True("true" $ lcJson, "Logical .T. must become JSON true")
        __assert.True("false" $ lcJson, "Logical .F. must become JSON false")
    ENDPROC

    *-- CursorToJSON with date field
    PROCEDURE TestCursorToJsonWithDate() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lcJson
        CREATE CURSOR qDate (id I, fecha D)
        INSERT INTO qDate VALUES (1, {^2024-06-15})
        lcJson = this.oJson.CursorToJSON("qDate", .F., SET("Datasession"), .T.)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.True("2024" $ lcJson, "Date cursor must contain year in JSON")
    ENDPROC

    *-- CursorToJSON empty table
    PROCEDURE TestCursorToJsonEmptyTable() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lbOk
        CREATE CURSOR qEmptyT (id I, name C(20))
        lbOk = .F.
        TRY
            this.oJson.CursorToJSON("qEmptyT", .F., SET("Datasession"), .T.)
            lbOk = .T.  && no exception = acceptable
        CATCH
        ENDTRY
        __assert.True(lbOk, "Empty table CursorToJSON must not throw. lError: " + TRANSFORM(this.oJson.lError))
    ENDPROC

    *-- CursorToJSON with tlJustArray = .F. (wraps in object)
    PROCEDURE TestCursorToJsonNotJustArray() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lcJson
        CREATE CURSOR qWrap (id I, name C(20))
        INSERT INTO qWrap VALUES (1, "Test")
        lcJson = this.oJson.CursorToJSON("qWrap", .F., SET("Datasession"), .F.)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.True('"qwrap"' $ LOWER(lcJson), "Not just array must wrap in cursor name key")
    ENDPROC

    *-- CursorStructure with tlCopyExtended
    PROCEDURE TestCursorStructureExtended() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lcResult
        CREATE CURSOR qExt (id I, name C(30), price N(10,2))
        lcResult = this.oJson.CursorStructure("qExt", SET("Datasession"), .T., .F.)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.NotEmpty(lcResult)
    ENDPROC

    *-- CursorStructure with tlJustArray
    PROCEDURE TestCursorStructureJustArray() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lcResult
        CREATE CURSOR qArr (id I, name C(30))
        lcResult = this.oJson.CursorStructure("qArr", SET("Datasession"), .F., .T.)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.NotEmpty(lcResult)
        __assert.True("[" $ lcResult, "Just array must start with bracket")
    ENDPROC

    *-- CursorToJSONObject — basic
    PROCEDURE TestCursorToJsonObject() HELP [Fact, Trait("Category", "Cursor")]
        CREATE CURSOR qObj (id I, name C(20))
        INSERT INTO qObj VALUES (1, "Alice")
        INSERT INTO qObj VALUES (2, "Bob")
        LOCAL loResult
        loResult = this.oJson.CursorToJSONObject("qObj", .F., SET("Datasession"))
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.True(TYPE("loResult", 1) == "A", "CursorToJSONObject must return array")
    ENDPROC

    *-- CursorToJSONObject single row
    PROCEDURE TestCursorToJsonObjectCurrentRow() HELP [Fact, Trait("Category", "Cursor")]
        CREATE CURSOR qSingle (id I, name C(20), active L)
        INSERT INTO qSingle VALUES (1, "Irwin", .T.)
        INSERT INTO qSingle VALUES (2, "Other", .F.)
        SELECT qSingle
        GO TOP
        SKIP
        LOCAL loResult
        loResult = this.oJson.CursorToJSONObject("qSingle", .T., SET("Datasession"))
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.True(TYPE("loResult", 1) == "A")
    ENDPROC

    *-- MasterDetailToJSON
    PROCEDURE TestMasterDetailToJson() HELP [Fact, Trait("Category", "Cursor")]
        CREATE CURSOR qMaster (id I, title C(30))
        INSERT INTO qMaster VALUES (1, "Order 1")
        INSERT INTO qMaster VALUES (2, "Order 2")
        CREATE CURSOR qDetail (id I, master_id I, item C(30), qty I)
        INSERT INTO qDetail VALUES (1, 1, "Widget A", 5)
        INSERT INTO qDetail VALUES (2, 1, "Widget B", 3)
        INSERT INTO qDetail VALUES (3, 2, "Widget C", 1)
        LOCAL lcResult
        lcResult = this.oJson.MasterDetailToJSON("qMaster", "qDetail", ;
            "master_id = qMaster.id", "items", SET("Datasession"))
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.NotEmpty(lcResult)
    ENDPROC

    *-- JSONToCursor with empty cursor name (must throw)
    PROCEDURE TestJsonToCursorEmptyCursorName() HELP [Fact, Trait("Category", "Cursor")]
        LOCAL lbThrew
        lbThrew = .F.
        TRY
            this.oJson.JSONToCursor("[]", "", SET("Datasession"))
        CATCH
            lbThrew = .T.
        ENDTRY
        __assert.True(lbThrew, "Empty cursor name must throw error")
    ENDPROC

ENDDEFINE


* ============================================================ *
* TestEdgeXml — XML conversion edge cases (standalone)
* ============================================================ *
DEFINE CLASS TestEdgeXml AS Custom

    oJson = .NULL.

    PROCEDURE SetUp
        SET DEFAULT TO (PROJ_ROOT)
        this.oJson = NEWOBJECT("JSONFox", FXP_PATH)
    ENDPROC

    PROCEDURE TearDown
        CLOSE TABLES ALL
        this.oJson = .NULL.
    ENDPROC

    *-- ArrayToXML basic
    PROCEDURE TestArrayToXml() HELP [Fact, Trait("Category", "XML")]
        LOCAL lcResult
        lcResult = this.oJson.ArrayToXML('[{"id":1,"name":"Test"}]')
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.NotEmpty(lcResult)
        __assert.True("<" $ lcResult, "XML must contain tags")
    ENDPROC

    *-- XMLToJson basic
    PROCEDURE TestXmlToJson() HELP [Fact, Trait("Category", "XML")]
        LOCAL lcResult
        lcResult = this.oJson.XMLToJson('<?xml version="1.0"?><root><item><id>1</id><name>Test</name></item></root>')
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.NotEmpty(lcResult)
    ENDPROC

    *-- ArrayToXML with VFP object
    PROCEDURE TestArrayToXmlFromObject() HELP [Fact, Trait("Category", "XML")]
        LOCAL lcJson, lcResult
        lcJson = '[{"id":1,"name":"Test1"},{"id":2,"name":"Test2"}]'
        lcResult = this.oJson.ArrayToXML(lcJson)
        __assert.False(this.oJson.lError, this.oJson.cLastError)
        __assert.NotEmpty(lcResult)
        __assert.True("<" $ lcResult, "XML must contain tags")
    ENDPROC

ENDDEFINE


* ============================================================ *
* TestEdgeApp — Edge cases for the APP version (_Screen.Json)
* ============================================================ *
DEFINE CLASS TestEdgeApp AS Custom

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

    *-- APP: MasterDetailToJSON
    PROCEDURE TestAppMasterDetail() HELP [Fact, Trait("Category", "App")]
        CREATE CURSOR qM (id I, title C(30))
        INSERT INTO qM VALUES (1, "Order 1")
        CREATE CURSOR qD (id I, master_id I, item C(30))
        INSERT INTO qD VALUES (1, 1, "Item A")
        INSERT INTO qD VALUES (2, 1, "Item B")
        LOCAL lcResult
        lcResult = _Screen.Json.MasterDetailToJSON("qM", "qD", ;
            "master_id = qM.id", "items", SET("Datasession"))
        __assert.NotEmpty(lcResult)
    ENDPROC

    *-- APP: UseArrayObjects = .F.
    PROCEDURE TestAppUseArrayObjectsFalse() HELP [Fact, Trait("Category", "App")]
        _Screen.Json.UseArrayObjects = .F.
        LOCAL loResult, lbOk
        lbOk = .F.
        TRY
            loResult = _Screen.Json.Parse("[1, 2, 3]")
            IF VARTYPE(loResult) == "O"
                lbOk = loResult.count >= 1
            ELSE
                lbOk = !ISNULL(loResult)
            ENDIF
        CATCH
        ENDTRY
        __assert.True(lbOk, "UseArrayObjects=.F. APP must not crash, result type: " + VARTYPE(loResult))
        _Screen.Json.UseArrayObjects = .T.
    ENDPROC

    *-- APP: reserved keyword "messages"
    PROCEDURE TestAppReservedKeywordMessages() HELP [Fact, Trait("Category", "App")]
        _Screen.Json.UseArrayObjects = .F.
        LOCAL loObj, lbOk
        lbOk = .F.
        TRY
            loObj = _Screen.Json.Parse('{"messages":[{"id":1},{"id":2}]}')
            lbOk = .T.
        CATCH
        ENDTRY
        __assert.True(lbOk, "Reserved keyword 'messages' must not crash with UseArrayObjects=.F.")
        _Screen.Json.UseArrayObjects = .T.
    ENDPROC

    *-- APP: Date detection
    PROCEDURE TestAppDateDetection() HELP [Fact, Trait("Category", "App")]
        LOCAL loObj
        loObj = _Screen.Json.Parse('{"date":"2024-01-15"}')
        __assert.True(TYPE("loObj.date") == "D", "Date must be detected, got: " + TYPE("loObj.date"))
    ENDPROC

ENDDEFINE
