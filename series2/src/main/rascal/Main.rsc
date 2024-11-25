module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import Map;

loc testProject = |cwd:///../java-test|;
loc smallProject = |cwd:///../smallsql0.21_src/smallsql0.21_src/|;
loc largeProject = |cwd:///../hsqldb-2.3.1/hsqldb-2.3.1/|;

int main(int testArgument=0) {
    list[Declaration] asts  = (getASTs(testProject));
    //traverseAST(asts[0]);
    //println("----");
    list[Declaration] decls = collectDeclarations([asts[2]]);
    list[Statement] stmts = collectStatements([asts[2]]);
    for(Declaration decl <- decls){
        println(decl);
        println("<decl.typ> from line <decl.src.begin.line> to line <decl.src.end.line>");
        println("------------------------------------");
    }

    for(Statement stmt <- stmts){
        println(stmt);
        println("from line <stmt.src.begin.line> to line <stmt.src.end.line>");
        println("------------------------------------");
    }

    //println(size(collectDeclarations(asts)));
    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

//What should it return?

//Should  you go over the asts 3 times? (for each duplication level once?)

bool areSubTreesEqual(Declaration ast1, Declaration ast2){
    if(ast1 == ast2){
        return true;
    }
    else{
        return false;
    }
}


//How to get to all subtrees? And how to collect them?
void traverseAST(Declaration ast){
        visit(ast) {
            case classDecl:\class(_, _, _, _, _, _): {
                println("Found a class declaration: <classDecl>");
                visit(classDecl) {
                    case methodDecl:\method(_, _, _, _, _, _): {
                        println("Found a method declaration: <methodDecl>");
                    }
                }
            }   
        }
    
}

list[Declaration] collectDeclarations(list[Declaration] asts) {
    list[Declaration] decls = [decl |Declaration decl <- asts[0]];

    visit(asts) {
        //This will overlap with class()
        case Declaration decl:
            decls: += [decl];
        case decl:\compilationUnit(_, _):
            decls += [decl];
        case decl:\compilationUnit(_, _, _):
            decls += [decl];
        case decl:\compilationUnit(_):
            decls += [decl];
        case decl:\enum(_, _, _, _, _):
            decls += [decl];
        case decl:\enumConstant(_, _, _, _):
            decls += [decl];
        case decl:\enumConstant(_, _, _):
            decls += [decl];
        case decl:\class(_, _, _, _, _, _):
            decls += [decl];
        case decl:\class(_):
            decls += [decl];
        case decl:\interface(_, _, _, _, _, _):
            decls += [decl];
        case decl:\field(_, _, _):
            decls += [decl];
        case decl:\initializer(_, _):
            decls += [decl];
        case decl:\method(_, _, _, _, _, _, _):
            decls += [decl];
        case decl:\method(_, _, _, _, _, _):
            decls += [decl];
        case decl:\constructor(_, _, _, _, _):
            decls += [decl];
        case decl:\import(_, _):
            decls += [decl];
        case decl:\importOnDemand(_, _):
            decls += [decl];
        case decl:\package(_, _):
            decls += [decl];
        case decl:\variables(_, _, _):
            decls += [decl];
        case decl:\variable(_, _):
            decls += [decl];
        case decl:\variable(_, _, _):
            decls += [decl];
        case decl:\typeParameter(_, _):
            decls += [decl];
        case decl:\annotationType(_, _, _):
            decls += [decl];
        case decl:\annotationTypeMember(_, _, _):
            decls += [decl];
        case decl:\annotationTypeMember(_, _, _, _):
            decls += [decl];
        // This will create duplicate covered lines with method()
        case decl:\parameter(_, _, _, _):
            decls += [decl];
        case decl:\dimension(_):
            decls += [decl];
        case decl:\vararg(_, _, _):
            decls += [decl];
    }
    return decls;
}

list[Statement] collectStatements(list[Declaration] asts) {
    list[Statement] subtrees = [];
    visit(asts) {
        case sub:\Statement: 
            subtrees += [sub];
        case sub:\assert(_, _):
           subtrees += [sub];        
        case sub:\block(_): 
            subtrees += [sub];
        case sub:\break(): 
            subtrees += [sub];
        case sub:\break(_): 
            subtrees += [sub];
        case sub:\continue(): 
            subtrees += [sub];
        case sub:\continue(_): 
            subtrees += [sub];
        case sub:\do(_, _): 
            subtrees += [sub];
        case sub:\empty(): 
            subtrees += [sub];
        case sub:\foreach(_, _, _): 
            subtrees += [sub];
        case sub:\for(_, _, _, _): 
            subtrees += [sub];
        case sub:\for(_, _, _): 
            subtrees += [sub];
        case sub:\if(_, _): 
            subtrees += [sub];
        case sub:\if(_, _, _): 
            subtrees += [sub];
        case sub:\label(_, _): 
            subtrees += [sub];
        case sub:\return(_): 
            subtrees += [sub];
        case sub:\return(): 
            subtrees += [sub];
        case sub:\switch(_, _): 
            subtrees += [sub];
        case sub:\case(_): 
            subtrees += [sub];
        case sub:\caseRule(_): 
            subtrees += [sub];
        case sub:\defaultCase(): 
            subtrees += [sub];
        case sub:\synchronizedStatement(_, _): 
            subtrees += [sub];
        case sub:\throw(_): 
            subtrees += [sub];
        case sub:\try(_, _): 
            subtrees += [sub];
        case sub:\try(_, _, _): 
            subtrees += [sub];
        case sub:\catch(_, _): 
            subtrees += [sub];
        case sub:\declarationStatement(_): 
            subtrees += [sub];
        case sub:\while(_, _): 
            subtrees += [sub];
        case sub:\expressionStatement(_): 
            subtrees += [sub];
        case sub:\constructorCall(_, _): 
            subtrees += [sub];
        case sub:\superConstructorCall(_, _, _): 
            subtrees += [sub];
        case sub:\superConstructorCall(_, _): 
            subtrees += [sub];
        case sub:\yield(_): 
            subtrees += [sub];
    }
    return subtrees;
}