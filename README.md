# JSONFox ![](images/prg.gif)  

**JSONFox** is a free **JSON / XML** ***parser*** for exchanging data between layers developed in Visual FoxPro 9.0

**NOTE:** This library was inspired by **[vfpjson](https://github.com/sait/vfpjson)**.


### Project Manager

**Irwin Rodríguez** (Toledo, Spain)

### Latest Release

**[JSONFox](/README.md)** - 1.9 (beta) - Release 2019-08-20 08:33:42 AM

<hr>

## Features

**JSONFox** supports XML serialization using a JSON Array as parameters. This is useful for CURSORS serialization between layers.

**JSONFox** adds an **underscore** before the attribute name to avoid internal conflict with native object properties name. That means you'll have to reference your deserialized object like: obj._attribute

**JSONFox** Analyzer recognize and serialize **DATE** and **DATETIME** types.

**JSONFox** now supports Cursor Serialization using the CursorToJSON() function. **(new)**
### Example
```xBase
* Serialize JSON String
 Set Procedure To "JSONFox.prg" Additive
 loJSON = NewObject("JSONFox", "JSONFox.prg")
 
Create Cursor cGames (game c(25), launched i(4))
Insert into cGames Values('Pac-Man', 1980)
Insert into cGames Values('Super Mario Bros', 1985)
Insert into cGames Values('Space Invaders', 1978)
Insert into cGames Values('The Legend of Zelda', 1986)

?loJSON.CursorToJson('cGames')
```
## Function Signature
CursorToJSON(tcCursor As String **[, tbCurrentRow As Boolean [, tnDataSession As Integer]]**)

* ![](images/prop.gif) **tcCursor:** the name of your in memory cursor.
* ![](images/prop.gif) **tbCurrentRow:** ¿Would you like to serialize the current row? .F. as default.
* ![](images/prop.gif) **tnDataSession:** Provide this parameter if you're working in a private environment.

<hr>

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

```xBase
 * Serialize JSON String
 Set Procedure To "JSONFox.prg" Additive
 loJSON = NewObject("JSONFox", "JSONFox.prg")
 Text To lcJsonStr NoShow
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
 EndText
 obj = loJSON.decode(lcJsonStr)
 
 * Don't forget check the LastErrorText
 If !Empty(loJson.LastErrorText) 
 	MessageBox(loJson.LastErrorText, 0+48, "Something went wrong")
	Release loJson
	Return
 EndIf
 
 ?obj._name
 ?obj._size
 
 Display Object Like obj
 
 * Deserialize Object
 cJSONStr = loJSON.encode(obj)
 If !Empty(loJson.LastErrorText) 
 	MessageBox(loJson.LastErrorText, 0+48, "Something went wrong")
	Release loJson
	Return
 EndIf
 ?cJSONStr
 
 * Serialize XML from JSON Array
 Text To lcStr NoShow
	 {
	  "status": "success",
	  "data": [
	    {
	      "id": 2,
	      "email": "rodriguez.irwin@gmail.com",
	      "name": "Irwin1985",
	      "lastName": "Rodriguez",
	      "sex": "1",
	      "salary": 2278.45,
	      "profesion_id": 1,
	      "birthDate": "1985-11-15",
	      "createdAt": "2019-03-31",
	      "single": true
	    }
	  ],
	  "code": 200,
	  "message": "success"
	}
ENDTEXT

obj = loJSON.Decode(lcStr)
IF !Empty(loJson.LastErrorText) 
	MessageBox(loJson.LastErrorText, 0+48, "Something went wrong")
	Release loJson
	Return
EndIf

* Encode just the Array attribute called (_data)*

lcJson = loJson.Encode(obj._data)

* Serialize the JSON string to XML string
lcXML = loJson.ArrayToXML(lcJson)

If !Empty(loJson.LastErrorText)
	MessageBox(loJson.LastErrorText, 0+48, "Error")
	Release loJson, obj, lcJsonIni
	Return
EndIf

* Serialize the XML document to VFP CURSOR **(this is cool)**
=XMLToCursor(lcXML, "qEmployees")

* Modifies some fields
Select qEmployees
Replace salary With 5.000 In qEmployees

* Serialize Cursor to XML stream data **(in memory)**
LOCAL cStrXML
=CursorToXML("qEmployees","cStrXML",1,0,0,"1")

* Now serialize the modified XML to JSON
cJson = loJson.XMLToJson(cStrXML)
If !Empty(loJson.LastErrorText)
	MessageBox(loJson.LastErrorText, 0+48, "Error")
	Release loJson, obj, lcJsonIni
	Return
EndIf
?cJson

Release loJson, obj
```
