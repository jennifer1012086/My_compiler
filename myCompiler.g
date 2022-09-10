grammar myCompiler;

options {
   language = Java;
}

@header {
    // import packages here.
    import java.util.HashMap;
    import java.util.ArrayList;
    import java.lang.*;
}

@members {
    boolean TRACEON = false;

    // Type information.
    public enum Type{
       ERR, BOOL, INT, FLOAT, CHAR, CONST_INT, VOID, DOUBLE, CONST_FLOAT;
    }

    // This structure is used to record the information of a variable or a constant.
    class tVar {
	   int   varIndex; // temporary variable's index. Ex: t1, t2, ..., etc.
	   int   iValue;   // value of constant integer. Ex: 123.
	   float fValue;   // value of constant floating point. Ex: 2.314.
   	   boolean  bValue;   // value of logical expression Ex: true / false
	};

    class Info {
       Type theType;  // type information.
       tVar theVar;
	   
	   Info() {
          theType = Type.ERR;
		  theVar = new tVar();
	   }
    };

	
    // ============================================
    // Create a symbol table.
	// ArrayList is easy to extend to add more info. into symbol table.
	//
	// The structure of symbol table:
	// <variable ID, [Type, [varIndex or iValue, or fValue]]>
	//    - type: the variable type   (please check "enum Type")
	//    - varIndex: the variable's index, ex: t1, t2, ...
	//    - iValue: value of integer constant.
	//    - fValue: value of floating-point constant.
    // ============================================

    HashMap<String, Info> symtab = new HashMap<String, Info>();

    // labelCount is used to represent temporary label.
    // The first index is 0.
    int labelCount = 0;
	
    // varCount is used to represent temporary variables.
    // The first index is 0.
    int varCount = 0;

    int strCount = 0;

    // Record all assembly instructions.
    List<String> TextCode = new ArrayList<String>();


    /*
     * Output prologue.
     */
    void prologue()
    {
	TextCode.add("; === prologue ====");
	TextCode.add("declare dso_local i32 @printf(i8*, ...)\n");
	TextCode.add("@str = private unnamed_addr constant [13 x i8] c\"Hello World \0\"");
	TextCode.add("@str1 = private unnamed_addr constant [4 x i8] c\"\%d \0\"");
	TextCode.add("@str2 = private unnamed_addr constant [7 x i8] c\"\%d \%d \0\"");
	TextCode.add("@str3 = private unnamed_addr constant [4 x i8] c\"\%f \0\"");
	TextCode.add("@str4 = private unnamed_addr constant [7 x i8] c\"\%f \%f \0\"");
	TextCode.add("@str5 = private unnamed_addr constant [7 x i8] c\"\%f \%d \0\"");
	TextCode.add("@str6 = private unnamed_addr constant [7 x i8] c\"\%d \%f \0\"");
	
	
    }
    
	
    /*
     * Output epilogue.
     */
    void epilogue()
    {
       /* handle epilogue */
       TextCode.add("\n; === epilogue ===");
	   TextCode.add("ret i32 0");
       TextCode.add("}");
    }
    
    
    /* Generate a new label */
    String newLabel()
    {
       labelCount ++;
       return (new String("L")) + Integer.toString(labelCount);
    } 
    
    
    public List<String> getTextCode()
    {
       return TextCode;
    }
}

program :
	{
           /* Output function prologue */
           prologue();
        }
	(define)*
	main_func
	;


main_func: INT MAIN_ '(' ')'
	{
		TextCode.add("\ndefine dso_local i32 @main()");
		TextCode.add("{");
	}
        '{' 
           statements
	   myreturn
        '}'
        {
	   if (TRACEON)
	      System.out.println("VOID MAIN () {declarations statements}");

           /* output function epilogue */	  
           epilogue();
        }
        ;


