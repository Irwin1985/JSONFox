* build_jsonfox.prg
* Ensambla y compila JsonFox.fxp desde las fuentes en src\
* Uso: DO build_jsonfox.prg   (desde la raíz del proyecto)
*
* Produce: JsonFox.prg (fuente combinada) + JsonFox.fxp (distribución)
*
* LA FUENTE DE VERDAD ES src\. JsonFox.prg es una SALIDA: no se edita a
* mano. Los arreglos del 30 y el 31 de agosto de 2026 se hicieron
* directamente en JsonFox.prg, el de 31 no llegó nunca a src\, y el
* primer build que se lanzó después (lo lanza tests\test_build.prg) lo
* deshizo sin avisar. tests\JsonFoxBuildSyncTests.prg comprueba que
* JsonFox.prg es exactamente lo que este script produce desde src\.
*
* Y este fichero va en CP1252 como cualquier .prg: hasta el 2026-09-19
* iba en UTF-8 y metía en JsonFox.prg los separadores de línea como
* bytes UTF-8 en medio de un fuente CP1252.

local lcRoot, lcOut, lcOutFile
lcRoot = addbs(justpath(sys(16)))  && directorio del propio PRG

lcOut = JsonFoxAssemble(lcRoot)

* -- Escribir JsonFox.prg --------------------------------------------------- *
lcOutFile = lcRoot + "JsonFox.prg"
* SAFETY OFF para el STRTOFILE (regla 63): con SAFETY ON, lo normal en el
* IDE, preguntaba si sobrescribir JsonFox.prg y un build lanzado desde
* fuera se quedaba esperando (visto el 2026-09-25).
local lcSafety
lcSafety = set("SAFETY")
set safety off
strtofile(lcOut, lcOutFile)
if lcSafety == "ON"
	set safety on
endif

* -- Compilar --------------------------------------------------------------- *
compile (lcOutFile)

if file(lcRoot + "JsonFox.fxp")
	? "BUILD OK -> JsonFox.fxp"
else
	? "BUILD FAILED -- JsonFox.fxp no generado"
endif

return


* JsonFoxAssemble: el texto de JsonFox.prg a partir de src\. Separado
* para que un test pueda compararlo con el fichero sin escribir nada.
function JsonFoxAssemble(tcRoot)
	local lcOut, lcFile, lcContent, lcSep, i

	lcSep = chr(13) + chr(10)

* -- 1. Cabecera de la librería autocontenida -------------------------------- *
	lcOut = ;
		"* ========================================================================" + lcSep + ;
		"* JSONFox - Self-contained standalone library" + lcSep + ;
		"* Version: 13.1.1" + lcSep + ;
		"* Description: Complete JSON parser and serializer for Visual FoxPro" + lcSep + ;
		[* Usage: jsonFox = NEWOBJECT("JSONFox", "JSONFox.prg")] + lcSep + ;
		"*" + lcSep + ;
		"* Changelog:" + lcSep + ;
		"*   13.1.1 (2026-09-25) - Fixed: EXTERNAL ARRAY loResult en Parse y en" + lcSep + ;
		"*               CursorToJSONObject. Sin él, compilar un proyecto que" + lcSep + ;
		"*               incluye JsonFox.prg abría el diálogo Locate File" + lcSep + ;
		"*               (Unknown LORESULT) y colgaba un build desatendido." + lcSep + ;
		"*   13.1 (2026-09-25) - La versión de este fichero pasa a ser la de la" + lcSep + ;
		"*               librería, la misma que la propiedad version (13.1)." + lcSep + ;
		"*               Sin cambios de código: la numeración 1.x de antes" + lcSep + ;
		"*               queda en este historial." + lcSep + ;
		"*   1.1.1 (2026-09-19) - Fixed: el tokenizer desescapaba DOS veces las \u" + lcSep + ;
		[*               ("x\\u0022" daba x"); ahora una sola pasada, con \b, \f] + lcSep + ;
		"*               y pares sustitutos. RETURN fuera de TRY en CursorToJSON," + lcSep + ;
		"*               CursorToJSONObject y CursorStructure (regla 6)." + lcSep + ;
		"*   1.1.0 (2026-06-14) - Fixed: lTablePrompt macro bug in Destroy," + lcSep + ;
		"*               ISO 8601 dates via TTOC(val,3), LOCAL llIsCollection" + lcSep + ;
		"*   1.0.0 (2026-06-14) - Initial self-contained standalone release" + lcSep + ;
		"* ========================================================================" + lcSep

* -- 2. Constantes de JSONFox.h (inlineadas) -------------------------------- *
	lcOut = lcOut + filetostr(tcRoot + "src\JSONFox.h") + lcSep + lcSep

* -- 3. Fuentes de clases en orden de dependencia --------------------------- *
* jsonutils no depende de nada -> primero
* tokenizer no depende de nada
* parser depende de tokenizer + utils
* jsonstringify depende de tokenizer + utils
* objecttojson depende de utils
* arraytocursor depende de tokenizer + utils
* cursortoarray depende de utils
* cursortojsonobject no depende de utils (usa SCATTER)
* structuretojson depende de utils
* jsonfox_class (facade) depende de todo lo anterior
	local laFiles[10]
	laFiles[1]  = "src\jsonutils.prg"
	laFiles[2]  = "src\tokenizer.prg"
	laFiles[3]  = "src\parser.prg"
	laFiles[4]  = "src\jsonstringify.prg"
	laFiles[5]  = "src\objecttojson.prg"
	laFiles[6]  = "src\arraytocursor.prg"
	laFiles[7]  = "src\cursortoarray.prg"
	laFiles[8]  = "src\cursortojsonobject.prg"
	laFiles[9]  = "src\structuretojson.prg"
	laFiles[10] = "src\jsonfox_class.prg"

	for i = 1 to alen(laFiles)
		lcFile = tcRoot + laFiles[i]
		if !file(lcFile)
			error "build_jsonfox: fichero no encontrado: " + lcFile
		endif
		lcContent = filetostr(lcFile)
* Eliminar la directiva #include del header (ya está inlineado arriba)
		lcContent = strtran(lcContent, '#include "JSONFox.h"',  "")
		lcContent = strtran(lcContent, "#include 'JSONFox.h'",  "")
		lcContent = strtran(lcContent, '#include "jsonfox.h"',  "")
		lcContent = strtran(lcContent, '#include "src\JSONFox.h"', "")
		lcOut = lcOut + lcSep + "* -- " + laFiles[i] + " -- *" + lcSep
		lcOut = lcOut + lcContent + lcSep
	endfor

	return lcOut
endfunc
