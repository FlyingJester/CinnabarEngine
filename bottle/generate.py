#!/usr/bin/python
# Generates a bottle reader from a JSON file.

import json
import datetime
import getopt
import sys

# Language output constants
CLANG = 0
MLANG = 1
JSON  = 2

# Default
lang = CLANG

tab = "    "
nl = "\n"

TYPES = ["int", "float", "string"]

c_preamble = """
#include <stdlib.h>
#include <string.h>

static unsigned bottle_read_string_file(FILE *from, struct BottleString *to){
    const unsigned len = fgetc(from);
    to->len = len;
    to->str = (char*)malloc(len);
    {
        const unsigned nread = fread(to->str, 1, len, from);
        if(nread == len)
            return BOTTLE_OK;
        else
            return BOTTLE_FAIL;
    }
}

static unsigned bottle_read_string_mem(const void *from_v, unsigned from_len,
    const unsigned at, unsigned *const len_to, struct BottleString *to){
    
    unsigned i = at;
    const unsigned char *const from = from_v;
    
    if(from_len <= i + 1)
        return BOTTLE_FAIL;
    else{
        const unsigned len = from[i++];
        if(from_len <= i + len)
            return BOTTLE_FAIL;
        to->len = len;
        to->str = (char*)malloc(len);
        memcpy(to->str, from + i, len);
        len_to[0] = len;
    }
    
    return BOTTLE_OK;
}

static void bottle_write_string_file(FILE *to, const struct BottleString *from){
    fputc(from->len, to);
    fwrite(from->str, 1, from->len, to);
}

static void bottle_write_string_mem(void *to_v, unsigned *at,
    const struct BottleString *from){

    unsigned char *const to = to_v;
    to[*at] = from->len;
    memcpy(to + 1, from->str, from->len);
    at[0] += from->len+1;
}

"""

def capitalize(name):
    i = 1
    l = len(name)
    if l == 0:
        return ""
    
    out = name[0].upper()
    while i < l:
        if name[i] == '_':
            i += 1
            while (i < l) and (name[i] == '_'):
                i+=1
            if i < l:
                out += name[i].upper()
        else:
            out += name[i]
        i += 1
    
    return out

def calcTabs(tabs):
    tabn = ""
    i = 0
    while i < tabs:
        tabn += tab
        i += 1
    return tabn

# Base Writer
class Writer:
    def __init__(self, name):
        self.name = name
        self.enums = []
    
    def getName(self):
        return self.name
    
    def beginEnums(self):
        pass
    
    def endEnums(self):
        pass

    def beginBlocks(self):
        pass
    
    def endBlocks(self):
        pass

    def getVariable(self, variable_name, variable_body):
        output = {"name":str(variable_name), "type":"", "attr":{}}
        if type(variable_body) is str or type(variable_body) is unicode:
            output["type"] = str(variable_body)
        elif type(variable_body) is dict:
            if not "type" in variable_body:
                print variable_body
            output["type"] = variable_body["type"]
            if (output["type"] == "string") and ("len" in variable_body):
                output["attr"]["len"] = variable_body["len"]
        else:
            print type(variable_body)
        
        if not ((output["type"] in TYPES) or (output["type"] in self.enums)):
            print ("Invalid type " + output["type"])
            err = "Type must be"
            for t in TYPES:
                err += " " + t
            print (err + " or an enum")
            quit()
        return output

