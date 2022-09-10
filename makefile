all:
	java -cp antlr-3.5.2-complete.jar org.antlr.Tool myCompiler.g
	javac -cp ./antlr-3.5.2-complete.jar myCompilerLexer.java myCompilerParser.java myCompiler_test.java

input1:
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test input1.c > input1.ll
	lli input1.ll
	llc input1.ll
	gcc -no-pie input1.s -o input1

input2:
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test input2.c > input2.ll
	lli input2.ll
	llc input2.ll
	gcc -no-pie input2.s -o input2

input3:
	java -cp ./antlr-3.5.2-complete.jar:. myCompiler_test input3.c > input3.ll
	lli input3.ll
	llc input3.ll
	gcc -no-pie input3.s -o input3

test1:
	cp input1.c test1.c
	clang -S -emit-llvm test1.c
test2:
	cp input2.c test2.c
	clang -S -emit-llvm test2.c
test3:
	cp input3.c test3.c
	clang -S -emit-llvm test3.c

clean:
	rm *.class *.ll *.s *.tokens myCompilerParser.java myCompilerLexer.java
	rm input1 input2 input3
