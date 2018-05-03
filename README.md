# Nim configparser
this is a pure [INI](https://en.wikipedia.org/wiki/INI_file) parser for nim

> Nim has advanced [parsecfg](https://nim-lang.org/docs/parsecfg.html)

## Example 

```nim
import configparser

let sample1 = """

[general]
appname = configparser
version = 0.1

[author]
name = xmonader
email = notxmonader@gmail.com


"""

var d = parseINI(sample1)

# doAssert(d.sectionsCount() == 2)
doAssert(d.getProperty("general", "appname") == "configparser")
doAssert(d.getProperty("general","version") == "0.1")
doAssert(d.getProperty("author","name") == "xmonader")
doAssert(d.getProperty("author","email") == "notxmonader@gmail.com")

d.setProperty("author", "email", "alsonotxmonader@gmail.com")
doAssert(d.getProperty("author","email") == "alsonotxmonader@gmail.com")
doAssert(d.hasSection("general") == true)
doAssert(d.hasSection("author") == true)
doAssert(d.hasProperty("author", "name") == true)
d.deleteProperty("author", "name")
doAssert(d.hasProperty("author", "name") == false)

echo d.toINIString()
let s = d.getSection("author")
echo $s
```


## How to
You can certainly use regular expressions [python configparser](https://github.com/python/cpython/blob/master/Lib/configparser.py#L559), but we will go for a simpler approach

### INI sample
```ini

[general]
appname = configparser
version = 0.1

[author]
name = xmonader
email = notxmonader@gmail.com
```
INI file consists of one or more sections and each section consists of one or more key value pairs separated by `=`


### Define your data types

```nim
import tables, strutils

```
We will use tables extensively
```nim
type Section = ref object
    properties: Table[string, string]
```
`Section` type contains `properties` table represents key value pairs 

```nim
proc setProperty*(this: Section, name: string, value: string) =
    this.properties[name] = value
```
To set property in the underlying `properties` table

```nim
proc newSection*() : Section =
    var s = Section()
    s.properties = initTable[string, string]()
    return s
```
To create new Section object

```nim
proc `$`*(this: Section) : string =
    return "<Section" & $this.properties & " >"
```
Simple `toString` proc using `*` operator
```nim
type INI = ref object
    sections: Table[string, Section]
```
`INI` type represents the whole document and contains a table `section` from `sectionName` to `Section` object.

```
proc newINI*() : INI = 
    var ini = INI()
    ini.sections = initTable[string, Section]()
    return ini
```
To craete new INI object
```nim
proc `$`*(this: INI) : string = 
    return "<INI " & $this.sections & " >"
```
define friendly `toString` proc using `*` operator


### Define API
```
proc setSection*(this: INI, name: string, section: Section) =
    this.sections[name] = section

proc getSection*(this: INI, name: string): Section =
    return this.sections.getOrDefault(name)

proc hasSection*(this: INI, name: string): bool =
    return this.sections.contains(name)

proc deleteSection*(this: INI, name:string) =
    this.sections.del(name)

proc sectionsCount*(this: INI) : int = 
    echo $this.sections
    return len(this.sections)
```
Some helper procs around INI objects for manipulating sections.

```nim

proc hasProperty*(this: INI, sectionName: string, key: string): bool=
    return this.sections.contains(sectionName) and this.sections[sectionName].properties.contains(key)

proc setProperty*(this: INI, sectionName: string, key: string, value:string) =
    echo $this.sections
    if this.sections.contains(sectionName):
        this.sections[sectionName].setProperty(key, value)
    else:
        raise newException(ValueError, "INI doesn't have section " & sectionName)

proc getProperty*(this: INI, sectionName: string, key: string) : string =
    if this.sections.contains(sectionName):
        return this.sections[sectionName].properties.getOrDefault(key)
    else:
        raise newException(ValueError, "INI doesn't have section " & sectionName)


proc deleteProperty*(this: INI, sectionName: string, key: string) =
    if this.sections.contains(sectionName) and this.sections[sectionName].properties.contains(key):
        this.sections[sectionName].properties.del(key)
    else:
        raise newException(ValueError, "INI doesn't have section " & sectionName)
```
More helpers around properties in the section objects managed by `INI` object

```nim
proc toINIString*(this: INI, sep:char='=') : string =
    var output = ""
    for sectName, section in this.sections:
        output &= "[" & sectName & "]" & "\n"
        for k, v in section.properties:
            output &= k & sep & v & "\n" 
        output &= "\n"
    return output
```
Simple proc `toINIString` to convert the nim structures into INI text string

### Parse!
OK, here comes the cool part

#### Parser states
```nim
type parserState = enum
    readSection, readKV
```
Here we have two states
- readSection: when we are supposed to extract section name from the current line
- readKV: when we are supposed to read the line in key value pair mode

#### ParseINI proc
```nim
proc parseINI*(s: string) : INI = 
```
Here we define a proc `parseINI` that takes a string `s` and creates an `INI` object

```nim
    var ini = newINI()
    var state: parserState = readSection
    let lines = s.splitLines
    
    var currentSectionName: string = ""
    var currentSection = newSection()
``` 
- `ini` is the object to be returned after parsing
- `state` the current parser state (weather it's `readSection` or `readKV`)
- `lines` input string splitted into lines `as we are a lines based parser`
- `currentSectionName` to keep track of what section we are currently in
- `currentSection` to populate `ini.sections` with `Section` object using `setSection` proc

```nim
   for line in lines:
```
for each line 
```nim
         if line.strip() == "" or line.startsWith(";") or line.startsWith("#"):
            continue
```
We continue if line is safe to igore `empty line` or starts with `;` or `#`

```nim
        if line.startsWith("[") and line.endsWith("]"):
            state = readSection
```
if line startswith `[` and ends with `]` then we set parser state to `readSection`

```nim
        if state == readSection:
            currentSectionName = line[1..<line.len-1]
            ini.setSection(currentSectionName, currentSection)
            state = readKV
```
if parser `state` is `readSection`
- extract section name `between [ and ]`
- add section object to the ini under the current section name
- change `state` to `readKV` to read key value pairs

```nim
        if state == readKV:
            let parts = line.split({'='})
            if len(parts) == 2:
                let key = parts[0].strip()
                let val = parts[1].strip()
                ini.setProperty(currentSectionName, key, val)
```
if `state` is `readKV` 
- extract `key` and `val` by splitting the line on `=`
- `setProperty` under the `currentSectionName` using `key` and `val`
```nim
    return ini
```
Here we return the populated `ini` object.

Feel free to send me PRs to make this tutorial/library better :)