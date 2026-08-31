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

No lances `vfp9.exe` a pelo. Sin FoxAgent estás ciego: un diálogo modal cuelga el proceso
y no hay forma de saber por qué — el proceso sigue vivo, no devuelve, y no hay traza.

```text
inspeccionar una sesion viva   ->  list_instances, get_variables, get_cursors, get_call_stack
conducir un formulario         ->  list_open_forms, find_control, click_control, send_key,
                                   set_control_text, invoke_method
escribir un fuente VFP         ->  write_source_file  (encoding + backup, ver regla 3)
compilar / ejecutar            ->  build_project, exec_command, run_tests
```

Si aun así hay que lanzar `vfp9.exe`: **ruta absoluta** al `.prg` y un `CONFIG.FPW` con
`RESOURCE = OFF`. Sin eso, VFP arranca con el directorio por defecto en `SYSTEM32` y
cualquier ruta relativa abre un diálogo "Open".

**No improvises VFP dentro de `eval_expression`/`EXECSCRIPT` para operar la interfaz.** Un
script improvisado ya abrió un diálogo de error en la sesión de producción de alguien y le
bloqueó la UI. Para la interfaz existen las tools tipadas; son la única vía.

*Origen: memoria `feedback_foxagent_para_pruebas_vfp`; instrucciones del servidor MCP de
FoxAgent.*

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

La regla completa, con el porqué y cómo comprobarlo, es la **9 (y la 51)** de
`vfp-coding-rules.md`. Lo que importa para la conducta:

- Un `.prg` de VFP se lee y se escribe **siempre** en CP1252. Nunca UTF-8.
- Los acentos y las eñes **se escriben**: en CP1252 ocupan un byte y VFP los muestra bien.
  Lo de "ASCII puro" era una limitación de la herramienta, no de VFP.
- La tool `Write` escribe UTF-8: **no sirve** para un `.prg` con acentos.
  Usa `write_source_file` de FoxAgent, o Python con `encoding='cp1252'`.
- Los `.prg` de **X#** son otra cosa: UTF-8 con BOM. No les apliques esto.
- Nunca `Set-Content -Encoding utf8` en PowerShell 5.1 sobre un fuente: corrompe los
  acentos en silencio.

Los binarios (`.scx`, `.vcx`, `.frx`, `.mnx`) **no se editan a mano y no se mueven sin su
fichero de memo** (`.sct`, `.vct`, `.frt`, `.mnt`): ahí es donde vive el código.

*Origen: `REGLAS-VFP.md` (fuente de verdad); memorias
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
