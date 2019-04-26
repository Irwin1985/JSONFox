DEFINE CLASS Test_JSONFox AS FxuTestCase OF FxuTestCase.prg
	#IF .F.
		LOCAL THIS AS Test_JSONFox OF Test_JSONFox.prg
	#ENDIF

	oJson 			= .NULL.
	icSetProcedure 	= SPACE(0)

	FUNCTION SETUP
		THIS.icSetProcedure = SET("Procedure")
		THIS.oJson 			= NEWOBJECT("JsonFox", "Tools\JsonFox.prg")
	ENDFUNC
*----------------------------------------------------------------------------Test Begin---------------------------------------------------------------*
	FUNCTION test_deberia_crear_el_objeto_json
		THIS.AssertIsObject(THIS.oJson, "No se pudo crear el objeto oJson")
	ENDFUNC

	FUNCTION test_deberia_parsear_una_cadena_json_sin_valores_vacios
		LOCAL lcJson AS STRING, loObj AS OBJECT, lcExpectedValue AS STRING
		TEXT TO lcJson noshow
			{
				"name": "irwin",
				"lastname": "rodríguez",
				"age": 33
			}
		ENDTEXT
		loObj 			= THIS.oJson.decode(lcJson)
		lcExpectedValue = "irwin"

		THIS.AssertNotNull(loObj, "No se pudo convertir el objeto [loObj]")
		THIS.MessageOut("Valor esparado: " + lcExpectedValue)
		THIS.MessageOut("Valor retornado: " + loObj._name)
	ENDFUNC

	FUNCTION test_deberia_parsear_una_cadena_json_con_valores_vacios
		LOCAL lcJson AS STRING, loObj AS OBJECT
		TEXT TO lcJson noshow
			{
				"name": "irwin",
				"lastname": "rodríguez",
				"city": "",
				"age": 33
			}
		ENDTEXT
		loObj = THIS.oJson.decode(lcJson)
		THIS.AssertNotNull(loObj, "No se pudo convertir el objeto [loObj]")
		IF !EMPTY(THIS.oJson.LastErrorText)
			THIS.messageOut("Ha ocurrido un error: " + THIS.oJson.LastErrorText)
		ELSE
		ENDIF
		THIS.MessageOut("El atributo a evaluar es city y debería estar vacío")
		THIS.AssertTrue(EMPTY(loObj._city),"El atributo city no está vacío")
		THIS.MessageOut("El atributo city está vacío, prueba OK.")
	ENDFUNC

	FUNCTION test_deberia_parsear_un_null
		LOCAL loObj AS OBJECT
		loObj = THIS.oJson.decode('{"movil": null}')
		THIS.AssertIsObject(loObj, "No se pudo crear el objeto [loObj]")
		THIS.AssertEquals(.NULL.,loObj._movil,"Los valores no son iguales")
		THIS.MessageOut("Valor esperado: .NULL.")
		THIS.MessageOut("Valor obtenido: " + TRANSFORM(loObj._movil))
	ENDFUNC

	FUNCTION test_deberia_parsear_un_entero
		LOCAL loObj AS OBJECT
		loObj = THIS.oJson.decode('{"edad": 33}')
		THIS.AssertIsObject(loObj, "No se pudo crear el objeto [loObj]")
		THIS.AssertEquals(33, loObj._edad,"Los valores no son iguales")
		THIS.MessageOut("Valor esperado: 33")
		THIS.MessageOut("Valor obtenido: " + TRANSFORM(loObj._edad))
	ENDFUNC

	FUNCTION test_deberia_parsear_un_decimal
		LOCAL loObj AS OBJECT
		loObj = THIS.oJson.decode('{"PI": 3.1415926535}')
		THIS.AssertIsObject(loObj, "No se pudo crear el objeto [loObj]")
		THIS.AssertEquals(3.1415926535, loObj._PI,"Los valores no son iguales")
		THIS.MessageOut("Valor esperado: 3.1415926535")
		THIS.MessageOut("Valor obtenido: " + TRANSFORM(loObj._PI))
	ENDFUNC

	FUNCTION test_deberia_parsear_verdadero
		LOCAL loObj AS OBJECT
		loObj = THIS.oJson.decode('{"hombre": true}')
		THIS.AssertIsObject(loObj, "No se pudo crear el objeto [loObj]")
		THIS.AssertEquals(.T., loObj._hombre,"Los valores no son iguales")
		THIS.MessageOut("Valor esperado: .T.")
		THIS.MessageOut("Valor obtenido: " + TRANSFORM(loObj._hombre))
	ENDFUNC

	FUNCTION test_deberia_parsear_falso
		LOCAL loObj AS OBJECT
		loObj = THIS.oJson.decode('{"mujer": false}')
		THIS.AssertIsObject(loObj, "No se pudo crear el objeto [loObj]")
		THIS.AssertEquals(.F., loObj._mujer,"Los valores no son iguales")
		THIS.MessageOut("Valor esperado: .F.")
		THIS.MessageOut("Valor obtenido: " + TRANSFORM(loObj._mujer))
	ENDFUNC

	FUNCTION test_deberia_parsear_fecha_corta_formato_yyy_mm_dd_separador_guion_medio
		LOCAL loObj AS OBJECT, lcFecha AS STRING
		SET CENTURY ON
		SET DATE DMY
		lcFecha = ALLTRIM(TRANSFORM(YEAR(DATE()))) + '-' + PADL(ALLTRIM(TRANSFORM(MONTH(DATE()))),2,'0') + '-' + PADL(ALLTRIM(TRANSFORM(DAY(DATE()))),2,'0')
		loObj 	= THIS.oJson.decode('{"fecha": "' + lcFecha + '"}')
		THIS.AssertIsObject(loObj, "No se pudo crear el objeto [loObj]")
		THIS.AssertEquals(DATE(), loObj._fecha,"Los valores no son iguales")
		THIS.MessageOut("Valor esperado: " + TRANSFORM(DATE()))
		THIS.MessageOut("Valor obtenido: " + TRANSFORM(loObj._fecha))
	ENDFUNC

	FUNCTION test_deberia_parsear_fecha_larga_formato_yyy_mm_dd_separador_guion_medio
		LOCAL loObj AS OBJECT, lcFecha AS STRING
		SET CENTURY ON
		SET DATE DMY
		lcFecha 	= '2019-04-25 17:51:18'
		lcExpected 	= '25/04/2019 05:51:18 PM'
		loObj 		= THIS.oJson.decode('{"fecha": "' + lcFecha + '"}')
		THIS.AssertIsObject(loObj, "No se pudo crear el objeto [loObj]")
		THIS.AssertEquals(lcExpected, TRANSFORM(loObj._fecha),"Los valores no son iguales")
		THIS.MessageOut("Valor esperado: " + TRANSFORM(lcExpected))
		THIS.MessageOut("Valor obtenido: " + TRANSFORM(loObj._fecha))
	ENDFUNC

	FUNCTION test_deberia_parsear_un_array
		LOCAL lcJson AS STRING, loObj AS OBJECT
		TEXT TO lcJson noshow
			{
				"estado": "1",
				"tabla":
				[
					"valor1",
					"valor2",
					"valor3",
					"",
					"valor5"
				]
			}
		ENDTEXT
		loObj = THIS.oJson.decode(lcJson)
		THIS.AssertIsObject(loObj)
		THIS.AssertNotNull(loObj, "No se pudo convertir el objeto [loObj]")
		IF !EMPTY(THIS.oJson.LastErrorText)
			THIS.messageOut("Ha ocurrido un error: " + THIS.oJson.LastErrorText)
		ELSE
		ENDIF
		lnExpected 	= 5
		lnGot 		= loObj._tabla.LEN()
		THIS.MessageOut("El array contiene " + TRANSFORM(lnGot) + " elementos")
		THIS.AssertEquals(lnExpected, lnGot, "Los valores no coinciden!")
	ENDFUNC

	FUNCTION deberia_generar_error_al_enviar_nombres_invalidos_de_columnas_o_campos
		LOCAL lcJson AS STRING, loObj AS OBJECT
		TEXT TO lcJson noshow
			{
				"estado":"1",
				"fecha":
					{
						"0":1556277466,
						"seconds":46,
						"minutes":17,
						"hours":6,
						"mday":26,
						"wday":5,
						"mon":4,
						"year":2019,
						"yday":115,
						"weekday":"Friday",
						"month":"April"
					}
			}
		ENDTEXT
		loObj = THIS.oJson.decode(lcJson)
		THIS.AssertIsObject(loObj, "No se pudo convertir el objeto [loObj]")
		lcXML = this.oJson.ArrayToXML(loObj._fecha)
		IF !EMPTY(THIS.oJson.LastErrorText)
			THIS.messageOut("Ha ocurrido un error: " + THIS.oJson.LastErrorText)
		ELSE
		ENDIF
	ENDFUNC
*----------------------------------------------------------------------------Test End-----------------------------------------------------------------*

	FUNCTION TearDown
		LOCAL lcProc
		lcProc = THIS.icSetProcedure
		SET PROCEDURE TO &lcProc
		THIS.oJson = .NULL.
	ENDFUNC
ENDDEFINE
