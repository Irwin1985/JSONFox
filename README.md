# JSONFox ![](images/prg.gif)  

**JSONFox** is a free **JSON / XML** ***parser*** for exchanging data between layers developed in Visual FoxPro 9.0

**NOTE:** This library was inspired by **[vfpjson](https://github.com/sait/vfpjson)**.


### Project Manager

**Irwin Rodríguez** (Toledo, Spain)

### Latest Release

**[JSONFox](/README.md)** - v.1.2 (beta) - Release 2019-03-30 01:47:31

<hr>

## Features

**JSONFox** supports XML serialization using a JSON Array as parameters. This is useful for CURSORS serialization between layers.

**JSONFox** adds an **underscore** before the attribute name for avoiding internal conflict with native object properties. That means you'll have to reference your deserialized object like: obj._attribute

**JSONFox** Analyzer recognize and serialize **DATE** and **DATETIME** types. **(new)**

## Properties
* ![](images/prop.gif) **LastErrorText:** Stores the possible error generated in the current sentence.

## Methods

* ![](images/meth.gif) **Decode(tcJsonStr AS MEMO):** Decode a valid JSON format string.
  * **tcJsonStr:** represents a valid JSON string format (required).

* ![](images/meth.gif) **LoadFile(tcJsonFile AS STRING):** Loads and decodes any file extension with a valid JSON format string inside.
  * **tcJsonFile:** represents any file extension with a valid JSON string format (required).

* ![](images/meth.gif) **ArrayToXML(tStrArray AS MEMO):** Serialize a JSON string to a XML representation.
  * **tStrArray:** represents a valid JSON Array string format.

* ![](images/meth.gif) **XMLToJson(tcXML AS MEMO):** Serialize a XML string to a JSON representation.
  * **tcXML:** represents a valid XML string format.

* ![](images/meth.gif) **Encode(vNewProp as variant):** Encode a JSON object into string.
  * **vNewProp:** represents any value type.
  
### Examples

<pre>
 * Serialize JSON String
 SET PROCEDURE TO "JSONFox.prg" ADDITIVE
 loJSON = NEWOBJECT("JSONFox", "JSONFox.prg")
 TEXT TO lcJsonStr NOSHOW
   {
    "name":"Irwin",
    "surname": "Rodriguez",
    "birth":"1985-11-15",
    "current_year": 2019    
    "wife": "Serelys Fonseca",
    "music_band":"The Beatles",
    "size": 1.79,
    "isGamer": false,
    "isProgrammer": true, 
    "hasCar": null
   }
 ENDTEXT
 obj = loJSON.decode(lcJsonStr)
 
 * Don't forget check the LastErrorText
 IF !EMPTY(loJson.LastErrorText) 
 	MESSAGEBOX(loJson.LastErrorText, 0+48, "Something went wrong")
	RELEASE loJson
	RETURN
 ELSE &&!EMPTY(loJson.LastErrorText)
 ENDIF &&!EMPTY(loJson.LastErrorText)
 
 ?obj._name
 ?obj._size
 
 DISPLAY OBJECTS LIKE obj
 
 * Deserialize Object
 cJSONStr = loJSON.encode(obj)
 IF !EMPTY(loJson.LastErrorText) 
 	MESSAGEBOX(loJson.LastErrorText, 0+48, "Something went wrong")
	RELEASE loJson
	RETURN
 ELSE &&!EMPTY(loJson.LastErrorText)
 ENDIF &&!EMPTY(loJson.LastErrorText)
 ?cJSONStr
 
 * Serialize XML from JSON Array
 TEXT TO lcStr NOSHOW
	 {
	  "status": "success",
	  "data": [
	    {
	      "id": 2,
	      "correo": "rodriguez.irwin@gmail.com",
	      "nombre": "Irwin1985",
	      "apellido": "Rodriguez",
	      "sexo": "1",
	      "sueldo": 2278.45,
	      "profesion_id": 1,
	      "fechanacimiento": "1985-11-15",
	      "fecharegistro": "2019-03-31",
	      "soltero": true
	    }
	  ],
	  "code": 200,
	  "message": "empleados consultados"
	}
ENDTEXT

obj = loJSON.Decode(lcStr)
IF !EMPTY(loJson.LastErrorText) 
	MESSAGEBOX(loJson.LastErrorText, 0+48, "Something went wrong")
	RELEASE loJson
	RETURN
ELSE &&!EMPTY(loJson.LastErrorText)
ENDIF &&!EMPTY(loJson.LastErrorText)

* Encode just the Array attribute called (_data)*

lcJson = loJson.Encode(obj._data)

* Serialize the JSON string to XML string
lcXML = loJson.ArrayToXML(lcJson)

IF !EMPTY(loJson.LastErrorText)
	MESSAGEBOX(loJson.LastErrorText, 0+48, "Error")
	RELEASE loJson, obj, lcJsonIni
	RETURN
ELSE &&!EMPTY(loJson.LastErrorText)
ENDIF &&!EMPTY(loJson.LastErrorText)

* Serialize the XML document to VFP CURSOR **(this is cool)**
=XMLTOCURSOR(lcXML, "qEmpleados")

* Modifies some fields
SELECT qEmpleados
REPLACE sueldo WITH 5.000 IN qEmpleados

* Serialize CURSOR to XML stream data **(in memory)**
LOCAL cStrXML
=CURSORTOXML("qEmpleados","cStrXML",1,0,0,"1")

* Now serialize the modified XML to JSON
cJson = loJson.XMLToJson(cStrXML)
IF !EMPTY(loJson.LastErrorText)
	MESSAGEBOX(loJson.LastErrorText, 0+48, "Error")
	RELEASE loJson, obj, lcJsonIni
	RETURN
ELSE &&!EMPTY(loJson.LastErrorText)
ENDIF &&!EMPTY(loJson.LastErrorText)
?cJson

RELEASE loJson, obj
</pre>