declarations: 
	type ID ';'
        {
           if (TRACEON)
              System.out.println("declarations: type ID : declarations");

           if (symtab.containsKey($ID.text)) {
              // variable re-declared.
              System.out.println("Type Error: " + 
                                  $ID.getLine() + 
                                 ": Redeclared ID.");
              System.exit(0);
           }
                 
           /* Add ID and its info into the symbol table. */
	        Info the_entry = new Info();
		the_entry.theType = $type.attr_type;
		the_entry.theVar.varIndex = varCount;
		varCount ++;
		symtab.put($ID.text, the_entry);

           // issue the instruction.
	   // Ex: \%a = alloca i32, align 4
           
	   if ($type.attr_type == Type.INT) 
	   { 
              TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
           }
	   else if ($type.attr_type == Type.FLOAT) 
	   { 
              TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca float, align 4");
           }
        }
	| INT ID '=' Number ';'
	{
		if (TRACEON)
              		System.out.println("declarations: type ID : declarations");

           	if (symtab.containsKey($ID.text)) {
              		// variable re-declared.
              		System.out.println("Type Error: " + 
                                  	$ID.getLine() + 
                                 		": Redeclared ID.");
              		System.exit(0);
           	}

		/* Add ID and its info into the symbol table. */
	        Info the_entry = new Info();
		the_entry.theType = Type.INT;
		the_entry.theVar.varIndex = varCount;
		varCount ++;
		symtab.put($ID.text, the_entry);

		Info num = new Info();
		num.theType = Type.CONST_INT;
		num.theVar.iValue = Integer.parseInt($Number.text);

		TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
		TextCode.add("store i32 " + num.theVar.iValue + ", i32* \%t" + the_entry.theVar.varIndex + ", align 4");
		
		
	}
	| FLOAT ID '=' FLOAT_NUM ';'
	{
		if (TRACEON)
              		System.out.println("declarations: type ID : declarations");

           	if (symtab.containsKey($ID.text)) {
              		// variable re-declared.
              		System.out.println("Type Error: " + 
                                  	$ID.getLine() + 
                                 		": Redeclared ID.");
              		System.exit(0);
           	}

		/* Add ID and its info into the symbol table. */
	        Info the_entry = new Info();
		the_entry.theType = Type.FLOAT;
		the_entry.theVar.varIndex = varCount;
		varCount ++;
		symtab.put($ID.text, the_entry);

		Info num = new Info();
		num.theType = Type.CONST_FLOAT;
		num.theVar.fValue = Float.parseFloat($FLOAT_NUM.text);

		double val = num.theVar.fValue;
		long ans = Double.doubleToLongBits(val);

		TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca float, align 4");
		TextCode.add("store float 0x" + Long.toHexString(ans) + ", float* \%t" + the_entry.theVar.varIndex);		
		
	}
	| type a=ID '=' b=ID ';'
	{
		if (TRACEON)
              		System.out.println("declarations: type ID : declarations");

           	if (symtab.containsKey($a.text)) {
              		// variable re-declared.
              		System.out.println("Type Error: " + 
                                  	$a.getLine() + 
                                 		": Redeclared ID.");
              		System.exit(0);
           	}
		if (!symtab.containsKey($b.text)) {
              		// variable un-declared.
              		System.out.println("Type Error: " + 
                                  	$a.getLine() + 
                                 		": Undeclared ID.");
              		System.exit(0);
           	}
		if ( symtab.get($a.text).theType != symtab.get($b.text).theType ) 
	   	{
           	   System.out.println("Error: " + 
				 $a.getLine() +
					": Type mismatch for the two silde operands in an assignment statement.");
		   symtab.get($a.text).theType = Type.ERR;
           	}

		/* Add ID and its info into the symbol table. */
	        Info the_entry = new Info();
		the_entry.theType = $type.attr_type;
		the_entry.theVar.varIndex = varCount;
		varCount ++;
		symtab.put($a.text, the_entry);

		
		if( $type.attr_type == Type.INT )
		{		
			TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca i32, align 4");
			TextCode.add("store i32 " + symtab.get($b.text).theVar.iValue + ", i32* \%t" + the_entry.theVar.varIndex +", align 4");
		}
		else if( $type.attr_type == Type.FLOAT )
		{
			double val = symtab.get($b.text).theVar.fValue;
			long ans = Double.doubleToLongBits(val);

			TextCode.add("\%t" + the_entry.theVar.varIndex + " = alloca float, align 4");
			TextCode.add("store float 0x" + Long.toHexString(ans) + ", float* \%t" + the_entry.theVar.varIndex);
		}		
		
	}
        ;


type
returns [Type attr_type]
    : INT       { if (TRACEON) System.out.println("type: INT");        		$attr_type = Type.INT; }
    | FLOAT     { if (TRACEON) System.out.println("type: FLOAT");      		$attr_type = Type.FLOAT; }
    | VOID	{ if (TRACEON) System.out.println("type: VOID");       		$attr_type = Type.VOID; }
    | CHAR	{ if (TRACEON) System.out.println("type: CHAR");       		$attr_type = Type.CHAR; }
    | BOOL	{ if (TRACEON) System.out.println("type: BOOL");       		$attr_type = Type.BOOL; }
    | DOUBLE    { if (TRACEON) System.out.println("type: DOUBLE");     		$attr_type = Type.DOUBLE; }
    | CONST_INT { if (TRACEON) System.out.println("type: CONST_INT");  		$attr_type = Type.CONST_INT; }
    | CONST_FLOAT { if (TRACEON) System.out.println("type: CONST_FLOAT");  	$attr_type = Type.CONST_FLOAT; }
	;

statements:
	( declarations
	| assign ';'
	| for_loop
	| while_loop
	| printf
	| if_then_statements
	 )*
    	;


/* define */
define 
    :   PO_SYM  'include' LIBRARY_H
    ;

/* for loop */
for_loop
    : FOR_ '('
	( assign ) ';'
		{
			TextCode.add("br label \%Fcond");
			TextCode.add("\nFcond:");
		}
	( condition ) ';'
		{
			TextCode.add("br i1 \%t" + (varCount-1) + ", label \%Fstart, label \%Fend" );
			TextCode.add("\nFround:");
		}
	( assign ) ')'
		{
			TextCode.add("br label \%Fcond");			
			TextCode.add("\nFstart:");
		}
	'{' statements '}'
		{
			TextCode.add("br label \%Fround");
			TextCode.add("\nFend:");
		}
    ;

/* while loop */
while_loop
    : WHILE_
		{
			TextCode.add("br label \%Wcond");
			TextCode.add("\nWcond:");
		} 
	'(' condition ')'
		{
			TextCode.add("br i1 \%t" + (varCount-1) + ", label \%Wstart, label \%Wend");
			TextCode.add("\nWstart:");
		}
	'{' statements '}'
		{
			TextCode.add("\nWend:");
		}
    ;


