#!/bin/bash


select choice in "Abdullah" "Islam" "Ahmed" "Hazem"
do
	case $choice in
		Abdullah ) 
			echo "Hello $choice" ;;
		Islam ) 
			echo "Hello $choice" ;;
		Ahmed )
			echo "Hello $choice" ;;
		* )
            echo "Invalid Choice " ;;
       esac
       
       if [ $choice = "Hazem" ]; then
	      break 
      else
	      continue
       fi
done