# JSON Writer, outputs an equivalent JSON file as its input
class JSONWriter(Writer):
    def __init__(self, name):
        Writer.__init__(self, name)
    
    def quote(self, str0, suffix = "", output = None):
        if output == None:
            output = self.output
        output.write('"' + str(str0) + '"' + suffix)
    
    def open(self, name):
        self.output = open(name + ".json", "wb")
        self.output.write('{' + nl + tab + '"name":"' + name + '",')

    def close(self):
        self.output.write('}')
        self.output.close()
    
    def beginEnums(self):
        self.output.write(nl + tab + '"enums":{' + nl)

    def endEnums(self):
        self.output.write(tab + "}," + nl)
    
    def writeEnum(self, enum_name, enumeration):
        self.enums.append(str(enum_name))
        self.output.write(tab + tab)
        if len(self.enums) != 1:
            self.output.write(',')
        self.quote(enum_name, ":[")
        if len(enumeration) > 0:
            self.output.write(nl + tab + tab + tab)
            for e in enumeration[:-1]:
                self.quote(e, ',' + nl)
                self.output.write(tab + tab + tab)
            self.quote(enumeration[-1])
            self.output.write(nl + tab + tab)
        
        self.output.write("]" + nl)
    
    def writeVariable(self, var):
        self.quote(var["name"], ':')
        if len(var["attr"]) == 0:
            self.quote(var["type"])
        else:
            self.output.write('{"type":')
            self.quote(var["type"])
            for key, val in var["attr"]:
                self.output.write(',')
                self.quote(key, ':')
                self.quote(val)
            self.output.write('}')

    def beginBlocks(self):
        self.output.write(tab + '"blocks":{' + nl)
    
    def endBlocks(self):
        self.output.write(tab + "}" + nl)
    
    def writeChildren(self, children, tabs):
        tabn = calcTabs(tabs)
        
        if not (str(children["enum"]) in self.enums):
            print ("Invalid enumeration value: " + str(children["enum"]))
            quit()
        
        self.output.write(tabn)
        self.output.write('"children":{ "enum":')
        self.quote(children["enum"], ',' + nl)
        
        l = len(children)
        i = 0
        
        for key in children:
            i += 1
            if key == "enum":
                continue
            self.writeBlock(str(key), children[key], tabs + 1)
            if i != l:
                self.output.write(',')
            self.output.write(nl)
        self.output.write(tabn + "}")
    
    def writeBlock(self, block_name, block, tabs=2):
        tabn = calcTabs(tabs)
        
        self.output.write(tabn)
        self.quote(block_name, ':{' + nl)
        l = len(block)
        i = 0
        for key in block:
            i += 1
            if key == "children":
                self.writeChildren(block["children"], tabs + 1)

            else:
                var = getVariable(key, block[key])
                self.output.write(tabn + tab)
                self.writeVariable(var)
            if i != l:
                self.output.write(',')
            self.output.write(nl)
        self.output.write(tabn + "}")

