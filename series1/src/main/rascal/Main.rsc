module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import Map;

loc projectLocation1 = |cwd:///../smallsql0.21_src/smallsql0.21_src/|;
loc projectLocation2 = |cwd:///../hsqldb-2.3.1/hsqldb-2.3.1/|;
loc testProjectLocation = |cwd:///../java-test/|;

void main(int testArgument = 0) {
    //println(manYears(linesOfCode(getASTs(testProjectLocation))));
    //println(manYears(linesOfCode(getASTs(testProjectLocation))));
    //println(unitSize(getUnits(getASTs(testProjectLocation))));
    int cd1 = codeDuplication3(getASTs(projectLocation2));
    int loc1 = linesOfCode(getASTs(projectLocation2));
    // int cd2 = codeDuplication2(getASTs(projectLocation2));
    // int loc2 = linesOfCode(getASTs(projectLocation2));
    println("cd1:<cd1>, loc1:<loc1>, percentag:<(cd1*100)/loc1>");
    // println("cd2:<cd2>, loc2:<loc2>, percentage:<(cd2/loc2)*100>");
    //println(codeDuplication2(getASTs(testProjectLocation)));
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

tuple[int, list[str]] mostOccurringVariables(list[Declaration] asts){
    map[str, int] variables = ();
    visit(asts) {
        case \variable(name, _): variables[name] ? 0 += 1; 
        case \variable(name, _, _): variables[name] ? 0 += 1; 
    }

    list[tuple[str,int]] variablesList = toList(variables);

    map[int, list[str]] mostOccuringVariables = ();
    for (tuple[str, int] varCount <- variablesList) {
        int count = varCount[1];
        str varName = varCount[0];
        mostOccuringVariables[count] ? [] += [varName];
    }

    list[tuple[int, list[str]]] sortedMostOccuringVariables = [];

    sortedMostOccuringVariables = sort(toList(mostOccuringVariables), bool(tuple[int, list[str]]a, tuple[int, list[str]]b) { return a[0] > b[0];});

    return head(sortedMostOccuringVariables);
}

//for java: roughly 0.12 MY per KLOC, so 0.00012 MY per LOC
real manYears(int linesOfCode){
    return (linesOfCode * 0.00012);
}

//only look at the highest level of the asts, so you can just get the source code and filter out the emtpy lines and comments
int linesOfCode(list[Declaration] asts) {
    int totalLines = 0;
    for (Declaration decl <- asts) {
        totalLines += getLinesOfCode(decl);
    }
    return totalLines;
}

//get total lines of code of a declaration. This can be anything ranging from a class to a function
int getLinesOfCode(Declaration decl) {
    str sourceCode = readFile(decl.src);
    list[str] lines = split("\n", sourceCode);
    list[str] codeLines = [line | line <- lines, !isWhitespaceOrComment(line)];
    return size(codeLines);
}

bool isWhitespaceOrComment(str line) {
    str trimmedLine = trim(line);
    return isWhitespace(trimmedLine) || isComment(trimmedLine);
}

bool isWhitespace(str line){
    return line == "";
}

//we are aware that this is leaving out certain forms of comment, for example inline comments (person./*blabla*/name) and comments at the end o a line (person.name //blabla)
bool isComment(str line){
    return startsWith(line, "//") || startsWith(line, "/*") || startsWith(line, "*") || startsWith(line, "*/");
}

list[int] lineLength(list[Declaration] asts){
    list[int] lineLength = [];
    for(Declaration decl <- asts){
        lineLength += [getAverageLineLength(decl)];
    }
    return lineLength;
}

real getAverageLineLength(Declaration decl){
    real totalLines = 0.0;
    real totalLength = 0.0;
    str sourceCode = readFile(decl.src);
    list[str] lines = split("\n", sourceCode);
    list[str] codeLines = [line | line <- lines, !isWhitespaceOrComment(line)];
    for(str codeLine <- codeLines){
        totalLines += 1;
        totalLength += size(codeLine);
    }
    return (totalLength / totalLines);
}

list[Declaration] getUnits(list[Declaration] asts){
    list[Declaration] units = [];
    visit(asts){
        case d:\method(_, _, _, _, _): units += [d];
        //As constructors are also kind of methods, and are also smallest possible runnable pieces of code, they should also be matched
        case d:\constructor(_, _, _, _): units += [d];
    }
    return units;
}

//The size of units influences their analysability and testability and therefore of the system as a whole
list[int] unitSize(list[Declaration] units){
    list[int] unitSizes = [];
    for(Declaration unit <- units){
        unitSizes += getLinesOfCode(unit);
    }
    return unitSizes;
}

//The complexity of sourcecode units influences the system’s changeability and its testability
list[int] unitComplexity(list[Declaration] units){
    list[int] complexities = [];
    for (Declaration unit <- units){
        int result = 1;
        // Add one complexity for each predicate/statement anywhere within this unit
        // visit(units) {
        //     case \append(_, _): complexity += 1;
        //     case \assert(_): complexity += 1;
        //     case \assignment(_, _, _): complexity += 1;
        //     case \block(_): complexity += 1;
        //     case \break(): complexity += 1;
        //     case \continue(): complexity += 1;
        //     case \do(_, _): complexity += 1;
        //     case \fail(): complexity += 1;
        //     case \filter(_, _): complexity += 1;
        //     case \for(_, _, _): complexity += 1;
        //     case \if(_, _): complexity += 1;
        //     case \return(_): complexity += 1;
        //     case \switch(_, _): complexity += 1;
        //     case \try(_, _): complexity += 1;
        //     case \variable(_, _): complexity += 1;
        //     case \visit(_, _): complexity += 1;
        //     case \while(_, _): complexity += 1;
        //     case \yield(_): complexity += 1;
        //}

        visit (unit) {
            case \if(_,_) : result += 1;
            case \if(_,_,_) : result += 1;
            case \case(_) : result += 1;
            case \do(_,_) : result += 1;
            case \while(_,_) : result += 1;
            case \for(_,_,_) : result += 1;
            case \for(_,_,_,_) : result += 1;
            case \foreach(_,_,_) : result += 1;
            case \catch(_,_): result += 1;
            case \conditional(_,_,_): result += 1;
            case \infix(_,"&&",_) : result += 1;
            case \infix(_,"||",_) : result += 1;
        }
        complexities += [result];
    }
    return complexities;
}

//The degree of sourcecode duplication (also called code cloning) influences analysability and change ability

//Go through the code using blocks of length 6. If a block has been seen before, mark the lines as duplicate and move on to the next block of 6
int codeDuplication(list[Declaration] asts){
    set[str] codeOverSixLines = {};
    //remove comments
    int duplicateLines = 0;
     for(Declaration file <- asts){
        loc fileLocation = file.src;
        str code = readFile(fileLocation);
        list[str] codeLines = cleanup(code);
        int length = size(codeLines);
        int i = 0;
        while(i < (length - 5)){
            int j = length -1;
            while(j >= (i + 5)){
                str codeSubSet = getCodeSubset(i, j, codeLines);
                if(md5Hash(codeSubSet) notin codeOverSixLines){
                    codeOverSixLines += md5Hash(codeSubSet);
                }
                else{
                    //skip over the code which is now found to be duplicate, as to not count it multiple times
                    duplicateLines += j - i + 1;
                    i = j;
                    j = length - 1;
                    break;
                }
                j -= 1;
            }
            i += 1;
        }
    }
    return duplicateLines;
}

int codeDuplication2 (list[Declaration] asts){
    set[str] sixLineCodeBlocks = {};
    set[str] duplicateLines = {};
    for (Declaration file <- asts){
        loc fileLocation = file.src;
        str code = readFile(fileLocation);
        list[str] codeLines = cleanup(code);
        int length = size(codeLines);
        int i = 0;
        while( i <= (length - 6)){
            str codeSubset = getCodeSubset(i, i+6, codeLines);
            list[str] sixLinesOfCode = getCodeSubset2(i, i+6, codeLines);
            if(md5Hash(codeSubset) notin sixLineCodeBlocks){
                sixLineCodeBlocks += md5Hash(codeSubset);
            }
            else{
                int codeLine = i;
                for(str line <- sixLinesOfCode){
                    //add the line in combination with the file location and the line number
                    // so each specific line will only be added once, but other occureces (other line or file) 
                    // will be added multiple times
                    str line = line + fileLocation.uri + "<codeLine>";
                    duplicateLines += md5Hash(line + fileLocation.uri + "<codeLine>");
                    codeLine +=1;
                }
            }
            i += 1;
        }
    }
    return size(duplicateLines);
}

int codeDuplication3 (list[Declaration] asts){
    // key: unique hash for each block fo code. Value: for each occurence of the code block
    // add a list of hash for each unique line (line + src + linenr)
    map[str,list[list[str]]] codeBlocks = ();
    set[str] duplicateLines = {};
    for (Declaration file <- asts){
        loc fileLocation = file.src;
        str code = readFile(fileLocation);
        list[str] codeLines = cleanup(code);
        int length = size(codeLines);
        int i = 0;
        while( i <= (length - 6)){
            str codeSubset = getCodeSubset(i, i+6, codeLines);
            list[str] sixLinesOfCode = getCodeSubset2(i, i+6, codeLines);
            str codeBlockHash = md5Hash(codeSubset);
            list[str] hashedLines = getHashedLines(sixLinesOfCode, [i .. i + 6], fileLocation);
            if(codeBlockHash notin codeBlocks){
                codeBlocks[codeBlockHash] = [hashedLines];
            }
            else{
                codeBlocks[codeBlockHash] += [hashedLines];
            }
            i += 1;
        }
    }
    //Go over all codeblocks, and check which ones occured more then once
    //Then add all the unique lines to a set, so you only count every line once
    for(tuple[str key, list[list[str]] uniquelLines] values <- toList(codeBlocks)){
        if(size(values.uniquelLines) > 1){
            for(list[str] nestedList <- values.uniquelLines){
                duplicateLines += {line | line <- nestedList};
            }
        }
    }
    return size(duplicateLines);
}

list[str] getHashedLines(list[str] codeLines, list[int] lineNumbers, loc location){
    return [codeLines[i] + location.uri + "<lineNumbers[i]>" | int i <- [0 .. 6]];
}

list[str] cleanup (str code){
    list[str] codeLines = split("\n", code);
    list[str] cleanedUpLines = [];
    for(str line <- codeLines){
        line = trim(line);
        if(!(isWhitespaceOrComment(line))){
            line += "\n";
            cleanedUpLines += [line];
        }
    }
    return cleanedUpLines;
}

str getCodeSubset(int begin, int end, list[str] code) {
    str codeSubset = "";
    for (int i <- [begin .. end]) {
        codeSubset += code[i] + "\n";
    }
    return codeSubset;
}

list[str] getCodeSubset2(int begin, int end, list[str] code) {
    list[str] codeSubset = [];
    for (int i <- [begin .. end]) {
        codeSubset += [code[i]];
    }
    return codeSubset;
}

//funtions to find the SIG ratings based on the metrics above
