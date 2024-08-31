#!/bin/bash

read -p "Enter a character or string: " input

if [ ${#input} -eq 1 ]; then
    case $input in
        [a-z])
            echo "You entered a lowercase alphabetic character"
            ;;
        [A-Z])
            echo "You entered an uppercase alphabetic character"
            ;;
        [0-9])
            echo "You entered a number"
            ;;
        *)
            echo "You entered a special character"
            ;;
    esac
else
    echo "You entered a string"
fi

