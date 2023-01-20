# configparser
# Copyright xmonader
# pure Ini configurations parser
import tables, strutils, strformat


type Section* = ref object
    properties: Table[string, string]


proc setProperty*(this: Section, name: string, value: sink string) =
    this.properties[name] = value

proc newSection*() : Section =
    var s = Section()
    s.properties = initTable[string, string]()

    return s

proc `$`*(this: Section): string =
    return "<Section" & $this.properties & " >"

type Ini* = ref object
    sections: Table[string, Section]

proc newIni*(): Ini = 
    var ini = Ini()
    ini.sections = initTable[string, Section]()
    return ini

proc `$`*(this: Ini): string = 
    return "<Ini " & $this.sections & " >"

proc setSection*(this: Ini, name: string, section: Section) =
    this.sections[name] = section

proc getSection*(this: Ini, name: string): Section =
    return this.sections.getOrDefault(name)

proc hasSection*(this: Ini, name: string): bool =
    return this.sections.contains(name)

proc deleteSection*(this: Ini, name:string) =
    this.sections.del(name)

proc sectionsCount*(this: Ini) : int =
    return len(this.sections)

proc hasProperty*(this: Ini, sectionName: string, key: string): bool=
    return this.sections.contains(sectionName) and this.sections[sectionName].properties.contains(key)

proc setProperty*(this: Ini, sectionName: string, key: string, value: string) =
    if this.sections.contains(sectionName):
        this.sections[sectionName].setProperty(key, value)
    else:
        raise newException(ValueError, "Ini doesn't have section " & sectionName)

proc getProperty*(this: Ini, sectionName: string, key: string): string =
    if this.sections.contains(sectionName):
        return this.sections[sectionName].properties.getOrDefault(key)
    else:
        raise newException(ValueError, "Ini doesn't have section " & sectionName)


proc deleteProperty*(this: Ini, sectionName: string, key: string) =
    if this.sections.contains(sectionName) and this.sections[sectionName].properties.contains(key):
        this.sections[sectionName].properties.del(key)
    else:
        raise newException(ValueError, "Ini doesn't have section " & sectionName)

proc toIniString*(this: Ini, sep:char='='): string =
    var output = ""
    for sectName, section in this.sections:
        output &= "[" & sectName & "]" & "\n"
        for k, v in section.properties:
            output &= k & sep & v & "\n" 
        output &= "\n"
    return output


type
    ParserState = enum
        readSection, readKV


proc parseIni*(s: string): Ini = 
    var ini = newIni()
    var state: ParserState = readSection
    let lines = s.splitLines
    
    var currentSectionName: string = ""
    var currentSection: Section

    for rawLine in lines:
        let line = rawLine.strip()
        if line.strip() == "" or line.startsWith(";") or line.startsWith("#"):
            continue
        if line.startsWith("["):
            if line.endsWith("]"):
                state = readSection
            else:
                raise newException(ValueError, fmt("Excpected line {line} to start with [ and end with ]"))

        if state == readSection:
            currentSectionName = line[1..<line.len-1]
            currentSection = newSection()
            ini.setSection(currentSectionName, currentSection)
            state = readKV
            continue

        if state == readKV:
            var parts = line.split({'='}, 1)
            if len(parts) == 2:
                var
                  key = strip(move parts[0])
                  val = strip(move parts[1])
                ini.setProperty(currentSectionName, key, val)
            else:
                raise newException(ValueError, fmt("Expected line {line} to have key = value"))
    return ini