/* printf */
printf
    :   PRINTF_ '(' STRING_TYPE ')'';'	    // printf("Hello World\n");
	{
		TextCode.add("\%t" + varCount + "= call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([13 x i8], [13 x i8]* @str, i32 0, i32 0))" );
		varCount ++;
	}
	| PRINTF_ '(' '"' '%''d' '"' ',' ID ')'';' // ex: printf("%d", id);
	{
		if (!symtab.containsKey($ID.text)) 
		   {
			   System.out.println("Error: " + 
						      $ID.getLine() + 
								  ": Undeclared ID.");
			   symtab.get($ID.text).theType = Type.ERR;
		   }
		if ( symtab.get($ID.text).theType != Type.INT ) 
	   	{
           	   System.out.println("Error: " + 
				 $ID.getLine() +
					": Type mismatch for the two silde operands in an assignment statement.");
		   symtab.get($ID.text).theType = Type.ERR;
           	}	
		
		Info theLHS = symtab.get($ID.text);

		TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + theLHS.theVar.varIndex + ", align 4");
		varCount ++;		
		TextCode.add("\%t" + varCount + "= call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str1, i32 0, i32 0), i32 \%t" + (varCount-1) +  ")" );
		varCount ++;
		
	}
	| PRINTF_ '(' '"' '%''d' '%''d' '"' ',' c=ID ',' d=ID ')' ';' // ex: printf("%d %d", a, b);
	{
		if (!symtab.containsKey($c.text) || !symtab.containsKey($d.text)) 
		   {
			   System.out.println("Error: " + 
						      $c.getLine() + 
								  ": Undeclared ID.");
			   symtab.get($c.text).theType = Type.ERR;
		   }
		if ( symtab.get($c.text).theType != Type.INT
		     ||   symtab.get($d.text).theType != Type.INT ) 
	   	{
           	   System.out.println("Error: " + 
				 $c.getLine() +
					": Type mismatch for the two silde operands in an assignment statement.");
           	}
		
	
		Info theLHS = symtab.get($c.text);
		Info theRHS = symtab.get($d.text);

		TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + theLHS.theVar.varIndex + ", align 4");
		varCount ++;
		TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + theRHS.theVar.varIndex + ", align 4");
		varCount ++;		
		TextCode.add("\%t" + varCount + "= call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @str2, i32 0, i32 0), i32 \%t" + (varCount-2) + ", i32 \%t" +(varCount-1) +  ")" );
		varCount ++;
	}
	| PRINTF_ '(' '"' '%''f' '"' ',' ID ')'';' // ex: printf("%f", id);
	{
		if (!symtab.containsKey($ID.text)) 
		   {
			   System.out.println("Error: " + 
						      $ID.getLine() + 
								  ": Undeclared ID.");
			   symtab.get($ID.text).theType = Type.ERR;
		   }
		if ( symtab.get($ID.text).theType != Type.FLOAT ) 
	   	{
           	   System.out.println("Error: " + 
				 $ID.getLine() +
					": Type mismatch for the two silde operands in an assignment statement.");
		   symtab.get($ID.text).theType = Type.ERR;
           	}	
		
		Info theLHS = symtab.get($ID.text);

		TextCode.add("\%t" + varCount + " = load float, float* \%t" + theLHS.theVar.varIndex );
		varCount ++;
		TextCode.add("\%t" + varCount + " = fpext float \%t" + (varCount-1) + " to double");
		varCount ++;		
		TextCode.add("\%t" + varCount + "= call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @str3, i32 0, i32 0), double \%t" + (varCount-1) +  ")" );
		varCount ++;
		
	}
	| PRINTF_ '(' '"' '%''f' '%''f' '"' ',' i=ID ',' j=ID ')' ';' // ex: printf("%f %f", a, b);
	{
		if (!symtab.containsKey($i.text) || !symtab.containsKey($j.text)) 
		   {
			   System.out.println("Error: " + 
						      $i.getLine() + 
								  ": Undeclared ID.");
			   symtab.get($i.text).theType = Type.ERR;
		   }
		if ( symtab.get($i.text).theType != Type.FLOAT
		     ||   symtab.get($j.text).theType != Type.FLOAT ) 
	   	{
           	   System.out.println("Error: " + 
				 $i.getLine() +
					": Type mismatch for the two silde operands in an assignment statement.");
           	}
		
	
		Info theLHS = symtab.get($i.text);
		Info theRHS = symtab.get($j.text);

		TextCode.add("\%t" + varCount + " = load float, float* \%t" + theLHS.theVar.varIndex + ", align 4");
		varCount ++;
		TextCode.add("\%t" + varCount + " = fpext float \%t" + (varCount-1) + " to double");
		varCount ++;
		TextCode.add("\%t" + varCount + " = load float, float* \%t" + theRHS.theVar.varIndex + ", align 4");
		varCount ++;		
		TextCode.add("\%t" + varCount + " = fpext float \%t" + (varCount-1) + " to double");
		varCount ++;
		TextCode.add("\%t" + varCount + "= call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @str4, i32 0, i32 0), double \%t" + (varCount-3) + ", double \%t" +(varCount-1) +  ")" );
		varCount ++;
	}
	| PRINTF_ '(' '"' '%''f' '%''d' '"' ',' e=ID ',' f=ID ')' ';' // ex: printf("%f %d", a, b);
	{
		if (!symtab.containsKey($e.text) || !symtab.containsKey($f.text)) 
		   {
			   System.out.println("Error: " + 
						      $e.getLine() + 
								  ": Undeclared ID.");
			   symtab.get($e.text).theType = Type.ERR;
		   }
		if ( symtab.get($e.text).theType != Type.FLOAT
		     ||   symtab.get($f.text).theType != Type.INT ) 
	   	{
           	   System.out.println("Error: " + 
				 $e.getLine() +
					": Type mismatch for the two silde operands in an assignment statement.");
           	}
		
	
		Info theLHS = symtab.get($e.text);
		Info theRHS = symtab.get($f.text);

		TextCode.add("\%t" + varCount + " = load float, float* \%t" + theLHS.theVar.varIndex + ", align 4");
		varCount ++;
		TextCode.add("\%t" + varCount + " = fpext float \%t" + (varCount-1) + " to double");
		varCount ++;
		TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + theRHS.theVar.varIndex + ", align 4");
		varCount ++;		
		TextCode.add("\%t" + varCount + "= call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @str5, i32 0, i32 0), double \%t" + (varCount-2) + ", i32 \%t" +(varCount-1) +  ")" );
		varCount ++;
	}
	| PRINTF_ '(' '"' '%''d' '%''f' '"' ',' g=ID ',' h=ID ')' ';' // ex: printf("%d %f", a, b);
	{
		if (!symtab.containsKey($g.text) || !symtab.containsKey($h.text)) 
		   {
			   System.out.println("Error: " + 
						      $g.getLine() + 
								  ": Undeclared ID.");
			   symtab.get($g.text).theType = Type.ERR;
		   }
		if ( symtab.get($g.text).theType != Type.INT
		     ||   symtab.get($h.text).theType != Type.FLOAT ) 
	   	{
           	   System.out.println("Error: " + 
				 $g.getLine() +
					": Type mismatch for the two silde operands in an assignment statement.");
           	}
		
	
		Info theLHS = symtab.get($g.text);
		Info theRHS = symtab.get($h.text);

		TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + theLHS.theVar.varIndex + ", align 4");
		varCount ++;
		TextCode.add("\%t" + varCount + " = load float, float* \%t" + theRHS.theVar.varIndex + ", align 4");
		varCount ++;
		TextCode.add("\%t" + varCount + " = fpext float \%t" + (varCount-1) + " to double");
		varCount ++;		
		TextCode.add("\%t" + varCount + "= call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([7 x i8], [7 x i8]* @str6, i32 0, i32 0), i32 \%t" + (varCount-3) + ", double \%t" +(varCount-1) +  ")" );
		varCount ++;
	}
    ;

		 
		 
