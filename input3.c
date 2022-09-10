#include <stdio.h>
#include <stdlib.h>

int main()
{
	int input = 40;
	int result = 50;
	
	float input_f = 3.5;

	result = input + result;

	if( result < 100  )
	{
		result = result + 50;
		input_f = (input_f * 1.5) + 0.45;
		printf("%d %f ", result, input_f);
	}
	else
	{
		result = result + 100;
		input_f = input_f + 0.45;
		printf("%d %f ", result, input_f);
	}

	return 0;
}
