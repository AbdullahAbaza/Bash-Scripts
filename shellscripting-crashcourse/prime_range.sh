#!/bin/bash

# Function to check if a number is prime
is_prime() {
    local num=$1
	if ((num <= 1)); then
		return 1 # Not prime
  	fi
  	if ((num == 2)); then
    	return 0 # 2 is prime
  	fi
  	if ((num % 2 == 0)); then
    	return 1 # Even numbers > 2 are not prime
  	fi
  	for ((i = 3; i * i <= num; i += 2)); do
    	if ((num % i == 0)); then
      	return 1 # Not prime
    	fi
  	done
  	return 0 # Prime
}

# Read range from the user
echo "Enter the starting number:"
read start
echo "Enter the ending number:"
read end

# Print prime numbers in the range
echo "Prime numbers between $start and $end:"
for ((n = start; n <= end; n++)); do
  if is_prime "$n"; then
    printf "%d " "$n"
  fi
done
echo