if_then_statements
	: IF_ 
		'(' condition ')' 
		{
			TextCode.add("br i1 \%t" + (varCount-1) + ", label \%Ltrue, label \%Lfalse");
			TextCode.add("\nLtrue:");	
		}
		'{' statements '}'
		{
			TextCode.add("br label \%Lend");
			TextCode.add("\nLfalse:");
		}
	(ELSE_ '{' statements '}'
		{
			TextCode.add("br label \%Lend");
		}
	)?
	{
		TextCode.add("\nLend:");
	}
    	;



assign
	: ID '=' arith_expression 
             {
		if (!symtab.containsKey($ID.text)) 
		   {
			   System.out.println("Error: " + 
						      $ID.getLine() + 
								  ": Undeclared ID.");
		   }
		                

		Info theRHS = $arith_expression.theInfo;
		Info theLHS = symtab.get($ID.text); 

		   
                if ((theLHS.theType == Type.INT) &&
                    (theRHS.theType == Type.INT)) 
		{		   
                   // issue store insruction.
                   // Ex: store i32 \%tx, i32* \%ty
                   TextCode.add("store i32 \%t" + theRHS.theVar.varIndex + ", i32* \%t" + theLHS.theVar.varIndex );
		} 
		else if ((theLHS.theType == Type.INT) &&
				    (theRHS.theType == Type.CONST_INT)) 
		{
                   // issue store insruction.
                   // Ex: store i32 value, i32* \%ty
                   TextCode.add("store i32 " + theRHS.theVar.iValue + ", i32* \%t" + theLHS.theVar.varIndex );				
		}
		else if((theLHS.theType == Type.FLOAT) &&
				    (theRHS.theType == Type.CONST_FLOAT))
		{
			double val = theRHS.theVar.fValue;
			long ans = Double.doubleToLongBits(val);
			TextCode.add("store float 0x" + Long.toHexString(ans) + ", float* \%t" + theLHS.theVar.varIndex);
		}
		else if((theLHS.theType == Type.FLOAT) &&
				    (theRHS.theType == Type.FLOAT))
		{
			TextCode.add("store float \%t" + theRHS.theVar.varIndex + ", float* \%t" + theLHS.theVar.varIndex);
		}
		else
	   	{
           	   System.out.println("Error: " + 
				 $arith_expression.start.getLine() +
					": Type mismatch for the two silde operands in an assignment statement.");
           	}
	     }
             ;

		   
