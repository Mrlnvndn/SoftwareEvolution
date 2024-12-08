module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import Map;
import Node;
import Location;
import util::Math;

loc testProject = |cwd:///../java-test|;
loc smallProject = |cwd:///../smallsql0.21_src/smallsql0.21_src/|;
loc largeProject = |cwd:///../hsqldb-2.3.1/hsqldb-2.3.1/|;

loc outputFile = |cwd:///output.txt|;
int massTreshold = 15;
int numBuckets = 0;

//key:bucket hash, value: node (subtree)
map[int, list[node]] buckets = ();
//For type II, key: subtree hash, value: node (subtree)
map[int, list[node]] nodeHashMap = ();
//For type I, key: subtree hash, value: node (subtree)
map[node, list[node]] nodeMap = ();
//list of node lists for each clone class
list[list[node]] cloneClasses = [];
//list of node lists for each clone pair
list[list[node]] clonePairs =[];


int main(int testArgument=0) {
    list[Declaration] asts  = (getASTs(testProject));

    getTypeIClones(asts);
    printCloneClasses();
    getTypeIIClones(asts);
    printCloneClasses();
    getTypeIIIClones(asts);
    printClonePairs();
    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

//Type I
void getTypeIClones(list[Declaration] asts){
    for(Declaration ast <- asts){
        fillNodeMap(ast);
    }

    cloneClasses =  [ class |list[node] class <- range(nodeMap), size(class) > 1];
    removeSubClones();
    println(size(cloneClasses));
}

void fillNodeMap(Declaration ast){
    visit(ast){
        case node n:{
            if(getMass(n) >= massTreshold){
                unsetN = unsetRec(n);
                if (unsetN in nodeMap) {
                    nodeMap[unsetN] += [n];
                } else {
                    nodeMap[unsetN] = [n];
                }
            }
        }
    }
}

void getTypeIIClones(list[Declaration] asts){
    //fill nodeHashMap
    for(Declaration ast <- asts){
        fillNodeHashMap(ast);
    }

    cloneClasses = [ class | list[node] class <- range(nodeHashMap), size(class) > 1];
    removeSubClones();
    println(size(cloneClasses));
}

void removeSubClones(){
    list[list[node]] duplicateSubClasses = [];
    int classSize = size(cloneClasses);
    for(int i <- [0 .. classSize]){
        list[node] c1 = cloneClasses[i];
        for(int j <- [0 .. classSize]){
            //dont compare the same class to eachother
            if(i != j){
                list[node] c2 = cloneClasses[j];
                //Check that for every node in c1, there is at least one node in c2 of which it is a subtree
                bool isSubNode = true;
                for (node n1 <- c1) {
                    bool found = false;
                    for (node n2 <- c2) {
                        //check if n1 is a subtree of n2
                        if (isSubtreeOf(n1, n2)) {
                            found = true;
                            break;
                        }
                    }
                    //if one node in c1 is not a subtree of any node in c2, mark it as not a subClass
                    if (!found) {
                        isSubNode = false;
                        break;
                    }
                }
                // if one node is not a subtree isSubtree is false and 
                if (isSubNode) {
                    duplicateSubClasses += [c1];
                }
            }
        }
    }
    for (list[node] duplicateSubClass <- duplicateSubClasses) {
        cloneClasses = [class | class <- cloneClasses, class != duplicateSubClass];
    }
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

loc getLoc(node n){
    switch(n.src){
        case loc l:
            return l;
    }
    throw "no loc found";
}

void getTypeIIIClones(list[Declaration] asts){

    for(Declaration ast <- asts){
        fillBins(ast);
    }
    
    //compare all nodes in the same bin with each other
    for(list[node] bin <- range(buckets)){
        for(int i <- [0 .. (size(bin) -1)]){
            node n1 = bin[i];
            for (int j <- [i+1 .. size(bin)]){
                node n2 = bin[j];
                if(similarity(n1,n2) > 0.9){
                    clonePairs += [n1, n2];
                }
            }
        }
    }
    println(size(clonePairs));
}

bool areSubTreesEqual(node node1, node node2){
    return (unset(node1) == unset(node2));
}

list[list[value]] detectCodeClones(list[Declaration] asts){
    
    for(Declaration ast <- asts){
        fillNodeHashMap(ast); 
    }

    println("size: <size(nodeHashMap)>");

    list[list[value]] duplication = [ [ duplicate.src | duplicate <- duplicates] | list[node] duplicates <- toList(range(nodeHashMap)), size(duplicates) > 1];

    println("size: <size(duplication)>");

     return duplication;
}

//Fill node hash map using a rolling hash function
int fillNodeHashMap(node tree){
    int treeHash = 0;

    list[node] children = getAllNodeChildren(tree);

    if (children == []){
        treeHash = computeHash(tree, [], true);
    }
    else {
        childHashes = [fillNodeHashMap(child) | node child <- children];
        treeHash = computeHash(tree, childHashes, true);
    }

    //get better value for tree mass treshold
    if(getMass(tree) >= massTreshold){
        if (treeHash in nodeHashMap) {
            nodeHashMap[treeHash] += [tree];
        } else {
            nodeHashMap[treeHash] = [tree];
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

    list[value] properties = [];
    if(useProperties){
        properties = getProperties(currentNode);
    }

    int treeHash = polynomialHash(getName(currentNode), properties);

    for(int childHash <- childHashes){
        treeHash = (treeHash * base + childHash) % prime;
    }
    return treeHash;
}

list[value] getProperties(node tree){
    list[value] properties = [];
    for(value prop <- getChildren(tree)){
        switch(prop){
            case node n:
                continue;
            case list[node] nList:
                continue;
            case Type t:
                println("type Type: <t>");
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
    //id nodes contain the names for variables, methods, etc. which should be ignored for type II and III.
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
            case Type t:
                println("type Type: <t>");
            default:
                // Handle other types if necessary
                continue;
            }
        }
    }
    

    return hashValue;
}

void printClonePairs(){
    for(list[node] clonePair <- clonePairs){
        for(node n <- clonePair){
            loc l = getLoc(n);
            println("name: <getName(n)>, loc: <l>");
        }
        println("-------------------------");
    }
}

void printCloneClasses(){
    for(list[node] cloneClass <- cloneClasses){
        for(node n <- cloneClass){
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
    visit(tree) {        
        case node n:
            nodes += n;
    }
    return nodes;
}

list[Declaration] collectUnits(list[Declaration] asts){
    list[Declaration] units = [];
    visit(asts){
        case unit:\method(_,_,_,_,_,_):
            units += [unit];
        case unit:\method(_,_,_,_,_,_,_):
            units += [unit];
    }
    return units;
}

int fillBins(node tree){
    int treeHash = 0;
    int treeMass = getMass(tree);
    list[node] children = getAllNodeChildren(tree);

    //if the node is a leaf node, give it a hash value of 1 so it does not impact the hash value 
    if (children == []){
        return 1;
    }
    else {
        childHashes = [fillBins(child) | node child <- children];
        //also ignore properties, to get a more generic hash
        treeHash = computeHash(tree, childHashes, false);
    }

    //get better value for tree mass treshold
    if(treeMass >= massTreshold){
        if (treeHash in buckets) {
            buckets[treeHash] += [tree];
        } else {
            buckets[treeHash] = [tree];
        }
    }
    return treeHash;
}

real similarity(node n1, node n2) {
    real sharedNodes = 0.0;
    real uniqueInN1 = 0.0;
    real uniqueInN2 = 0.0;
    
    set[node] nodesInN2 = collectNodes(n2);

    visit(n1) {
        case node child1: {
            bool found = false;
            for (node child2 <- nodesInN2) {
                if (deepEquals(child1, child2)) {
                    sharedNodes += 1.0;
                    nodesInN2 -= child2;
                    found = true;
                    break;
                }
            }
            if (!found) {
                uniqueInN1 += 1.0;
            }
        }
    }

    uniqueInN2 += toReal(size(nodesInN2));
    real similarity = 2 * sharedNodes / (2 * sharedNodes + uniqueInN1 + uniqueInN2);

    println(similarity);
    return similarity;
}

//Calculate mass 
int getMass(node tree){
    int numberOfNodes = 0;
    visit(tree){
        case node n:
            numberOfNodes += 1;
    }
    return numberOfNodes;
}

list[Statement] collectStatements(list[Declaration] asts) {
    list[Statement] subtrees = [];
    visit(asts) {
        case Statement stmt: 
            subtrees += [stmt];
    }
    return subtrees;
}