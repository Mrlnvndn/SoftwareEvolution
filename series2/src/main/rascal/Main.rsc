module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import DateTime;
import List;
import Set;
import String;
import Map;
import Node;
import Location;
import util::Math;

//LOCATIONS
loc testProject = |cwd:///../java-test|;
loc smallProject = |cwd:///../smallsql0.21_src/smallsql0.21_src/|;
loc largeProject = |cwd:///../hsqldb-2.3.1/hsqldb-2.3.1/|;
loc outputFile = |cwd:///output.txt|;

//Parameters
int massThreshold = 20;
int ignoreSubtreeThreshold = 15;
real similarityThreshold = 0.8;

//For type II and III, key: node (subtree) hash, value: node (subtree)
map[int, set[node]] nodeHashMap = ();
//For type I, key: node (subtree) without location properties, value: node (subtree) with location properties
map[node, set[node]] nodeMap = ();
//list of node lists for each clone pair
list[set[node]] clonePairs =[];

void main() {
    println("massThreshold: <massThreshold>");
    println("ignoreSubtreeThreshold: <ignoreSubtreeThreshold>");
    println("similarityThreshold: <similarityThreshold>");
    
    // evaluateProjectCodeDuplication("java-test", testProject);

    evaluateProjectCodeDuplication("smallsql", smallProject);

    // evaluateProjectCodeDuplication("hsqldb", largeProject);
}

void evaluateProjectCodeDuplication(str projectName, loc projectLocation){
    println("start time <projectName>: <now()>");
    list[Declaration] asts  = (getASTs(projectLocation));
    int totalLoc = getTotalLinesOfCode(asts);

    list[set[node]] cloneClasses = [];
    bool showExamples = false;
    println(projectName);

    if(projectName == "testProject")
        showExamples = true;

    cloneClasses = getTypeIClones(asts);
    analyseCloneClasses(cloneClasses, totalLoc, showExamples);
    writeClones(cloneClasses,"<projectName>TypeIClones");

    cloneClasses = getTypeIIClones(asts);
    analyseCloneClasses(cloneClasses, totalLoc, showExamples);
    writeClones(cloneClasses, "<projectName>TypeIIClones");


    cloneClasses = getTypeIIIClones(asts);
    analyseCloneClasses(cloneClasses, totalLoc, showExamples);
    writeClones(cloneClasses, "<projectName>TypeIIIClones");

    println("end time <projectName>: <now()>");
}

void analyseCloneClasses(list[set[node]]  cloneClasses, int totalLoc, bool showExamples){

    //print % of duplicated lines
    //print biggest clone (in lines)
    calcDupLinePctAndLargestClone(cloneClasses, totalLoc);

    //print # of clone classes
    println("Number of clone classes: <size(cloneClasses)>");

    int totalNubmerOfClones = 0;
    for(set[node] cloneClass <- cloneClasses){
        totalNubmerOfClones += size(cloneClass);
    }
    println("number of clones: <totalNubmerOfClones>");
    
    //print biggest clone class (in members)
    findBiggestCloneClass(cloneClasses);

    //print example clones
    if(showExamples){
        printClones(cloneClasses);
   }

}

void calcDupLinePctAndLargestClone(list[set[node]] cloneClasses, int totalLoc) {
    set[str] dupLines = {};
    int largestCloneSize = -1;
    node largestClone;
    for (set[node] cloneClass <- cloneClasses) {
        for (node n <- toList(cloneClass)) {
            loc nLoc = getLoc(n);
            if ((nLoc.end.line - nLoc.begin.line) + 1 > largestCloneSize) {
                largestClone = n;
                largestCloneSize = nLoc.end.line - nLoc.begin.line;
            }
            for (int lineNr <- [nLoc.begin.line .. nLoc.end.line + 1]) {
                dupLines += {"<nLoc.uri><lineNr>"};
            }
        }
    }
    println("Duplicate line Percentage: <size(dupLines)*100 / totalLoc>");
    loc largestCloneLoc = getLoc(largestClone);
    println("Biggest clone # lines: <largestCloneLoc.end.line - largestCloneLoc.begin.line + 1>");

}

