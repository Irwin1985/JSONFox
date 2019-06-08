*====================================================================
* JSONFox Unit Tests
*====================================================================
Define Class JSONFoxTest As FxuTestCase Of FxuTestCase.prg
	#If .F.
		Local This As JSONFoxTest Of JSONFoxTest.prg
	#Endif

	icTestPrefix = "test"

	Procedure Setup
		Public Json
		Json = Newobject("JsonFox", "Tools\JsonFox.prg")

*====================================================================
	Procedure TearDown
		Release Json

*====================================================================
	Procedure test_should_create_json_object
		This.AssertIsObject(Json, "Json object was not created")

*====================================================================
	Procedure test_should_parse_json_string_without_empty_values
		Local lcJson As String, loObj As Object, lcExpectedValue As String
		Text To lcJson noshow
			{
				"name": "irwin",
				"lastname": "rodríguez",
				"age": 33
			}
		EndText
		loObj 			= Json.decode(lcJson)
		lcExpectedValue = "irwin"

		This.AssertNotNull(loObj, "can not convert loObj object")
		This.MessageOut("Expected value: " + lcExpectedValue)
		This.MessageOut("Returned Value: " + loObj._name)

*====================================================================
	Procedure test_should_parse_json_string_with_empty_values
		Local lcJson As String, loObj As Object
		Text To lcJson noshow
			{
				"name": "irwin",
				"lastname": "rodríguez",
				"city": "",
				"age": 33
			}
		EndText
		loObj = Json.decode(lcJson)
		This.AssertNotNull(loObj, "can not convert loObj object")
		This.AssertTrue(Empty(Json.LastErrorText), "LastErrorText: " + Json.LastErrorText)
		This.MessageOut("Evaluates city attribute and should be empty")
		This.AssertTrue(Empty(loObj._city), "city attribute is not empty")
		This.MessageOut("City attribute is empty. Test passed!")

*====================================================================
	Procedure test_should_parse_a_null_value
		Local loObj As Object
		loObj = Json.decode('{"movil": null}')
		This.AssertIsObject(loObj, "can not create loObj object")
		This.AssertEquals(.Null., loObj._movil, "Values does not match")
		This.MessageOut("Expected Value: .NULL.")
		This.MessageOut("Returned Value: " + Transform(loObj._movil))

*====================================================================
	Procedure test_should_parsear_an_integer_value
		Local loObj As Object
		loObj = Json.decode('{"age": 33}')
		This.AssertIsObject(loObj, "can not create loObj object")
		This.AssertEquals(33, loObj._age, "Values does not match")
		This.MessageOut("Expected Value: 33")
		This.MessageOut("Returned Value: " + Transform(loObj._age))

*====================================================================
	Procedure test_should_parse_a_decimal_value
		Local loObj As Object
		loObj = Json.decode('{"PI": 3.1415926535}')
		This.AssertIsObject(loObj, "can not create loObj object")
		This.AssertEquals(3.1415926535, loObj._PI, "values does not match")
		This.MessageOut("Expected Value: 3.1415926535")
		This.MessageOut("Returned Value: " + Transform(loObj._PI))

*====================================================================
	Procedure test_should_parse_true_value
		Local loObj As Object
		loObj = Json.decode('{"male": true}')
		This.AssertIsObject(loObj, "can not create loObj object")
		This.AssertEquals(.T., loObj._male, "values does not match")
		This.MessageOut("Expected Value: .T.")
		This.MessageOut("Returned Value: " + Transform(loObj._male))

*====================================================================
	Procedure test_should_parse_false_value
		Local loObj As Object
		loObj = Json.decode('{"female": false}')
		This.AssertIsObject(loObj, "can not create loObj object")
		This.AssertEquals(.F., loObj._female, "values does not match")
		This.MessageOut("Expected Value: .F.")
		This.MessageOut("Returned Value: " + Transform(loObj._female))

*====================================================================
	Procedure test_should_parse_short_date_format_yyy_mm_dd_hifen_separator
		Local loObj As Object, lcDate As String
		Set Century On
		Set Date Dmy
		lcDate = Alltrim(Transform(Year(Date()))) + '-' + Padl(Alltrim(Transform(Month(Date()))),2,'0') + '-' + Padl(Alltrim(Transform(Day(Date()))),2,'0')
		loObj  = Json.decode('{"date": "' + lcDate + '"}')
		This.AssertIsObject(loObj, "can not create loObj object")
		This.AssertEquals(Date(), loObj._date, "values does not match")
		This.MessageOut("Expected Value: " + Transform(Date()))
		This.MessageOut("Returned Value: " + Transform(loObj._date))

*====================================================================
	Procedure test_should_parse_long_date_format_yyy_mm_dd_hifen_separator
		Local loObj As Object, lcDate As String
		Set Century On
		Set Date Dmy
		lcDate 		= '2019-04-25 17:51:18'
		lcExpected 	= '25/04/2019 05:51:18 PM'
		loObj 		= Json.decode('{"date": "' + lcDate + '"}')
		This.AssertIsObject(loObj, "can not create loObj object")
		This.AssertEquals(lcExpected, Transform(loObj._date), "values does not match")
		This.MessageOut("Expected Value: " + Transform(lcExpected))
		This.MessageOut("Returned Value: " + Transform(loObj._date))

*====================================================================
	Procedure test_should_parse_an_array_value
		Local lcJson As String, loObj As Object
		Text To lcJson noshow
			{
				"state": "1",
				"table":
				[
					"value1",
					"value2",
					"value3",
					"",
					"value5"
				]
			}
		EndText
		loObj = Json.decode(lcJson)
		This.AssertIsObject(loObj)
		This.AssertNotNull(loObj, "can not convert loObj object")
		If !Empty(Json.LastErrorText)
			This.MessageOut("Ha ocurrido un error: " + Json.LastErrorText)
		Endif
		lnExpected 	= 5
		lnGot 		= loObj._table.Len()
		This.MessageOut("Array contains {" + Transform(lnGot) + "} elements")
		This.AssertEquals(lnExpected, lnGot, "values does not match")

*====================================================================
	Procedure test_should_generate_an_error_when_sending_invalid_columns_names_or_fields_names
		Local lcJson As String, loObj As Object
		Text To lcJson noshow
			{
				"state":"1",
				"date":
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
		EndText
		loObj = Json.decode(lcJson)
		This.AssertIsObject(loObj, "can not convert [loObj]")
		lcXML = Json.ArrayToXML(loObj._date)
		If !Empty(Json.LastErrorText)
			This.MessageOut("Ha ocurrido un error: " + Json.LastErrorText)
		Endif

*====================================================================
Enddefine