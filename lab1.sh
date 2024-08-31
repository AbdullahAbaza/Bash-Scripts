#! /bin/bash


read -p "Enter Full_Name: " -a name
read -p "Birth_year: " birth_year
read -p "Faculty: " faculty
read -p "Graduation year: " grad_year

echo -e "Your Full Info: \n ${name[@]} \n $birth_year \n $faculty \n $grad_year"
