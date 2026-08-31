# VFP — Reglas de codificación obligatorias

**Fichero canónico.** Cubre todos los proyectos de `C:\Desarrollo\IrwinRodriguez.dev`.
Cómo consultarlo, cómo añadir una regla y por qué la numeración es sagrada: `README.md`.

| | |
|---|---|
| **Alcance** | El **lenguaje** VFP 9 y sus formatos de fichero. Las reglas de herramientas (FoxUnit, `vfp2text`, `foxengine`) están en `tooling-rules.md`; las de X#, en `xsharp-coding-rules.md` |
| **Origen** | Unificado el 2026-08-15 desde cuatro copias divergentes (`VFP.AI.SDK/docs/`, raíz, `FoxPilot/Docs/`, `FoxFE Core/Docs/`) más reglas dispersas en prosa por siete proyectos |
| **Numeración** | 1-42 conservadas **verbatim** de `VFP.AI.SDK/docs/vfp-coding-rules.md`, que tenía 86 referencias entrantes. 43-52 incorporadas en la unificación; 53 añadida en A14b de VFP.AI.SDK (2026-08-16); 54 y 55 en FoxServer 0.9 (2026-08-21); **55.1** ampliando la 55 en FoxServer 0.9 (2026-08-22) |
| **Regla de oro** | **Nunca se renumera.** Una regla que se cae se marca obsoleta y su número se retira |

---

## 1. Arrays: deteccion de tipo

VFP no permite `VARTYPE(var) = 'A'` para detectar arrays.
Usar `TYPE("variable", 1)` en su lugar.

```foxpro
* INCORRECTO — VARTYPE no devuelve 'A' para arrays
IF VARTYPE(toResults) = 'A'

* CORRECTO — TYPE con segundo parametro 1
IF TYPE("toResults", 1) = 'A'
```

## 2. Arrays: declaracion EXTERNAL ARRAY

Antes de acceder a elementos de un array recibido como parametro,
declararlo con `EXTERNAL ARRAY` para que VFP lo reconozca como array
y no como una posible funcion o programa.

```foxpro
* INCORRECTO — VFP puede interpretar toResults[i] como llamada a funcion
FUNCTION ProcessResults(toResults)
    loItem = toResults[1]

* CORRECTO — EXTERNAL ARRAY le dice al compilador que es un array
FUNCTION ProcessResults(toResults)
    EXTERNAL ARRAY toResults
    loItem = toResults[1]
```

Error si se omite: `Unknown TORESULTS - Undefined` o dialogo "Locate File".

## 3. Arrays: retorno por referencia

Para devolver un array desde una funcion, usar `RETURN @arrayName`.
El `@` pasa el array por referencia.

```foxpro
FUNCTION GetNames()
    LOCAL ARRAY laNames[3]
    laNames[1] = "A"
    laNames[2] = "B"
    laNames[3] = "C"
    RETURN @laNames
ENDFUNC
```

## 4. Arrays: declaracion LOCAL separada

No mezclar variables escalares y arrays en un mismo `LOCAL`.
Declararlos por separado.

```foxpro
* INCORRECTO — puede causar "Unknown LANAMES - Undefined"
LOCAL loReg, ARRAY laNames[1]

* CORRECTO
LOCAL loReg
LOCAL ARRAY laNames[1]
```

## 5. CATCH sin variable TO

No usar `CATCH TO loEx` — puede colgar el compilador VFP en ciertos contextos.
Usar `CATCH` sin variable y flags si se necesita tracking de errores.

```foxpro
* INCORRECTO — puede colgar el compilador VFP
TRY
    loObj = CREATEOBJECT("SomeClass")
CATCH TO loEx
    THIS.cError = loEx.Message
ENDTRY

* CORRECTO
LOCAL llOk
llOk = .T.
TRY
    loObj = CREATEOBJECT("SomeClass")
CATCH
    THIS.cError = "Failed to create SomeClass"
    llOk = .F.
ENDTRY
```

## 6. RETURN fuera de TRY/CATCH

`RETURN` no puede aparecer dentro de `TRY/CATCH/ENDTRY` (Error 2060).
Siempre fuera del bloque.

```foxpro
* CORRECTO
FUNCTION DoSomething()
    LOCAL llResult
    llResult = .F.
    TRY
        llResult = .T.
    CATCH
        llResult = .F.
    ENDTRY
    RETURN llResult
ENDFUNC
```

## 7. IF sin THEN, una linea por bloque

VFP no admite `IF cond THEN bloque` en una sola linea.
Tampoco usar `THEN`. Cada bloque en su propia linea.

```foxpro
* INCORRECTO
IF USED("tabla") THEN USE IN tabla

* CORRECTO
IF USED("tabla")
    USE IN tabla
ENDIF
```

## 8. DO CASE sin dos puntos (:)

No usar `CASE x : bloque` en una linea.
Cada `CASE` y su bloque en lineas separadas.

```foxpro
* CORRECTO
DO CASE
CASE lcKey == "A"
    THIS.cProp = lcVal
CASE lcKey == "B"
    THIS.nProp = VAL(lcVal)
ENDCASE
```

> Fuente de verdad de esta regla (codificación de fuentes VFP y uso de
> FoxAgent): `IrwinRodriguez.dev/REGLAS-VFP.md`. Si algo de aquí y de allí
> no coincide, manda aquel fichero.

## 9. Un `.prg` va en CP1252 — y los acentos SE ESCRIBEN

**Corregida el 2026-08-22.** Decía *"ASCII puro en .prg: sin acentos, sin enie, sin em dash,
solo caracteres 0-127"*, y estaba escrita del revés: describía la limitación de **la
herramienta que escribe**, no la de VFP. VFP 9 lee y escribe en la página de códigos ANSI, o
sea **Windows-1252**, donde un acento ocupa **un byte** y se ve perfectamente. Prohibirlos
costaba legibilidad —en los comentarios y en los literales que ve el usuario— a cambio de
nada que VFP pidiera.

**La regla, entera:** un `.prg` se lee y se escribe SIEMPRE como **CP1252**. Nunca UTF-8.

Y la otra mitad, que es la que hay que leer para atreverse: **los acentos, la eñe y los
signos de apertura (`¿` `¡`) son bienvenidos**, también en los comentarios. En CP1252 ocupan
**un byte** y VFP los muestra bien. Lo único que no puede pasar es que el fichero acabe en
UTF-8.

### Por qué UTF-8 lo rompe, y por qué el BOM no es lo principal

En UTF-8 un acento ocupa **dos** bytes. Si VFP lee ese fichero como CP1252, ve los dos por
separado:

```text
"Descripción"
   en CP1252 :  ... 69 [F3] 6E      <- UN byte
   en UTF-8  :  ... 69 [C3 B3] 6E   <- DOS bytes

lo que VFP muestra si el fichero está en UTF-8 :  DescripciÃ³n
y si además lleva BOM                          :  ï»¿DescripciÃ³n
```

El BOM añade tres caracteres de basura **al principio**. El destrozo de verdad es que **cada
acento se parte en dos, en todo el fichero** — también en las líneas que no tocaste. Quitar
el BOM no arregla nada por sí solo: la codificación es lo que manda.

### Cómo se escribe sin romperlo

| Vía | Qué hacer |
|---|---|
| **FoxAgent** `write_source_file` | La recomendada para los binarios (`.scx`/`.vcx`/…): pone la codificación y hace copia con marca de tiempo |
| **Python** | `io.open(p, encoding='cp1252', newline='')` para leer y para escribir; `newline=''` conserva los finales de línea |
| **PowerShell** | `[IO.File]::ReadAllText($ruta, [Text.Encoding]::GetEncoding(1252))` y `WriteAllText` igual |
| **La herramienta de escritura de un agente** | Suele guardar **UTF-8**. Sólo vale si el contenido es ASCII puro (0-127), que en las dos codificaciones son los mismos bytes. Con acentos hay que reconvertir después |

### Comprobarlo cuesta una línea

Un `.prg` sano con acentos **no** debe decodificar como UTF-8:

```python
d = open(ruta, 'rb').read()
print('no-ASCII:', sum(1 for b in d if b > 127))   # 0 => el fichero no prueba nada
try:
    d.decode('utf-8'); print('OJO: es UTF-8, está mal')
except UnicodeDecodeError:
    print('OK: es CP1252')
```

### Lo que CP1252 no tiene se RECHAZA, no se degrada

CP1252 **sí** tiene euro, comillas curvas, raya larga y puntos suspensivos: no hay que
evitarlos. Lo que no tiene —checkmarks, flechas Unicode, alfabetos no latinos— no se
sustituye por `?` a espaldas de nadie: se rechaza nombrando el carácter. Ver la regla 51.

### Los `.prg` de X# son OTRA COSA

`FoxServer.Core`, `Nexum.Http` y compañía usan la misma extensión, pero **no los lee VFP: los
compila X#**. Ésos van en **UTF-8 con BOM**. No les apliques esta regla.

*Origen: la regla vieja venía de `VFP.AI.SDK`, donde el ASCII puro era un cortafuegos contra
la herramienta de escritura, no una exigencia de VFP. Corregida el 2026-08-22.*

## 10. Un `PROCEDURE` indentado con TAB no lo descubre FoxUnit — y la suite sale verde

**Corregida en la unificación (2026-08-15).** Decía *"Usar espacios para indentacion. Nunca
tabs"*, y era falsa como regla general: todo el producto de `VFP.AI.SDK` está indentado con
tabuladores desde A4 y compila y funciona. La regla verdadera es más estrecha y mucho más
peligrosa.

