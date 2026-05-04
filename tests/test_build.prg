#define PROJ_ROOT "F:\Desarrollo\GitHub\JSONFox"
#define FXP_PATH  "F:\Desarrollo\GitHub\JSONFox\JsonFox.fxp"

DEFINE CLASS TestBuildJsonFox AS Custom

    PROCEDURE TestBuildProducesAnFxp() HELP [Fact, Trait("Category", "Build")]
        SET DEFAULT TO (PROJ_ROOT)
        * Borrar FXP previo si existe para forzar rebuild limpio
        IF FILE(FXP_PATH)
            DELETE FILE (FXP_PATH)
        ENDIF
        DO build_jsonfox.prg
        __assert.True(FILE(FXP_PATH), "JsonFox.fxp debe existir tras el build")
    ENDPROC

ENDDEFINE
