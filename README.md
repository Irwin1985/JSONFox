# JSONFox ![](docs/prg.gif)  

**JSONFox** is a free **JSON / XML** ***parser*** for Visual FoxPro 9.0

Si te gusta mi trabajo puedes apoyarme con un donativo:   
[![DONATE!](http://www.pngall.com/wp-content/uploads/2016/05/PayPal-Donate-Button-PNG-File-180x100.png)](https://www.paypal.com/donate/?hosted_button_id=LXQYXFP77AD2G) 

    Gracias por tu apoyo!

### Project Manager

**Irwin Rodríguez** (Toledo, Spain)

### New DLL JSONFoxHelper.dll
If you want to speed up the lexing process then you should use the JSONFoxHelper dll built in C# that scans the tokens faster. In order to use this scanner instead of the native one you just need to activate the *NetScanner* property like the example below:

```xBase
// activate the property before using any routine from json class.
_Screen.Json.netScanner = .T.
_Screen.Json.Parse(myJSONString)
```
### How fast is the scanning process against the native way?
I did a timing parsing a json file which size was 8mb. The native scanner lasts more than 15 minutes and the new scanner just 93 seconds. Pretty amazing isn't it?

# NOTE
Remember register the JSONFoxHelper.dll before using it. Check this article if you got stuck: https://stackoverflow.com/questions/7092553/turn-a-simple-c-sharp-dll-into-a-com-interop-component


### What's new in Version 9

1. Faster Lexical Analizer
  - I've optimised the string recogniser which is faster now.
  - Special characters and Hex values should be faster
2. Faster Parser
  - The whole algorith has been rewriten and now creates a real array instead an object.
3. Faster DATE and DATETIME recogniser.
4. Faster JSON to cursor conversion
  - Now it used sorted dictionaries instead of plain arrays

### Basic Usage
```xBase
* Now you can use JSONFox as a compiled App...
 Do LocFile("JSONFox", "app")

* Parse a string into an object.
 MyObj = _Screen.Json.Parse('{"foo": "bar"}')
 ?MyObj.foo

**New** you may also parse any valid JSON string.
 ?_Screen.Json.Parse('"bar"') && bar
 ?_Screen.Json.Parse('true')  && .T.
 ?_Screen.Json.Parse('false') && .F.
 ?_Screen.Json.Parse('null')  && .NULL.
 ?_Screen.Json.Parse('1985')  && 1985
 
* Convert Cursor into JSON string.
Create Cursor cGames (game c(25), launched i(4))
Insert into cGames Values('Pac-Man', 1980)
Insert into cGames Values('Super Mario Bros', 1985)
Insert into cGames Values('Space Invaders', 1978)
Insert into cGames Values('The Legend of Zelda', 1986)

?_Screen.Json.CursorToJson('cGames')

* Convert any cursor structure into JSON
?_Screen.Json.CursorStructure('cGames')
```
## Full Documentation
* ![](docs/meth.gif) **_Screen.Json.CursorToJSON(tcCursor As String *[, tbCurrentRow, tnDataSession, tbJustArray, tbParseUTF8, tbTrimChars]*)**
* ![](docs/prop.gif) **tcCursor:** the name of your cursor.
* ![](docs/prop.gif) **tbCurrentRow:** ¿Would you like to serialize the current row? .F. as default.
* ![](docs/prop.gif) **tnDataSession:** Provide this parameter if you're working in a private session.
* ![](docs/prop.gif) **tbJustArray:** if is set to .T. then you get just an array with the data, otherwise you'll get an object containing both the cursor name and the array data.
* ![](docs/prop.gif) **tbParseUTF8:** if is set to .T. then all special characters will be encoded. Eg: 'é' => '\u00e9'
* ![](docs/prop.gif) **tbTrimChars:** if is set to .T. then all right blank spaces will be trimed.

<hr>

## Properties
* ![](docs/prop.gif) **LastErrorText:** Stores the possible error generated in the current sentence.

## Methods
<hr>

### Examples

```xBase
 * Sample 1: Serialize JSON String
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
 
 * Sample 2: JSONArray to Cursor
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
	    },
      {
          "id": 3,
          "email": "oscaraguero85@gmail.com",
          "name": "oscar",
          "lastName": "aguero",
          "sex": "1",
          "salary": 1500.45,
          "profesion_id": 1,
          "birthDate": "1985-06-18",
          "createdAt": "2021-10-11",
          "single": true
      }      
	  ],
	  "code": 200,
	  "message": "success"
	}
ENDTEXT

obj = _Screen.Json.Parse(lcStr)

* Make a copy of the internal array from obj.data
Acopy(obj.data, aEmployeeList)

* Now pass the aEmployeeList by reference with '@'
lcJsonArray = _Screen.Json.Encode(@aEmployeeList)

* Convert the JSONArray into VFP CURSOR **(this is cool)**
_Screen.Json.JSONToCursor(lcJsonArray, "qEmployees")

* Modify some fields
Select qEmployees
Replace salary With 5.000 In qEmployees

* Now serialize the cursor to JSON
cJson = _Screen.json.CursorToJson("qEmployees")
?cJson

* Sample 3: Stringify Example
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

**SIN GARANTÍA**

EL SOFTWARE SE PROPORCIONA "TAL CUAL", SIN GARANTÍA DE NINGÚN TIPO, EXPRESA O IMPLÍCITA, INCLUYENDO PERO NO LIMITADO A LAS GARANTÍAS DE COMERCIABILIDAD, IDONEIDAD PARA UN PROPÓSITO PARTICULAR Y NO INFRACCIÓN. EN NINGÚN CASO LOS AUTORES O TITULARES DE DERECHOS DE AUTOR SERÁN RESPONSABLES DE NINGÚN RECLAMO, DAÑO U OTRA RESPONSABILIDAD, YA SEA EN UNA ACCIÓN CONTRACTUAL, AGRAVIO O DE OTRA MANERA, QUE SURJA DE, FUERA DE O EN RELACIÓN CON EL SOFTWARE O EL USO U OTRAS NEGOCIOS EN EL SOFTWARE.