**En un fichero de tests, indenta con espacios. Siempre.** El descubridor de FoxUnit no
reconoce un `PROCEDURE` precedido de tabulador, así que el test **desaparece del inventario
sin un solo aviso**.

```foxpro
DEFINE CLASS TabProbeTests AS Custom
    PROCEDURE Test_ConEspacios() HELP [Fact]     && descubierto
        __assert.True(.T., "espacios")
    ENDPROC

	PROCEDURE Test_ConTab() HELP [Fact]          && INVISIBLE (indentado con TAB)
		__assert.True(.T., "tab")
	ENDPROC
ENDDEFINE
```

Medido con `foxunit` el 2026-08-15 sobre ese fichero exacto:

```text
foxunit list  ->  { "total": 1, ... }      solo Test_ConEspacios
foxunit run   ->  1 passed  (22ms)         VERDE
```

Lo caro no es perder el test: es que **la suite no se pone roja**. Un test que no existe no
falla, y nadie va a buscar lo que nunca apareció en la lista. Es el mismo modo de fallo
silencioso que la regla 42, y por el mismo motivo hay que conocerlo de antemano.

En el **producto** los tabuladores son legales y se usan. Si escribes código para un
repositorio, mira cómo está indentado el fichero de al lado (`cat -A` distingue `^I` de
espacios) y sigue esa convención — con la única excepción innegociable de los `Tests\*.prg`.

## 11. Finales de línea: no asumas ninguno — mira el fichero

**Corregida en la unificación (2026-08-15).** Decía *"Line endings Windows (CR+LF). No solo
LF"*, y en la práctica no se cumple: los `.prg` de `VFP.AI.SDK` están en **LF puro**,
FoxExtends documenta *"LF puro (sin CR)"* como obligatorio, y la regla 39 de este mismo
documento describe repositorios con finales **mezclados dentro del mismo árbol**.

VFP lee los tres (CRLF, LF y CR solo) sin quejarse, así que el final de línea **no es un
problema de VFP**: es un problema de `git`, de `ALINES()` (regla 34) y de diffs que salen
enteros en rojo.

La regla operativa:

```text
fichero que ya existe   respeta el final de linea que tiene. No lo "arregles" de paso
fichero nuevo           el mismo que sus vecinos en esa carpeta
.gitattributes          si el repo lo declara, manda el .gitattributes
```

Un commit que cambia 1.200 líneas porque tu editor normalizó los finales esconde las 3 que
de verdad tocaste.

## 12. Tablas DBF libres

- Nombres de campo: maximo 10 caracteres.
- Campos C(): maximo 254 caracteres. Para textos largos usar M (memo).
- Tags de indice: maximo 10 caracteres.

## 13. Aritmetica de DATETIME

`DATETIME + n` suma n **segundos**, no n dias.
Usar constantes de segundos: 1 minuto = 60, 1 hora = 3600, 1 dia = 86400.

## 14. SELECT INTO ARRAY

Declarar el array antes de usarlo en SELECT.

```foxpro
LOCAL ARRAY laCount[1]
laCount[1] = 0
SELECT COUNT(*) FROM orders INTO ARRAY laCount
```

---

## 15. No encadenar metodos sobre el resultado de una llamada

VFP **no** admite `this.Metodo().OtroMetodo()`: parsea `Metodo()` como referencia a un
array y falla con *'RESULTFACTORY' is not an array* o *Invalid subscript reference*.

Es la misma familia que la regla ya conocida de `CREATEOBJECT(...).Metodo()`.

```foxpro
* INCORRECTO
return this.ResultFactory().CreateSuccess(tcMessage, tvData)

* CORRECTO -- el objeto intermedio necesita una variable
local loFactory
loFactory = this.ResultFactory()
return loFactory.CreateSuccess(tcMessage, tvData)
```

Descubierto en A4 al introducir las factorias de `ToolResult` y `VfpAiError`.

---

## 16. `Name` es una propiedad reservada de Custom

Toda clase derivada de `Custom` (o de cualquier control) trae ya una propiedad `Name`, y
VFP **valida su contenido como identificador**. Asignarle un valor con guiones, puntos o
espacios lanza *Expression evaluated to an illegal value* en el `Init`, y el error apunta
al nombre de la clase, no a la linea, asi que cuesta encontrarlo.

```foxpro
* INCORRECTO -- 'gpt-4o-mini' no es un identificador valido
define class MiDescriptor as custom
    procedure init(tcId)
        this.Name = tcId
    endproc
enddefine

* CORRECTO -- usar un nombre propio para el dato
define class MiDescriptor as custom
    Id = ""
    DisplayName = ""
    procedure init(tcId)
        this.Id = tcId
    endproc
enddefine
```

Descubierto en A5 al crear los descriptores de proveedor y modelo.

---

## 17. INLIST() y `=` respetan SET EXACT

Con `SET EXACT OFF` (el valor por defecto), la comparacion de cadenas es por prefijo. Eso
afecta tambien a `INLIST()`:

```foxpro
? "BOOLEAN" = "B"                       && .T.  con EXACT OFF
? INLIST("BOOLEAN", "N", "B", "F")      && .T.  -- casi nunca es lo que se quiere
? "BOOLEAN" == "B"                      && .F.  comparacion exacta
```

Un `DO CASE` que mezcle codigos de un caracter con nombres largos clasifica mal:
`"BOOLEAN"` cae en la rama de los numericos por culpa de `"B"`.

```foxpro
* INCORRECTO
case inlist(lcType, "N", "I", "Y", "B", "F") or lcType == "NUMBER"

* CORRECTO -- primero los nombres largos con ==, y los codigos solo si miden 1
case lcType == "NUMBER" or lcType == "NUMERIC"
    return "number"
case len(lcType) = 1 and inlist(lcType, "N", "I", "Y", "B", "F")
    return "number"
```

No cambiar `SET EXACT` globalmente para arreglarlo: afecta a todo el proceso, incluida la
aplicacion anfitriona. Escribir la comparacion correcta es local y no sorprende a nadie.

Descubierto en A6 escribiendo el mapeo de tipos del generador de schema.

---

## 18. El marcador de comentario `&&` no puede escribirse como literal de cadena

El compilador de VFP trata `&&` como inicio de comentario **aunque este entre comillas**. Una
linea que contenga el literal de dos ampersands hace que el fichero entero deje de compilar,
con un generico `Syntax error` que no dice donde.

```foxpro
* INCORRECTO -- el .prg no compila
lnPos = AT("&&", lcLinea)

* CORRECTO -- el marcador se construye en tiempo de ejecucion
lcMarcador = CHR(38) + CHR(38)
lnPos = AT(lcMarcador, lcLinea)
```

Un ampersand **suelto** dentro de una cadena (`"a & b"`) es perfectamente valido: el problema
son los dos seguidos.

Solo importa cuando se escribe codigo que analiza codigo VFP -- un escaner, un formateador, un
generador. Descubierto en A8 escribiendo `Tests/SecurityInvariantTests.prg`.

---

## 19. ALLTRIM() quita espacios, no tabuladores

```foxpro
? LEFT(ALLTRIM(CHR(9) + "* comentario"), 1) == "*"     && .F.  el tabulador sigue delante
? LEFT(ALLTRIM(CHRTRAN(CHR(9) + "* comentario", CHR(9), " ")), 1) == "*"   && .T.
```

Las fuentes de este repositorio estan indentadas con tabuladores, asi que cualquier analisis
linea a linea tiene que normalizarlos antes de recortar. Sin eso, una linea de comentario
indentada no se reconoce como comentario.

Descubierto en A8: el escaner de ejecucion dinamica contaba de mas porque leia los
`EVALUATE` que aparecen dentro de comentarios.

---

## 20. FGETS() sin segundo argumento trunca a 254 caracteres

```foxpro
lcLinea = FGETS(lnHandle)          && como maximo 254 caracteres
lcLinea = FGETS(lnHandle, 16384)   && la linea entera
```

Lo peor no es el truncado: es que **el resto de la linea se devuelve como si fuera la linea
siguiente**. Un fichero JSONL valido se lee partido, la primera mitad como registro bueno y la
segunda como basura.

Descubierto en A8, cuando el sobre de evento v2 hizo que las lineas del journal pasaran de
~250 a ~260 caracteres y `VfpAiExecutionReplay` empezo a ver lineas corruptas que no existian.
El defecto era anterior: solo hacia falta una linea larga para verlo.

---

## 21. Una propiedad y un metodo no pueden llamarse igual

VFP no distingue mayusculas, asi que una propiedad `_jsonWriter` y un metodo `_JsonWriter()`
en la misma clase son el mismo nombre. El error en tiempo de ejecucion es
`Property _JSONWRITER is not a method or event.`

```foxpro
* INCORRECTO
hidden _jsonWriter
hidden function _JsonWriter
    ...

* CORRECTO -- nombres distintos
hidden _writerRef
hidden function _JsonWriter
    ...
```

Descubierto en A8 al cachear el escritor JSON del journal.

---

## 22. VFP no encadena sobre el resultado de NINGUN metodo

La regla ya estaba escrita para `CREATEOBJECT()` (seccion sobre ejecucion inline), pero es mas
amplia: **VFP no sabe navegar el resultado de ninguna llamada**. Da igual que sea un
`CREATEOBJECT()`, un metodo propio o un metodo de otro objeto.

