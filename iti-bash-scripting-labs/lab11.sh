#!/bin/bash

Add() {
  local sum=$(( $1 + $2 ))
  echo $sum
}

Sub() {
  local sub=$(( $1 - $2 ))
  echo $sub
}

Mul() {
  local mul=$(( $1 * $2 ))
  echo $mul
}

Div() {
  if [[ $2 -eq 0 ]]; then
    echo "Division by zero is not allowed"
    exit 1
  fi
  local div=$(( $1 / $2 ))
  echo $div
}

Moduls() {
  local remainder=$(( $1 % $2 ))
  echo $remainder
}


result=0

while true; do

    read -p "Enter two Integer Numbers: " -a input

    if [[ ${#input[@]} -ne 2 ]]; then
        echo "You should enter two numbers separated by space!"
        continue
    fi

    # this condition check if input is not integer numbers
    if ! [[ "${input[0]}" =~ ^[0-9]+$ ]] || ! [[ "${input[1]}" =~ ^[0-9]+$ ]]; then
        echo "Your Input should be Integer values"
        continue
    fi
    
    select operation in "Add" "Sub" "Mul" "Div" "Moduls" "Exit"
    do
    case $operation in
      Add )
        result=$(Add ${input[0]} ${input[1]})
        ;;
      Sub )
        result=$(Sub ${input[0]} ${input[1]})
        ;;
      Mul )
        result=$(Mul ${input[0]} ${input[1]})
        ;;
      Div )
        result=$(Div ${input[0]} ${input[1]})
        ;;
      Moduls )
        result=$(Moduls ${input[0]} ${input[1]})
        ;;
      Exit )
        echo "Exiting..."
        exit 0
        ;;
      * )
        echo "Invalid Option $REPLY"
        continue
        ;;
    esac

    echo "Result = $result"
    break
  done
done

