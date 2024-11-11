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

int main(int testArgument=0) {
    println(findNullReturned(getASTs(projectLocation1)));
    println(findNullReturned(getASTs(projectLocation2)));
    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

int getNumberOfInterfaces(list[Declaration] asts){
    int interfaces = 0;
    visit(asts){
        case \interface(_, _, _, _): interfaces += 1;
    }
    return interfaces;
}

int getNumberOfForLoops(list[Declaration] asts){
 // TODO: Create this function
    int forLoops = 0;
    visit(asts) {
        case \for(_, _, _, _): forLoops += 1;
    }
    return forLoops;
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

tuple[int, list[str]] mostOccurringNumbers(list[Declaration] asts){
    map[str, int] numbers = ();
    visit(asts) {
        case \number(numberValue): numbers[numberValue] ? 0 += 1; 
    }

    list[tuple[str,int]] numbersList = toList(numbers);

    map[int, list[str]] mostOccuringNumbers = ();
    for (tuple[str, int] varCount <- numbersList) {
        int count = varCount[1];
        str varName = varCount[0];
        mostOccuringNumbers[count] ? [] += [varName];
    }

    list[tuple[int, list[str]]] sortedMostOccuringNumbers = [];

    sortedMostOccuringNumbers = sort(toList(mostOccuringNumbers), bool(tuple[int, list[str]]a, tuple[int, list[str]]b) { return a[0] > b[0];});

    return head(sortedMostOccuringNumbers);
}

list[loc] findNullReturned(list[Declaration] asts){
    list[loc] nullLocations = [];
    
    visit(asts){
        case n:\return(\null()): nullLocations += [n.src];
    }
    return nullLocations;
}

test bool numberOfInterfaces() {
 return getNumberOfInterfaces(getASTs(projectLocation1)) == 1;
}