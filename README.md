# JSONFox ![](docs/prg.gif)  

**JSONFox** is a free **JSON / XML** ***parser*** for Visual FoxPro 9.0

### Project Manager

**Irwin Rodríguez** (Toledo, Spain)

### Latest Release

**[JSONFox]** - 3.1 - Release 2020-10-19 08:45:10

**[JSONFox]** - 3.0 - Release 2020-10-14 17:26:07

**[JSONFox]** - 2.8 - Release 2020-10-10 18:17:34

**[JSONFox]** - 2.7 - Release 2020-09-29 14:05:46

**[JSONFox]** - 2.6 - Release 2020-09-26 18:34:42

**[JSONFox]** - 2.5 - Release 2020-09-15 11:01:14

**[JSONFox]** - 2.4 - Release 2020-09-11 13:29:08

**[JSONFox]** - 2.3 - Release 2020-08-09 20:14:01

**[JSONFox]** - 2.2 - Release 2020-08-07 23:29:18

**[JSONFox]** - 2.1 - Release 2020-08-05 23:12:07

**[JSONFox]** - 2.0 - Release 2020-07-28 19:50:42

<hr>

### Features

**JSONFox** has a new built-in function called `CursorStructure` wich retrieve the JSON representation of the alias given. **(new)**

**JSONFox** has a new built-in function called `JSONViewer` wich open a JSON viewer form. **(new)**

**JSONFox** has a new built-in function called `Stringify` for object serialization and indentation. **(new)**

**JSONFox** has a new built-in function called `JSONToCursor`. **(new)**

**JSONFox** has a JSON Empty Class called `JSON` in which you can extends all those classes you need to convert into JSON representation. **(new)**

**JSONFox** supports XML serialization by passing a JSON Array string representation as parameter. This is useful for CURSORS serialization between layers.

**JSONFox** Parser recognize **DATE** and **DATETIME** types.

**JSONFox** supports Cursor Serialization using the `CursorToJSON()` built-in function.

### Basic Usage
```xBase
* Now you can use JSONFox as a compiled App...
 Do LocFile("JSONFox", "app")

* Parse a string into an object.
 MyObj = _Screen.Json.Parse('{"foo": "bar"}')
 ?MyObj.foo
 
* Convert Cursor into JSON string.
Create Cursor cGames (game c(25), launched i(4))
Insert into cGames Values('Pac-Man', 1980)
Insert into cGames Values('Super Mario Bros', 1985)
Insert into cGames Values('Space Invaders', 1978)
Insert into cGames Values('The Legend of Zelda', 1986)

?_Screen.Json.CursorToJson('cGames')
```
## Function Signature
`_Screen.Json.CursorToJSON(tcCursor As String **[, tbCurrentRow As Boolean [, tnDataSession As Integer]]**)`

* ![](docs/prop.gif) **tcCursor:** the name of your cursor.
* ![](docs/prop.gif) **tbCurrentRow:** ¿Would you like to serialize the current row? .F. as default.
* ![](docs/prop.gif) **tnDataSession:** Provide this parameter if you're working in a private session.

<hr>

## Properties
* ![](docs/prop.gif) **LastErrorText:** Stores the possible error generated in the current sentence.

## Methods
<hr>

### (New Methods)

* ![](docs/meth.gif) **_Screen.Json.Parse(tcJsonStr AS MEMO):** Parse the string text as JSON (Visual Foxpro Empty class object representation)
  * **tcJsonStr:** represents a valid JSON string format (required).

* ![](docs/meth.gif) **_Screen.Json.Stringify(tvNewVal As Variant):** Return an indented JSON string corresponding to the specified value.
  * **tvNewVal:** you can pass either an object or a raw JSONString (required).

* ![](docs/meth.gif) **_Screen.Json.Decode(tcJsonStr AS MEMO):** Decode a valid JSON format string.
  * **tcJsonStr:** represents a valid JSON string format (required).

* ![](docs/meth.gif) **_Screen.Json.LoadFile(tcJsonFile AS STRING):** Loads and decodes any file extension with a valid JSON format string inside.
  * **tcJsonFile:** represents any file extension with a valid JSON string format (required).

* ![](docs/meth.gif) **_Screen.Json.ArrayToXML(tStrArray AS MEMO):** Serialize a JSON string to a XML representation.
  * **tStrArray:** represents a valid JSON Array string format.

* ![](docs/meth.gif) **_Screen.Json.XMLToJson(tcXML AS MEMO):** Serialize a XML string to a JSON representation.
  * **tcXML:** represents a valid XML string format.

* ![](docs/meth.gif) **_Screen.Json.Encode(vNewProp as variant):** Encode a JSON object into string.
  * **vNewProp:** represents any value type.
  
### Examples

