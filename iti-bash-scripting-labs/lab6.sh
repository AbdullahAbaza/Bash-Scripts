#!/bin/bash

read -p "Enter your grade: " grade

if ((grade >= 0 && grade < 50)); then
    echo "Your rating is Failed"
elif ((grade >= 50 && grade < 65)); then
    echo "Your rating is Normal"
elif ((grade >= 65 && grade < 75)); then
    echo "Your rating is Good"
elif ((grade >= 75 && grade < 85)); then
    echo "Your rating is Very Good"
elif (grade >= 85); then
    echo "Your rating is Excellent"
fi
