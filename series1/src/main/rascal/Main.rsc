module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import Map;

loc smallProjectLocation = |cwd:///../smallsql0.21_src/smallsql0.21_src/|;
loc largeProjectLocation = |cwd:///../hsqldb-2.3.1/hsqldb-2.3.1/|;
loc testProjectLocation = |cwd:///../java-test/|;

int codeBlockSize = 6;

void main(int testArgument = 0) {
    analyzeProject("Test Project", testProjectLocation);
    analyzeProject("Small Project", smallProjectLocation);
    analyzeProject("Large Project", largeProjectLocation);
}

void analyzeProject(str projectName, loc projectLocation) {
    list[Declaration] asts = getASTs(projectLocation);
    list[Declaration] units = getUnits(asts);

    // volume
    int totalLOC = totalLinesOfCode(asts);
    real my = manYears(totalLOC);

    // unit size
    list[int] unitSizesList = unitSizes(units);
    real averageLineLength = averageLineLength(asts);

    // complexity
    list[tuple[int, int]] unitComplexityList = unitComplexity(units);
    // code duplication
    int codeDupl = codeDuplication(asts, codeBlockSize);

    // risk profiles
    map[str, real] unitSizeRiskProfile = unitSizeRiskProfile(unitSizesList);
    map[str, real] complexityRiskProfile = complexityRiskProfile(unitComplexityList);

    // SIG scores
    str volumeRating = volumeRating(my);
    str unitSizeRating = riskProfileToRating(unitSizeRiskProfile);
    str complexityRating = riskProfileToRating(complexityRiskProfile);
    str duplicationRating = duplicationRating(codeDupl, totalLOC);

    // maintainability scores
    str analysabilityRating = sigRatingAverage([volumeRating,duplicationRating, unitSizeRating]);
    str changeabilityRating = sigRatingAverage([complexityRating, duplicationRating]);
    str testabilityRating = sigRatingAverage([complexityRating,unitSizeRating]);
    str overalMaintainabilityRating = sigRatingAverage([analysabilityRating, changeabilityRating, testabilityRating]);

    println("<projectName> Metric Values:");
    println("Man Years: <my>");
    println("Unit sizes: <unitSizesList>");
    println("Average Line Length: <averageLineLength>");
    println("Unit Complexities: <unitComplexityList>");
    println("Dupliate lines: <codeDupl>");
    println();

    println("<projectName> Risk Profiles (\<LOC,Category\>)");
    println("Unit Size Risk Profile: <unitSizeRiskProfile>");
    println("Complexity Risk Profile: <complexityRiskProfile>");
    println();

    println("<projectName> SIG Scores:");
    println("Volume Rating: <volumeRating>");
    println("Unit Size Rating: <unitSizeRating>");
    println("Complexity Rating: <complexityRating>");
    println("Duplication Rating: <duplicationRating>");
    println();

    println("<projectName> Maintainability Scores:");
    println("Analysability Rating: <analysabilityRating>");
    println("Changeability Rating: <changeabilityRating>");
    println("Testability Rating: <testabilityRating>");
    println("Overall Maintainability Rating: <overalMaintainabilityRating>");
    println("--------------------------------------------");
    println();
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
int totalLinesOfCode(list[Declaration] asts) {
    int totalLines = 0;
    for (Declaration decl <- asts) {
        totalLines += getLinesOfCode(decl);
    }
    return totalLines;
}

// COMPLEXITY PER UNIT:

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

//The size of units influences their analysability and testability and therefore of the system as a whole
list[int] unitSizes(list[Declaration] units){
    list[int] unitSizes = [];
    for(Declaration unit <- units){
        unitSizes += getLinesOfCode(unit);
    }
    return unitSizes;
}

//get total lines of code of a declaration. This can be anything ranging from a class to a function
int getLinesOfCode(Declaration decl) {
    str sourceCode = readFile(decl.src);
    list[str] lines = split("\n", sourceCode);
    list[str] codeLines = [line | line <- lines, !isWhitespaceOrComment(line)];
    return size(codeLines);
}

real averageLineLength(list[Declaration] units) {
    real totalLines = 0.0;
    real totalLength = 0.0;
    for (Declaration unit <- units) {
        real unitLines = 0.0;
        real unitLength = 0.0;
        str sourceCode = readFile(unit.src);
        list[str] lines = split("\n", sourceCode);
        list[str] codeLines = [line | line <- lines, !isWhitespaceOrComment(line)];
        for (str codeLine <- codeLines) {
            unitLines += 1;
            unitLength += size(codeLine);
        }
        totalLines += unitLines;
        totalLength += unitLength;
    }
    return totalLength / totalLines;
}

real getAverageLineLength(Declaration unit){
    real totalLines = 0.0;
    real totalLength = 0.0;
    str sourceCode = readFile(unit.src);
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

//we are aware that this is leaving out certain forms of comment, for example inline comments (person./*blabla*/name) 
//and comments at the end of a line (person.name //blabla)
bool isComment(str line){
    return startsWith(line, "//") || startsWith(line, "/*") || startsWith(line, "*") || startsWith(line, "*/");
}

//funtions to find the SIG ratings based on the metrics above
map[str, real] complexityRiskProfile(list[tuple[int linesOfCode, int complexity]] ccs) {
    map[str, real] locPerCategory = ("low": 0.0, "moderate": 0.0, "high": 0.0, "veryHigh": 0.0);

    for (tuple[int linesOfCode, int complexity] cc <- ccs) {
        if (cc.complexity <= 10) {
            locPerCategory["low"] += cc.linesOfCode;
        } else if (cc.complexity <= 20) {
            locPerCategory["moderate"] += cc.linesOfCode;
        } else if (cc.complexity <= 50) {
            locPerCategory["high"] += cc.linesOfCode;
        } else {
            locPerCategory["veryHigh"] += cc.linesOfCode;
        }
    }

    return locPerCategory;
}

map[str, real] unitSizeRiskProfile(list[int] linesOfCodePerUnit){
    map[str, real] locPerCategory = ("low": 0.0, "moderate": 0.0, "high": 0.0, "veryHigh": 0.0);
    
    for(int linesOfCode <- linesOfCodePerUnit){
        if(linesOfCode <= 15){
             locPerCategory["low"] += linesOfCode;
        }
        else if(linesOfCode <= 30){
             locPerCategory["moderate"] += linesOfCode;
        }
        else if(linesOfCode <= 60){
             locPerCategory["high"] += linesOfCode;
        }
        else{
             locPerCategory["veryHigh"] += linesOfCode;
        }
    }

    return locPerCategory;
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

str volumeRating (real manYears){
    if (manYears <= 8){
        return "++";
    }
    if (manYears > 8 && manYears <= 30){
        return "+";
    }
    if (manYears > 30 && manYears <= 80){
        return "o";
    }
    if (manYears > 80 && manYears <= 160){
        return "+";
    }
    else {
        return "--";
    }
}

str riskProfileToRating(map[str, real] locPerCategory) {
    real total = locPerCategory["low"] + locPerCategory["moderate"] + locPerCategory["high"] + locPerCategory["veryHigh"];
    real veryHighPerc = locPerCategory["veryHigh"] / total * 100;
    real highPerc = locPerCategory["high"] / total * 100;
    real moderatePerc = locPerCategory["moderate"] / total * 100;
    real lowPerc = locPerCategory["low"] / total * 100;

    if (veryHighPerc < 1 && highPerc < 1 && moderatePerc <= 25) {
        return "++";
    } else if (veryHighPerc < 1 && highPerc <= 5 && moderatePerc <= 30) {
        return "+";
    } else if (veryHighPerc < 1 && highPerc <= 10 && moderatePerc <= 40) {
        return "o";
    } else if (veryHighPerc <= 5 && highPerc <= 15 && moderatePerc <= 50) {
        return "-";
    } else {
        return "--";
    }
}

str sigRatingAverage(list[str] scores){
    real totalScore = 0.0;
    for(str score <- scores){
        if(score == "++"){
            totalScore += 2;
        }if(score == "+"){
            totalScore += 1;
        }if(score == "-"){
            totalScore -= 1;
        }if(score == "--"){
            totalScore -= 2;
        }
    }

    real averageScore = totalScore / size(scores);

    if (averageScore >= 1.5) {
        return "++";
    } else if (averageScore >= 0.5) {
        return "+";
    } else if (averageScore >= -0.5) {
        return "o";
    } else if (averageScore >= -1.5) {
        return "-";
    } else {
        return "--";
    }
}