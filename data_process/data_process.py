#!/usr/bin/env python3

import sys, os, csv, json
from operator import itemgetter

# Argument checks
if len(sys.argv) != 3:
    sys.exit(f"Usage: {sys.argv[0]} <Input CSV> <Species list JSON>")

inputFilePath = sys.argv[1]
speciesListFilePath = sys.argv[2]

if not inputFilePath.endswith(".csv"):
    sys.exit("Input file does not have CSV file extension.")
if not speciesListFilePath.endswith(".json"):
    sys.exit("Species list file does not have JSON file extension.")


# Read input

inputCsv = csv.reader(open(inputFilePath, "r"), delimiter=";")

count = 0
inputList = []
for row in inputCsv:
	if count > 0:
		inputList.append(row)
	count += 1

print(f"Read {str(count)} rows from input file.")

# Sort

# X
inputList = sorted(inputList, key=lambda x: float(x[0]), reverse=False)
# Y
inputList = sorted(inputList, key=lambda x: float(x[1]), reverse=False)
# Week
inputList = sorted(inputList, key=lambda x: int(x[3]), reverse=False)
# Year
inputList = sorted(inputList, key=lambda x: int(x[2]), reverse=False)


# Split by species

speciesListJson = json.load(open(speciesListFilePath, "r"))
print(f"Read {len(speciesListJson)} species from species list.")

speciesCount = 0
for species in speciesListJson:

	if speciesCount > 0:

		speciesId = species["species_id"]

		# Bird attributes
		speciesDict = {
			"species_id":	speciesId,
			"latin":		species["latin"],
			"english":		species["english"],
			"slices":		[]
		}

		# Slices
		count = 0
		for row in inputList:
			if row[4] == speciesId:
				slice = {
					"week":		row[2]
				}
				speciesDict["slices"].append(slice)
				count += 1

		# Output
		if count:
			filePath = f"{speciesId}.json"
			json.dump(speciesDict, open(filePath, "w"), indent = 4)
			print(f"Wrote {str(count)} rows to {filePath} ({species['english']})")

	speciesCount += 1

print(f"Done!")
