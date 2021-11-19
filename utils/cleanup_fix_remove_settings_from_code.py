#!/usr/bin/python

import os
import json
import sys

numfiles = 0
numFixableFiles = 0
numFixedFiles = 0
dryRun = "--dry-run" in sys.argv

attribs = set([])

def findJsonStart(data):

    index = data.rfind("\n\n{\n")
    if(index < 0):
        return -1

    index += 2
    test = data[index:]
    print(test)
    jsondata = json.loads(test)
    if "outputSelection" not in jsondata.keys():
        return -1
    attribs.update(jsondata.keys())
    return index


def getFiles(base):
    # traverse root directory, and list directories as dirs and files as files
    for root, dirs, files in os.walk(base):
        for f in files:
            yield os.path.join(root, f)


for path in getFiles(sys.argv[1]):
    if not path.endswith(".sol"): #ignore non-sol files
        continue
    numfiles +=1
    with open(path, 'r+') as f:
        data = f.read()
        lenBefore = data.count("\n")
        if "outputSelection" in data: # safetycheck 1
            print(path)
            numFixableFiles +=1
            if data.endswith("}"): # safetycheck 2

                newEnd = findJsonStart(data) # safetycheck 3 (is json)
                if newEnd < 0:
                    print("NOT JSON")
                    continue

                if lenBefore - data[:newEnd].count("\n") > 150: # safetycheck 4 (does not truncate too much)
                    print("ERROR: truncates too much: %s (%d)"%(path,lenBefore - data[:newEnd].count("\n") ))
                    continue

                numFixedFiles +=1
                if dryRun:
                    continue
                f.seek(0)
                f.write(data[:newEnd]) #truncate
                f.truncate()


print(numfiles)
print(numFixableFiles)
print(numFixedFiles)
print(attribs)

