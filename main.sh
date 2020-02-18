#!/bin/bash
set -e

if [ -z $1 ]; then    
    echo "Base branch argument not found, in most cases it should be origin/master"
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
    shift
    local files_changed=("$@")
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
                        js_files_array=("${js_files_array[@]}" "$file_changed")
                        return_code=1
                    fi
                fi
            done
        fi       
    done
    if [[ $return_code -eq 1  ]]; then
        echo "  $updated_type:"        
        for js_file in ${js_files_array[@]}
        do
            echo "      $js_file"
        done
    fi
}

filter_out_minor_changes() {
    # Function only meant to be used with "modified" files
    local git_diff_stats
    git_diff_stats=$(git diff $base_branch --numstat --diff-filter=M)
    SAVEIFS=$IFS   # Save current IFS
    IFS=$'\n'      # Change IFS to new line
    git_diff_stats=($git_diff_stats) # split to array
    IFS=$SAVEIFS   # Restore IFS
   
    modified_files=

    for (( i=0; i<${#git_diff_stats[@]}; i++ )) ; 
    do
        stat_lines=(${git_diff_stats[$i]})

        lines_added=${stat_lines[0]}
        lines_removed=${stat_lines[1]}
        filename=${stat_lines[2]}

        # Strategy to determine significance - tweak as needed
        if [ $lines_added -ge 5 ]; then
            modified_files="$modified_files $filename"
        fi
    done
}

echo "Started typescript migration"

modified_files=$(git diff $base_branch --name-status --diff-filter=A | awk '{print $2}' | tr "\n" "\n")
validate_no_js "Added" "${modified_files[@]}"
final_return_code=$(($final_return_code+$return_code >= 1 ? 1 : 0))

filter_out_minor_changes
validate_no_js "Modified" "${modified_files[@]}"
final_return_code=$(($final_return_code+$return_code >= 1 ? 1 : 0))

modified_files=$(git diff $base_branch --name-status --diff-filter=R | awk '{print $3}' | tr "\n" "\n")
validate_no_js "Renamed" "${modified_files[@]}"
final_return_code=$(($final_return_code+$return_code >= 1 ? 1 : 0))

# TODO(etsai) - I cannot seem to replicate these diff filter changes
# modified_files=$(git diff $base_branch --name-status --diff-filter=C | awk '{print $2}' | tr "\n" "\n")
# validate_no_js "Copied" "${modified_files[@]}"
# final_return_code=$(($final_return_code+$return_code >= 1 ? 1 : 0))

# modified_files=$(git diff $base_branch --name-status --diff-filter=T | awk '{print $2}' | tr "\n" "\n")
# validate_no_js "Type Changed" "${modified_files[@]}"
# final_return_code=$(($final_return_code+$return_code >= 1 ? 1 : 0))

echo
if [[ $final_return_code -eq 1 ]]; then 
    echo "error: JS(X)? files detected, be sure to update the files above before proceeding"
else
    echo "All touched files have been updated"
fi
echo "Exiting with code: $final_return_code"
exit $final_return_code
