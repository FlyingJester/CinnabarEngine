#!/usr/bin/python
# Generates thin Mercury bindings based on JSON specifications

import json
import sys

def usage():
	print ("USAGE: mgenbind.py INPUT.json")

if len(sys.argv) < 2:
	usage()
	quit()

if ("--help" in sys.argv) or ("-h" in sys.argv):
	print ("mgenbind: Generate Mercury bindings for simple C interfaces.")
	usage()
	quit()


pretty = False
if ("--pretty" in sys.argv) or ("-p" in sys.argv):
	pretty = True

input = sys.argv[1]

infile = open(input, "rb")
input_object = json.loads(infile.read())
infile.close()

# Get configuration globals
def MaybeArray(name):
	if name in input_object:
		return input_object[name]
	return []

prefixes = MaybeArray("prefixes")
suffixes = MaybeArray("suffixes")
enums = MaybeArray("enums")
preds = []

def NameMToC(name):
	if "." in name:
		return name.split(".")[-1]
	return name

# Prepares a Mercury name from a C name
def PrepareName(name):
	for prefix in prefixes:
		if name.startswith(prefix):
			name = name[len(prefix):]
	for suffix in suffixes:
		if name.endswith(suffix):
			name = name[:-len(suffix)]
	out = name[0].lower()
	i = 1
	while i < len(name):
		c = name[i]
		if c.islower():
			out += c
		elif i+1 < len(name) and name[i+1].islower():
			out += "_" + c.lower()
		else:
			out += c.lower()
		i += 1
	return out

def PredArg(arg):
	if "::" in arg:
		return {"n":arg.split("::")[0], "m":arg.split("::")[1]}
	else:
		return {"n":arg, "m":"in"}

def ParsePred(name, pred):
	args = []
	for arg in pred:
		args.append(PredArg(arg))
	ma = []
	ca = []
	for arg in args:
		# Check for an _Array type
		arname = "_Array"
		if arg["n"].startswith(arname):
			that = arg["n"][len(arname):]
			i = 0
			while that[i].isdigit():
				i += 1
			size = int(that[:i])
			type = that[i:]

			i = 0

			while i < size:
				ma.append({"n":type, "m":arg["m"]})
				i += 1

			ca.append({"n":NameMToC(type), "t":"array", "l":size, "m":arg["m"]})
		elif arg["n"][0] == '_':
			if arg["n"][1] == '_':
				val = arg["n"][2:]
				silent = True
			else:
				val = arg["n"][1:]
				silent = False
			prefix = str(PrepareName(val))
			ca.append({"n":val, "t":"hardcode", "s":silent})
		else:
			ma.append(arg)
			ca.append({"n":NameMToC(arg["n"]), "m":arg["m"]})
	return {"n":name, "ma":ma, "ca":ca}

ppreds = MaybeArray("preds")
for p in ppreds:
	preds.append(ParsePred(p, ppreds[p]))

dupreds = MaybeArray("destructive_update_preds")
for type in dupreds:
	for u in dupreds[type]:
		pred = ParsePred(u, dupreds[type][u])
		pred["ma"] += [{"n":type, "m":"di"}, {"n":type, "m":"uo"}]
		pred["ca"].append({"n":NameMToC(type), "t":"loop"})
		preds.append(pred)

if not "name" in input_object:
	name = input.split['.'][0]
else:
	name = input_object["name"]

windows_includes = MaybeArray("windows_includes")
apple_includes = MaybeArray("apple_includes")
other_includes = MaybeArray("other_includes")
includes = MaybeArray("includes")

# Create output file
outfile = open(name + ".m", "wb")

# Pretty printing wrappers.
def Pretty(str):
	if pretty:
		outfile.write(str)

def PrettyNL():
	Pretty("\n")

#Write interface
outfile.write(":- module " + name + ".\n")
outfile.write(":- interface.\n")
PrettyNL()

for m in MaybeArray("imports"):
	outfile.write(":- use_module " + m + ".\n")

for m in MaybeArray("submodules"):
	outfile.write(":- include_module " + name + "." + m + ".\n")

PrettyNL()

# Enums
for e in enums:
	outfile.write(":- type " + e + " --->")
	PrettyNL()
	i = 0
	en = enums[e]
	while i < len(en):
		Pretty("\t")
		outfile.write(PrepareName(en[i]))
		i += 1
		if i < len(en):
			outfile.write(" ; ")
			PrettyNL()
	outfile.write(".\n")
	PrettyNL()

# Predicates
for p in preds:
	outfile.write(":- pred " + PrepareName(p["n"]))
	for arg in p["ca"]:
		if "t" in arg and arg["t"] == "hardcode" and not arg["s"]:
			outfile.write("_"+PrepareName(arg["n"]))
	outfile.write("(")
	i = 0
	while i < len(p["ma"]):
		arg = p["ma"][i]
		outfile.write(arg["n"] + "::" + arg["m"])
		i+=1
		if i != len(p["ma"]):
			outfile.write(", ")
	outfile.write(") is det.\n")

