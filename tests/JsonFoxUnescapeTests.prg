* ==================================================================
* JsonFoxUnescapeTests.prg
*
* Lo que afirma esta suite: que JSONFox desescapa una cadena JSON en
* UNA sola pasada, como manda RFC 8259, y que una barra escapada
* seguida de u (c:\\users) es una barra y una u, no un \uXXXX.
*
* POR QUÉ EXISTE (medido el 2026-09-18, ronda 13 del canal FoxMind):
*
*   Tokenizer.string() llamaba a escapeCharacters() y DESPUÉS a
*   checkUnicodeFormat(). La primera pasada dejaba "\\u0022" como el
*   texto \u0022, y la segunda lo volvía a interpretar: salía una
*   comilla. Y c:\\users\\x quedaba en c:\users\x, que la segunda
*   pasada tomaba por un \uXXXX inválido.
*
*   Además, la rama de cadenas largas (100 caracteres o más) usaba
*   STRTRAN encadenados: \\ antes que \n, así que "\\n" acababa en
*   barra + salto de línea real.
*
*   Y Stringify lo heredaba: formatea re-tokenizando su propia salida,
*   así que una ruta c:\users\x escrita salía como c:\\x. El round-trip
*   de abajo lo mide.
*
* Vive AQUÍ, en el repositorio canónico, y no en los que usan una copia:
* nació en VFP.AI.SDK el 2026-09-19 contra su copia de JsonFox.prg, y
* se movió cuando el arreglo se rehízo donde tenía que estar.
*
* Sin red, sin procesos, sin FoxCore. Los esperados con acento van con
* CHR(): un literal con ñ en un __assert no compara igual que el código
* (FoxMind\CLAUDE.md §2).
*
* cApiRoot: ruta al proyecto. Ajustar si se mueve.
* ==================================================================

DEFINE CLASS JsonFoxUnescapeTests AS Custom
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
    ENDPROC

* El caso medido en la ronda 13, tal cual: barra escapada + r, barra
* escapada + u0022, barra escapada doble. Una vuelta, no dos.
    PROCEDURE Test_Parse_UnEscapeDobleSeQuedaComoTexto() HELP [Fact]
        LOCAL loObj, lcOut
        loObj = THIS.oJson.Parse('{"a":"x\\r\\ny \\u0022q\\u0022 c:\\\\d"}')
        lcOut = loObj.a

        __assert.Equal('x\r\ny \u0022q\u0022 c:\\d', lcOut, "una sola vuelta")
        __assert.Equal(26, LEN(lcOut), "26 caracteres")
        __assert.Equal(0, OCCURS(CHR(13), lcOut), "ningún CR real")
        __assert.Equal(0, OCCURS('"', lcOut), "ninguna comilla: \u0022 es texto")
    ENDPROC

* Cualquier ruta bajo C:\Users dentro de un JSON es una barra escapada
* seguida de u. Es la que rompía el FLL, las tools y los proveedores.
    PROCEDURE Test_Parse_RutaBajoUsersEsUnaRuta() HELP [Fact]
        LOCAL loObj
        loObj = THIS.oJson.Parse('{"file":"c:\\users\\x\\y.prg","dir":"c:\\users\\"}')

        __assert.Equal('c:\users\x\y.prg', loObj.file, "la ruta entera y correcta")
        __assert.Equal('c:\users\', loObj.dir, "y una barra pegada a la comilla de cierre")
    ENDPROC

* \uXXXX pasa de UTF-16 a CP1252: ñ es CHR(241), y el euro, que no está
* en Latin-1, es 0x80 en CP1252.
    PROCEDURE Test_Parse_UnicodeACp1252() HELP [Fact]
        LOCAL loObj, lcOut
        loObj = THIS.oJson.Parse('{"a":"e\u00F1e a\u00F1o \u20AC \u0022"}')
        lcOut = loObj.a

        __assert.Equal("e" + CHR(241) + "e a" + CHR(241) + "o " + CHR(128) + ' "', lcOut, "")
        __assert.Equal(128, ASC(SUBSTR(lcOut, 9, 1)), "el euro es 0x80 en CP1252")
    ENDPROC

* Los escapes de RFC 8259, todos, y lo que no es un escape se queda
* tal cual con su barra.
    PROCEDURE Test_Parse_LosEscapesSimples() HELP [Fact]
        LOCAL loObj
        loObj = THIS.oJson.Parse('{"a":"a\r\nb\t\"q\"\/\\","b":"x\by\fz","c":"\z"}')

        __assert.Equal("a" + CHR(13) + CHR(10) + "b" + CHR(9) + '"q"/\', loObj.a, "")
        __assert.Equal("x" + CHR(8) + "y" + CHR(12) + "z", loObj.b, "\b y \f también son escapes")
        __assert.Equal("\z", loObj.c, "un escape que no existe se queda tal cual")
    ENDPROC

* La rama de cadenas largas (100 caracteres o más) tenía su propio
* desescapado con STRTRAN encadenados. Mismo contrato para cualquier
* longitud.
    PROCEDURE Test_Parse_CadenaLargaMismoContrato() HELP [Fact]
        LOCAL loObj, lcRelleno, lcOut
        lcRelleno = REPLICATE("abcdefghij", 12)
        loObj = THIS.oJson.Parse('{"a":"' + lcRelleno + ' x\\r\\ny \\u0022q\\u0022 c:\\\\users\\\\x"}')
        lcOut = loObj.a

        __assert.True(LEN(lcOut) > 100, "es la rama larga: " + TRANSFORM(LEN(lcOut)))
        __assert.Equal(lcRelleno + ' x\r\ny \u0022q\u0022 c:\\users\\x', lcOut, "una sola vuelta")
        __assert.Equal(0, OCCURS(CHR(13), lcOut), "ningún CR real")
        __assert.Equal(0, OCCURS('"', lcOut), "ninguna comilla")
    ENDPROC

* Ida y vuelta con el Stringify del propio JSONFox: lo que se escribe se
* lee igual, con una ruta bajo Users, saltos, comillas y una ñ.
    PROCEDURE Test_Parse_RoundTripConStringify() HELP [Fact]
        LOCAL loObj, lcJson, loBack, lcTexto
        lcTexto = 'c:\users\x' + CHR(13) + CHR(10) + '"q" \u0022 ' + CHR(241)
        loObj = CREATEOBJECT("Empty")
        ADDPROPERTY(loObj, "ruta", lcTexto)

        lcJson = THIS.oJson.Stringify(loObj)
        loBack = THIS.oJson.Parse(lcJson)

        __assert.Equal(lcTexto, loBack.ruta, "ida y vuelta: " + lcJson)
        __assert.Equal(1, OCCURS("users", lcJson), "el JSON escrito conserva la ruta")
    ENDPROC

ENDDEFINE