# C Writer
class CWriter(Writer):
    def __init__(self, name):
        Writer.__init__(self, name)
    
    def open(self, name):
        self.c = open(name + ".c", "wb")
        self.c.write('#include "' + name + '.h"' + nl)
        self.c.write(c_preamble)
        self.h = open(name + ".h", "wb")
                
        self.h.write("#pragma once" + nl)
        self.h.write("/* AUTOGENERATED, DO NOT EDIT" + nl)
        self.h.write(" * Created by libbottle generate.py, ")
        self.h.write(str(datetime.date.today()))
        self.h.write(nl + " */ " + nl + nl)
        inc_guard = "BOTTLE_" + name.upper() + "_HEAD"
        self.h.write("#ifndef " + inc_guard + nl)
        self.h.write("#define " + inc_guard + nl)
        self.h.write(nl + "#include <stdio.h>" + nl)
        self.h.write(nl + "#ifdef __cplusplus" + nl)
        self.h.write('extern "C" {' + nl)
        self.h.write("#endif" + nl)
        self.h.write(nl)
        self.h.write("#ifndef BOTTLE_ENUMS" + nl)
        self.h.write("#define BOTTLE_ENUMS" + nl)
        self.h.write("#define BOTTLE_OK 0" + nl)
        self.h.write("#define BOTTLE_FAIL 1" + nl)
        self.h.write(nl)
        self.h.write("struct BottleString { char *str; unsigned len; }; ")
        self.h.write(nl)
        self.h.write("#endif" + nl + nl)
    
    def close(self):
        self.h.write(nl + "#ifdef __cplusplus" + nl)
        self.h.write('}' + nl)
        self.h.write("#endif" + nl)
        self.h.write(nl + "#endif" + nl)
        
        self.c.close()
        self.h.close()
    
    def writeMemReaderChildren(self, children, tabs, parents):
        pass

    def writeFileReaderChildren(self, children, tabs, parents):
        enum_name_u = capitalize(children["enum"])
        tabn = calcTabs(tabs)
        self.c.write(tabn + "out->")
        for p in parents:
            self.c.write(p + ".")
        self.c.write(enum_name_u + " = fgetc(from); " + nl)
        self.c.write(tabn + "switch(out->")
        for p in parents:
            self.c.write(p + ".")
        self.c.write(enum_name_u + "){" + nl)
        for key in children:
            if key == "enum":
                continue
            self.c.write(tabn + "if(feof(from) != 0) return BOTTLE_FAIL;" + nl)
            self.c.write(tabn + tab + "case e" + capitalize(key) + ":" + nl)
            self.writeFileReader(key, children[key], tabs + 2, parents + [enum_name_u + "Data", key])
            self.c.write(tabn + tab + "break;" + nl)
        self.c.write(tabn + "}" + nl)

    def writeMemReader(self, block_name, block, tabs = 1, parents = []):
        cap_name = capitalize(block_name)

    def writeFileReader(self, block_name, block, tabs = 1, parents = []):
        cap_name = capitalize(block_name)
        tabn = calcTabs(tabs)
        for key in block:
            if key == "children":
                continue
            self.c.write(tabn + "if(feof(from) != 0) return BOTTLE_FAIL;" + nl)
            var = self.getVariable(key, block[key])
            if var["type"] == "string":
                self.c.write(tabn + "bottle_read_string_file(from, &(out->")
                for p in parents:
                    self.c.write(p + ".")
                self.c.write(var["name"] + "));" + nl)
            elif var["type"] in self.enums:
                self.c.write(tabn + "{ unsigned i; fread(&i, 1, 4, from);" + nl)
                self.c.write(tabn + tab + "out->")
                for p in parents:
                    self.c.write(p + ".")
                self.c.write(var["name"] + " = i; }" + nl)
            else:
                self.c.write(tabn + "fread(&(out->")
                for p in parents:
                    self.c.write(p + ".")
                self.c.write(var["name"] + "), 1, 4, from);" + nl)
        if "children" in block:
            self.c.write(tabn + "{" + nl)
            self.writeFileReaderChildren(block["children"], tabs + 1, parents)
            self.c.write(tabn + "}" + nl)

    def writeMemWriterChildren(self, children, tabs, parents):
        pass

    def writeFileWriterChildren(self, children, tabs, parents):
        enum_name_u = capitalize(children["enum"])
        tabn = calcTabs(tabs)
        self.c.write(tabn + "fputc(from->")
        for p in parents:
            self.c.write(p + ".")
        self.c.write(enum_name_u + ", to); " + nl)
        self.c.write(tabn + "switch(from->")
        for p in parents:
            self.c.write(p + ".")
        self.c.write(enum_name_u + "){" + nl)
        for key in children:
            if key == "enum":
                continue
            self.c.write(tabn + tab + "case e" + capitalize(key) + ":" + nl)
            self.writeFileWriter(key, children[key], tabs + 2, parents + [enum_name_u + "Data", key])
            self.c.write(tabn + tab + "break;" + nl)
        self.c.write(tabn + "}" + nl)

    def writeMemWriter(self, block_name, block, tabs = 1, parents = []):
        cap_name = capitalize(block_name)

    def writeFileWriter(self, block_name, block, tabs = 1, parents = []):
        cap_name = capitalize(block_name)
        tabn = calcTabs(tabs)
        for key in block:
            if key == "children":
                continue
            var = self.getVariable(key, block[key])
            if var["type"] == "string":
                self.c.write(tabn + "bottle_write_string_file(to, &(from->")
                for p in parents:
                    self.c.write(p + ".")
                self.c.write(var["name"] + "));" + nl)
            elif var["type"] in self.enums:
                self.c.write(tabn + "{ const unsigned i = from->")
                for p in parents:
                    self.c.write(p + ".")
                self.c.write(var["name"] + "; fwrite(&i, 1, 4, to); };" + nl)
            else:
                self.c.write(tabn + "fwrite(&(from->")
                for p in parents:
                    self.c.write(p + ".")
                self.c.write(var["name"] + "), 1, 4, to);" + nl)
        if "children" in block:
            self.c.write(tabn + "{" + nl)
            self.writeFileWriterChildren(block["children"], tabs + 1, parents)
            self.c.write(tabn + "}" + nl)
    
    def writeEnum(self, enum_name_l, enumeration):
        l = len(enumeration)
        enum_name = "EnumBottle" + capitalize(enum_name_l)
        self.enums.append(enum_name_l)
        if l == 0:
            self.h.write("typedef unsigned " + enum_name + ";" + nl)
        else:
            self.h.write("enum " + enum_name + "{" + nl)
            for e in enumeration:
                self.h.write(tab + "e" + capitalize(str(e)) +"," + nl)
            self.h.write(tab + "NUM_" + capitalize(enum_name_l) + nl + "};" + nl)
    
    def writeChildren(self, children, tabs):
        tabn0 = calcTabs(tabs - 1)
        tabn = tabn0 + tab
        enum_name_u = capitalize(children["enum"])
        enum_name = "EnumBottle" + enum_name_u
        self.h.write(tabn0 + "enum " + enum_name + " " + enum_name_u + ";" + nl)
        self.h.write(tabn0 + "union{" + nl)

        for key in children:
            if key == "enum":
                continue
            child = children[key]
            if len(child) == 0:
                self.h.write(tabn + "/* No members for " + key + "*/" + nl)
            else:
                self.h.write(tabn + "struct {" + nl)
                self.writeBlock(key, child, tabs + 1, False)
                self.h.write(tabn + "} " + key + ";" + nl)
            
        
        self.h.write(tabn0 + "}" + enum_name_u + "Data;" + nl)

    def writeBlock(self, block_name, block, tabs=1, write_struct = True):
        tabn0 = calcTabs(tabs - 1)
        tabn = tabn0 + tab
        cap_name = capitalize(block_name)
        if write_struct:
            mem_reader = "unsigned Bottle_Load" + cap_name + "Mem(struct Bottle" + cap_name + " *out, const void *mem, unsigned len)"
            file_reader = "unsigned Bottle_Load" + cap_name + "File(struct Bottle" + cap_name + " *out, FILE *from)"
            
            mem_writer = "void *Bottle_Write" + cap_name + "Mem(const struct Bottle" + cap_name + "* from, unsigned *size_out)"
            file_writer = "void Bottle_Write" + cap_name + "File(const struct Bottle" + cap_name + "* from, FILE *to)"
            
            self.h.write(tabn0)
            self.h.write("struct Bottle" + cap_name + ";" + nl)
            self.h.write(nl)
            self.h.write(mem_reader + ";" + nl)
            self.h.write(file_reader + ";" + nl)
            self.h.write(mem_writer + ";" + nl)
            self.h.write(file_writer + ";" + nl)

            self.c.write(mem_writer  +"{" + nl)
            self.writeMemWriter(block_name, block)
            self.c.write("}" + nl)

            self.c.write(file_writer  +"{" + nl)
            self.writeFileWriter(block_name, block)
            self.c.write("}" + nl)

            self.c.write(mem_reader  +"{" + nl)
            self.writeMemReader(block_name, block)
            self.c.write("}" + nl)

            self.c.write(file_reader  +"{" + nl)
            self.writeFileReader(block_name, block)
            self.c.write("}" + nl)

            self.h.write("struct Bottle" + cap_name + " { " + nl)

        for key in block:
            if key == "children":
                continue
            var = self.getVariable(key, block[key])
            self.h.write(tabn)
            if var["type"] == "string":
                self.h.write("struct BottleString ")
            elif var["type"] in self.enums:
                self.h.write("enum EnumBottle" + capitalize(var["type"]) + ' ')
            else:
                self.h.write(var["type"] + ' ')
            self.h.write(var["name"] + ";" + nl)
        
        if "children" in block:
            self.writeChildren(block["children"], tabs+1)
        if write_struct:
            self.h.write(calcTabs(tabs - 1) + "};" + nl)

