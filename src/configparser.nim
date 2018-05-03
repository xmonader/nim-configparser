# configparser
# Copyright xmonader
# pure INI configurations parser
import tables, strutils


type Section = ref object
    properties: Table[string, string]


proc setProperty*(this: Section, name: string, value: string) =
    this.properties[name] = value

proc newSection*() : Section =
    var s = Section()
    s.properties = initTable[string, string]()

    return s

proc `$`*(this: Section) : string =
    return "<Section" & $this.properties & " >"

type INI = ref object
    sections: Table[string, Section]

proc newINI*() : INI = 
    var ini = INI()
    ini.sections = initTable[string, Section]()
    return ini

proc `$`*(this: INI) : string = 
    return "<INI " & $this.sections & " >"

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

proc toINIString*(this: INI, sep:char='=') : string =
    var output = ""
    for sectName, section in this.sections:
        output &= "[" & sectName & "]" & "\n"
        for k, v in section.properties:
            output &= k & sep & v & "\n" 
        output &= "\n"
    return output


type parserState = enum
    readSection, readKV


proc parseINI*(s: string) : INI = 
    var ini = newINI()
    var state: parserState = readSection
    let lines = s.splitLines
    
    var currentSectionName: string = ""
    var currentSection = newSection()
    
    for line in lines:
        if line.strip() == "" or line.startsWith(";") or line.startsWith("#"):
            continue
        if line.startsWith("[") and line.endsWith("]"):
            state = readSection

        if state == readSection:
            currentSectionName = line[1..<line.len-1]
            ini.setSection(currentSectionName, currentSection)
            state = readKV

        if state == readKV:
            let parts = line.split({'='})
            if len(parts) == 2:
                let key = parts[0].strip()
                let val = parts[1].strip()
                ini.setProperty(currentSectionName, key, val)
    return ini
        
            
        

        