/* condition */
condition returns [Info theInfo]
@init { theInfo = new Info(); } 
    :   ID logical_OPT arith_expression 
	{
		  if (!symtab.containsKey($ID.text)) 
		   {
			   System.out.println("Error: " + 
						      $ID.getLine() + 
								  ": Undeclared ID.");
			   symtab.get($ID.text).theType = Type.ERR;
		   } 		

		if( !(symtab.get($ID.text).theType == Type.INT &&
			($arith_expression.theInfo.theType == Type.CONST_INT
			|| $arith_expression.theInfo.theType == Type.INT)
		     || symtab.get($ID.text).theType == Type.FLOAT &&
			($arith_expression.theInfo.theType == Type.CONST_FLOAT 
			|| $arith_expression.theInfo.theType == Type.FLOAT) ) )
		{
			System.out.println("Error: " + 
						$ID.getLine() +
					": Type mismatch for the operator "+ $logical_OPT.text + " in an expression.");
		}

		int id, expr;

		if( $logical_OPT.text.equals(">") )
		{
			$theInfo.theType = Type.BOOL;
			Type the_type = symtab.get($ID.text).theType;

			switch (the_type) 
			{
				case INT: 
					
					if( $arith_expression.theInfo.theType == Type.INT )
					{
						$theInfo.theVar.bValue = symtab.get($ID.text).theVar.iValue > $arith_expression.theInfo.theVar.iValue ? true : false;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						
						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 
							+$arith_expression.theInfo.theVar.varIndex+ ", align 4");
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_INT )
					{
						$theInfo.theVar.bValue = symtab.get($ID.text).theVar.iValue > $arith_expression.theInfo.theVar.iValue ? true : false;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						
						id = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp sgt i32 \%t" + id + ", " + $arith_expression.theInfo.theVar.iValue);
					}
				
					varCount ++;
				        break;
				case FLOAT:
					$theInfo.theVar.bValue = symtab.get($ID.text).theVar.fValue > $arith_expression.theInfo.theVar.fValue ? true : false;

					if( $arith_expression.theInfo.theType == Type.FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);

						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 
							+$arith_expression.theInfo.theVar.varIndex);
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = fcmp ogt float \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);

						id = varCount; varCount++;
						double val = $arith_expression.theInfo.theVar.fValue;
						long ans = Double.doubleToLongBits(val);
						TextCode.add("\%t" + varCount + " = fcmp ogt float \%t" + id + ", 0x" + Long.toHexString(ans));
					}
					varCount ++;
				        break;
		        }
			
		}
		else if( $logical_OPT.text.equals("<") )
		{
			$theInfo.theType = Type.BOOL;
			Type the_type = symtab.get($ID.text).theType;

			switch (the_type) 
			{
				case INT: 
					$theInfo.theVar.bValue = symtab.get($ID.text).theVar.iValue < $arith_expression.theInfo.theVar.iValue ? true : false;

					if( $arith_expression.theInfo.theType == Type.INT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 
							+$arith_expression.theInfo.theVar.varIndex+ ", align 4");
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_INT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						id = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp slt i32 \%t" + id + ", " + $arith_expression.theInfo.theVar.iValue);
					}
					varCount ++;
				         break;
				case FLOAT:
					$theInfo.theVar.bValue = symtab.get($ID.text).theVar.fValue < $arith_expression.theInfo.theVar.fValue ? true : false;

					if( $arith_expression.theInfo.theType == Type.FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);

						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 
							+$arith_expression.theInfo.theVar.varIndex);
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = fcmp olt float \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);

						id = varCount; varCount++;
						double val = $arith_expression.theInfo.theVar.fValue;
						long ans = Double.doubleToLongBits(val);
						TextCode.add("\%t" + varCount + " = fcmp olt float \%t" + id + ", 0x" + Long.toHexString(ans));
					}
					varCount ++;
				         break;
		        }
		}
		else if( $logical_OPT.text.equals(">=") )
		{
			$theInfo.theType = Type.BOOL;
			Type the_type = symtab.get($ID.text).theType;

			switch (the_type) 
			{
				case INT:
					$theInfo.theVar.bValue = symtab.get($ID.text).theVar.iValue >= $arith_expression.theInfo.theVar.iValue ? true : false;

					if( $arith_expression.theInfo.theType == Type.INT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 
							+$arith_expression.theInfo.theVar.varIndex+ ", align 4");
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_INT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						id = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp sge i32 \%t" + id + ", " + $arith_expression.theInfo.theVar.iValue);
					}
					varCount ++;
				        break;
				case FLOAT:
					$theInfo.theVar.bValue = symtab.get($ID.text).theVar.fValue >= $arith_expression.theInfo.theVar.fValue ? true : false;
				
					if( $arith_expression.theInfo.theType == Type.FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);
						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 
							+$arith_expression.theInfo.theVar.varIndex);
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = fcmp oge float \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);
						id = varCount; varCount++;
						double val = $arith_expression.theInfo.theVar.fValue;
						long ans = Double.doubleToLongBits(val);
						TextCode.add("\%t" + varCount + " = fcmp oge float \%t" + id + ", 0x" + Long.toHexString(ans));
					}
					varCount ++;
				        break;
		        }
		}
		else if( $logical_OPT.text.equals("<=") )
		{
			$theInfo.theType = Type.BOOL;
			Type the_type = symtab.get($ID.text).theType;

			switch (the_type) 
			{
				case INT:
					$theInfo.theVar.bValue = symtab.get($ID.text).theVar.iValue <= $arith_expression.theInfo.theVar.iValue ? true : false;

					if( $arith_expression.theInfo.theType == Type.INT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 
							+$arith_expression.theInfo.theVar.varIndex+ ", align 4");
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_INT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						id = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp sle i32 \%t" + id + ", " + $arith_expression.theInfo.theVar.iValue);
					}
					varCount ++;
				        break;
				case FLOAT:
					$theInfo.theVar.bValue = symtab.get($ID.text).theVar.fValue <= $arith_expression.theInfo.theVar.fValue ? true : false;
			
					if( $arith_expression.theInfo.theType == Type.FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);
						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 
							+$arith_expression.theInfo.theVar.varIndex);
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = fcmp ole float \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);
						id = varCount; varCount++;
						double val = $arith_expression.theInfo.theVar.fValue;
						long ans = Double.doubleToLongBits(val);
						TextCode.add("\%t" + varCount + " = fcmp ole float \%t" + id + ", 0x" + Long.toHexString(ans));
					}
					varCount ++;
				        break;
		        }
		}
		else if( $logical_OPT.text.equals("==") )
		{
			$theInfo.theType = Type.BOOL;		
			Type the_type = symtab.get($ID.text).theType;

			switch (the_type) 
			{
				case INT:
					$theInfo.theVar.bValue = symtab.get($ID.text).theVar.iValue == $arith_expression.theInfo.theVar.iValue ? true : false;

					if( $arith_expression.theInfo.theType == Type.INT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 
							+$arith_expression.theInfo.theVar.varIndex+ ", align 4");
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_INT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						id = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp eq i32 \%t" + id + ", " + $arith_expression.theInfo.theVar.iValue);
					}
					varCount ++;
				         break;
				case FLOAT:
					$theInfo.theVar.bValue = symtab.get($ID.text).theVar.fValue == $arith_expression.theInfo.theVar.fValue ? true : false;

					if( $arith_expression.theInfo.theType == Type.FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);
						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 
							+$arith_expression.theInfo.theVar.varIndex);
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = fcmp oeq float \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);
						id = varCount; varCount++;
						double val = $arith_expression.theInfo.theVar.fValue;
						long ans = Double.doubleToLongBits(val);
						TextCode.add("\%t" + varCount + " = fcmp oeq float \%t" + id + ", 0x" + Long.toHexString(ans));
					}
					varCount ++;
				        break;
		        }
		}
		else if( $logical_OPT.text.equals("!=") )
		{
			$theInfo.theType = Type.BOOL;
			Type the_type = symtab.get($ID.text).theType;

			switch (the_type) 
			{
				case INT: 
					$theInfo.theVar.bValue = symtab.get($ID.text).theVar.iValue != $arith_expression.theInfo.theVar.iValue ? true : false;
					

					if( $arith_expression.theInfo.theType == Type.INT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 
							+$arith_expression.theInfo.theVar.varIndex+ ", align 4");
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_INT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load i32, i32* \%t" 	
							+symtab.get($ID.text).theVar.varIndex+ ", align 4");
						id = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = icmp ne i32 \%t" + id + ", " + $arith_expression.theInfo.theVar.iValue);
					}
					varCount ++;
				        break;
				case FLOAT:
					$theInfo.theVar.bValue = symtab.get($ID.text).theVar.fValue != $arith_expression.theInfo.theVar.fValue ? true : false;
					

					if( $arith_expression.theInfo.theType == Type.FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);
						id = varCount; varCount++;
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 
							+$arith_expression.theInfo.theVar.varIndex);
						varCount++;
						expr = varCount; varCount++;
						TextCode.add("\%t" + varCount + " = fcmp une float \%t" + id + ", \%t" + expr);
					}
					else if( $arith_expression.theInfo.theType == Type.CONST_FLOAT )
					{
						TextCode.add("\%t" 
							+ varCount 
							+ " = load float, float* \%t" 	
							+symtab.get($ID.text).theVar.varIndex);
						id = varCount; varCount++;
						double val = $arith_expression.theInfo.theVar.fValue;
						long ans = Double.doubleToLongBits(val);
						TextCode.add("\%t" + varCount + " = fcmp une float \%t" + id + ", 0x" + Long.toHexString(ans));
					}
					varCount ++;
				        break;
		        }
		}  
	}
    ;

