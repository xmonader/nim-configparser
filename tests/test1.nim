import configparser

let sample1 = """

[general]
appname = configparser
version = 0.1

[author]
name = xmonader
email = notxmonader@gmail.com

"""

let sample2 = """
[general
appname = configparser
version = 1.4

"""

let sample3 = """

[general]
appname = configparser
version 1.4
"""

var d = parseIni(sample1)

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

echo d.toIniString()
let s = d.getSection("author")
echo $s

try:
  var d = parseIni(sample2)
except ValueError:
  echo "Error " & getCurrentExceptionMsg()


try:
  var d = parseIni(sample3)
except ValueError:
  echo "Error " & getCurrentExceptionMsg()