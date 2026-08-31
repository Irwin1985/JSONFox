# Reglas de la casa para tocar Visual FoxPro

**Este fichero es la fuente de verdad.** Si otro documento del repo dice algo
distinto sobre lo que hay aquí, manda éste. Las copias que quedan por los
proyectos deben limitarse a apuntar aquí, no a repetir la regla.

Ruta canónica: `C:\Desarrollo\IrwinRodriguez.dev\REGLAS-VFP.md`

---

## 1. Codificación: CP1252, **y los acentos se escriben**

> **Un fuente de VFP se lee y se escribe SIEMPRE en CP1252 (Windows-1252).
> Nunca UTF-8, nunca con BOM. Y los acentos, la eñe y los signos de apertura
> se escriben con normalidad — también en los comentarios.**

Aplica a `.prg`, `.h`, y a los textos intermedios de `vfp2text` (`.VC2`, `.SC2`,
`.DB2`, …).

### Por qué las dos mitades importan

VFP 9 lee sus fuentes en la página de códigos ANSI del sistema, que aquí es
Windows-1252. Ahí **un acento ocupa un byte** y se ve perfectamente. `á` es
`E1`, `ñ` es `F1`, `¿` es `BF`.

En UTF-8 ese mismo acento ocupa **dos** bytes. Si VFP lee un fichero UTF-8
creyéndolo CP1252, ve los dos por separado:

```
"Descripción"
   CP1252 : 44 65 73 63 72 69 70 63 69 [F3] 6E      11 bytes  <- UN byte
   UTF-8  : 44 65 73 63 72 69 70 63 69 [C3 B3] 6E   12 bytes  <- DOS bytes

lo que VFP muestra si el fichero está en UTF-8 :  DescripciÃ³n
y si además lleva BOM                          :  ï»¿DescripciÃ³n
```

El BOM añade tres caracteres de basura **al principio**. El destrozo de verdad
es que **cada acento se parte en dos, en todo el fichero**. Quitar el BOM no
arregla nada por sí solo: lo que manda es la codificación.

### Medido, no supuesto (2026-08-30)

El mismo `.prg` escrito de tres maneras, con `ñ ó · ¿` dentro de un literal,
ejecutado por VFP 9 y comparando **los bytes** que escribe cada uno:

| Fuente | Bytes de salida | Por encima de 127 | Qué pasa |
|---|---|---|---|
| **CP1252 sin BOM** | 44 | **5** — `f1` `f3` `f3` `b7` `bf` | ✅ un byte por acento, correcto |
| UTF-8 sin BOM | 49 | **10** — `c3 b1`, `c3 b3`, `c2 b7`, `c2 bf` | ⚠️ **se ejecuta sin quejarse** y cada acento queda como DOS caracteres |
| UTF-8 con BOM | — | — | ❌ ni compila: *«16: Unrecognized command verb»* |

El del BOM al menos **grita**. El de UTF-8 sin BOM es el que hace daño: el
programa corre, nadie ve un error, y los literales llevan el doble de
caracteres de los que deberían. Una comparación de cadenas deja de casar y
el `LEN()` miente.

> Y una trampa al comprobarlo: **mira los bytes, no la cadena impresa.** Al
> imprimir el resultado decodificado, la consola vuelve a re-codificar y
> enseña el texto bien aunque los bytes estén mal. Pasó al hacer esta misma
> medición: la primera lectura decía que los tres casos funcionaban.

### La otra mitad: prohibir acentos NO es la regla

Durante un tiempo esta regla se escribió como *«ASCII puro en los .prg: sin
acentos, sin eñe»*. **Eso describía la limitación de la herramienta que
escribe, no la de VFP**, y se corrigió el 2026-08-22.

Escribir en ASCII puro *funciona* —los bytes 0-127 son idénticos en las dos
codificaciones— pero cuesta legibilidad en un producto en castellano y no hacía
falta. Una etiqueta que dice `Descripcion` en una pantalla que ve un cliente es
una errata, no una decisión técnica.

**Si tu herramienta sólo sabe escribir UTF-8, el problema es tuyo, no del
fichero: conviértelo.** Nunca al revés.

### Cómo se escribe sin romperlo

| Vía | Qué hacer |
|---|---|
| **FoxAgent** `write_source_file` | La recomendada. Pone la codificación correcta y hace copia con marca de tiempo |
| **Python** | `io.open(p, 'r', encoding='cp1252', newline='')` para leer y `'w'` con lo mismo para escribir. `newline=''` conserva los finales de línea tal cual |
| **PowerShell** | `[IO.File]::ReadAllText($ruta, [Text.Encoding]::GetEncoding(1252))` y `WriteAllText` igual |
| **La herramienta de escritura del agente** | Escribe **UTF-8**. Vale para ASCII puro; **con acentos hay que reconvertir después**, no evitarlos |

### Comprobarlo cuesta una línea

Un fuente sano con acentos **no** debe decodificar como UTF-8. Si decodifica,
está mal escrito:

```python
d = open(ruta, 'rb').read()
print('BOM     :', d[:3] == b'\xef\xbb\xbf')          # tiene que ser False
print('acentos :', sum(1 for x in d if x > 127))      # los que toque
try:
    d.decode('utf-8'); print('OJO: es UTF-8, está mal')
except UnicodeDecodeError:
    print('OK: es CP1252')
```