```foxpro
* INCORRECTO -- "Unrecognized command verb" en compilacion, o
* "UIRESOLVER is a method, event, or object" en ejecucion
return this.UiResolver(toContext).ResolveFromContext(toContext, tcName)
loExec.SetCapabilitySet(CREATEOBJECT("VfpAiCapabilitySet").DefaultHost())
if this.HostPolicy().AllowMessageBox

* CORRECTO -- el objeto tiene que vivir en una variable
local loResolver
loResolver = this.UiResolver(toContext)
return loResolver.ResolveFromContext(toContext, tcName)

local loFactory
loFactory = createobject("VfpAiCapabilitySet")
loExec.SetCapabilitySet(loFactory.DefaultHost())

local loPolicy
loPolicy = this.HostPolicy()
if loPolicy.AllowMessageBox
```

El codigo del repositorio ya lo respetaba por costumbre (`loFactory = this.ResultFactory()` y luego
usarlo), pero no estaba dicho como regla general. Se colo en catorce sitios de la primera pasada de
A10. Si un metodo devuelve un objeto que hay que usar, **siempre** una variable en medio.

**Y una precisión que hace falta desde que existe la 55.1:** `WITH ... ENDWITH` **no** es
una salida para *este* caso. Sirve cuando encadenabas por **fluidez** sobre un objeto que
muta —`.Where().OrderBy().Take()`— porque ahí el retorno de cada llamada sobra. Aquí no
sobra: el objeto que devuelve `this.UiResolver(toContext)` **es** lo que necesitas usar
después. Cuando hace falta el valor devuelto, la variable en medio no tiene sustituto.

---

## 23. Un comentario dentro de una continuacion `;` rompe la sentencia

Una linea de comentario colocada entre dos tramos unidos por `;` parte la sentencia en dos.

```foxpro
* INCORRECTO
return "A," + ;
* este comentario parte la sentencia
    "B," + ;
    "C"

* CORRECTO -- el comentario va ENCIMA de la sentencia entera
* este comentario explica la lista
return "A," + ;
    "B," + ;
    "C"
```

Los dos errores que produce no mencionan el comentario:

```text
Error in line N:   Missing operand.
Error in line N+1: Unrecognized command verb.
```

Pasado dos veces en A10: en `VfpAiError.ListCodes()` y en la allowlist de
`Tests/SecurityInvariantTests.prg`.

---

## 24. `SYS(16)` devuelve un prefijo cuando se llama desde un metodo

Desde el nivel de modulo, `SYS(16)` devuelve la ruta del programa. Desde un **metodo de una clase
cargada con `SET PROCEDURE`**, devuelve la ruta precedida del nombre del procedimiento:

```text
nivel de modulo:  C:\ruta\PROGRAMA.FXP
dentro de metodo: PROCEDURE MICLASE.MIMETODO C:\ruta\MICLASE.FXP
```

De modo que `JUSTPATH(SYS(16))` da basura dentro de un metodo. Si hay que deducir el directorio del
programa desde una clase, hay que limpiar el prefijo antes (ver `VfpEnvironment.CleanProgramPath()`).
La ruta puede llevar espacios, asi que solo se descartan los dos primeros tokens.

Descubierto en A10 al mover `GetLanguage`/`Is64bit` de la fachada -- donde la llamada estaba fuera de
toda clase -- a `VfpEnvironment`.

---

## 25. No redeclarar `Name` en una subclase de `Custom`

`Custom` ya trae `Name`. Redeclararla con cadena vacia deja el objeto en un estado que VFP rechaza
cuando despues se le asigna un valor:

```foxpro
* INCORRECTO
define class MiFake as Custom
    Name = ""        && a partir de aqui, loObj.Name = "algo" falla
    ...

* Error: "Error with  - Name : Expression evaluated to an illegal value."
```

Lo mismo aplica a otros miembros nativos de `Custom`. Para dobles de formulario en tests, es mejor
instanciar un `Container` de verdad y usar `AddObject()`: la jerarquia `Controls`/`ControlCount`
resultante es la autentica, no una imitacion.

Descubierto en A10 escribiendo los tests de `VfpUiResolver`.

---

## 26. `Name` tiene que ser un identificador valido -- amplia la regla 25

La regla 25 decia "no redeclarar `Name` con cadena vacia en una subclase de `Custom`". **Era mas
estrecha que el problema.** `Name` es un miembro nativo, y VFP exige que su valor sea un identificador
valido: sin guiones, sin puntos, no vacio.

```foxpro
* INCORRECTO -- "Expression evaluated to an illegal value" al asignarla despues
define class RuntimeTask as custom
    Name = ""

* INCORRECTO -- "Object name is invalid", por el guion
define class LocalSyncRuntimeAdapter as RuntimeAdapter
    Name = "local-sync"

* CORRECTO -- semantica propia, nombre propio
define class RuntimeTask as custom
    TaskName = ""

define class LocalSyncRuntimeAdapter as RuntimeAdapter
    AdapterName = "local-sync"
```

Regla practica: **no uses `Name` para semantica tuya en una subclase de `Custom`**. Ponle un nombre que
diga de que hablas (`TaskName`, `AdapterName`, `ToolName`) y deja `Name` en paz.

Lo caro no es el arreglo: es que el sintoma -- `Object name is invalid` en mitad de una ejecucion --
no menciona `Name` ni la clase que lo declara.

Nota: esto NO aplica a objetos `Empty`, que no tienen miembros nativos. Por eso `ToolParameter.Name`
-- frontera con FoxAgent -- puede seguir llamandose asi sin problema.

Descubierto en A11, por dos caminos distintos, un mes despues de escribir la regla 25.

---

## 27. Un test que se lee a si mismo se encuentra a si mismo

