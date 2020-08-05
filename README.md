# JSONFox ![](images/prg.gif)  

**JSONFox** is a free **JSON / XML** ***parser*** for Visual FoxPro 9.0

### Project Manager

**Irwin Rodríguez** (Toledo, Spain)

### Latest Release

**[JSONFox](/README.md)** - 2.0 - Release 2020-07-28 19:50:42

<hr>

### Features

**JSONFox** has a new built-in function called `JSONViewer` wich open a JSON viewer form. **(new)**

**JSONFox** has a new built-in function called `Stringify` for object serialization and indentation. **(new)**

**JSONFox** has a new built-in function called `JSONToCursor`. **(new)**

**JSONFox** has a JSON Empty Class called `JSON` in which you can extends all those classes you need to convert into JSON representation. **(new)**

**JSONFox** supports XML serialization by passing a JSON Array string representation as parameter. This is useful for CURSORS serialization between layers.

**JSONFox** Parser recognize **DATE** and **DATETIME** types.

**JSONFox** supports Cursor Serialization using the CursorToJSON() built-in function.

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
_Screen.Json.CursorToJSON(tcCursor As String **[, tbCurrentRow As Boolean [, tnDataSession As Integer]]**)

* ![](images/prop.gif) **tcCursor:** the name of your cursor.
* ![](images/prop.gif) **tbCurrentRow:** ¿Would you like to serialize the current row? .F. as default.
* ![](images/prop.gif) **tnDataSession:** Provide this parameter if you're working in a private session.

<hr>

## Properties
* ![](images/prop.gif) **LastErrorText:** Stores the possible error generated in the current sentence.

## Methods
<hr>

### (New Methods)

* ![](images/meth.gif) **_Screen.Json.Parse(tcJsonStr AS MEMO):** Parse the string text as JSON (Visual Foxpro Empty class object representation)
  * **tcJsonStr:** represents a valid JSON string format (required).

* ![](images/meth.gif) **_Screen.Json.Stringify(tvNewVal As Variant):** Return an indented JSON string corresponding to the specified value.
  * **tvNewVal:** you can pass either an object or a raw JSONString (required).

* ![](images/meth.gif) **_Screen.Json.Decode(tcJsonStr AS MEMO):** Decode a valid JSON format string.
  * **tcJsonStr:** represents a valid JSON string format (required).

* ![](images/meth.gif) **_Screen.Json.LoadFile(tcJsonFile AS STRING):** Loads and decodes any file extension with a valid JSON format string inside.
  * **tcJsonFile:** represents any file extension with a valid JSON string format (required).

* ![](images/meth.gif) **_Screen.Json.ArrayToXML(tStrArray AS MEMO):** Serialize a JSON string to a XML representation.
  * **tStrArray:** represents a valid JSON Array string format.

* ![](images/meth.gif) **_Screen.Json.XMLToJson(tcXML AS MEMO):** Serialize a XML string to a JSON representation.
  * **tcXML:** represents a valid XML string format.

* ![](images/meth.gif) **_Screen.Json.Encode(vNewProp as variant):** Encode a JSON object into string.
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
### JSONViewer() function
![String Indentation](docs/sample1.png)  *String Indentation*
![No Indentation](docs/sample2.png)  *No Indentation*

### Release History

<hr>

2020-07-30

* JsonToCursor() function.

* Negative Numbers recognition.

* Empty array parsing.

2020-07-31

* Datetime parsing supported formats: 

   * JavaScript built-in JSON object
 
   * ISO 8601
 
   * Visual Foxpro

2020-08-02

* Empty object parsing.

* GetPosition() and SetPosition() functions added into StreamReader class.

2020-08-05

* Stringify() function: parsing empty array and empty object.

* JSONToRTF() function: JSON string format to RTF representation.

* JSONViewer() function: open a JSON form viewer.


## License

JSONFox is released under the MIT Licence.