# Mercury Writer
class MWriter(Writer):

    def __init__(self, name):
        Writer.__init__(self, name)
    
    def open(self, name):
        self.src_name = name
        self.file = open(self.src_name + ".m", "wb")
        self.int = ""
        self.imp = ""

    def close(self):
        out = self.file
        out.write(":- module " + self.src_name + "." + nl)
        out.write("% AUTOGENERATED, DO NOT EDIT" + nl)
        out.write("% Created by libbottle generate.py, ")
        out.write(str(datetime.date.today()))
        out.write(nl)
        out.write(":- interface." + nl)
        out.write(self.int)
        out.write(nl)
        out.write(":- implementation." + nl)
        out.write(self.imp)
        out.write(nl)

        self.int = ""
        self.imp = ""
    
    def writeEnum(self, enum_name, enumeration):
        self.enums.append(enum_name)
        self.int += ":- type " + enum_name + " ---> "
        l = len(enumeration)
        if l == 0:
            self.int += enum_name + "_unit." + nl
        elif l == 1:
            self.int += enumeration[0] + "." + nl
        else:
            self.int += nl
            for e in enumeration[:-1]:
                self.int += tab + e + " ;" + nl
            self.int += tab + enumeration[-1] + "." + nl
        

def help():
    if len(sys.argv) == 0:
        name = "generate.py"
    else:
        name = sys.argv[0]
    print ("USAGE: " + name + " [OPTIONS] INPUT")
    print ("OPTIONS:")
    print ("    --help, -h")
    print ("        Displays this help message and exits")
    print ("    --lang LANG, -lLANG")
    print ("        Sets the output language. Choices are c, m[ercury], or j[son]")
    print ("    --nl {DOS|UNIX}, -n{d|u}")
    print ("        Sets line endings to dos or unix. Default is unix.")
    print ("    --tabs N, -t[n]")
    print ("        Use N spaces for tabs, or if zero (or just -t) use tab characters")

