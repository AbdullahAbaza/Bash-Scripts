#! /bin/bash

cities=("Cairo" "Alex")

echo "cities: ${cities[@]}"

echo "Seconed City: ${cities[1]}"

new_elem_idx="${#cities[@]}" 

read -p "Enter A new City: " input

cities[new_elem_idx]=$input

echo "number of cities Now: ${#cities[@]} "

read -p "Enter another city: " input
cities[0]=$input

echo "All Cities: ${cities[@]}"