### Excepciones, y son sólo dos

- **Los `.prg` de X#** (`FoxServer/src/`, `FoxCore`, …) usan la extensión `.prg`
  pero **no los lee VFP: los compila X#**. Van en **UTF-8 con BOM**, como el
  resto de esos proyectos.
- **Los `.ps1`** van en **ASCII puro**, y ésa sí es una regla real: PowerShell
  5.1 lee un `.ps1` sin BOM como ANSI y se come los acentos. No es la misma
  regla ni el mismo motivo.

### Script de emergencia

Si un fuente quedó en UTF-8 y VFP lo muestra con mojibake:

```powershell
$c = [IO.File]::ReadAllText($ruta, [Text.Encoding]::UTF8)
[IO.File]::WriteAllText($ruta, $c, [Text.Encoding]::GetEncoding(1252))
```

⚠️ Ejecutarlo sobre un fichero que **ya** está en CP1252 lo corrompe. Comprueba
antes con el fragmento de arriba.

---

## 2. FoxAgent para todo lo que toque a FoxPro

> **Si vas a ejecutar, compilar o inspeccionar algo de VFP, hazlo a través de
> FoxAgent. Un `vfp9.exe` lanzado a pelo es un proceso sin ojos.**

### Por qué

VFP abre un **modal** ante casi cualquier contratiempo. Un fichero que no
existe, un `ZAP` con
`SET SAFETY ON`, un error de sintaxis, un `LOCFILE` buscando algo que no está:
todos abren un **diálogo modal**. Y un modal en un proceso al que nadie mira
significa:

- el proceso se queda ahí para siempre,
- el agente ve un *timeout* y no sabe por qué,
- y lo normal es que interprete mal la causa y se ponga a arreglar lo que no es.

Pasa **mucho**, y el coste no es el minuto perdido: es el diagnóstico
equivocado que viene detrás.

### Qué usar

| Para | Herramienta |
|---|---|
| Ver qué instancias hay | `list_instances` |
| **Arrancar una sesión propia** | `launch_instance` — es TUYA, no la del usuario |
| Ejecutar algo | `exec_command`, `eval_expression` |
| **Ver qué pasa** | `take_screenshot` — antes de teorizar, mira |
| Conducir pantallas | `list_open_forms`, `find_control`, `click_control`, `set_control_text` |
| Contestar a un modal | `send_key` con la letra del botón |
| Cerrar la sesión | `close_instance` |
| Escribir un fuente | `write_source_file` (codificación + copia de seguridad) |

**La sesión del usuario la levanta él; la tuya la levantas tú.** Trabajar en la
suya sin avisar le rompe lo que esté haciendo.

### Lo que hace que valga la pena

Con un modal en pantalla **la sesión sigue viva**: `take_screenshot` y
`send_key` funcionan. Es decir, con FoxAgent un diálogo inesperado es *un dato*;
sin FoxAgent es *un cuelgue*.

### Si aun así lanzas un `vfp9.exe` suelto

Porque a veces es lo razonable — una compilación headless, un script de una
línea. Entonces, y sin excepción:

1. **Ruta ABSOLUTA** al `.prg`. Una relativa se resuelve contra el directorio
   por defecto de VFP, que no es el del proceso, y sale un
   *«File does not exist»* modal.
2. **Comprueba que el fichero existe** antes de lanzar. La mitad de los cuelgues
   son una ruta mal montada por el shell.
3. **`CONFIG.FPW` con `SCREEN = OFF` y `RESOURCE = OFF`**, pasado con `-c`.
4. **`ON ERROR`** que escriba a un log y haga `QUIT`. Sin eso, cualquier error
   es un modal.
5. **Borra el `.fxp`** antes de relanzar tras editar el `.prg`: VFP ejecuta el
   compilado cacheado y estarás probando la versión anterior.
6. **Timeout y plan B**: si no vuelve, captura la pantalla completa y mata el
   proceso por PID — nunca por nombre, que puede haber una sesión del usuario.

---

## 3. Dónde está el resto

Éste manda sobre **codificación** y sobre **cómo se ejecuta VFP**. Lo demás vive
en `shared/vfp-rules/`, y cada fichero manda sobre lo suyo:

| Fichero | Qué manda |
|---|---|
| `vfp-coding-rules.md` | El lenguaje: `RETURN` dentro de `TRY/CATCH`, `DO CASE`, aritmética de `DATETIME`, límites de las tablas libres, `HELP` de 255… (55 reglas numeradas) |
| `tooling-rules.md` | Las herramientas: `foxengine`, `vfp2text`, FoxAgent, exit codes, build |
| `xsharp-coding-rules.md` | X# |
| `agent-conduct.md` | **Cómo se trabaja**: probar la UI con sesión propia, FoxProof para los tests nuevos, verificar antes de afirmar. Cita a éste para los §1 y §2 en vez de repetirlos |

> **Este fichero viaja.** Desde el 2026-08-31, `shared/vfp-rules/sync-rules.ps1`
> lo copia a `<repo>\shared-rules\` de cada proyecto que toca VFP, porque vivir
> solo en la raíz del árbol lo dejaba invisible para quien clona un repo suelto
> —el tester de FoxAgent, por ejemplo—. La copia es generada: **no la edites**,
> edita éste.
