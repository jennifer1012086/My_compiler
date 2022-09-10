先執行 make 指令, 產生 myCompilerLexer.java 、myCompilerParser.java 、myCompiler.tokens
執行 make input1:
	產生 input1.c 的執行檔、並命名為 input1
	執行 ./input1 會產生第一個測試程式的結果
執行 make input2:
	產生 input2.c 的執行檔、並命名為 input2
	執行 ./input2 會產生第二個測試程式的結果
執行 make input3:
	產生 input3.c 的執行檔、並命名為 input3
	執行 ./input3 會產生第三個測試程式的結果
執行 make clean:
	會刪除所有 make 指令產生出來的檔案

