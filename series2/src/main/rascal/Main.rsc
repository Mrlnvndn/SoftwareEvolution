module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import Map;
import Node;

loc testProject = |cwd:///../java-test|;
loc smallProject = |cwd:///../smallsql0.21_src/smallsql0.21_src/|;
loc largeProject = |cwd:///../hsqldb-2.3.1/hsqldb-2.3.1/|;

loc outputFile = |cwd:///output.txt|;

int numBuckets = 0;

int main(int testArgument=0) {
    list[Declaration] asts  = (getASTs(testProject));

    numBuckets = 10;

    list[tuple[node, node]] clonePairs = detectCodeClones(asts);
    appendToFile(outputFile, clonePairs);
    
    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

bool areSubTreesEqual(Declaration ast1, Declaration ast2){
    return true;
}

list[tuple[node, node]] detectCodeClones(list[Declaration] asts){
    //key:bucket hash, value: node (subtree)
    map[int, list[node]] buckets = ();
     //list of node lists for each clone class
    list[list[node]] cloneClasses = [];
    //list of node tuples for each clone pair
    list[tuple[node, node]] clonePairs = [];
    //key: subtree hash, value: node (subtree)
    map[int, list[node]] nodeMap = ();
    
    for(Declaration ast <- asts){
        computeSubTreeHash(ast, buckets, nodeMap); 
    }

     for(tuple[int, list[node]] bucket <- toList(buckets)){
        //identify clone clonePairs
        clonePairs = findClonePairs(buckets);
        //group pairs into cloneClasses 
     }

     return clonePairs;
}

int computeSubTreeHash(node tree, map[int, list[node]] buckets, map[int, list[node]] nodeMap){
    int treeHash = 0;

    list[list[node]] childrenList = [child | list[node] child <- getChildren(tree)];
    list[node] children = [child | list[node] childList <- childrenList, node child <- childList];
    children += [child | node child <- getChildren(tree)];
    println("node name: <getName(tree)>");
    for(node n <- children){
        println("node children: <getName(n)>");
    }
    if (children == []){
        treeHash = computeHash(tree, []);
    }
    else {
        // check size of subtree
        childHashes = [computeSubTreeHash(child, buckets, nodeMap) | node child <- children];
        treeHash = computeHash(tree, childHashes);
    }

    // // Add size check
    // int bucketIndex = treeHash % numBuckets;
    // if (bucketIndex notin buckets){
    //     buckets[bucketIndex] = [];
    // }
    // buckets[bucketIndex] += [tree];

    return treeHash;
}

//This needs to be refined
int computeHash(node currentNode, list[int] childHashes){
    int base = 31;
    int prime = 1000000007;
    int treeHash = polynomialHash(getName(currentNode));

    for(int childHash <- childHashes){
        treeHash = (treeHash * base + childHash) % prime;
    }
    return treeHash;
}

int polynomialHash(str s, int base = 31, int prime = 1000000007) {
    int hashValue = 0;
    for (int c <- chars(s)) {
        hashValue = (hashValue * base + c) % prime;
    }
    return hashValue;
}

list[tuple[node, node]] findClonePairs( map[int, list[node]] buckets){
    list[tuple[node, node]] pairs = [];
    list[list[node]] bucketsValues = toList(range(buckets));
    //Compare all nodes in the same bucket
    for (int i <- [ 0 .. size(bucketsValues)]){
        list[node] bucket = bucketsValues[i];
        for(int j <- [0 .. size(bucket) - 1]){
            for(int k <- [j + 1 .. size(bucket)]){
                node node1 = bucket[j];
                node node2 = bucket[k];
                // Ensure structural equality
                if(deepEquals(node1, node2)){ // Ensure structural equality
                    pairs += [<node1, node2>];
                }
            }
        }
    }
    return pairs;
}

bool deepEquals(node node1, node node2){

    //compare two subtrees toroughly. getName gets the type (methodCall, Class, method)
    if (getName(node1) != getName(node2)) {
        println("not equal:");
        println("loc1: <node1.src>");
        println("loc2: <node2.src>");
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

int hashSubTree(node subTree){
    int hash = 0;
    list[value] children = getChildren(subTree);

    list[Expression] exprs =[];

    for (value child <- children) {
        switch (child) {
            case Statement stmts: \block(statements):{
                for(Statement stmt <- stmts){
                    //give a rating for each statement
                    hash = hash + 1;

                }
            }
            case Statement stmt:
                println("Statement: <stmt>");
            case Declaration decl:
                println("Declaration: <decl>");
            case Expression expr:{
                println("Expression: <expr>");
                exprs += [expr];
            }
        }
    }

    return hash;
}

list[node] collectNodes(list[Declaration] asts) {
    list[node] nodes = [];
    visit(asts) {        
        case Declaration decl:{
            nodes += [decl];
            println("keywords decl: <getName(decl)>");
        }
        case Statement stmt:{
            nodes += [stmt];
            println("keywords stmt: <getName(stmt)>");

        }
        case Expression expr:{
            nodes += [expr];
            println("keywords expr: <getName(expr)>");

        }
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

int getMass(Declaration decl){
    return decl.src.end.line - decl.src.begin.line + 1;
}

list[Statement] collectStatements(list[Declaration] asts) {
    list[Statement] subtrees = [];
    visit(asts) {
        case Statement stmt: 
            subtrees += [stmt];
    }
    return subtrees;
}