```xBase
 * Serialize JSON String
 Do LocFile("JSONFox", "app")
 * Parse from string
 Text To lcJsonStr NoShow
   {
    "name":"Irwin",
    "surname": "Rodriguez",
    "birth":"1985-11-15",
    "current_year": 2019,
    "wife": "Serelys Fonseca",
    "music_band":"The Beatles",
    "size": 1.79,
    "isgamer": false,
    "isprogrammer": true, 
    "hascar": null
   }
 EndText
 obj = _Screen.Json.Parse(lcJsonStr)
 
 * Don't forget check the LastErrorText
 If _Screen.Json.lError
   MessageBox(_Screen.Json.LastErrorText, 48, "Something went wrong")
   Return
 EndIf
 
 ?obj.name
 ?obj.size
 
 * Deserialize and Indent
 cJSONStr = _Screen.Json.Stringify(obj)
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

obj = _Screen.Json.Parse(lcStr)
* Encode just the Array attribute called (data)*
lcJsonArray = _Screen.Json.Parse(obj._data)

* Serialize the JSON string to XML string
lcXML = _Screen.Json.ArrayToXML("[" + lcJsonArray + "]")

* Serialize the XML document to VFP CURSOR **(this is cool)**
=XMLToCursor(lcXML, "qEmployees")

* Modifies some fields
Select qEmployees
Replace salary With 5.000 In qEmployees

* Serialize Cursor to XML stream data **(in memory)**
LOCAL cStrXML
=CursorToXML("qEmployees", "cStrXML", 1, 0, 0,"1")

* Now serialize the modified XML to JSON
cJson = _Screen.Json.XMLToJson(cStrXML)
?cJson

* Decorate and print any class
* Suppose you have a person class.
oPerson = CreateObject("PersonClass")
With oPerson
	.fullname = "Jhon Doe"
	.age = 45
	.gender = "Male"
	.married = .T.
	.birthdate = Date(1985, 11, 15)
	.created = Datetime()
EndWith

* Now you need to extend this person class
oJhon = NewObject("JSon", "JsonDecorator.prg")
?oJhon.to_json()
{
  "age": 45,
  "birthdate": "1985-11-15",
  "created": "2020-07-28 09:29:41 PM",
  "fullname": "Jhon Doe",
  "gender": "Male",
  "married": true
}

* Stringify Example
cJson = '{"age":45,"birthdate":"1985-11-15","created":"2020-07-28 09:29:41 PM","fullname":"Jhon Doe","gender":"Male","married":true,"soports":["running","swiming","basket-ball"]}'
?_Screen.Json.Stringify(cJson)

```
### CursorStructure() function
```xBase
Use Home(2) + "NorthWind\Customers.dbf"
?_Screen.Json.CursorStructure('Customers', Set("Datasession"), .T.)
// Function Signature
// CursorStructure(tcAlias, tnDataSessionID, tlCopyExtended)
// 1. tcAlias is the alias given.
// 2. tnDataSessionID is the current Datasession where Alias() lives (for private data sessions).
// 3. tlCopyExtended if .F. then copy FIELD_NAME, FIELD_TYPE, FIELD_LENGTH and FIELD_DECIMAL_PLACES. 
//    if is .T. then parse all the alias data structure.
```
### JSONViewer() function
```xBase
 Text To lcStr NoShow
  {
    "array": [
      1,
      2,
      3
    ],
    "boolean": false,
    "color": "gold",
    "null": null,
    "number": 123,
    "object": null,
    "string": "Hello World"
  }
ENDTEXT
_Screen.Json.JSONViewer(lcStr)
```
![](docs/sample1.png)
![](docs/sample2.png)

### Release History

<hr>

2020-10-19

* `CursorStructure`()` function.

2020-10-14

* Core changes (including JSONFox.h instead of token objects for better performance).


2020-07-30

* `JsonToCursor()` function.

* Negative Numbers recognition.

* Empty array parsing.

2020-07-31

* Datetime parsing supported formats: 

   * JavaScript built-in `JSON` object
 
   * ISO 8601
 
   * Visual Foxpro

2020-08-02

* Empty object parsing.

* `GetPosition()` and `SetPosition()` functions added into StreamReader class.

2020-08-05

* `Stringify()` function: parsing empty array and empty object.

* `JSONToRTF()` function: JSON string format to RTF representation.

* `JSONViewer()` function: open a JSON form viewer.

2020-08-07

* `Encode()` function: now accept 2 parameters (toObjRef As Object **[, tcFlags]**) *Where tcFlags could be a combination of these values:*

| Parameter | Description |
| --------- | ----------- |
| P | Protected |
| H | Hidden |
| G | Public |
| N | Native |
| U | User Defined |
| C | Changed |
| I | Inherited |
| B | Base |
| R | Read Only |

2020-08-09

* LL(k) implemented using the FoxQueue class.

2020-09-11

* `JSONToCursor()` function: now accept another parameter called `tlJustArray`. You must pass it as .T. if you want just the Array representation of your cursor.*

* `Stringify()` function: now can receive either strings objects or array representation.*


## License

`JSONFox` is released under the MIT Licence.