void findBiggestCloneClass(list[set[node]] cloneClasses){
    set[node] biggestCloneClass = cloneClasses[0];

    for(set[node] cloneClass <- cloneClasses){
        if(size(cloneClass) > size(biggestCloneClass)){
            biggestCloneClass = cloneClass;
        }
    }
    println("Biggest clone class: ");
    printClones([biggestCloneClass]);
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

int getTotalLinesOfCode(list[Declaration] asts){
    return sum([file.src.end.line | Declaration file <- asts]);
}

//Type I
list[set[node]] getTypeIClones(list[Declaration] asts){

    nodeMap = ();

    for(Declaration ast <- asts){
        fillNodeMap(ast);
    }

    list[set[node]] cloneClasses =  [ class |set[node] class <- range(nodeMap), size(class) > 1];

    return removeSubClones(cloneClasses);
}

void fillNodeMap(Declaration ast){
    visit(ast){
        case node n:{
            if(getMass(n) >= massThreshold){
                unsetN = unsetRec(n);
                if (unsetN in nodeMap) {
                    nodeMap[unsetN] += {n};
                } else {
                    nodeMap[unsetN] = {n};
                }
            }
        }
    }
}

list[set[node]] getTypeIIClones(list[Declaration] asts){

    nodeHashMap = ();

    for(Declaration ast <- asts){
        fillNodeHashMap(ast);
    }

    list[set[node]] cloneClasses = [ class | set[node] class <- range(nodeHashMap), size(class) > 1];

    return removeSubClones(cloneClasses);
}

list[set[node]] removeSubClones(list[set[node]] clones) {
    println("subclone removal started now: <now()>");

    // Sort clones by size in descending order to prioritize larger clones
    list[set[node]] sortedClones = sort(clones, bool(set[node] a, set[node] b) { return (size(a) > size(b)); });


    // Initialize a set to keep track of clones to remove
    set[set[node]] clonesToRemove = {};

    map[int, list[set[node]]] sizeToClones = ();

    // Precompute a map from size to clone classes for efficient lookup
    for(set[node] cloneClass <- sortedClones){
        sizeToClones[size(cloneClass)] = (size(cloneClass) in sizeToClones ? sizeToClones[size(cloneClass)] + [cloneClass] : [cloneClass]);
    }

    // Iterate over each clone class
    for (set[node] c1 <- sortedClones) {
        if (c1 in clonesToRemove) continue; // Skip if already marked for removal

        // Find potential super clone classes where size(c2) divides size(c1)
        list[int] possibleSizes = [s | int s <- domain(sizeToClones), size(c1) % s == 0];

        // Iterate over potential sizes to find super clones
        for (int s <- possibleSizes) {
            for (set[node] c2 <- sizeToClones[s]) {
                if (all(n1 <- c1, any(n2 <- c2, isSubtreeOf(n1, n2)))) {
                    clonesToRemove += {c1};
                    break; // No need to check other c2s once c1 is marked
                }
            }
            if (c1 in clonesToRemove) break; // Exit early if c1 is marked
        }
    }

    // Filter out the clones marked for removal
    list[set[node]] filteredClones = [c | set[node] c <- sortedClones, (c notin clonesToRemove)];

    println("subclone removal finished: <now()>");
    return filteredClones;
}

//check if n1 is a subtree of n2
bool isSubtreeOf(node n1, node n2){
    if(n1.src? && n2.src?){
        loc loc1 = getLoc(n1);
        loc loc2 = getLoc(n2);

        if(isStrictlyContainedIn(loc1, loc2)){
            return true;
        }
    }
    return false;
}

//Hacky way to get the .src from a node as type loc instead of value
loc getLoc(node n){
    switch(n.src){
        case loc l:
            return l;
    }
    throw "no loc found";
}

list[set[node]] getTypeIIIClones(list[Declaration] asts){
    list[set[node]] cloneClasses = [];
    map[node,set[node]] nodeSimilarityGraph = ();

    list[set[node]] binClonePairs = [];
    for(Declaration ast <- asts){
        fillNodeHashMap(ast, ignoreSmallTrees=true);
    }

    println("Number of bins: <size(nodeHashMap)>");

    //compare all nodes in the same bin with each other
    for(set[node] binSet <- range(nodeHashMap)){
        list[node] binList = toList(binSet);
        binClonePairs = [];
        for(int i <- [0 .. (size(binList) -1)]){
            node n1 = binList[i];
            for (int j <- [i+1 .. size(binList)]){
                node n2 = binList[j];
                if(similarity(n1,n2) >= similarityThreshold){
                    binClonePairs += [{n1, n2}];
                    nodeSimilarityGraph[n1] = (n1 in nodeSimilarityGraph ? nodeSimilarityGraph[n1] + {n2} : {n2});
                    nodeSimilarityGraph[n2] = (n2 in nodeSimilarityGraph ? nodeSimilarityGraph[n2] + {n1} : {n1});
                }
            }
        }
    }

    cloneClasses = findMaximalCliques(nodeSimilarityGraph);
    return removeSubClones(cloneClasses);
}

list[set[node]] bronKerboschPivot(set[node] R, set[node] P, set[node] X, map[node, set[node]] graph, list[set[node]] cliques) {
    if (size(P) == 0 && size(X) == 0) {
        cliques += R;
        return cliques;
    }
    node u = choosePivot(P, X, graph); // pivot
    for (node v <- (P - graph[u])) {
        cliques = bronKerboschPivot(R + v, P & graph[v], X & graph[v], graph, cliques);
        P -= v;
        X += v;
    }
    return cliques;
}

node choosePivot(set[node] P, set[node] X, map[node, set[node]] graph) {
    node bestNode;
    int maxNeighbors = - 1;
    for (node u <- P + X) {
        int neighborCount = size(P * graph[u]);
        if (neighborCount > maxNeighbors) {
            maxNeighbors = neighborCount;
            bestNode = u;
        }
    }
    return bestNode;
}

list[set[node]] findMaximalCliques(map[node, set[node]] graph) {
    list[set[node]] cliques = [];
    cliques = bronKerboschPivot({}, {n | n <- graph}, {}, graph, cliques);
    return cliques;
}

//Fill node hash map using a rolling hash function
int fillNodeHashMap(node tree, bool ignoreSmallTrees = false){
    int treeHash = 0;
    int treeMass = getMass(tree);
    list[node] children = getAllNodeChildren(tree);

    //for Type III
    if (ignoreSmallTrees && treeMass < ignoreSubtreeThreshold){
        return -1; // Special value to indicate this node should be ignored
    }
    //for Type II
    else if (children == []){
        return computeHash(tree, [], true);
    }
    else {
        childHashes = [fillNodeHashMap(child, ignoreSmallTrees=ignoreSmallTrees) | node child <- children];
        treeHash = computeHash(tree, childHashes, true);
    }

    //get better value for tree mass treshold
    if(treeMass >= massThreshold){
        if (treeHash in nodeHashMap) {
            nodeHashMap[treeHash] += {tree};
        } else {
            nodeHashMap[treeHash] = {tree};
        }
    }
    return treeHash;
}

list[node] getAllNodeChildren(node tree){
    list[value] valueChildren = getChildren(tree);
    list[node] nodeChildren =[];
    for(value child <- valueChildren){
        switch (child){
            case list[node] nodeList:
                nodeChildren += [loneNode | node loneNode <- nodeList];
            case node loneNode:
                nodeChildren += [loneNode];
        }
    }

    return nodeChildren;
}

//This needs to be refined
int computeHash(node currentNode, list[int] childHashes, bool useProperties){
    int base = 31;
    int prime = 1000000007;

    list[value] properties = useProperties ? getProperties(currentNode) : [];

    int treeHash = polynomialHash(getName(currentNode), properties);

    for(int childHash <- childHashes){
        if(childHash != -1){
            treeHash = (treeHash * base + childHash) % prime;
        }
    }
    return treeHash;
}

//get all non-node children
list[value] getProperties(node tree){
    list[value] properties = [];
    for(value prop <- getChildren(tree)){
        switch(prop){
            case node n:
                continue;
            case list[node] nList:
                continue;
            default:
                properties += [prop];
        }
    }
    return properties;
}

int polynomialHash(str nodeName, list[value] properties, int base = 31, int prime = 1000000007) {
    int hashValue = 0;
    for (int c <- chars(nodeName)) {
        hashValue = (hashValue * base + c) % prime;
    }
    //id nodes contain the names for variables, methods, etc. which should be ignored for type II and type III hash values.
    if(nodeName != "id"){
        for (value prop <- properties) {
            switch (prop) {
            case int i:
                hashValue = (hashValue * base + i) % prime;
            case str s:
                for (int c <- chars(s)) {
                hashValue = (hashValue * base + c) % prime;
                }
            case bool b:
                hashValue = (hashValue * base + (b ? 1 : 0)) % prime;
            default:
                // Handle other types if necessary
                continue;
            }
        }
    }

    return hashValue;
}

void writeClones(list[set[node]] cloneGroups, str fileName){
    loc fileLoc = toLocation("results/<fileName>.txt");
    writeFile(fileLoc, "");
    for(set[node] cloneGroup <- cloneGroups){
        for(node n <- cloneGroup){
            loc l = getLoc(n);
            appendToFile(fileLoc, "name: <getName(n)>, loc: <l> \n");
        }
        appendToFile(fileLoc, "------------------------- \n");
    }
}

void printClones(list[set[node]] cloneGroups){
    for(set[node] cloneGroup <- cloneGroups){
        for(node n <- cloneGroup){
            loc l = getLoc(n);
            println("name: <getName(n)>, loc: <l>");
        }
        println("-------------------------");
    }
}

bool deepEquals(node node1, node node2){

    //compare two subtrees toroughly. getName gets the type (methodCall, Class, method)
    if (getName(node1) == getName(node2)){
        list[value] properties1 = getProperties(node1);
        list[value] properties2 = getProperties(node2);

        if (size(properties1) != size(properties2)) {
            return false;
        }

        for (int i <- [0 .. size(properties1)]) {
            if (properties1[i] != properties2[i]) {
                return false;
            }
        }
    }
    if (getName(node1) != getName(node2)) {
        return false;
    }

    list[node] children1 = [ child | node child <- getChildren(node1)];
    list[node] children2 = [ child | node child <- getChildren(node2)];

    if (size(children1) != size(children2)) {
        return false;
    }

    for (int i <- [0 .. size(children1)]) {
        value child1 = children1[i];
        for (int j <- [0 .. size(children1)]){
            value child2 = children2[j];
            if(!deepEquals(child1, child2)){
                return false;
            }
        }
    }

    return true;

}


//Deprecated
set[node] collectNodes(node tree) {

    set[node] nodes = {};
    visit(unsetRec(tree)) {
        case node n:{
            nodes += n;
        }
    }
    return nodes;
}

real similarity(node n1, node n2) {
    unsetRec(n1);

    real sharedNodes = 0.0;
    real uniqueInN1 = 0.0;
    real uniqueInN2 = 0.0;

    set[node] nodesInN2 = collectNodes(n2);
    set[node] nodesInN1 = collectNodes(n1);

    for(node child1 <- nodesInN1) {
        bool found = false;
        for (node child2 <- nodesInN2) {
            list[value] child1Properties = getProperties(child1);
            list[value] child2Properties = getProperties(child2);
            if (child1Properties == child2Properties) {
                sharedNodes += 1.0;
                //remove the node, so it wont be matched multiple times
                nodesInN2 -= child2;
                found = true;
                break;
            }
        }
        if (!found) {
            uniqueInN1 += 1.0;
        }
    }

    uniqueInN2 += toReal(size(nodesInN2));
    real similarity = 2 * sharedNodes / (2 * sharedNodes + uniqueInN1 + uniqueInN2);

    return similarity;
}

//Calculate mass
int getMass(node tree){
    int numberOfNodes = 0;
    visit(unsetRec(tree)){
        case node n:
            numberOfNodes += 1;
    }
    return numberOfNodes;
}