# Write implementation.
PrettyNL()
outfile.write(":- implementation.\n")
PrettyNL()

#windows_includes = []
#apple_includes = []
#other_includes = []
#includes = []

def WriteIncludes(incs, pre = None):
	if len(incs) == 0:
		return
	outfile.write(':- pragma foreign_decl("C", "')
	PrettyNL()
	if pre != None:
		outfile.write(pre + '\n')
	for i in incs:
		if i[0] != '"' and i[0] != '<':
			print ("Invalid brackets on include '" + i + "'")
			quit()
		if not ((i[0] == '"' and i[-1] == '"') or (i[0] == '<' and i[-1] == '>')):
			print ("Include '" + i + "' does not have consistent brackets")
			quit()
		outfile.write('#include ' + i + '\n')
	if pre != None and "#if" in pre:
		outfile.write('#endif')
	outfile.write('").\n')
	PrettyNL()

WriteIncludes(windows_includes, "#ifdef WIN32_")
WriteIncludes(apple_includes, "#ifdef __APPLE__")
WriteIncludes(other_includes, "#if (!(defined(__APPLE__))) && (!(defined(_WIN32)))")
WriteIncludes(includes)

# Enums
for e in enums:
	outfile.write(':- pragma foreign_enum("C", ' + e + "/0, [")
	PrettyNL()
	i = 0
	en = enums[e]
        while i < len(en):
                Pretty("\t")
                outfile.write(PrepareName(en[i]) + ' - "' + en[i] + '"')
                i += 1
                if i < len(en):
                        outfile.write(",")
                        PrettyNL()
        outfile.write("]).\n")
        PrettyNL()

if len(enums) != 0:
	PrettyNL()

# Predicates
for p in preds:
	outfile.write(':- pragma foreign_proc("C", ' + PrepareName(p['n']))
	for arg in p["ca"]:
		if "t" in arg and arg["t"] == "hardcode" and not arg["s"]:
			outfile.write("_"+PrepareName(arg["n"]))
	outfile.write('(')
	i = 0
	while i < len(p["ma"]):
		arg = p["ma"][i]
		outfile.write(NameMToC(arg["n"]).upper() + str(i) + "::" + arg["m"])
		i+=1
		if i != len(p["ma"]):
			outfile.write(", ")
	outfile.write('),')
	Pretty("\n\t")
	outfile.write("[will_not_call_mercury, will_not_throw_exception,")
	Pretty("\n\t")
	outfile.write("thread_safe, promise_pure, does_not_affect_liveness],")
	Pretty('\n\t')
	outfile.write('"')
	PrettyNL()

	i = 0
	e = 0
	# Prepare any looped or array arguments.
	while e < len(p["ca"]):
		arg = p["ca"][e]
		if "t" in arg:
			if arg["t"] == "array":
				n = 0
				se = str(e)
				Pretty("\t")
				outfile.write(arg["n"] + " Array" + se + "[" + str(arg["l"]) + "];")
				PrettyNL()
				while n < arg["l"]:
					Pretty("\t")
					outfile.write("Array" + se + "[" + str(n) + "] = " + arg["n"].upper() + str(i) + ";")
					PrettyNL()
					i += 1
					n += 1
				i -= 1
				outfile.write("\n")
			if arg["t"] == "loop":
				outfile.write("\t" + arg["n"].upper() + str(i+1) + "=" + arg["n"].upper() + str(i) + ";\n")
				i += 1
			elif arg["t"] == "hardcode":
				i -= 1
		i += 1
		e += 1
	
	i = 0
	e = 0
	
	# Write the function call
	Pretty("\t")
	outfile.write(p["n"])
	outfile.write("(")
	while e < len(p["ca"]):
		arg = p["ca"][e]
		if "t" in arg:
			if arg["t"] == "array":
				if e != 0:
					outfile.write(", ")
				outfile.write("Array" + str(e))
				i += arg["l"] - 1
			if arg["t"] == "loop":
				i += 1
			elif arg["t"] == "hardcode":
				if e != 0:
					outfile.write(", ")
				outfile.write(arg["n"])
				i -= 1
		else:
			if e != 0:
				outfile.write(", ")
			if arg["n"] == "c_pointer":
				outfile.write("(const void*)C_POINTER" + str(i))
			else:
				outfile.write(arg["n"].upper() + str(i))
		e += 1
		i += 1

	outfile.write(');')
	Pretty("\n\t")
	outfile.write('").\n')
	PrettyNL()

outfile.close()
