*========================================================================*
* Class StructureToJSON
*========================================================================*
Define Class StructureToJSON As Session
	nSessionID = 0
	curName = ""
	lExtended = .F.
	Hidden utils
* Field constants	
	#Define FIELD_NAME							1
	#Define FIELD_TYPE							2
	#Define FIELD_WIDTH							3
	#Define DECIMAL_PLACES						4
	#Define NULL_VALUES_ALLOWED					5
	#Define CODE_PAGE_TRANSLATION_NOT_ALLOWED	6
	#Define FIELD_VALIDATION_EXPRESSION			7
	#Define FIELD_VALIDATION_TEXT				8
	#Define FIELD_DEFAULT_VALUE					9
	#Define TABLE_VALIDATION_EXPRESSION			10
	#Define TABLE_VALIDATION_TEXT				11
	#Define LONG_TABLE_NAME						12
	#Define INSERT_TRIGGER_EXPRESSION			13
	#Define UPDATE_TRIGGER_EXPRESSION			14
	#Define DELETE_TRIGGER_EXPRESSION			15
	#Define TABLE_COMMENT						16
	#Define NEXTVALUE_FOR_AUTOINCREMENTING		17
	#Define STEP_FOR_AUTOINCREMENTING			18
	#Define CHARACTER_TYPE						'C'
	#Define NUMERIC_TYPE						'N'
	#Define LOGICAL_TYPE						'L'
&& ======================================================================== &&
&& Function Init
&& ======================================================================== &&
	Function Init
		This.utils = Createobject("JsonUtils")
	Endfunc
*========================================================================*
* Function StructureToJSON
*========================================================================*
	Function StructureToJSON As Memo
		If !Empty(This.nSessionID)
			Set DataSession To (This.nSessionID)
		Endif
		Local lcStructJSON As Memo, lcFieldJSON as memo, lnLength As Integer
		lcStructJSON = '{"' + Lower(this.curName) + '":['
		lcFieldJSON  = ''
		lnLength 	 = 0
		If Used(this.curName)
			lnLength = Afields(aStruct, this.curName)
			If lnLength > 0
				For i = 1 To lnLength
					lcFieldJSON = lcFieldJSON + Iif(i==1, '{', ',{')
					lcFieldJSON = lcFieldJSON + '"field_name":' + this.utils.GetValue(aStruct[i, FIELD_NAME], CHARACTER_TYPE)
					lcFieldJSON = lcFieldJSON + ',"field_type":' + this.utils.GetValue(aStruct[i, FIELD_TYPE], CHARACTER_TYPE)
					lcFieldJSON = lcFieldJSON + ',"field_width":' + this.utils.GetValue(aStruct[i, FIELD_WIDTH], NUMERIC_TYPE)
					lcFieldJSON = lcFieldJSON + ',"decimal_places":' + this.utils.GetValue(aStruct[i, DECIMAL_PLACES], NUMERIC_TYPE)
					If this.lExtended
						lcFieldJSON = lcFieldJSON + ',"null_values_allowed":' + this.utils.GetValue(aStruct[i, NULL_VALUES_ALLOWED], LOGICAL_TYPE)
						lcFieldJSON = lcFieldJSON + ',"code_page_translation_not_allowed":' + this.utils.GetValue(aStruct[i, CODE_PAGE_TRANSLATION_NOT_ALLOWED], LOGICAL_TYPE)
						lcFieldJSON = lcFieldJSON + ',"field_validation_expression":' + this.utils.GetValue(aStruct[i, FIELD_VALIDATION_EXPRESSION], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"field_validation_text":' + this.utils.GetValue(aStruct[i, FIELD_VALIDATION_TEXT], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"field_default_value":' + this.utils.GetValue(aStruct[i, FIELD_DEFAULT_VALUE], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"table_validation_expression":' + this.utils.GetValue(aStruct[i, TABLE_VALIDATION_EXPRESSION], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"table_validation_text":' + this.utils.GetValue(aStruct[i, TABLE_VALIDATION_TEXT], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"long_table_name":' + this.utils.GetValue(aStruct[i, LONG_TABLE_NAME], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"insert_trigger_expression":' + this.utils.GetValue(aStruct[i, INSERT_TRIGGER_EXPRESSION], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"update_trigger_expression":' + this.utils.GetValue(aStruct[i, UPDATE_TRIGGER_EXPRESSION], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"delete_trigger_expression":' + this.utils.GetValue(aStruct[i, DELETE_TRIGGER_EXPRESSION], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"table_comment":' + this.utils.GetValue(aStruct[i, TABLE_COMMENT], CHARACTER_TYPE)
						lcFieldJSON = lcFieldJSON + ',"nextvalue_for_autoincrementing":' + this.utils.GetValue(aStruct[i, NEXTVALUE_FOR_AUTOINCREMENTING], NUMERIC_TYPE)
						lcFieldJSON = lcFieldJSON + ',"step_for_autoincrementing":' + this.utils.GetValue(aStruct[i, STEP_FOR_AUTOINCREMENTING], NUMERIC_TYPE)
					EndIf
					lcFieldJSON = lcFieldJSON + '}'
				Endfor
			Endif
		EndIf
		lcStructJSON = lcStructJSON + lcFieldJSON + ']}'
		Return lcStructJSON
	Endfunc
Enddefine
