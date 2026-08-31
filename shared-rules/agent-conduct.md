# Conducta del agente en este árbol

**Fichero canónico.** Aplica a **cualquier** agente de IA que trabaje en
`C:\Desarrollo\IrwinRodriguez.dev`, en cualquier proyecto, sea cual sea el lenguaje.

Los otros tres ficheros de esta carpeta dicen **cómo se escribe** el código. Éste dice
**cómo se trabaja**: con qué herramienta se toca VFP, qué se ejecuta y qué no, y qué se
verifica antes de afirmar algo. Todas las reglas de aquí nacieron de una sesión que salió
mal, y cada una lleva su origen.

Protocolo para añadir reglas: `README.md`. **La numeración no se reordena.**

---

## 1. Todo lo que toque VFP pasa por FoxAgent

**La regla entera, con el porqué y la lista de qué usar para cada cosa, está en
`REGLAS-VFP.md` §2** — la fuente de verdad, que va al lado de este fichero. Aquí solo el
titular y lo que añade la práctica:

> Si vas a ejecutar, compilar o inspeccionar algo de VFP, hazlo a través de FoxAgent.
> Un `vfp9.exe` lanzado a pelo es un proceso sin ojos.

Un modal deja el proceso esperando para siempre; el agente ve un *timeout* y no sabe por
qué. Con FoxAgent la sesión sigue viva y `take_screenshot`/`send_key` funcionan: **un
diálogo inesperado pasa de ser un cuelgue a ser un dato.**

Lo que este fichero añade, porque no es de codificación sino de conducta:

**No improvises VFP dentro de `eval_expression`/`EXECSCRIPT` para operar la interfaz.** Un
script improvisado ya abrió un diálogo de error en la sesión de producción de alguien y le
bloqueó la UI. Para la interfaz existen las tools tipadas (`list_open_forms`,
`find_control`, `click_control`, `send_key`, `set_control_text`, `invoke_method`); son la
única vía.

*Origen: `REGLAS-VFP.md` §2; memoria `feedback_foxagent_para_pruebas_vfp`; instrucciones
del servidor MCP de FoxAgent.*

---

## 2. Prueba la interfaz con una sesión propia, no con la del usuario

`launch_instance` levanta una sesión VFP **tuya**. La sesión que el usuario tiene abierta
sigue siendo suya: no la cierres, no le cambies el `SET DEFAULT`, no le abras tablas.

Dos consecuencias que ya costaron tiempo:

- **El usuario levanta su aplicación; tú solo cierras lo que levantaste tú.**
  `close_instance` solo cierra lo que abrió FoxAgent, y está bien que sea así.
- Cuando hay dos sesiones (la registrada con el proyecto abierto y la de pruebas),
  **verifica el PID antes de culpar a la caché**: un `reload_procedure` que "no hace
  efecto" casi siempre fue a la sesión equivocada.

Los fallos de interfaz no los ve ningún test de sintaxis. Conducir el formulario de verdad
encontró cuatro en una sola pasada (2026-08-30).

*Origen: memorias `feedback_probar_ui_con_sesion_propia`,
`feedback_foxagent_multisession_targeting`, `feedback_verify_before_asking`.*

---

## 3. Los fuentes VFP son CP1252 — y los acentos se escriben

**La regla entera está en `REGLAS-VFP.md` §1**, que manda sobre codificación: el porqué en
bytes, la medición de 2026-08-30, las dos excepciones (los `.prg` de X# van en UTF-8 con
BOM; los `.ps1` en ASCII puro) y el script de emergencia. Léela antes de escribir tu primer
`.prg`. Y las reglas 9 y 51 de `vfp-coding-rules.md` la citan desde el lado del lenguaje.

El titular, y las dos trampas de herramienta que se pagan en esta capa:

> Un fuente de VFP se lee y se escribe SIEMPRE en CP1252. Nunca UTF-8, nunca con BOM.
> Y los acentos y la eñe **se escriben**, también en los comentarios.

- **La tool `Write` del agente escribe UTF-8.** Vale para ASCII puro; con acentos hay que
  reconvertir después. La vía buena es `write_source_file` de FoxAgent (pone la
  codificación y hace copia con marca de tiempo) o Python con `encoding='cp1252'`.
- **Nunca `Set-Content -Encoding utf8` en PowerShell 5.1** sobre un fuente: corrompe los
  acentos en silencio. Si hay que revertirlo, se hace con CP1252, **no con Latin1**, y se
  verifica contando caracteres U+FFFD, no buscando un patrón.

Y una que es de formato de fichero, no de codificación: los binarios (`.scx`, `.vcx`,
`.frx`, `.mnx`) **no se editan a mano y no se mueven sin su fichero de memo** (`.sct`,
`.vct`, `.frt`, `.mnt`): ahí es donde vive el código.

