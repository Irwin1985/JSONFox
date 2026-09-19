* ==================================================================
* JsonFoxBuildSyncTests.prg
*
* Lo que afirma esta suite: que JsonFox.prg es EXACTAMENTE lo que
* build_jsonfox.prg produce desde src\. Ni un byte más.
*
* POR QUÉ EXISTE: la fuente de verdad es src\ y JsonFox.prg es una
* salida, pero hasta el 2026-09-19 los dos iban por libre. Los arreglos
* del 30 y el 31 de agosto de 2026 se hicieron a mano en JsonFox.prg; el
* del 31 no llegó nunca a src\, y el siguiente build (el que lanza
* tests\test_build.prg) lo borró sin avisar. Al revés también pasaba:
* src\ tenía una corrección del T_NONE que JsonFox.prg no.
*
* Si este test falla, NO se arregla editando JsonFox.prg: se lleva el
* cambio a src\ y se vuelve a lanzar el build.
*
* cApiRoot: ruta al proyecto. Ajustar si se mueve.
* ==================================================================

DEFINE CLASS JsonFoxBuildSyncTests AS Custom
    cApiRoot = "C:\Desarrollo\IrwinRodriguez.dev\JSONFox\"

    PROCEDURE SetUp() HELP []
        SET PROCEDURE TO (THIS.cApiRoot + "build_jsonfox.prg") ADDITIVE
    ENDPROC

    PROCEDURE Test_Build_JsonFoxPrgEsLoQueSaleDeSrc() HELP [Fact]
        LOCAL lcEsperado, lcReal, lnI
* Sin CR: src\ y JsonFox.prg salen con LF o con CRLF segun como se
* sacaron de git (core.autocrlf), y eso no es una divergencia.
        lcEsperado = CHRTRAN(JsonFoxAssemble(THIS.cApiRoot), CHR(13), "")
        lcReal = CHRTRAN(FILETOSTR(THIS.cApiRoot + "JsonFox.prg"), CHR(13), "")

* FoxProof ensena solo el ULTIMO assert que falla: el que dice que
* hacer va el ultimo.
        __assert.Equal(LEN(lcEsperado), LEN(lcReal), "mismo tamaño")
        IF !(lcEsperado == lcReal)
            FOR lnI = 1 TO MIN(LEN(lcEsperado), LEN(lcReal))
                IF !(SUBSTR(lcEsperado, lnI, 1) == SUBSTR(lcReal, lnI, 1))
                    EXIT
                ENDIF
            NEXT
            __assert.Equal(SUBSTR(lcEsperado, MAX(lnI - 40, 1), 80), SUBSTR(lcReal, MAX(lnI - 40, 1), 80), ;
                "JsonFox.prg no es el build de src\ (primer byte distinto: " + TRANSFORM(lnI) + ;
                "). Lleva el cambio a src\ y lanza build_jsonfox.prg; no edites JsonFox.prg")
        ENDIF
    ENDPROC

* El build no mete bytes UTF-8 en un fuente CP1252: hasta el 2026-09-19
* el propio build_jsonfox.prg iba en UTF-8 y sus separadores salían en
* JsonFox.prg como E2 94 80.
    PROCEDURE Test_Build_SinBytesUtf8() HELP [Fact]
        LOCAL lcReal
        lcReal = FILETOSTR(THIS.cApiRoot + "JsonFox.prg")

        __assert.Equal(0, OCCURS(CHR(0xE2) + CHR(0x94) + CHR(0x80), lcReal), "sin separadores UTF-8")
        __assert.Equal(0, OCCURS(CHR(0xEF) + CHR(0xBF) + CHR(0xBD), lcReal), "sin caracteres de reemplazo")
    ENDPROC

ENDDEFINE