and_or
    :
	AN_OP
	| OR_OP
    ;

/* logical operator */
logical_OPT
    :    EQ_OP  
	| LE_OP  
	| GE_OP   
	| NE_OP   
	| LS_SYM  
	| RS_SYM  
    ;
			   
arith_expression returns [Info theInfo]
@init { Info theInfo = new Info(); } 
                : a=multExpr { $theInfo=$a.theInfo; }
                 ( '+' b=multExpr
                    {		  
                       // code generation.					   
                       if (($a.theInfo.theType == Type.INT) &&
                           ($b.theInfo.theType == Type.INT)) 
			{
                           TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       } 
			else if (($a.theInfo.theType == Type.INT) &&
					       ($b.theInfo.theType == Type.CONST_INT)) 
		       {
                           TextCode.add("\%t" + varCount + " = add nsw i32 \%t" + $a.theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
			else if (($a.theInfo.theType == Type.FLOAT) &&
					       ($b.theInfo.theType == Type.FLOAT)) 
		       {
                           TextCode.add("\%t" + varCount + " = fadd float \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $b.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.FLOAT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
			else if (($a.theInfo.theType == Type.FLOAT) &&
					       ($b.theInfo.theType == Type.CONST_FLOAT)) 
		       {
				double val = $b.theInfo.theVar.fValue;
				long ans = Double.doubleToLongBits(val);
                           TextCode.add("\%t" + varCount + " = fadd float \%t" + $a.theInfo.theVar.varIndex + ", 0x" + Long.toHexString(ans));
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.FLOAT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
			else
		       {
				  System.out.println("Error: " + 
						         $a.start.getLine() +
								 ": Type mismatch for the operator + in an expression.");
			      $b.theInfo.theType = Type.ERR;
		       }
                    }
                 | '-' c=multExpr
		    {		  
                       // code generation.					   
                       if (($a.theInfo.theType == Type.INT) &&
                           ($c.theInfo.theType == Type.INT)) 
			{
                           TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       } 
			else if (($a.theInfo.theType == Type.INT) &&
					       ($c.theInfo.theType == Type.CONST_INT)) 
		       {
                           TextCode.add("\%t" + varCount + " = sub nsw i32 \%t" + $a.theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.INT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
			else if (($a.theInfo.theType == Type.FLOAT) &&
					       ($c.theInfo.theType == Type.FLOAT)) 
		       {
                           TextCode.add("\%t" + varCount + " = fsub float \%t" + $a.theInfo.theVar.varIndex + ", \%t" + $c.theInfo.theVar.varIndex);
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.FLOAT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
			else if (($a.theInfo.theType == Type.FLOAT) &&
					       ($c.theInfo.theType == Type.CONST_FLOAT)) 
		       {
				double val = $c.theInfo.theVar.fValue;
				long ans = Double.doubleToLongBits(val);
                           TextCode.add("\%t" + varCount + " = fsub float \%t" + $a.theInfo.theVar.varIndex + ", 0x" + Long.toHexString(ans));
					   
					       // Update arith_expression's theInfo.
					       $theInfo.theType = Type.FLOAT;
					       $theInfo.theVar.varIndex = varCount;
					       varCount ++;
                       }
			else
		       {
				  System.out.println("Error: " + 
						         $a.start.getLine() +
								 ": Type mismatch for the operator - in an expression.");
			      $b.theInfo.theType = Type.ERR;
		       }
                    }
                 )*
                 ;

multExpr
returns [Info theInfo]
@init { Info theInfo = new Info();}
          : a=signExpr { $theInfo=$a.theInfo; }
          ( '*' b=signExpr
		{
			if(!($a.theInfo.theType == Type.INT &&
			($b.theInfo.theType == Type.CONST_INT
			|| $b.theInfo.theType == Type.INT)
		     || $a.theInfo.theType == Type.FLOAT &&
			($b.theInfo.theType == Type.CONST_FLOAT 
			|| $b.theInfo.theType == Type.FLOAT) ) )
			{
				System.out.println("Error: " + 
						         $a.start.getLine() +
								 ": Type mismatch for the operator * in an expression.");
			      $b.theInfo.theType = Type.ERR;
			}			

			Type the_type = $a.theInfo.theType;			
			$theInfo.theType = the_type;

			switch (the_type) 
			{
				case INT: 
					$theInfo.theVar.iValue = $a.theInfo.theVar.iValue*$b.theInfo.theVar.iValue;
					if($b.theInfo.theType == Type.INT)
					{
						TextCode.add("\%t"+ varCount +" = mul nsw i32 \%t" + $a.theInfo.theVar.varIndex + ", i32 \%t" + $b.theInfo.theVar.varIndex);
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if($b.theInfo.theType == Type.CONST_INT)
					{
						TextCode.add("\%t"+ varCount +" = mul nsw i32 \%t" + $a.theInfo.theVar.varIndex + ", " + $b.theInfo.theVar.iValue);
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				        break;
				case FLOAT:
					$theInfo.theVar.fValue = $a.theInfo.theVar.fValue*$b.theInfo.theVar.fValue;
					if($b.theInfo.theType == Type.FLOAT)
					{
						TextCode.add("\%t"+ varCount +" = fmul float \%t" + $a.theInfo.theVar.varIndex + ", float \%t" + $b.theInfo.theVar.varIndex);
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if($b.theInfo.theType == Type.CONST_FLOAT)
					{
						double val = $b.theInfo.theVar.fValue;
						long ans = Double.doubleToLongBits(val);
						TextCode.add("\%t"+ varCount +" = fmul float \%t" +$a.theInfo.theVar.varIndex+ ", 0x" +  Long.toHexString(ans) );
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				         break;
		        }
		}
          | '/' c=signExpr
		{
			if(!($a.theInfo.theType == Type.INT &&
			($c.theInfo.theType == Type.CONST_INT
			|| $c.theInfo.theType == Type.INT)
		     || $a.theInfo.theType == Type.FLOAT &&
			($c.theInfo.theType == Type.CONST_FLOAT 
			|| $c.theInfo.theType == Type.FLOAT) ) )
			{
				System.out.println("Error: " + 
						         $a.start.getLine() +
								 ": Type mismatch for the operator / in an expression.");
			      $b.theInfo.theType = Type.ERR;
			}

			Type the_type = $a.theInfo.theType;			
			$theInfo.theType = the_type;

			switch (the_type) 
			{
				case INT: 
					$theInfo.theVar.iValue = $a.theInfo.theVar.iValue/$b.theInfo.theVar.iValue;
					if($b.theInfo.theType == Type.INT)
					{
						TextCode.add("\%t"+ varCount +" = udiv i32 \%t" + $a.theInfo.theVar.varIndex + ", i32 \%t" + $c.theInfo.theVar.varIndex);
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if($b.theInfo.theType == Type.CONST_INT)
					{
						TextCode.add("\%t"+ varCount +" = udiv i32 \%t" + $a.theInfo.theVar.varIndex + ", " + $c.theInfo.theVar.iValue);
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				         break;
				case FLOAT:
					$theInfo.theVar.fValue = $a.theInfo.theVar.fValue/$b.theInfo.theVar.fValue;
					if($b.theInfo.theType == Type.FLOAT)
					{
						TextCode.add("\%t"+ varCount +" = fdiv float \%t" + $a.theInfo.theVar.varIndex+ ", float \%t" + $c.theInfo.theVar.varIndex);
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
					else if($b.theInfo.theType == Type.CONST_FLOAT)
					{
						double val = $c.theInfo.theVar.fValue;
						long ans = Double.doubleToLongBits(val);
						TextCode.add("\%t"+ varCount +" = fdiv float \%t" + $a.theInfo.theVar.varIndex + ", 0x" + Long.toHexString(ans));
						$theInfo.theVar.varIndex = varCount;
						varCount ++;
					}
				         break;
		        }
		}
	  )*
	  ;

signExpr
returns [Info theInfo]
@init { Info theInfo = new Info();}
        : a=primaryExpr { $theInfo=$a.theInfo; } 
        | '-' primaryExpr 
		{ 
			Type the_type = $primaryExpr.theInfo.theType;			
			$theInfo.theType = the_type;


			switch (the_type) 
			{
				case INT: 
					$theInfo.theVar.iValue = $primaryExpr.theInfo.theVar.iValue*-1;
				         break;
				case FLOAT:
					$theInfo.theVar.fValue = $primaryExpr.theInfo.theVar.fValue*-1;
				         break;
				
		        }
		}
	;
		  
primaryExpr
returns [Info theInfo]
@init { theInfo = new Info();}
           : Number
		{
            		$theInfo.theType = Type.CONST_INT;
			$theInfo.theVar.iValue = Integer.parseInt($Number.text);
		}
           | FLOAT_NUM
		{
			$theInfo.theType = Type.CONST_FLOAT;
			$theInfo.theVar.fValue = Float.parseFloat($FLOAT_NUM.text);
		}
           | ID
              {
                // get type information from symtab.
                Type the_type = symtab.get($ID.text).theType;
		$theInfo.theType = the_type;

                // get variable index from symtab.
                int vIndex = symtab.get($ID.text).theVar.varIndex;
				
                switch (the_type) 
		{
                case INT: 
                         // get a new temporary variable and
			// load the variable into the temporary variable.
                         
			// Ex: \%tx = load i32, i32* \%ty.
			TextCode.add("\%t" + varCount + " = load i32, i32* \%t" + vIndex);
				         
			// Now, ID's value is at the temporary variable \%t[varCount].
			// Therefore, update it.
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
                         break;
                case FLOAT:
			TextCode.add("\%t" +varCount + " = load float, float* \%t" + vIndex);
			$theInfo.theVar.varIndex = varCount;
			varCount ++;
                         break;
			
                }
              }
	   | '(' arith_expression ')'
		{
			$theInfo = $arith_expression.theInfo;
		}
           ;

/* return */
myreturn
    : 'return' arith_expression ';'
    ;

		   
/* A number: can be an integer value */
Number
    :    ('0'..'9')*
    ;

/* We're going to ignore all white space characters */
WS  
    :   (' ' | '\t' | '\r'| '\n') {$channel=HIDDEN;}
    ;


		   
/* ====== description of the tokens ====== */

/*----------------------*/
/*------Library---------*/
/*----------------------*/

STDIO	    : 'stdio.h';
STDLIB	    : 'stdlib.h';
STRING	    : 'string';
STDBOOL	    : 'stdbool.h';

/*----------------------*/
/*   Reserved Keywords  */
/*----------------------*/
INT    : 'int';
CHAR   : 'char';
VOID   : 'void';
FLOAT  : 'float';
DOUBLE : 'double';
BOOL   : 'bool';
TRUE_	    : 'true';
FALSE_	    : 'false';
CONST_INT   : 'const int';
CONST_FLOAT : 'const float';
WHILE_      : 'while';
DO_	    : 'do';
FOR_	    : 'for';
MAIN_	    : 'main';
RETURN_	    : 'return';
INCLUDE_    : 'include';
STRUCT_	    : 'struct';
BREAK_	    : 'break';
SWITCH_	    : 'switch';
CASE_	    : 'case';
IF_	    : 'if';
ELSE_	    : 'else';
ELSE_IF_    : 'else if';
DEFINE_	    : 'define';
PRINTF_	    : 'printf';


/*----------------------*/
/*       Symbols        */
/*----------------------*/
EQ_SYM : '=';
SE_SYM : ';';
PO_SYM : '#';
AN_SYM : '&';
DO_SYM : '.';
CO_SYM : ',';
LP_SYM : '(';
RP_SYM : ')';
LC_SYM : '{';
RC_SYM : '}';
LM_SYM : '[';
RM_SYM : ']';
LS_SYM : '<';
RS_SYM : '>';
DQ_SYM : '"';
PL_SYM : '+';
MI_SYM : '-';
MU_SYM : '*';
DI_SYM : '/';
MO_SYM : '%';
NO_SYM : '!';
PT_SYM : '->';

/*----------------------*/
/*  Compound Operators  */
/*----------------------*/

EQ_OP : '==';
LE_OP : '<=';
GE_OP : '>=';
NE_OP : '!=';
PP_OP : '++';
MM_OP : '--';
AN_OP : '&&';
OR_OP : '||'; 
RSHIFT_OP : '<<';
LSHIFT_OP : '>>';

ID 
	: ('a'..'z' | 'A'..'Z' | '_')('a'..'z' | 'A'..'Z' | '_'| '0'..'9')*;

FLOAT_NUM: FLOAT_NUM1 | FLOAT_NUM2 | FLOAT_NUM3;
fragment FLOAT_NUM1: (DIGIT)+'.'(DIGIT)*;
fragment FLOAT_NUM2: '.'(DIGIT)+;
fragment FLOAT_NUM3: (DIGIT)+;

/* Library */
LIBRARY_H: LS_SYM (STDIO | STRING | STDLIB | STDBOOL)  RS_SYM; 

/* String */
STRING_TYPE: '"' (DIGIT | LETTER | ' ' ) + '"'; 

/* Comments */
COMMENT1 : '//'(.)*'\n';
COMMENT2 : '/*' (.)* '*/';


fragment LETTER : 'a'..'z' | 'A'..'Z' | '_';
fragment DIGIT : '0'..'9';
