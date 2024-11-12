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

void main(int testArgument=0) {
    //println(manYears(linesOfCode(getASTs(testProjectLocation))));
    //println(manYears(linesOfCode(getASTs(testProjectLocation))));
    //println(unitSize(getUnits(getASTs(testProjectLocation))));
    println(codeDuplication(getASTs(testProjectLocation)));
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

int getLinesOfCode(Declaration decl) {
    //first, read the code from the sourceCode
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

bool isComment(str line){
    return startsWith(line, "//") || startsWith(line, "/*") || startsWith(line, "*") || startsWith(line, "*/");
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
    str codeToBeCompared = "";
    //remove comments
    int duplication = 0;
     for(Declaration file <- asts){
        println(file.src);
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
                    println(codeLines);
                    println("--------");
                    println(codeSubSet);
                    duplication +=1;
                    println("old i: <i>");
                    i = j;                    
                    println("new i: <i>");
                    println("old j: <j>");
                    j = length - 1;
                    
                    println("j: <j>");
                    break;
                }
                j -= 1;
            }
            i += 1;
        }
        println("file cleared");
    }
    return duplication;
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

//funtions to find the SIG ratings based on the metrics above
