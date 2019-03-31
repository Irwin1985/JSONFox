# JSONFox ![](images/prg.gif)  

**JSONFox** is a free **JSON / XML** ***parser*** for exchanging data between layers developed in Visual FoxPro 9.0

**NOTE:** This library was inspired by **[vfpjson] (https://github.com/sait/vfpjson)**.


### Project Manager

**Irwin Rodríguez** (Toledo, Spain)

### Latest Release

**[JSONFox](/README.md)** - v.1.2 (beta) - Release 2019-03-30 01:47:31

<hr>

## Features

**JSONFox** supports XML serialization using a JSON Array as parameters. This is useful for CURSORS serialization between layers.
**JSONFox** adds an **underscore** before the attribute name for avoiding internal conflict with native object properties. That means you'll have to reference your deserialized object like: obj._attribute

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
 *-- Serialize JSON String*
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
 
 *-- Don't forget check the LastErrorText*
 IF !EMPTY(loJson.LastErrorText) 
 	MESSAGEBOX(loJson.LastErrorText, 0+48, "Something went wrong")
	RELEASE loJson
	RETURN
 ELSE &&!EMPTY(loJson.LastErrorText)
 ENDIF &&!EMPTY(loJson.LastErrorText)
 DISPLAY OBJECTS LIKE obj
 
 *-- Deserialize Object*
 cJSONStr = loJSON.encode(obj)
 IF !EMPTY(loJson.LastErrorText) 
 	MESSAGEBOX(loJson.LastErrorText, 0+48, "Something went wrong")
	RELEASE loJson
	RETURN
 ELSE &&!EMPTY(loJson.LastErrorText)
 ENDIF &&!EMPTY(loJson.LastErrorText)
 ?cJSONStr
 
 *-- Serialize XML from JSON Array*
 
 
 
 
</pre>
