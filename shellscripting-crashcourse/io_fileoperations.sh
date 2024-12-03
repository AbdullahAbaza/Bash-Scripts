#!/bin/bash

# Check if file exist
if [ ! -d /$HOME/.ssh/ ]
then 
    echo ".ssh directory not found" >> ./output.log
else 
    echo ".ssh directory exist ... listing its content"
    ls -lah ~/.ssh
fi





