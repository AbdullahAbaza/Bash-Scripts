#!/bin/bash 

for_loop() {
    names=("Ahmed" "Mohamed" "Ali" "Omar")
    echo "array elements: ${names[@]}"
    echo "array indeces: ${!names[@]}"
    echo "array length: ${#names[@]}"

    for value in ${names[@]} ; do
        echo $value
    done
    
}

# for_loop

function while_loop1() {
    n=1
    while [ $n -le 10 ];
    do
        echo counter at $n  
        n=$(( n+1 ))
    done
}

function while_loop2() {
    printf "counter: "
    n=1
    while [ $n -le 10 ];
    do
        printf "%d " "$n"  
        (( n++ ))
    done
}


# Until loop

function until_loop() {
    counter=10
    until [ $counter -lt 1 ]; 
    do
        printf "%d " "$counter"
        (( counter-- ))
    done
}



