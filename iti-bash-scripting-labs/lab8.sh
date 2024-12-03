#! /bin/bash

NAME="Amin"

read -p "What is my name: " input

while [ $NAME != $input ]
do 
	echo "Wrong Answer!"
	read -p "Try Again: " input
done 

echo "You Got It"

