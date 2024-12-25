#! /bin/bash

for i in 1 2 3 4 5
do 
	echo $i
done

echo -e "============================= \n"

for i in {1..5}
do 
	echo -n "$i "
done

echo -e "\n==============================="

for i in {1..10..2}
do 
	echo -n "$i" 
done

echo -e "\n================================"


for (( i=0; i<5; i++ )) # 0 1 2 3 4
do 
	echo -n "$i "
done