def iop(i, p):
    return (i == "-" + p[0]) or (i == "--" + p) or (i == p[0]) or (i == p)

if len(sys.argv) < 2:
    help()
    quit()
else:
    opts, args = getopt.getopt(sys.argv[1:], 'ht:l:n:', ["lang=", "nl=", "tabs=", "help"])
    for opt, x in opts:
        if iop(opt, "help"):
            help()
            quit()
    
    if len(args) == 0:
        print ("No input files specified")
    
    for opt, val in opts:
        l = val.lower()
        if iop(opt, "lang"):
            if iop(l, "c++") or l == "c":
                lang = CLANG
            elif iop(l, "mercury"):
                lang = MLANG
            elif iop(l, "json"):
                lang = JSON
            else:
                print ("Invalid language: " + l)
                quit()
        if iop(opt, "nl"):
            if iop(l, "dos") or iop(l, "windows") or iop(l, "msdos") or l == "ms-dos":
                nl = "\r\n"
            elif iop(l, "unix") or iop(l, "linux") or l == "n":
                nl = "\n"
            else:
                print ("Invalid line ending: " + l)
                quit()
        if iop(opt, "tabs"):
            if val == "":
                tab = "\n"
            else:
                try:
                    n = int(val)
                    if n == 0:
                        tab = "\n"
                    else:
                        tab = ""
                        i = 0
                        while i < n:
                            tab += ""
                except:
                    print ("Invalid tabs: " + val)
                    quit()

    if len(args) == 0:
        quit()

    # Do actual parsing
    for input in args:
        infile = open(input, "rb")
        input_object = json.loads(infile.read())
        if not ("name" in input_object):
            print ("Input has no name property")
            quit()
        else:
            name = input_object["name"]
        if lang == CLANG:
            writer = CWriter(name)
        elif lang == MLANG:
            writer = MWriter(name)
        elif lang == JSON:
            writer = JSONWriter(name)
        else:
            print ("INTERNAL ERROR: Invalid language " + str(lang))
            quit()
        
        writer.open(str(name))
        
        # Write all enums
        if "enums" in input_object:
            enums = input_object["enums"]
            writer.beginEnums()
            for e in enums:
                writer.writeEnum(e, enums[str(e)])
            writer.endEnums()
        
        # Write blocks
        if "blocks" in input_object:
            writer.beginBlocks()
            blocks = input_object["blocks"]
            for b in blocks:
                writer.writeBlock(b, blocks[str(b)])
            writer.endBlocks()
        
        writer.close()
        
