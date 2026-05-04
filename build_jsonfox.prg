* build_jsonfox.prg
* Ensambla y compila JsonFox.fxp desde las fuentes en src\
* Uso: DO build_jsonfox.prg   (desde la raíz del proyecto)
*
* Produce: JsonFox.prg (fuente combinada) + JsonFox.fxp (distribución)

local lcRoot, lcOut, lcFile, lcContent, lcHeader, lcSep
lcRoot = addbs(justpath(sys(16)))  && directorio del propio PRG
lcOut  = ""
lcSep  = chr(13) + chr(10)

* ── 1. Header: constantes de JSONFox.h (inlineadas) ──────────────────────── *
lcHeader = filetostr(lcRoot + "src\JSONFox.h")
* Quitar comentarios de línea para reducir ruido, conservar los #define
lcOut = lcHeader + lcSep + lcSep

* ── 2. Fuentes de clases en orden de dependencia ─────────────────────────── *
* jsonutils no depende de nada → primero
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

local i
for i = 1 to alen(laFiles)
	lcFile = lcRoot + laFiles[i]
	if !file(lcFile)
		error "build_jsonfox: fichero no encontrado: " + lcFile
	endif
	lcContent = filetostr(lcFile)
	* Eliminar la directiva #include del header (ya está inlineado arriba)
	lcContent = strtran(lcContent, '#include "JSONFox.h"',  "")
	lcContent = strtran(lcContent, "#include 'JSONFox.h'",  "")
	lcContent = strtran(lcContent, '#include "jsonfox.h"',  "")
	lcContent = strtran(lcContent, '#include "src\JSONFox.h"', "")
	lcOut = lcOut + lcSep + "* ── " + laFiles[i] + " ── *" + lcSep
	lcOut = lcOut + lcContent + lcSep
endfor

* ── 3. Escribir JsonFox.prg ──────────────────────────────────────────────── *
local lcOutFile
lcOutFile = lcRoot + "JsonFox.prg"
strtofile(lcOut, lcOutFile)

* ── 4. Compilar ──────────────────────────────────────────────────────────── *
compile (lcOutFile)

if file(lcRoot + "JsonFox.fxp")
	? "BUILD OK → JsonFox.fxp (" + transform(fsize(lcRoot + "JsonFox.fxp")) + " bytes)"
else
	? "BUILD FAILED — JsonFox.fxp no generado"
endif