*Origen: `REGLAS-VFP.md` §1 (fuente de verdad); memorias
`feedback_reglas_vfp_fuente_de_verdad`, `feedback_powershell_encoding_corruption`.*

---

## 4. Los tests nuevos van en FoxProof; FoxUnit es legado

Decisión de Irwin del **2026-08-23**. Los tests nuevos se escriben para FoxProof
(`HELP [Fact]`, clase `AS Custom`, asserts con `__assert`; manual en `FoxProof\MANUAL.md`)
y se corren con la tool `run_tests` o con `foxproof.exe`.

Las suites FoxUnit que quedan **documentan casos** pero varias apuntan a rutas de la unidad
vieja y sus mocks están desfasados: no corren tal cual y no se amplían. Migrarlas es tarea
pendiente, no urgente.

Dos trampas al estrenar FoxProof, las dos ya pagadas:

- FoxProof corre sobre **VFP Advanced**: un `.fxp` compilado con VFP 9 da **error 1195**,
  que llega disfrazado de otra cosa (en el portal apareció como "Body JSON invalido").
  Compila el fuente en el `SetUp` con el motor que ejecuta.
- FoxProof compila el `.prg` dentro de un `EXECSCRIPT`: **`SYS(16)` no dice dónde está el
  fichero.** Las rutas van absolutas, en una función `Root()`.

*Origen: memoria `feedback_portal_tests_foxproof`; `IrwinPortalApi\Tests\B0MachineProofTests.prg`
fue el primer ejemplo.*

---

## 5. Ninguna herramienta deja un diálogo esperando a un humano

Es el requisito que se deriva de la visión del stack: un agente opera estas herramientas, y
un agente no puede pulsar "Aceptar".

El patrón de referencia lo puso FoxServer: evaluar `_screen.Visible` — `.T.` = modo
interactivo (alguien abrió el IDE), `.F.` = modo invisible (me usa un agente por CLI).
Toda herramienta VFP que se quede en el catálogo adopta ese patrón o nace headless.

Nada de fixtures que dependan de un modal (`Locate File`, `SAFETY`): no son deterministas y
dejan VFP colgado pidiendo intervención humana.

Y al revés: **un watchdog no cierra diálogos a propósito.** Pulsar a ciegas un modal
desconocido podría confirmar un sobrescribir o un borrar — convertiría un cuelgue en pérdida
de datos, y taparía el bug de fondo. Se mata el proceso y se reporta.

*Origen: `PLAN-ORDEN-DE-LA-CASA.md` §0; `FoxEngine\CLAUDE.md` (modo desatendido);
memoria `feedback_no_human_dialog_tests`.*

---

## 6. Verifica antes de preguntar, y separa lo observado de lo inferido

Antes de pedirle al usuario que cierre algo, reinicie algo o toque algo:

```text
comprueba instancias y bloqueos      list_instances antes de pedir "cierra FoxMart"
ejecuta el binario                   antes de pedir un reinicio
captura el monitor entero            antes de teorizar sobre un proceso colgado
```

Los diálogos de VFP **no salen en una captura por-app**: hay que capturar todo el monitor.
Un proceso "colgado sin motivo" suele ser un modal que nadie está viendo.

Al reportar, di qué viste y qué dedujiste, por separado. "El proceso no responde" y "el
proceso está colgado por un modal" son afirmaciones distintas y solo una de las dos la
observaste.

*Origen: memorias `feedback_foxagent_verify_before_asking`, `feedback_full_desktop_screenshots`.*

---

## 7. Un `.fxp` viejo gana al `.prg` nuevo

Medido: un `.prg` de las 15:39 y un `.FXP` de las 15:34 en la misma carpeta, y `vfp9 -T`
ejecutó **el `.FXP`**. Borra el `.fxp` antes de correr algo que acabas de editar.

Es la causa más barata de "pero si ya lo he arreglado", y no avisa de nada.

*Origen: memoria `feedback_vfp_fxp_viejo_gana`.*

---

## 8. Antes de recomendar algo que leíste en una memoria o en un doc, verifica que sigue existiendo

Las memorias y los handoffs reflejan lo que era cierto cuando se escribieron. Si uno nombra
un fichero, una función, una ruta o un flag, **compruébalo contra el árbol** antes de
apoyarte en ello.

Este árbol tiene precedentes de sobra: rutas a una unidad que ya no se usa, un
`bJsonFoxLoaded` que dejó de existir, un `foxunit.exe` que ahora vive en otro sitio, y
cabeceras de plan que mienten sobre su propio estado.

*Origen: la limpieza del 2026-08-31; el propio `PLAN-ORDEN-DE-LA-CASA.md` abre pidiendo que
sus cabeceras no mientan.*
