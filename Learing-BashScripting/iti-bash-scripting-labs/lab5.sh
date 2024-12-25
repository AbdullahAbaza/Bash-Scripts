#! /bin/bash

read -p "Please enter an integer number: " number

if (( number % 2 == 0 ))
then
	echo "$number is even"
else
	echo "$number is odd"
fi

