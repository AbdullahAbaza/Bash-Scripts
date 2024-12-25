#!/bin/bash

read -p "Enter a single or double character: "  input


case "${input:0:1}" in
    [a-z] )
        echo "First char is a lowercase alphabetic character"
        ;;
    [A-Z] )
        echo "First char is an uppercase alphabetic character"
        ;;
    [0-9] )
        echo "First char is a number"
        ;;
    ? )
        echo "First char is a special character"
        ;;
    *)
        echo "Invalid Input"
        ;;
esac



