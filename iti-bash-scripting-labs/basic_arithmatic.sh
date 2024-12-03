#! /bin/bash


num1=5
num2=10

echo "Addition = $(( num1 + num2 ))"

echo --------------------------------

# method 2 expretions


echo "addition =  $(expr $num1 + $num2)"


# handling float number using bench calculator bc


float=3.14

echo "float addition=" $(($float + 1.0) | bc)



