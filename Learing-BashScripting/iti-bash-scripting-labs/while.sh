#! /bin/bash

#while [ condition ]
#do
#	COMMANDS
#done



n=1
while [ $n -le 10 ]; do 
	echo Number $n
	n=$(( n+1 ))
done


# n++ = n+1

echo "-------------------------------------"

y=1
while (( y <= 10 )); do 
	echo Number $y
	(( y++ ))  # y=$(( y+1 ))
	sleep 0.5
done
	

