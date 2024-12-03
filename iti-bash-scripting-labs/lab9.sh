#!/bin/bash

echo "Enter 10 numbers: "
sum=0

for i in {1..10}
do
    read -p "Enter number $i: " input
    if [[ $input =~ ^[0-9]+$ ]]; then
        sum=$(( sum + $input ))
    else
        echo -e "You should enter a number\n"
        i=$(( i-1 ))
    fi
done

echo "Summation is equal: $sum"

