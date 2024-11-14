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
    // int cd1 = codeDuplication(getASTs(projectLocation2), 6);
    //println(lineLength(getASTs(projectLocation2)));
    // int cd2 = codeDuplication2(getASTs(projectLocation2));
    // int loc2 = linesOfCode(getASTs(projectLocation2));
    // println("cd1:<cd1>, loc1:<loc1>, percentag:<(cd1*100)/loc1>");
    // println("cd2:<cd2>, loc2:<loc2>, percentage:<(cd2/loc2)*100>");
    //println(codeDuplication2(getASTs(testProjectLocation)));

    // println(volumeRating(manYears(linesOfCode(getASTs(testProjectLocation)))));
    // println(volumeRating(manYears(linesOfCode(getASTs(projectLocation1)))));
    // println(volumeRating(manYears(linesOfCode(getASTs(projectLocation2)))));

    // println(complexityRating(unitComplexity(getUnits(getASTs(testProjectLocation)))));
    // println(complexityRating(unitComplexity(getUnits(getASTs(projectLocation1)))));
    // println(complexityRating(unitComplexity(getUnits(getASTs(projectLocation2)))));

    println(duplicationRank(codeDuplication(getASTs(testProjectLocation),6), linesOfCode(getASTs(testProjectLocation))));
    println(duplicationRank(codeDuplication(getASTs(projectLocation1),6), linesOfCode(getASTs(projectLocation1))));
    println(duplicationRank(codeDuplication(getASTs(projectLocation2),6), linesOfCode(getASTs(projectLocation2))));
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

//VOLUME:

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

// COMPLEXITY PER UNIT:

//The size of units influences their analysability and testability and therefore of the system as a whole
list[int] unitSize(list[Declaration] units){
    list[int] unitSizes = [];
    for(Declaration unit <- units){
        unitSizes += getLinesOfCode(unit);
    }
    return unitSizes;
}

//The complexity of sourcecode units influences the system’s changeability and its testability
list[tuple[int, int]] unitComplexity(list[Declaration] units){
    list[tuple[int, int]] complexities = [];
    for (Declaration unit <- units){
        int result = 1;
        // Add one complexity for each decision point anywhere within this unit
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
        complexities += [<getLinesOfCode(unit), result>];
    }
    return complexities;
}

// CODE DUPLICATION:

//Go through the code using blocks of length x. If a block has been seen before, mark the lines as duplicate and move on to the next block of 6
int codeDuplication (list[Declaration] asts, int codeBlockSize){
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
        while( i <= (length - codeBlockSize)){
            str codeBlock = getCodeBlockAsString(i, i+ codeBlockSize, codeLines);
            list[str] codeBlockList = getCodeBlockAsList(i, i+codeBlockSize, codeLines);
            str codeBlockHash = md5Hash(codeBlock);
            list[str] hashedLines = getHashedLines(codeBlockList, [i .. i + codeBlockSize], fileLocation);
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
    return [md5Hash(codeLines[i] + location.uri + "<lineNumbers[i]>") | int i <- [0 .. size(codeLines)]];
}

list[str] cleanup (str code){
    list[str] codeLines = split("\n", code);
    list[str] cleanedUpLines = [];
    for(str line <- codeLines){
        line = trim(line);
        cleanedUpLines += [line + "\n" | line <- codeLines, !isWhitespaceOrComment(line)];
    }
    return cleanedUpLines;
}

str getCodeBlockAsString(int begin, int end, list[str] code) {
    str codeSubset = "";
    for (int i <- [begin .. end]) {
        codeSubset += code[i] + "\n";
    }
    return codeSubset;
}

list[str] getCodeBlockAsList(int begin, int end, list[str] code) {
    list[str] codeSubset = [];
    for (int i <- [begin .. end]) {
        codeSubset += [code[i]];
    }
    return codeSubset;
}

// UNIT SIZE:

//get total lines of code of a declaration. This can be anything ranging from a class to a function
int getLinesOfCode(Declaration decl) {
    str sourceCode = readFile(decl.src);
    list[str] lines = split("\n", sourceCode);
    list[str] codeLines = [line | line <- lines, !isWhitespaceOrComment(line)];
    return size(codeLines);
}

list[real] lineLength(list[Declaration] asts){
    list[real] lineLength = [];
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

// HELPER FUNCTIONS:

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


//funtions to find the SIG ratings based on the metrics above
str volumeRating (real manYears){
    if (manYears <= 8){
        return "++";
    }
    if (manYears > 8 && manYears <= 30){
        return "+";
    }
    if (manYears > 30 && manYears <= 80){
        return "+";
    }
    if (manYears > 80 && manYears <= 160){
        return "+";
    }
    else {
        return "--";
    }
}

str complexityRating(list[tuple[int linesOfCode, int complexity]] ccs){
    real veryHigh = 0.0;
    real high = 0.0;
    real moderate = 0.0;
    real low = 0.0;
    
    for(tuple[int linesOfCode, int complexity]cc <- ccs){
        if (cc.complexity <=10){
            low += cc.linesOfCode;
        }
        if (cc.complexity > 10 && cc.complexity <= 20){
            moderate += cc.linesOfCode;
        }
        if (cc.complexity > 20 && cc.complexity <= 50){
            high += cc.linesOfCode;
        }
        if (cc.complexity > 50 ){
            veryHigh += cc.linesOfCode;
        }
    }

    real total = low + moderate + high + veryHigh;
    real veryHighPerc = veryHigh/total * 100;
    real highPerc = high/total * 100;
    real moderatePerc = moderate/total * 100;
    real lowPerc = low/total * 100;
    println("veryHighPerc: <veryHighPerc>, highPerc: <highPerc>, moderatePerc: <moderatePerc>, lowPerc: <lowPerc>, totalPerc: <lowPerc+moderatePerc+highPerc+veryHighPerc>");
    if(veryHighPerc < 1 && highPerc < 1 && moderatePerc <= 25){
        return "++";
    }
    if(veryHighPerc < 1 && highPerc <= 5 && moderatePerc <= 30){
        return "+";
    }
    if(veryHighPerc < 1 && highPerc <= 10 && moderatePerc <= 40){
        return "o";
    }
    if(veryHighPerc <= 5 && highPerc <= 15 && moderatePerc <= 50){
        return "-";
    }
    else{
        return "--";
    }
}

str duplicationRating(int duplication, int linesOfCode){
    int duplicationPerc = duplication * 100 / linesOfCode;
    if(duplicationPerc <= 3)    {
        return "++";
    }
    if(duplicationPerc <= 5){
        return "+";
    }
    if(duplicationPerc <= 10){
        return "o";
    }
    if(duplicationPerc <= 20 ){
        return "-";
    }
    else{
        return "--";
    }
}
