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
 *-- Create object
 SET PROCEDURE TO "JSONFox.prg" ADDITIVE
 loJSON = NEWOBJECT("JSONFox", "JSONFox.prg")
 obj = loJSON.decode('{"name":"Irwin Rodriguez", "age": 33, "birth": "1985-11-15", "wife": "Serelys Fonseca", "music_band": "The Beatles", "PI": 3.14159265, "married": false, "programmer": true, "hascar": null}')
 
</pre>
