#!/bin/bash

HOUR_RATE=50
FULL_HOURS=40
DEDUCTION_RATE=0.1

read -p "Please enter your working hours: " working_hours

salary=$((working_hours * HOUR_RATE))

if [ $working_hours -lt $FULL_HOURS ] 
then
	deduction=$(echo "$salary * $DEDUCTION_RATE" | bc)
	salary=$(echo "$salary - $deduction" | bc) 
	echo "There is a salary deduction"
fi

echo "Your salary is: $salary"


