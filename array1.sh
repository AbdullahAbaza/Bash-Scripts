#! /bin/bash

arr=('a' 'b' 'c' 'd' 'e' 'f')

echo "array elements: ${arr[@]}"

echo "array indexs:${!arr[@]}"

echo "array length: ${#arr[@]}"

arr[100]="100th_element"

echo "new array: ${arr[@]}"

echo "index after adding at idx 100: ${!arr[@]}"

new_elm_idx=${#arr[@]}
arr[new_elm_idx]="Abdullah"

echo "array after adding with length:  ${arr[@]}"

arr+=('plus1' 'plus2') 

echo "array after adding with + :  ${arr[@]} "

echo "final indexes: ${!arr[@]}"

exit 0


