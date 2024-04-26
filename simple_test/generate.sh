#!/bin/bash

# Function to generate a random string
generate_random_string() {
    # Length of the random string
    local length=$1

    # Characters to choose from for the random string
    local chars='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

    # Generating the random string
    local random_string=''
    for (( i=0; i<$length; i++ )); do
        local char_index=$(( RANDOM % ${#chars} ))
        random_string+="${chars:char_index:1}"
    done
    echo "$random_string"
}

# Number of pairs to generate
num_pairs=10  # Change this to the desired number of pairs

# CSV file to output the pairs
csv_file="random_pairs.csv"

# Header for the CSV file
echo "String1,String2" > "$csv_file"

# Generating random pairs and writing them to the CSV file
for (( i=1; i<=$num_pairs; i++ )); do
    string1=$(generate_random_string 10)  # Change 10 to the desired length of string
    string2=$(generate_random_string 10)  # Change 10 to the desired length of string
    echo "$string1,$string2" >> "$csv_file"
done

echo "Random pairs generated and saved to $csv_file"
