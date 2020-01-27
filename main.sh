#!/bin/bash
set -e

if [ -z $1 ]; then    
    echo "Base branch argument not found, in most cases it should be master"
    echo "Usage: ./main.sh <BASE_BRANCH> <APP_DIRECTORY> <BLACKLIST_DIRECTORY>"
    exit 1
fi

if [ -z $2 ]; then
    echo "Application path argument not found"
    echo "Usage: ./main.sh <BASE_BRANCH> <APP_DIRECTORY> <BLACKLIST_DIRECTORY>"
    exit 1
fi

base_branch=$1
application_directories=$(echo $2 | tr "," "\n")
blacklist_directories=$(echo $3 | tr "," "\n")
final_return_code=0

validate_no_js() {
    local updated_type=$1
    local files_changed=$2
    local js_files_array=()
    return_code=0

    for file_changed in $files_changed
    do
        if [[ $file_changed =~ .*\.jsx? ]]; then
            for application_directory in $application_directories
            do
                if [[ $file_changed =~ $application_directory.* ]]; then
                    local blacklisted=0
                    for blacklist_directory in $blacklist_directories
                    do
                        if [[ $file_changed =~ $blacklist_directory.* ]]; then
                            blacklisted=1
                        fi
                    done
                    if [ $blacklisted -eq 0 ]; then
                        js_files_array+=( $file_changed )
                        return_code=1
                    fi
                fi
            done
        fi       
    done

    if [[ $return_code -eq 1  ]]; then
        echo "  $updated_type:"        
        for js_file in $js_files_array
        do
            echo "      $js_file"
        done
    fi
}

echo "Started typescript migration"

added_files=$(git diff $base_branch --name-status --diff-filter=A | awk '{print $2}' | tr "\n" "\n")
validate_no_js "Added" $added_files
final_return_code=$(($final_return_code+$return_code >= 1 ? 1 : 0))

modified_files=$(git diff $base_branch --name-status --diff-filter=C | awk '{print $2}' | tr "\n" "\n")
validate_no_js "Copied" $modified_files
final_return_code=$(($final_return_code+$return_code >= 1 ? 1 : 0))

modified_files=$(git diff $base_branch --name-status --diff-filter=M | awk '{print $2}' | tr "\n" "\n")
validate_no_js "Modified" $modified_files
final_return_code=$(($final_return_code+$return_code >= 1 ? 1 : 0))

modified_files=$(git diff $base_branch --name-status --diff-filter=R | awk '{print $2}' | tr "\n" "\n")
validate_no_js "Renamed" $modified_files
final_return_code=$(($final_return_code+$return_code >= 1 ? 1 : 0))

modified_files=$(git diff $base_branch --name-status --diff-filter=T | awk '{print $2}' | tr "\n" "\n")
validate_no_js "Type Changed" $modified_files
final_return_code=$(($final_return_code+$return_code >= 1 ? 1 : 0))

echo
if [[ $final_return_code -eq 1 ]]; then 
    echo "error: JS(X)? files detected, be sure to update the files above before proceeding"
fi
echo "Exiting with code: $final_return_code"
exit $final_return_code