Una suite puede verificar su propia disciplina leyendo su fichero (p.ej. "esta suite no lanza
procesos"). La trampa: las agujas aparecen en las lineas del propio `__assert` -- tanto en la
expresion como **en el mensaje de error** -- asi que el test falla siempre, por su propio texto.

```foxpro
* INCORRECTO -- se encuentra a si mismo dos veces
__assert.False(".BAT" $ lcClean, "Ni ningun .bat")

* CORRECTO -- aguja compuesta, y mensaje sin el token
__assert.False((".B" + "AT") $ lcClean, "Ni ejecuta ficheros por lotes")
```

Descubierto en A11 con `Test_Suite_NoLanzaProcesos`. El patron es util; la trampa no es evidente
hasta que se pisa.

---

## 28. `CTOD()` y `CTOT()` dependen de `SET DATE` -- y `CTOD("yyyymmdd")` no funciona nunca

Convertir texto a fecha con `CTOD()`/`CTOT()` lee la cadena **segun la configuracion regional
vigente**, asi que el mismo texto da una fecha, otra, o una fecha vacia. Y el formato compacto
`yyyymmdd` -- el que uno escribiria pensando que es el neutro -- no lo entiende ninguno.

Comprobado en VFP 9 para A11b:

| Expresion | `SET DATE AMERICAN` | `SET DATE DMY` |
|---|---|---|
| `CTOD("08/14/2026")` | `20260814` | **vacia** |
| `CTOD("20260814")` | **vacia** | **vacia** |
| `TTOC(dt)` | segun configuracion | segun configuracion |
| `TTOC(dt, 1)` | `20260814103000` | `20260814103000` |

```foxpro
* INCORRECTO -- depende del entorno, y el caso compacto siempre falla
lcOut = dtoc(ldFecha)
ldBack = ctod(lcTexto)

* CORRECTO -- formato fijo al salir, reconstruccion explicita al volver
lcOut = dtos(ldFecha)                  && yyyymmdd
lcOut = ttoc(ltFecha, 1)               && yyyymmddhhmmss
ldBack = date(val(left(lcOut, 4)), val(substr(lcOut, 5, 2)), val(substr(lcOut, 7, 2)))
```

Descubierto en A11b escribiendo `RuntimeTaskSerializer`: un mensaje que se lee distinto segun la
configuracion regional del proceso que lo recibe no es un mensaje. Aplica a cualquier serializacion,
exportacion o fichero de intercambio, no solo al transporte de tareas.

---

## 29. Una propiedad no puede llamarse como una variable de sistema (`_BUILDER`, `_TALLY`, ...)

VFP trae variables de sistema con nombre `_XXX` (`_SCREEN`, `_VFP`, `_TALLY`, `_BUILDER`,
`_WIZARD`, `_GALLERY`, `_TEXT`, `_CLIPTEXT`, ...). Declarar una **propiedad** con uno de esos
nombres hace que la clase falle **al instanciarse**:

```text
Must be a variable or array.
```

Comprobado en VFP 9 para A12, con `_builder` y con `_tally`:

```foxpro
* INCORRECTO -- CREATEOBJECT() falla con "Must be a variable or array"
define class MiMapper as custom
    hidden _builder
    procedure init
        this._builder = createobject("VfpAiToolSchemaBuilder")
    endproc
enddefine

* CORRECTO -- un nombre que no colisione
define class MiMapper as custom
    hidden _schemaBuilder
    procedure init
        this._schemaBuilder = createobject("VfpAiToolSchemaBuilder")
    endproc
enddefine
```

Lo caro no es el arreglo: es que **el error no menciona el miembro** ni la clase, y aparece al crear
el objeto, no al compilar. Si `CREATEOBJECT()` de una clase recien escrita falla con ese mensaje,
mirar primero los nombres de sus propiedades: `TYPE("_loquesea")` distinto de `"U"` en una sesion
limpia significa que el nombre esta cogido.

Es la misma familia que las reglas 16, 25 y 26 (`Name`): VFP tiene vocabulario reservado y no avisa
al declararlo, solo al usarlo.

**La comprobacion, en una linea.** Antes de bautizar una propiedad `_algo`, en una sesion limpia:

```foxpro
? TYPE("_algo")     && "U" = el nombre esta libre; cualquier otra cosa = cogido
```

A11b.1 la aplico por adelantado al bautizar `_bridge`, `_credentials` y `_schemaBuilder`, y no
costo nada: la regla solo es cara cuando se descubre despues.

Descubierto en A12 escribiendo `ProviderToolSchemaMapper`.

---

## 30. Un parametro logico OMITIDO llega como `.F.`, no como "sin valor"

Con las cadenas, `EVL()` basta para distinguir "no me lo pasaron" de "me pasaron algo", porque un
parametro omitido llega como `.F.` y `VARTYPE() != 'C'` lo delata. Con los **logicos** eso no
funciona: el valor omitido y el `.F.` explicito son indistinguibles por tipo.

```foxpro
* INCORRECTO -- llamar sin argumentos toma la rama del .F.
function PromptChars
    lparameters tlIncludeSystem
    if vartype(tlIncludeSystem) != 'L' or tlIncludeSystem   && siempre .F. si se omite
        lnTotal = len(this.SystemPrompt)
    endif

* CORRECTO -- PCOUNT() es lo unico que sabe cuantos llegaron
function PromptChars
    lparameters tlIncludeSystem
    local llIncludeSystem
    llIncludeSystem = .t.
    if pcount() >= 1
        llIncludeSystem = iif(vartype(tlIncludeSystem) == 'L', tlIncludeSystem, .t.)
    endif
```

Regla practica: si un parametro logico tiene que valer `.T.` por defecto, **hace falta `PCOUNT()`**.
Si su defecto es `.F.`, no hace falta nada.

Descubierto en A12: `PromptChars()` devolvia la suma sin el prompt de sistema, y el test lo cazo
porque afirmaba el numero exacto en vez de "mayor que cero".

---

## 31. `USE IN SELECT(alias)` sin guardia cierra el area ACTUAL

`SELECT(cAlias)` devuelve el numero de area de trabajo del alias, **o 0 si no esta abierto**. Y
`USE IN 0` no significa "en ninguna": significa **en el area actual**. De modo que el idioma habitual
para cerrar una tabla, sin comprobar antes que esta abierta, cierra la tabla del llamante:

```foxpro
* INCORRECTO -- si el alias no esta abierto, SELECT() da 0 y se cierra el area actual
use in select("mi_tabla")

* CORRECTO -- la guardia no es cosmetica
if used("mi_tabla")
    use in select("mi_tabla")
endif
```

Es la misma familia que las reglas 25, 26 y 29: VFP no avisa, y el sintoma aparece lejos --el
llamante descubre que su cursor ya no esta abierto en una linea que no toca ninguna tabla.

### Y por que el alias no puede calcularse

La clausula `ALIAS` de `USE` no admite una expresion de nombre entre parentesis, asi que un alias
calculado obligaria a macro-expansion (`use ... alias &lcAlias`), que A3b prohibio. La salida es
**derivar el alias del nombre del fichero** --`USE (lcFichero) IN 0 SHARED` deja como alias el
nombre base-- y validar ese nombre como identificador simple antes de usarlo.

```foxpro
* CORRECTO -- el alias sale del fichero, y el nombre se valida antes
lcFichero = addbs(lcDirectorio) + lcTabla + ".dbf"
use (lcFichero) in 0 shared         && alias = lcTabla
```

Regla practica para cualquier clase del SDK que abra una tabla propia: **guardar `SELECT()` al
entrar y restaurarlo al salir**, no tocar `SET DELETED` --es global y afecta al host entero-- y
resolver el borrado con un campo logico propio.

Aplicada por adelantado en A13a al escribir `DbfMemoryStore`, que es la primera clase del SDK que
crea una tabla en el disco del host. La regla solo es cara cuando se descubre despues.

---

## 32. Un test que se lee a si mismo choca con el VOCABULARIO, no solo consigo mismo

La regla 27 decia: una suite que verifica su propia disciplina leyendo su fichero se encuentra a si
misma en el texto de sus `__assert`, asi que las agujas van compuestas. **Era mas estrecha que el
problema.** La aguja tambien choca con **identificadores legitimos** del producto y con **los
comentarios** del propio test.

Caso real de A13b: la suite comprueba que no lanza procesos buscando la extension de los ficheros por
lotes. El kind de tarea de embeddings **termina con esa extension**, asi que el guardia senalaba un
nombre de evento perfectamente correcto.

```foxpro
* INCORRECTO -- el kind legitimo dispara el guardia
lcSource = UPPER(FILETOSTR(lcMiFichero))
__assert.False((".B" + "AT") $ lcSource, "Ni ficheros por lotes")

* CORRECTO -- se quita el token legitimo ANTES de buscar,
* y NO se relaja la aguja: eso la dejaria sin servir para nada
lcClean = STRTRAN(lcSource, "EMBEDDING." + "BATCH", "")
__assert.False((".B" + "AT") $ lcClean, "Ni ficheros por lotes")
```

Dos detalles que costaron un intento cada uno:

1. **El corte del token va DESPUES del punto.** Partirlo antes deja la aguja contigua en la propia
   linea del filtro, y el test se vuelve a encontrar.
2. **Los COMENTARIOS cuentan.** El escaner lee el fichero entero; nombrar la extension en la prosa
   que explica el problema basta para que el test falle. Hay que describirla en palabras.

Y una comprobacion que conviene anadir siempre que se filtre: que el filtro no se haya comido medio
fichero.

```foxpro
__assert.True(LEN(lcClean) > LEN(lcSource) - 500, "Solo se quita el token legitimo")
```

Descubierto en A13b. El patron de la regla 27 sigue siendo util; lo que hace falta es saber que la
trampa tiene tres caras y no una.

---

## 33. FGETS() sin tamano y la regla 22, otra vez -- y como dejar de pisarlas

Dos reglas viejas, dos formas nuevas de tropezar con ellas. Se anotan juntas porque la leccion es la
misma: **una regla que solo esta escrita se vuelve a pisar; una regla convertida en API, no.**

### 33.1 FGETS() en un fichero de datos propio

La regla 20 nacio leyendo el journal JSONL. Vale igual para cualquier fichero de lineas largas que el
SDK escriba: un almacen de vectores de 256 componentes pasa de 2000 caracteres por linea.

```foxpro
* INCORRECTO -- lee 254 y devuelve el resto COMO SI FUERA OTRA LINEA
lcLinea = FGETS(lnHandle)

* CORRECTO -- y la constante, en una propiedad, para poder explicarla
MaxLineBytes = 262144
lcLinea = FGETS(lnHandle, THIS.MaxLineBytes)
```

Lo peligroso no es el truncado: es que el parser se traga la segunda mitad como si fuera un registro,
y produce datos plausibles y equivocados.

### 33.2 La regla 22 se pisa cuando falta un setter

`VFP no navega el resultado de un metodo` es la regla 22. En una fase se colo **diez veces**, siempre
con la misma forma:

```foxpro
* INCORRECTO -- Syntax error, y el mensaje no menciona el encadenado
loIndexer.GetChunker().MaxChunkChars = 120
```

La solucion mecanica es una variable intermedia en cada sitio. La solucion **buena** es que la clase
de fuera exponga lo que hace falta:

```foxpro
* CORRECTO -- y ademas mejor API: el host no tiene que conocer la pieza de dentro
loIndexer.SetChunkSize(120)
```

Regla practica: **si al escribir una llamada aparece `obj.Getter().Propiedad`, no falta una variable
intermedia -- falta un metodo.** El encadenado prohibido es, casi siempre, la senal de una API que
obliga a bajar un nivel.

Descubierto en A13c, escribiendo el almacen de vectores en fichero y el indexador de documentos.

---

## 34. `ALINES()` decide por su cuenta qué hacer con los campos vacíos

`ALINES()` es el idioma habitual para partir una cadena por un separador: se sustituye el separador
por un salto de línea y se parsea. Funciona mientras **todos** los campos tengan contenido. En cuanto
uno puede venir vacío, deja de servir para posiciones fijas: `ALINES()` no garantiza devolver una
entrada por cada línea vacía, así que **un campo vacío en medio desplaza todos los siguientes una
posición**.

```foxpro
* INCORRECTO -- con "a|b||d", laParts[4] puede acabar valiendo "" o "d",
* y el parser no tiene forma de saber cuál
lnCount = ALINES(laParts, CHRTRAN(lcLinea, "|", CHR(13)))
lcCuarto = laParts[4]

* CORRECTO -- un recorrido con AT()/SUBSTR() conserva los vacíos en su sitio
lnCount = THIS.SplitFields(lcLinea, @laParts)
```

```foxpro
FUNCTION SplitFields(tcLine, taParts)
    EXTERNAL ARRAY taParts
    LOCAL lcText, lnCount, lnPos, lnAt
    lcText = IIF(VARTYPE(tcLine) == 'C', tcLine, "")
    lnCount = 0
    lnPos = 1
    DO WHILE .T.
        lnAt = AT("|", SUBSTR(lcText, lnPos))
        lnCount = lnCount + 1
        DIMENSION taParts[lnCount]
        IF lnAt = 0
            taParts[lnCount] = SUBSTR(lcText, lnPos)
            EXIT
        ENDIF
        taParts[lnCount] = SUBSTR(lcText, lnPos, lnAt - 1)
        lnPos = lnPos + lnAt
    ENDDO
    RETURN lnCount
ENDFUNC
```

Es la misma familia que la regla 20 (`FGETS()` sin tamaño) y tiene el mismo agravante: **no rompe,
miente**. El parser se traga la línea desplazada y produce registros plausibles y equivocados.

Regla práctica: `ALINES()` está bien para partir texto en líneas o en tokens que se van a recorrer;
**no** para leer un formato de posiciones fijas. En cuanto el formato tenga un campo opcional, hace
falta un separador que conserve los vacíos.

Descubierto en A13d, al añadir dos campos al fichero de `FileVectorStore` — campos que legítimamente
pueden venir vacíos, que es lo que destapó el defecto latente del parser de A13c.

---

## 35. Un dato derivado sólo es reutilizable si se guarda con su procedencia

No es una regla de sintaxis de VFP, sino de diseño de datos, y se paga igual de cara.

Un índice, una caché o cualquier cálculo que se guarde para no repetirlo necesita llevar al lado
**con qué se calculó**, no sólo el resultado. Sin eso hay exactamente dos salidas, y las dos son
malas: recalcularlo siempre —y entonces guardarlo no sirvió de nada— o darlo por bueno siempre —y
entonces el día que cambia la configuración el dato miente sin avisar.

```foxpro
* INCOMPLETO -- se puede saber si el texto cambio, no si lo calculo el mismo modelo
loVector.ContentHash = lcHuellaDelTexto

* COMPLETO -- las tres cosas que deciden si sigue valiendo
loVector.ContentHash = lcHuellaDelTexto
loVector.ModelId = lcModelo
loVector.ProviderId = lcProveedor
```

El corolario que importa: **un dato guardado que no puede demostrar su procedencia se recalcula**. Es
preferible una llamada de más a un índice del que no se sabe de dónde salió. Eso permite además que un
formato antiguo se lea sin migración — se lee, no se da por vigente, y se rehace una vez.

Y la marca de tiempo que acompaña a esa procedencia va en `yyyymmddhhmmss` (regla 28), no en un
`DATETIME` serializado por omisión: si el dato lo va a leer otro proceso, una marca que se interpreta
según la configuración regional no es una marca.

Descubierto en A13d escribiendo el reindexado incremental: `ContentHash` por sí solo contestaba media
pregunta, y la mitad que faltaba —cambiar de modelo de embeddings invalida el índice entero sin tocar
una letra del documento— es justo la que nadie ve venir.

---

## 36. `Error` es un miembro nativo de `Custom` — amplía las reglas 16, 25, 26 y 29

La familia ya estaba escrita para `Name` (16, 25, 26) y para los nombres de variable de sistema
`_XXX` (29). Falta un miembro que nadie ve venir porque **no se parece a un nombre reservado**:
`Error` es el **evento de error** de todo objeto VFP.

```foxpro
* INCORRECTO -- la clase revienta AL INSTANCIARSE
define class WorkerTaskResult as custom
    Error = null
    procedure init
        this.Error = createobject("WorkerTaskError")
    endproc
enddefine

* Error en tiempo de ejecucion:
*   ERROR is a method, event, or object.

* CORRECTO -- semantica propia, nombre propio
define class WorkerTaskResult as custom
    ErrorInfo = null
enddefine
```

Lo caro no es el arreglo: es que **el mensaje no menciona la clase ni la propiedad**, y el fallo
aparece dentro de un `CREATEOBJECT()` que puede estar tres niveles por debajo de lo que se estaba
probando. En A11b.2 se manifestó como una cadena de once tests fallando por motivos que parecían
distintos entre sí.

Miembros nativos que **no** deben usarse como propiedades propias en una subclase de `Custom`:

```text
Name  Error  Class  ParentClass  BaseClass  Comment  Tag  Parent  Application  Objects
```

Regla práctica, la misma de siempre: **si el nombre describe algo del objeto en general y no de tu
dominio, ya está cogido.** `TaskName`, `AdapterName`, `ErrorInfo`, `ToolName` no chocan con nada.

Descubierto en A11b.2 escribiendo el resultado del worker.

---

## 37. `HIDDEN` es invisible para las subclases — incluso a través de `DODEFAULT()`

En VFP, `HIDDEN` no significa «privado del objeto»: significa **privado de la clase que lo declara**.
Una subclase no ve ese miembro, y —esto es lo que sorprende— **tampoco lo ve un método heredado que se
ejecuta con `DODEFAULT()`**.

```foxpro
* INCORRECTO -- si esta clase va a subclasificarse
define class LoopbackTaskBridge as FoxCoreTaskBridge
    hidden _tasks, _counter

    function SubmitTask
        lparameters toRequest
        this._counter = this._counter + 1      && OK aqui
        ...
    endfunc
enddefine

* El doble de pruebas:
DEFINE CLASS FaultyBridge AS LoopbackTaskBridge
    FUNCTION SubmitTask(toRequest)
        RETURN DODEFAULT(toRequest)            && revienta
    ENDFUNC
ENDDEFINE

* Error en tiempo de ejecucion:
*   Property _COUNTER is not found.     [submittask:1662]
```

El mensaje señala una línea **del padre**, que el autor del doble no ha escrito y probablemente no ha
leído. Y sólo aparece cuando alguien subclasifica: la clase original funciona perfectamente sola,
así que el defecto viaja sin ser visto hasta el primer doble de tests.

```foxpro
* CORRECTO -- si la clase esta pensada para heredarse
define class LoopbackTaskBridge as FoxCoreTaskBridge
    protected _tasks, _counter
```

Regla práctica: **`HIDDEN` sólo para clases hoja.** En cuanto una clase existe para ser extendida —un
contrato, un adapter, un bridge, un store— sus miembros internos van `PROTECTED`. `HIDDEN` no compra
encapsulación frente al mundo exterior que `PROTECTED` no compre ya: las dos son invisibles desde
fuera, y la diferencia es exactamente la que rompe a los herederos.

Descubierto en A11b.2, con un bridge en el árbol de producto que existe **para** ser subclasificado
por la suite.

---

## 38. La regla 22 vale para métodos PROPIOS, no para los nativos — y el error miente

La regla 22 dice que VFP no encadena sobre el resultado de **ningún** método. A12b encontró que la
frase es correcta en la práctica pero incompleta en el diagnóstico, y la diferencia importa porque
determina dónde se busca el fallo.

```foxpro
* FUNCIONA -- Item() es un metodo NATIVO de Collection
loFirst = loHost.Items.Item(1).Index

* FALLA -- First() es un metodo escrito por nosotros
loFirst = loHost.First().Index
```

El error de la segunda forma es:

```text
Invalid subscript reference.
```

**Que no menciona ni el método, ni la propiedad, ni el encadenamiento.** Habla de subíndices, así que
lo primero que uno mira es el array o la colección — que están perfectos. Es el mismo patrón de la
regla 29: el mensaje señala una categoría de problema que no es la que hay.

Comprobado con un script mínimo: la misma propiedad (`Index`), en el mismo objeto, encadenada desde
`Collection.Item()` devuelve su valor y encadenada desde una `FUNCTION` propia lanza *Invalid
subscript reference*.

Regla práctica, sin excepciones que memorizar: **si el método lo has escrito tú, una variable en
medio.** Da igual lo corto que sea el encadenamiento y da igual que otro encadenamiento parecido
funcione tres líneas más arriba.

```foxpro
* CORRECTO
loFirst = loResponse.FirstToolCall()
__assert.Equal("c1", loFirst.ToolCallId, "...")
```

Descubierto en A12b, escribiendo el test de varias tool calls por respuesta.

### Apéndice A11b.3 — el mismo error, otro mensaje

`this.GetSession().MarkCrashed()` es la regla de arriba con una vuelta de tuerca en el diagnóstico:

```text
Invalid subscript reference.   [crash:1228]
```

La línea que señala es **del método llamado** (`crash`, línea 1228 del módulo), no de la que encadena.
Quien lea la traza empieza a buscar en el sitio equivocado — el cuerpo de un método que está
perfectamente bien.

Tercera aparición en tres fases. La regla práctica no cambia y no admite excepciones: **si el método
lo has escrito tú, una variable en medio**.

```foxpro
* CORRECTO
local loSession
loSession = this.GetSession()
loSession.MarkCrashed()
```

---

## 39. Los `.prg` de este repositorio tienen finales de línea MEZCLADOS

No es una regla del lenguaje: es una del repositorio, y cuesta lo mismo que una del lenguaje cuando se
tropieza con ella.

Varios `.prg` tienen tramos con `CRLF` y tramos con `LF`, resultado de años de ediciones desde editores
distintos. VFP los compila igual y no se nota nunca… hasta que una sustitución de texto asume uno de
los dos:

```python
# Falla en silencio: el fichero tiene 
 en ese tramo
old = '		case lcCode == "X"
			return .t.
'
assert old in s        # AssertionError, y el bloque SE VE en el fichero
```

El síntoma es de los peores: **la cadena está delante de tus ojos y el buscador dice que no está.** Y
`grep` no ayuda, porque encuentra cada línea por separado.

Cómo comprobarlo antes de perder el rato:

```bash
sed -n '298,300p' fichero.prg | od -c | head
```

Y cómo escribir la sustitución para que no dependa de ello: normalizar a `
`, sustituir, y volver a
poner el final de línea que tuviera el fichero.

```python
crlf = '
' in s
s_n  = s.replace('
', '
')
s_n  = s_n.replace(old, new, 1)
if crlf:
    s_n = s_n.replace('
', '
')
```

Descubierto en A11b.4, dos veces en la misma sesión.

## 40. `FGETS(h, n)` rechaza `n > 8192`, y un `TRY/CATCH` alrededor lo vuelve invisible

`FGETS()` sin segundo argumento lee 254 caracteres y devuelve el resto **como si fuera otra línea**
(regla 20). El arreglo obvio es pasarle un `n` grande. Y ahí está la trampa: **VFP9 acepta como
máximo 8192**. Por encima lanza

```text
Function argument value, type, or count is invalid.
```

Medido en esta máquina, sobre un fichero real:

```text
n omitido : len=28   OK
n=254     : len=28   OK
n=8192    : len=28   OK
n=8193    : ERROR
n=16384   : ERROR
n=262144  : ERROR
```

Lo caro no es el límite: es **dónde aparece**. Un lector que envuelve su bucle en `TRY/CATCH` —lo
normal en un lector defensivo— se traga la excepción en la **primera vuelta** y devuelve *cero
líneas*. No un error: cero líneas. Que es exactamente lo que devuelve un fichero vacío.

> **Síntoma:** todo test que espera 0 líneas pasa; todo test que espera datos falla con 0. El
> fichero está en disco, con contenido, y el lector jura que no hay nada.

Así estuvieron `VfpAiExecutionReplay` (pedía 16384) y `FileVectorStore` (pedía 262144): **ninguno
de los dos leyó nunca un fichero**, y sus 26 tests llevaban rotos desde que se subió el número.

### Cómo se lee una línea más larga que 8192

Bajar la constante no basta cuando la línea de verdad es más larga —un vector de 1536 componentes
pasa de 12000 caracteres—, porque entonces se cambia "no lee nada" por "lee media línea y se la
cree". Hay que leer a trozos y volver a juntarlos, y para eso hace falta saber si el trozo terminó
la línea o la cortó. Por longitud no se puede: una línea de exactamente `n` da el mismo `LEN` que
una cortada.

**El puntero del fichero sí lo sabe.** `FGETS` consume el CR/LF al llegar al final de la línea, así
que el puntero avanza *más* que los caracteres devueltos:

```foxpro
do while !llDone
    lnBefore = fseek(tnHandle, 0, 1)
    lcChunk  = fgets(tnHandle, 8192)
    lnAfter  = fseek(tnHandle, 0, 1)

    lcLine = lcLine + lcChunk

    * Avanzo mas de lo devuelto -> se comio el terminador -> fin de linea.
    * Avanzo exactamente lo devuelto -> no hubo terminador -> sigue.
    if lnAfter > lnBefore + len(lcChunk)
        llDone = .t.
    endif
    if feof(tnHandle)
        llDone = .t.
    endif
enddo
```

### Reglas

> * `FGETS(h, n)` con `n > 8192` **lanza**. Topa siempre el valor, aunque venga de una propiedad
>   pública que un host pueda subir.
> * Una constante de "tamaño máximo de línea" por encima de 8192 no es un límite generoso: es un
>   lector que no lee.
> * Si el bucle va dentro de `TRY/CATCH`, sospecha de "0 líneas" antes que de "fichero vacío".

Descubierto en A11b.6-fix, midiendo por qué 26 tests de persistencia leían cero de ficheros que
estaban llenos.
## 41. `SYS(16)` dentro de un método NO devuelve una ruta: lleva un prefijo delante

Útil para que una clase se auto-localice sin una propiedad de configuración que alguien tiene que
recordar rellenar — pero **hay que leerlo bien**, y A11b.6 lo leyó mal.

Dentro de un **método de una clase** cargada con `SET PROCEDURE`, `SYS(16)` devuelve:

```text
PROCEDURE <CLASE>.<METODO> <ruta completa del .fxp>
```

En un `.prg` de **nivel superior** sí devuelve la ruta a secas — y de ahí venía la confusión.
`JUSTPATH()` sobre la forma con prefijo se traga el prefijo entero y produce una "ruta" que empieza
por `PROCEDURE `.

```foxpro
* INCORRECTO dentro de un metodo -- devuelve "PROCEDURE MICLASE.MIMETODO C:\...\"
lcCarpeta = JUSTPATH(SYS(16))

* CORRECTO -- se quita el prefijo cuando esta
lcSys = SYS(16)
IF UPPER(LEFT(lcSys, 10)) == "PROCEDURE "
    lnCut = AT(" ", lcSys, 2)          && el prefijo tiene DOS espacios
    IF lnCut > 0
        lcSys = SUBSTR(lcSys, lnCut + 1)
    ENDIF
ENDIF
lcCarpeta = JUSTPATH(lcSys)
```

Se corta por el **segundo** espacio y no por el último a propósito: el prefijo tiene exactamente dos
y la ruta puede llevar espacios propios.

Escrito en A11b.6 con la forma equivocada, y **corregido en A11b.7** (`CurrentSourceFile()`), que fue
cuando hubo un `FoxCore.Runtime` de verdad ejecutando el script y el `DO` a una ruta imposible se vio.
Hasta entonces nadie ejecutaba lo que esa función producía. Ver
`VFP.AI.SDK/docs/foxcore-worker-a11b7.md` §4.

Esto es lo que permite que `FoxCoreProcessHost.ResolveEntryPointPath()` construya una ruta
absoluta a `vfpaisdkmain.prg`/`.app` sin que nadie tenga que configurarla — asumiendo que el
fichero de entrada vive instalado junto a `FoxCoreProcess.prg`, que es la disposición real del
SDK. Si un día el layout cambia (entrada en otra carpeta), esta suposición deja de valer y hay que
volver a una propiedad explícita (`EntryPointPath`, que ya existe como *override* justamente por
si acaso).

Descubierto en A11b.6, resolviendo cómo un script ejecutado en un `vfp9.exe` recién arrancado —sin
el directorio de trabajo de este proceso, y sin ningún `SetWorkingDirectory` que fijarlo— podía
encontrar el punto de entrada del SDK.


---

## 42. Un `.fxp` compilado con varios procesos VFP a la vez puede salir incompleto — y se queda así

Un `vfp9.exe` lanzado por `FoxCore.Runtime` hace `DO vfpaisdkmain`, que carga medio SDK con
`SET PROCEDURE`. Dos veces en A11b.9, el worker falló con:

```text
Error 1: File 'vfpaiworkerexecute.prg' does not exist.
```

El mensaje engaña: el fichero existe, la función existe y el código es correcto. VFP no encontró la
función en ningún fichero de procedimientos cargado, así que intentó ejecutarla como programa.

**Lo que se midió, y es peor que una carrera puntual:**

- El `.fxp` era **más reciente** que su `.prg`, así que VFP lo daba por bueno y **no lo recompilaba**:
  el fallo persistía ejecución tras ejecución.
- El mismo `.fxp` funcionaba en el proceso de tests (las **clases** resolvían) y fallaba en el
  worker (la **función suelta** no). Un `.fxp` puede quedar utilizable a medias.
- `foxengine build --target App` **no** reescribe los `.fxp`, así que compilar el proyecto no lo
  arregla.
- Se generó tras editar un `.prg` y correr acto seguido una suite completa — 41 procesos VFP
  compilando el mismo árbol.

**Regla:** si un worker falla con `File '<algo>.prg' does not exist` sobre algo que sí existe,
**borrar los `.fxp` de la raíz y repetir**. No buscar el error en el código. Y después de editar un
`.prg` que el worker carga, dejar que se compile con calma —un `SET PROCEDURE` en un proceso, o la
suite de ese módulo— antes de lanzar el smoke real.

Aplica a cualquier escenario en el que varios procesos VFP comparten un árbol de `.prg`: no es
específico de FoxCore. Descubierto en A11b.9. Ver
`VFP.AI.SDK/docs/foxcore-worker-a11b9.md` §10.

---

# Reglas incorporadas en la unificación (2026-08-15)

Las diez siguientes existían en el paraguas pero **fuera de toda lista numerada**: dos en el
`vfp-coding-rules.md` de la raíz, y ocho en prosa dentro de `CLAUDE.md`, `AGENTS.md` y manuales
de siete proyectos distintos. Se numeran aquí por primera vez.

---

## 43. `LOCAL ARRAY` no puede mezclar arrays y escalares en la misma sentencia

`LOCAL ARRAY nombre[n]` declara que **todo** lo que sigue separado por comas es también un
array. Mezclar escalares produce *Syntax error* en compilación.

```foxpro
* INCORRECTO -- lnMbrN, lnMI y llArrN no son arrays
local array laMbrN[1,3], lnMbrN, lnMI, llArrN

* CORRECTO -- dos sentencias
local array laMbrN[1,3]
local lnMbrN, lnMI, llArrN
```

Independiente de mayúsculas/minúsculas. Amplía la regla 4.

*Origen: `vfp-coding-rules.md` de la raíz, regla 15 — renumerada, porque la 15 de VFP.AI.SDK
ya ocupaba el número con otra regla distinta.*

---

## 44. `SCAN` no admite `IN alias`

No existe la sintaxis `SCAN IN alias`. `SCAN` opera **siempre** sobre el área de trabajo
actual. Para recorrer un cursor concreto hay que seleccionarlo antes.

```foxpro
* INCORRECTO -- SCAN IN no es sintaxis VFP
SCAN IN curTrialPrds
    lcName = curTrialPrds.PRD_SLUG
ENDSCAN

* CORRECTO
SELECT curTrialPrds
SCAN
    lcName = curTrialPrds.PRD_SLUG
ENDSCAN
```

`SCAN` solo acepta `[NOOPTIMIZE] [Scope] [FOR cond] [WHILE cond]`. Es una trampa fácil porque
`USE ... IN 0`, `COUNT ... IN` y `DELETE ... IN` **sí** admiten `IN`.

*Origen: `vfp-coding-rules.md` de la raíz, regla 16 — renumerada por el mismo motivo.*

---

## 45. Los alias `A` a `J` están reservados

VFP reserva las diez primeras letras como nombres de área de trabajo heredados. Usar una como
alias falla con un error que no explica nada:

```foxpro
* INCORRECTO
USE clientes ALIAS c
* -> 24: Alias name is already in use

* CORRECTO
USE clientes ALIAS cli
```

Muerde sobre todo con alias de una letra generados por código (`c` de *cursor*, `d` de
*datos*, `e` de *empresa*...). La defensa es no generar nunca un alias de un solo carácter.

*Origen: `FoxEngine/AGENTS.md` §8.*

---

## 46. `TRY/CATCH` gana a `ON ERROR` — y con `ON ERROR` instalado, un comando que falla NO lanza

Dos hechos que van juntos porque el segundo solo se entiende con el primero.

**1. La precedencia.** Si hay un `TRY/CATCH` alrededor, el error va al `CATCH` y el `ON ERROR`
instalado **no se ejecuta**. Un manejador global no ve lo que ocurre dentro de un `TRY`.

**2. La trampa cara.** Al revés, con un `ON ERROR` instalado y **sin** `TRY/CATCH`, VFP da el
error por **atendido** y sigue en la sentencia siguiente. Desde fuera —desde COM, por ejemplo—
la llamada parece haber funcionado:

```foxpro
ON ERROR DO MiManejador WITH ERROR(), MESSAGE()
_VFP.FormCount = 99          && ilegal: no lanza, no aborta, no se entera nadie
```

Un puente que ejecute comandos VFP y se fíe de "no hubo excepción" reportará `executed: true`
para comandos que nunca corrieron. Hay que **preguntarle al manejador** si registró algo, no
deducirlo de la ausencia de excepción.

Dos consecuencias operativas para cualquier código que ejecute comandos de terceros:

- Instalar el propio `ON ERROR` y **restaurar el del host SIEMPRE** en un `FINALLY`. Un
  `ON ERROR` ajeno abrió un modal en la sesión de producción de un usuario y le bloqueó la UI.
- No es un sandbox: se reporta el **primer** error y VFP continúa; un payload que ceda el
  control deja la aplicación con tu manejador puesto hasta que vuelva.

*Origen: `FoxAgent/CLAUDE.md`, Bridge 1.8.3 (2026-07-30), bugs B20 y B22. Costó una ronda de
testing con un usuario real.*

---

## 47. `EMPTY()` no cuenta los NULL — vacías + no vacías ≠ total

En una columna que admite nulos, `NULL` no es "vacío": es un tercer estado.

```foxpro
LOCAL ARRAY laA[1], laB[1]
laA[1] = 0
laB[1] = 0
SELECT COUNT(*) FROM t WHERE  EMPTY(VENCE) INTO ARRAY laA    && no cuenta los NULL
SELECT COUNT(*) FROM t WHERE !EMPTY(VENCE) INTO ARRAY laB    && tampoco
* laA[1] + laB[1] < RECCOUNT("t")  -- y es correcto, no es un bug
```

Todo predicado sobre `NULL` devuelve `NULL`, que no es `.T.`, así que la fila **no entra en
ninguna de las dos ramas**. Para contarlas: `ISNULL(campo)`.

Consultar si la columna es nullable antes de sacar conclusiones de un recuento. Es de los
errores que producen un informe plausible y equivocado, que es la peor clase.

*Origen: `FoxAgent/docs/AGENT.md` §6.ter.*

---

## 48. VFP limita a 27 parámetros por función

Tope duro del lenguaje. Una función que necesite más tiene que recibir un objeto, un array o
una `Collection`.

Consecuencia práctica en librerías de utilidades: una `HASHTABLE(k1, v1, k2, v2, ...)` llega
como mucho a **13 pares** si reserva un parámetro para algo más, y una `ALIST(nombre, e1..eN)`
a **26 elementos**. Si una firma se acerca al tope, el diseño ya está pidiendo un objeto.

*Origen: `FoxExtends/HANDOFF-FOXEXTENDS.md` §8, donde el tope aparece como limitación
funcional de `ALIST` y `HASHTABLE`.*

---

## 49. Escribir fuera de rango o de precisión NO da error: recorta en silencio

Tres pérdidas de datos que VFP hace sin avisar al escribir en una tabla:

| Caso | Qué hace VFP | Qué se pierde |
|---|---|---|
| Texto más largo que `C(n)` | trunca a `n` | el final de la cadena |
| `DATETIME` con fracciones de segundo en una columna `T` | descarta la fracción | la precisión sub-segundo |
| `DATETIME` guardado en una columna `D` | se queda la fecha | **la hora entera** |

Las tres son daño invisible: el `REPLACE` funciona, la fila queda escrita y el problema
aparece semanas después, cuando alguien compara con el origen. Y no vuelve: el dato ya no
está.

La defensa es **validar antes de escribir** —`LEN(lcTexto) <= n`— y rechazar en vez de
recortar. Un rechazo es un bug que se ve hoy; un recorte es uno que se ve dentro de un año.

*Origen: `FoxAgent/docs/AGENT.md` §6.ter, donde las tools de escritura rechazan explícitamente
en lugar de imitar el comportamiento de VFP.*

---

## 50. Los fuentes binarios van en PAREJA con su fichero de memo

Formularios, clases, informes, menús, proyectos y tablas son **dos** ficheros, y el contenido
que importa vive en el segundo:

| Binario | Memo | Qué hay en el memo |
|---|---|---|
| `.scx` | `.sct` | el código de los métodos del formulario |
| `.vcx` | `.vct` | el de la biblioteca de clases |
| `.frx` | `.frt` | expresiones y código del informe |
| `.mnx` | `.mnt` | el de las opciones de menú |
| `.pjx` | `.pjt` | los campos memo del proyecto |
| `.dbf` | `.fpt` | el contenido de los campos memo |

**Copiar, mover, respaldar o revertir uno sin el otro destruye trabajo en silencio.** Un
backup de un `.scx` sin su `.sct` restaura un formulario con todos los métodos **vacíos**, y
un `.dbf` sin su `.fpt` restaura los registros con **todos los memos vacíos**. En los dos
casos el fichero abre sin dar ningún error.

Corolario para `git`: los seis pares se marcan `binary` en `.gitattributes`, y un conflicto de
merge **no se resuelve a mano** — se elige una versión completa del par
(`git checkout --ours/--theirs` sobre **ambos** ficheros) y se rehace el cambio del otro lado.

*Origen: `FoxAgent/docs/AGENT.md` §1, `VFP.AI.SDK/docs/build-reproducible.md` §6.*

---

## 51. Los fuentes VFP son CP1252 (Windows-1252), no UTF-8

VFP 9 lee y escribe texto en la página de códigos ANSI. Un `.prg`, `.h` o `.sc2` escrito en
UTF-8 llega a VFP con **todos** los acentos corrompidos: los tuyos y los que ya había.

**El daño es silencioso.** El mojibake no se ve hasta que un humano abre el formulario.

**La regla es CP1252** (regla 9, corregida el 2026-08-22). El ASCII puro no es una
estrategia alternativa: es un caso particular.

```text
CP1252 explicito     LA REGLA. Un acento ocupa UN byte y VFP lo muestra bien, asi que se
                     escribe con normalidad -- tambien en los comentarios. CP1252 SI tiene
                     euro, comillas curvas, rayas largas y puntos suspensivos. Lo que NO
                     tiene (checkmarks, alfabetos no latinos) hay que detectarlo y
                     rechazarlo, no sustituirlo por '?' a espaldas de nadie.

ASCII puro (0-127)   CASO PARTICULAR, no alternativa: si el fichero no necesita ni un
                     acento, vale en las dos codificaciones sin convertir nada. Sirve
                     cuando quien escribe solo sabe guardar UTF-8. Lo que ya NO es: una
                     excusa para escribir "generacion" sin tilde en un comentario.
```

Una herramienta que escriba fuentes VFP debe **negarse nombrando el carácter** que no cabe en
CP1252, nunca degradarlo en silencio.

*Origen: `FoxAgent/docs/AGENT.md` §0.1 y §3, `Vfp2Text/AGENTS.md` §4, y la regla 9 de este
documento.*

---

## 52. Evalúa un payload UNA sola vez — preguntar el tipo ya lo ejecuta

Cuando se recibe una expresión de fuera (un agente, un script, una macro) es tentador
inspeccionarla antes de usarla. Cada inspección es **una ejecución más**:

```foxpro
* INCORRECTO -- ejecuta el payload DOS o TRES veces
lcTipo  = VARTYPE(EVALUATE(lcExpr))            && 1a
lvValor = EVALUATE(lcExpr)                     && 2a
lcClase = EVALUATE(lcExpr + ".Class")          && 3a
```

Con una expresión pura no se nota. Con una que **escribe** —un `EXECSCRIPT` que modifica
datos— se aplica entera dos veces, y la segunda lectura devuelve el estado que dejó la
primera: el clásico "no cambió nada" cuando en realidad cambió dos veces.

```foxpro
* CORRECTO -- una ejecucion, y despues solo LECTURAS
PUBLIC __tmp_ev
__tmp_ev = EVALUATE(lcExpr)                    && la unica ejecucion
lcTipo  = VARTYPE(__tmp_ev)
lcClase = IIF(lcTipo == 'O', __tmp_ev.Class, "")
RELEASE __tmp_ev
```

Es la misma variable intermedia que exigen las reglas 15 y 22, aquí por un motivo distinto:
allí porque VFP no encadena, aquí porque **evaluar tiene efectos**.

*Origen: `FoxAgent/CLAUDE.md`, Bridge 1.8.3 bug B22. Medido con VFP real: ruta antigua 2
ejecuciones, ruta nueva 1.*

---

## 53. VFP no tiene escape de comillas: `""` dentro de `"..."` es un error de sintaxis

El síntoma engaña dos veces. Primero porque `""` es el escape en VB, en X# y en casi todo el xBase
moderno, así que se escribe sin pensar. Y segundo porque cuando cae en el inicializador de una
propiedad de un `DEFINE CLASS`, el fichero **entero** deja de compilar con un `Syntax error` que
apunta a esa línea — y si la clase es la sexta de un fichero de mil líneas, lo primero que se
sospecha es el método recién escrito.

```foxpro
* INCORRECTO -- "Error in line N: Syntax error.", en un metodo Y en una propiedad
lc = "{""ok"":true}"

DEFINE CLASS FakeHttpClient AS Custom
    cBodyText = "{""ok"":true}"
ENDDEFINE
```

VFP no lo lee como una comilla escapada: lo lee como **tres literales pegados** —`"{"`, `ok`,
`":true}"`— sin ningún operador entre ellos. De ahí el error de sintaxis, y de ahí que sea de
*sintaxis* y no de tipos.

La solución es que VFP tiene **tres delimitadores de cadena** precisamente para no necesitar escape:

```foxpro
* CORRECTO -- comilla simple
lc = '{"ok":true}'

* CORRECTO -- corchetes
lc = [{"ok":true}]

* CORRECTO -- CHR(34), cuando hacen falta los tres delimitadores a la vez
lc = "{" + CHR(34) + "ok" + CHR(34) + ":true}"
```

En un `DEFINE CLASS` valen las tres, y también componerlo en `Init()` — el inicializador de una
propiedad admite cualquier constante, así que `cBodyText = '{"ok":true}'` es suficiente y no hace
falta bajar a `Init()` sólo por esto.

Regla práctica: **cadena que contiene comillas dobles → delimítala con comilla simple o corchetes.**
Nunca dobles la comilla.

*Origen: VFP.AI.SDK, fase A14b, `HttpConnectorContracts.prg`, 2026-08-16. Medido con `COMPILE` sobre
`.prg` de repro: falla igual en un método que en una propiedad; `'...'`, `[...]` y `CHR(34)`
compilan y devuelven el valor correcto. Costó un ciclo entero de compilación descartar el método
recién escrito antes de mirar la línea que el `.err` señalaba.*

---

## 54. `MLINE()`/`MEMLINES()` parten las lineas largas: dependen de `SET MEMOWIDTH`

El sintoma es de los caros: el bucle recorre la cadena, no da ningun error, y **no hace nada**.
Ni excepcion ni linea suelta: simplemente ninguna iteracion sirve para nada.

`MLINE()` y `MEMLINES()` no trocean por CR/LF. Trocean por CR/LF **y ademas** por el ancho de
`SET MEMOWIDTH`, que vale **50** por defecto. Una ruta de fichero normal pasa de 50 caracteres,
asi que se parte en dos "lineas" y ninguna de las dos existe como fichero.

```foxpro
* INCORRECTO -- con MEMOWIDTH a 50, una ruta de 62 caracteres sale en 2 trozos
lcLista = FILETOSTR(lcFichero)   && "C:\Desarrollo\...\FoxServer.Host.exe" + CRLF
FOR lnI = 1 TO MEMLINES(lcLista)
    lcExe = ALLTRIM(MLINE(lcLista, lnI))
    IF !FILE(lcExe)              && falla en las DOS pasadas
        LOOP
    ENDIF
    * ...nunca se llega aqui
ENDFOR

* CORRECTO -- ALINES() trocea solo por CR/LF, sin mirar MEMOWIDTH
LOCAL lnLineas
LOCAL ARRAY laLineas[1]
lnLineas = ALINES(laLineas, lcLista)
FOR lnI = 1 TO lnLineas
    lcExe = ALLTRIM(laLineas[lnI])
    * ...
ENDFOR
```

`SET MEMOWIDTH TO 254` antes del bucle tambien lo arregla, pero es peor: es un ajuste global que
alguien puede cambiar en otro sitio, y deja el codigo dependiendo de un estado invisible. Y 254
tampoco basta para una ruta larga de verdad.

Regla practica: **`MLINE`/`MEMLINES` son para presentar texto en pantalla, no para leer datos.**
Para partir por lineas, `ALINES()` (ojo a la regla 34 si los campos pueden venir vacios).

*Origen: FoxForge, `providers/web/classes/foxserverprojecthook.vcx`, 2026-08-21. El hook escribia
en un fichero temporal las rutas de los FoxServer que paraba, para relanzarlos despues; el bucle
de relanzado no relanzaba nada y no daba error. Costo un ciclo de depuracion entero porque el
codigo se lee correcto y el fallo no deja rastro: se sospecho antes del WMI, de los permisos y del
propio fichero temporal que de MLINE.*

---

## 55. El encadenado SI funciona sobre un objeto COM -- amplia las reglas 22 y 38

Las reglas 22 y 38 dicen que VFP no navega el resultado de un metodo propio, y son ciertas.
Pero tienen una excepcion que importa mucho, porque de ella depende que un idioma documentado
de FoxServer funcione en produccion y falle en las pruebas.

**Depende de COMO se creo el objeto, no de la clase.**

```foxpro
* La MISMA clase, el MISMO encadenado, dos resultados distintos:

* FALLA -- objeto VFP nativo
SET PROCEDURE TO FoxServerResponse.prg ADDITIVE
loRes = CREATEOBJECT("FoxServerResponse")
loRes.status(201).json('{"ok":true}')      && 'STATUS' is not an array.

* FUNCIONA -- el mismo objeto, creado por COM
loRes = CREATEOBJECT("miproyecto.FoxServerResponse")
loRes.status(201).json('{"ok":true}')      && status=201, body correcto
```

La causa: sobre un objeto nativo VFP resuelve el miembro en compilacion y se atasca igual que
en las reglas 22 y 38. Sobre un objeto COM la llamada es tardia por `IDispatch`: cada llamada
devuelve un puntero que VFP navega sin problema.

Y el error sigue mintiendo, como en la regla 38: *'STATUS' is not an array* no menciona ni el
metodo, ni el encadenamiento, ni COM. Ademas la llamada suelta **si** funciona
(`loRes.status(201)` a secas va bien en los dos casos), asi que el sospechoso natural --el
metodo-- esta sano.

Consecuencia practica para quien escriba pruebas o bancos de pruebas: **si en produccion el
objeto llega por COM, en la prueba tiene que llegar por COM.** Montarlo con
`SET PROCEDURE` + `CREATEOBJECT` da rojos en codigo que funciona, que es la peor clase de
prueba que existe: manda a corregir lo que no esta roto.

*Origen: FoxServer 0.9, fase 0.5, `src/FoxServer.Tests.Vfp/FoxServerResponseTests.prg`,
2026-08-21. El primer intento de la suite VFP creaba el response con SET PROCEDURE y daba rojo
en `res.status(200).json(...)`, que es LITERALMENTE lo que escribe todo controlador generado
por FoxForge y que en produccion responde 201 correctamente. Se descarto por medicion que
fuera cosa de EXECSCRIPT (falla igual compilado) y de una colision propiedad/metodo (no la
hay) antes de dar con la diferencia real.*

### 55.1 `WITH ... ENDWITH`: la salida cuando el objeto es nativo

Las reglas 22, 38 y 55 dicen cuándo el encadenado falla. Falta decir qué hacer entonces, y
la respuesta no es resignarse a una variable intermedia por línea: **`WITH ... ENDWITH` da
el mismo aspecto fluido sin pedirle al parser lo que no sabe hacer.**

```foxpro
* NO COMPILA sobre un objeto nativo -- regla 22
loQuery.Where("p => p.Edad > 25").OrderBy("p => p.Nombre").Take(2)

* SI, y se lee igual de bien
WITH loQuery
    .Where("p => p.Edad > 25")
    .OrderBy("p => p.Nombre")
    .Take(2)
    loResultado = .ToList()
ENDWITH
```

**Por qué funciona, que es lo que hay que entender para saber cuándo NO sirve.** No es que
`WITH` habilite el encadenado: es que **lo elimina**. Cada línea arranca del objeto del
`WITH`, que está resuelto una sola vez, y **el valor que devuelve cada método se descarta**.
Nunca se navega el resultado de una llamada, que es justo lo que VFP no puede hacer.

Y por eso tiene un límite: **el objeto tiene que MUTAR**. Los métodos van acumulando estado
en él y el resultado sale de una llamada terminal —`.ToList()`, `.Average()`— que es la
única cuyo retorno se recoge, en una asignación normal. Si el patrón fuera un constructor
que devuelve un objeto NUEVO en cada paso, `WITH` no ayudaría: ahí sí hace falta la variable
intermedia.

Nótese que los métodos de `LinqQuery` **sí** hacen `RETURN THIS`. Eso no sobra —los hace
encadenables donde el encadenado funciona, o sea sobre COM (regla 55)— pero **dentro del
`WITH` ese retorno no se usa para nada**. Las dos cosas conviven: el mismo objeto se puede
usar encadenado por COM y con `WITH` en nativo.

Sirve igual para el idioma de FoxServer cuando el `res` no viene por COM:

```foxpro
WITH loRes
    .status(200)
    .json(lcCuerpo)
ENDWITH
```

*Origen: `LinqVFP/linq.prg` (Irwin Rodriguez, 2026), donde es el modo de uso documentado de
la biblioteca. Anotado aquí el 2026-08-22 al descubrir que el plan de la fase 2.6 de
FoxServer proponía un API fluido —`Request(...).WithQuery(...).Run()`— que el lenguaje no
admite sobre un objeto nativo. El banco se escribió sin encadenar; `WITH` era la otra
salida.*
