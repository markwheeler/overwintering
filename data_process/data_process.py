#!/usr/bin/env python3

import sys, os, csv
from operator import itemgetter

# Argument checks
if len(sys.argv) != 3:
    sys.exit(f"Usage: {sys.argv[0]} <Input CSV> <Species list CSV>")

inputFilePath = sys.argv[1]
speciesListFilePath = sys.argv[2]

if not inputFilePath.endswith(".csv"):
    sys.exit("Input file does not have CSV file extension.")
if not speciesListFilePath.endswith(".csv"):
    sys.exit("Species list file does not have CSV file extension.")


# Read input

inputCsv = csv.reader(open(inputFilePath, "r"), delimiter=";")

count = 0
inputList = []
for row in inputCsv:
	if count > 0:
		inputList.append(row)
	count += 1

print(f"Read {str(count)} rows.")

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

speciesListCsv = csv.reader(open(speciesListFilePath, "r"), delimiter=",")

speciesCount = 0
for species in speciesListCsv:

	if speciesCount > 0:

		speciesId = species[0]

		# Output
		outputCsv = csv.writer(open(f"{speciesId}.csv", "w"))

		# Names on first row
		outputCsv.writerow([species[2], species[1], None, None])

		count = 0
		for row in inputList:
			if row[4] == speciesId:
				outputCsv.writerow(row[:-1])
				count += 1

		if count:
			print(f"Wrote {str(count)} rows to {speciesId}.csv ({species[2]})")
		else:
			os.remove(f"{speciesId}.csv")

	speciesCount += 1

print(f"Done! Processed {speciesCount - 1} species.")
