#include <stdio.h>
#include <stdlib.h>

int main()
{
	int input_a = 1;
	int input_c = 1;
	
	float input_b;
	float input_d;
	
	int i;

	input_b = 7.25;
	input_d = 0.25;
	
	for(i=0; i!=5; i=i+1)
	{
		if(input_a == 1)
		{
			input_a = input_a + input_c;
		}
		else
		{
			input_a = (input_a*3+(input_c-1))*2;
			input_b = input_b*1.5 + input_d - 1.25;
		}
	}

	printf("%d %f ", input_a, input_b);
	
	return 0;
}
