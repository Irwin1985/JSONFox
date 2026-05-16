#define PROJ_ROOT "C:\Desarrollo\IrwinRodriguez.dev\JSONFox"
#define FXP_PATH  "C:\Desarrollo\IrwinRodriguez.dev\JSONFox\JsonFox.fxp"

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
